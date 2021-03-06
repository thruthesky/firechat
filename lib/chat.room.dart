part of 'firechat.dart';

/// Chat room message list helper class.
///
/// By defining this helper class, you may open more than one chat room at the same time.
/// todo separate this class to `chat.dart`
class ChatRoom extends ChatBase {
  /// Api Singleton
  static ChatRoom _instance;
  static ChatRoom get instance {
    if (_instance == null) {
      _instance ??= ChatRoom();
    }
    return _instance;
  }

  int _limit = 30;

  /// upload progress
  double progress = 0;

  /// When user scrolls to top to view previous messages, the app fires the scroll event
  /// too much, so it fetches too many batches(pages) at one time.
  /// [_throttle] reduces the scroll event to relax the fetch racing.
  /// [_throttle] is working together with [_throttling]
  /// 1500ms is recommended.
  int _throttle = 1500;
  bool _throttling = false;

  /// When the room information changes or there is new message, then [changes] will be posted.
  ///
  /// This event will be posted when
  /// - init with `null`
  /// - fetching messages(created, modified, updated), with the last chat message.
  ///   When there are messages from Firestore, there might be many message in one fetch, that's why it returns only last message.
  /// - sending a message, with the chat message to be sent.
  /// - cancelling for sending a message. `null` will be passed.
  BehaviorSubject<ChatMessage> changes = BehaviorSubject.seeded(null);

  /// When user scrolls, this event is posted.
  /// If it is scroll up, true will be passed over the parameter.s
  PublishSubject<bool> scrollChanges = PublishSubject();

  /// Whenever global room information chagnes, [globalRoomChanges] will be posted with
  /// the global room document
  ///
  BehaviorSubject<ChatGlobalRoom> globalRoomChanges = BehaviorSubject.seeded(null);

  StreamSubscription _chatRoomSubscription;
  StreamSubscription _currentRoomSubscription;
  StreamSubscription _globalRoomSubscription;

  /// Loaded the chat messages of current chat room.
  List<ChatMessage> messages = [];

  /// [loading] becomes true while the app is fetching more messages.
  /// The app should display loader while it is fetching.
  bool loading = false;

  /// Current room's global room document.
  ///
  /// Use this to dipplay title or other information of the current room.
  /// When `/chat/global-rooms/list/{roomId}` changes, it will be updated and calls render handler.
  ChatGlobalRoom global;

  /// Chat room properties
  String get id => global?.roomId ?? '';
  String get title => global?.title;

  /// The [users] holds the firebase uid(s) of the global.users which will be loaded
  /// when user enters chat room and the global room information has fetched.
  /// The [users] will be available immediately after chat room entering.
  List<String> get users => global?.users;
  List<String> get moderators => global?.moderators;
  List<String> get blockedUsers => global?.blockedUsers;
  Timestamp get createdAt => global.createdAt;

  /// push notification topic name
  String get topic => 'notifyChat-${this.id}';

  final textController = TextEditingController();
  final scrollController = ScrollController();

  /// When keyboard(keypad) is open, the app needs to adjust the scroll.
  final keyboardVisibilityController = KeyboardVisibilityController();
  StreamSubscription keyboardSubscription;

  /// Scrolls down to the bottom when,
  /// * chat room is loaded (only one time.)
  /// * when I chat,
  /// * when new chat is coming and the page is scrolled near to bottom. Logically it should not scroll down when the page is scrolled far from the bottom.
  /// * when keyboard is open and the page scroll is near to bottom. Locally it should not scroll down when the user is reading message that is far from the bottom.
  scrollToBottom({int ms = 100}) {
    /// This is needed to safely scroll to bottom after chat messages has been added.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients)
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: ms), curve: Curves.ease);
    });
  }

  ChatMessage isMessageEdit;
  bool get isCreate => isMessageEdit == null;

  String _displayName;

  String get displayName => _displayName ?? loginUserUid;

  /// Enter chat room
  ///
  /// If [hatch] is set to true, then it will always create new room even if you are talking to
  /// same person. The room id is auto generated by adding new document.
  /// If [hatch] is set to false, then it will do md5() with the ID(s) of room users, so, it
  /// does not generate new room id.
  ///
  /// Null or empty string in [users] will be wiped out.
  ///
  /// Whenever global room information changes, it is updated on [global].
  Future<void> enter({String id, List<String> users, bool hatch = true, String displayName}) async {
    /// confusing with [this.id], so, it goes as `_id`.
    String _id = id;
    _displayName = displayName;

    if (loginUserUid == null) {
      throw LOGIN_FIRST;
    }

    if (users == null) users = [];
    // [users] has empty elem,ent, remove.
    users.removeWhere((element) => element == null || element == '');
    if (_id != null && users.length > 0) {
      throw BOTH_OF_ID_AND_USERS_HAVE_VALUE;
    }

    if (_id == null && users.length == 0) {
      throw EMPTY_ID_AND_USERS;
    }

    // Note that, if `id` is set, `users` is ignored. And if both exists, it throws an error.
    if (_id != null) {
      // Enter existing room
      // If permission-denied error happens here,
      // 1. Probably the room does not exists.
      // 2. Or, the login user is not a user of the room.
      // print(f.user.uid);
      // print(_id);
      global = await getGlobalRoom(_id);
    } else {
      // Add login user(uid) into room users.
      users.add(loginUserUid);
      // Avoid duplicated users.
      users = users.toSet().toList();
      if (hatch) {
        // Always create new room
        await ___create(users: users);
      } else {
        // Create room named based on the user
        // Users array can contain no user or only one user, or even many users.
        // User id must be sorted to generate same room id with same user.
        users.sort();
        String uids = users.join('');
        _id = md5.convert(utf8.encode(uids)).toString();
        try {
          // Get global room to see if it exists
          // print("======================== get room information ======================");
          global = await getGlobalRoom(_id);

          // Base on the security rule the code below will not called even the room doesnt exist
          // because it will throw an error of permission-denied if global-rooms/list/room_id doesnt exist
          // if not exists, create.
          if (global == null) {
            // print("==================== global is null =========================");
            await ___create(id: _id, users: users);
          }
        } catch (e) {
          // If room does not exist(or it cannot read), then create.
          // getGlobalRoom(id) will throw error if room doesnt exist yet, and it will fall down to `permission-denied`.
          if (e.code == 'permission-denied') {
            // continue to create room
            // print("============== permission-denied ========================");
            await ___create(id: _id, users: users);
          } else {
            rethrow;
          }
        }
      }
    }

    // fetch latest messages
    fetchMessages();

    // Listening current global room for changes and update.
    if (_globalRoomSubscription != null) _globalRoomSubscription.cancel();

    _globalRoomSubscription = globalRoomDoc(global.roomId).snapshots().listen((event) {
      global = ChatGlobalRoom.fromSnapshot(event);
      // print(' ------------> global updated; ');
      // print(global);
      globalRoomChanges.add(global);
    });

    // Listening current room document change event (in my room list).
    //
    // This will be notify the listener when chat room title changes, or new users enter, etc.
    if (_currentRoomSubscription != null) _currentRoomSubscription.cancel();
    _currentRoomSubscription = currentRoom.snapshots().listen((DocumentSnapshot doc) {
      if (doc.exists == false) {
        // User left the room. So the room does not exists.
        return;
      }

      // If the user got a message from a chat room where the user is currently in,
      // then, set `newMessages` to 0.
      final data = ChatUserRoom.fromSnapshot(doc);
      if (int.parse(data.newMessages) > 0 && data.createdAt != null) {
        currentRoom.update({'newMessages': 0});
      }
    });

    // fetch previous chat when user scrolls up
    scrollController.addListener(() {
      // mark if scrolled up
      if (scrollUp) {
        scrolledUp = true;
      }
      // fetch previous messages
      if (scrollUp && atTop) {
        fetchMessages();
      }
      scrollChanges.add(scrollUp);
    });

    // Listen to keyboard
    //
    // When keyboard opens, scroll to bottom only if needed when user open/hide keyboard.
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible && atBottom) {
        scrollToBottom(ms: 10);
      }
    });
  }

  /// Returns the current room in my room list.
  DocumentReference get currentRoom => myRoom(id);

  Future<void> ___create({List<String> users, String id}) async {
    // String roomId = chatRoomId();
    // print('roomId: $roomId');

    final info = ChatGlobalRoom(
      users: users,
      moderators: [loginUserUid],
      createdAt: FieldValue.serverTimestamp(),
    );

    DocumentReference doc;
    if (id == null) {
      doc = await globalRoomListCol.add(info.data);
    } else {
      doc = globalRoomListCol.doc(id);
      // Cannot create if the document is already exists.
      // Cannot update if the user is not one of the room user.
      await doc.set(info.data);
    }

    global = ChatGlobalRoom.fromSnapshot(await doc.get());

    await sendMessage(
      text: ChatProtocol.roomCreated,
      displayName: displayName,
    );
  }

  /// Fetch previous messages
  fetchMessages() async {
    if (_throttling || noMoreMessage) return;
    loading = true;
    _throttling = true;

    page++;
    if (page == 1) {
      final ref = myRoom(global.roomId);
      // print('ref: ${ref.path}');
      await ref.set({'newMessages': 0}, SetOptions(merge: true));
    }

    /// Get messages for the chat room
    Query q = messagesCol(global.roomId)
        .orderBy('createdAt', descending: true)

        /// todo make it optional from firestore settings.
        .limit(_limit); // 몇 개만 가져온다.

    if (messages.isNotEmpty) {
      q = q.startAfter([messages.first.createdAt]);
    }

    // Listens all the message for update/delete.
    //
    // Note that, when a user chats, [changes] event will be posted twice. one for
    // create(for offline support), the other for modified(real data from firestore).
    // And this may cause the app to render twice and scroll to bottom twice. You may
    // do `debounce` to fix this one.
    _chatRoomSubscription = q.snapshots().listen((snapshot) {
      // print('fetchMessage() -> done: _page: $_page');
      // Block loading previous messages for some time.

      loading = false;
      Timer(Duration(milliseconds: _throttle), () => _throttling = false);

      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final message = ChatMessage.fromData(documentChange.doc.data(), id: documentChange.doc.id);

        // message.id = documentChange.doc.id;

        // print('type: ${documentChange.type}. ${message['text']}');

        /// 새로 채팅을 하거나, 이전 글을 가져 올 때, 새 채팅(생성)뿐만 아니라, 이전 채팅 글을 가져올 때에도 added 이벤트 발생.
        if (documentChange.type == DocumentChangeType.added) {
          // Two events will be fired on the sender's device.
          // First event has null of FieldValue.serverTimestamp()
          // Only one event will be fired on other user's devices.
          if (message.createdAt == null) {
            messages.add(message);
          }

          /// if it's new message, add at bottom.
          else if (messages.length > 0 &&
              messages[0].createdAt != null &&
              message.createdAt.microsecondsSinceEpoch >
                  messages[0].createdAt.microsecondsSinceEpoch) {
            messages.add(message);
          } else {
            // if it's old message, add on top.
            messages.insert(0, message);
          }

          // if it is loading old messages
          // and if it has less messages than the limit
          // check if it is the very first message.
          if (message.createdAt != null) {
            if (snapshot.docs.length < _limit) {
              if (message.text == ChatProtocol.roomCreated) {
                noMoreMessage = true;
                // print('-----> noMoreMessage: $noMoreMessage');
              }
            }
          }
        } else if (documentChange.type == DocumentChangeType.modified) {
          final int i = messages.indexWhere((r) => r.id == message.id);
          if (i > -1) {
            messages[i] = message;
          }
        } else if (documentChange.type == DocumentChangeType.removed) {
          final int i = messages.indexWhere((r) => r.id == message.id);
          if (i > -1) {
            messages.removeAt(i);
          }
        } else {
          assert(false, 'This is error');
        }
      });

      changes.add(messages.last);
    });
  }

  /// Unsubscribe room event listeners
  ///
  /// Especially when unit testing, multiple users log in/out at the same time
  /// and permission erros will happen here by listening other user's document.
  ///
  ///
  /// Must be set to null since these are checked if null before re-subscriptoin.
  ///
  /// When a user enters a chat room, the app will listen,
  /// 1. the chat message colltion,
  /// 2. the current room information,
  /// 3. the global room infromation
  /// And right before the user leave the room, it should be unsubscribed.
  unsubscribe() {
    if (_chatRoomSubscription != null) {
      _chatRoomSubscription.cancel();
      _chatRoomSubscription = null;
    }
    if (_currentRoomSubscription != null) {
      _currentRoomSubscription.cancel();
      _currentRoomSubscription = null;
    }
    if (_globalRoomSubscription != null) {
      _globalRoomSubscription.cancel();
      _globalRoomSubscription = null;
    }

    if (keyboardSubscription != null) {
      keyboardSubscription.cancel();
      keyboardSubscription = null;
    }
    resetRoom();
  }

  resetRoom() {
    global = null;
    messages = [];
    page = 0;
    noMoreMessage = false;
  }

  /// Send chat message to the users in the room
  ///
  /// [displayName] is the name that the sender will use. The default is
  /// `ff.user.displayName`.
  ///
  /// [photoURL] is the sender's photo url. Default is `ff.user.photoURL`.
  ///
  /// [type] is the type of the message. It can be `image` or `text` if string only.
  Future<Map<String, dynamic>> sendMessage({
    @required String text,
    Map<String, dynamic> extra,
    @required String displayName,
    String photoURL = '',
  }) async {
    if (displayName == null || displayName.trim() == '') {
      throw CHAT_DISPLAY_NAME_IS_EMPTY;
    }

    Map<String, dynamic> message = {
      'senderUid': loginUserUid,
      'senderDisplayName': displayName,
      'senderPhotoURL': photoURL,
      'text': text,

      // Make [newUsers] empty string for re-setting(removing) from previous
      // message.
      'newUsers': [],

      if (extra != null) ...extra,
    };

    if (isCreate) {
      // Time that this message(or last message) was created.
      message['createdAt'] = FieldValue.serverTimestamp();

      await messagesCol(global.roomId).add(message);
      // print(message);
      message['newMessages'] = FieldValue.increment(1); // To increase, it must be an udpate.
      List<Future<void>> messages = [];

      /// Just incase there are duplicated UIDs.
      List<String> roomUsers = [...global.users.toSet()];

      /// Send a message to all users in the room.
      for (String uid in roomUsers) {
        // print(chatUserRoomDoc(uid, info['id']).path);
        messages.add(userRoomDoc(uid, global.roomId).set(message, SetOptions(merge: true)));
      }
      // print('send messages to: ${messages.length}');
      await Future.wait(messages);
    } else {
      message['updatedAt'] = FieldValue.serverTimestamp();
      await messagesCol(global.roomId).doc(isMessageEdit.id).update(message);
      isMessageEdit = null;
    }

    return message;
  }

  /// Add users to chat room
  ///
  /// Once user(s) has added, `who added who` messages will be delivered to all
  /// of room users. `newUsers` array will have the names of newly added users.
  ///
  /// [users] is a Map of user uid and user name. like `{uidA: 'nameA', ...}`
  ///
  /// See readme
  ///
  /// todo before adding user, check if the user is in `blockedUsers` property and if yes, throw a special error code.
  /// Todo move this method to `ChatRoom`
  /// todo use arrayUnion on Firestore
  Future<void> addUser(Map<String, String> users) async {
    /// Get latest info from server.
    /// There might be a chance that somehow `info['users']` is not upto date.
    /// So, it is safe to get room info from server.
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);

    if (_globalRoom.blockedUsers != null && _globalRoom.blockedUsers.length > 0) {
      for (String blockedUid in _globalRoom.blockedUsers) {
        if (users.keys.contains(blockedUid)) {
          throw ONE_OF_USERS_ARE_BLOCKED;
        }
      }
    }

    List<String> newUsers = [...List<String>.from(_globalRoom.users), ...users.keys.toList()];
    newUsers = newUsers.toSet().toList();

    /// Update users first and then send chat messages to all users.
    /// In this way, newly entered/added user(s) will have the room in the my-room-list

    /// Update users array with added user.
    final doc = globalRoomDoc(_globalRoom.roomId);
    await doc.update({'users': newUsers});

    /// Update last message of room users.
    await sendMessage(text: ChatProtocol.add, displayName: displayName, extra: {
      'newUsers': users.values.toList(),
    });
  }

  /// Returns a user's room (that has last message of the room) document
  /// reference.
  DocumentReference userRoomDoc(String uid, String roomId) {
    return userRoomListCol(uid).doc(roomId);
  }

  /// Moderator removes a user
  Future<void> blockUser(String uid, String userName) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    _globalRoom.users.remove(uid);

    // List<String> blocked = info.blocked ?? [];
    _globalRoom.blockedUsers.add(uid);

    /// Update users and blockedUsers first to inform by sending a message.
    await globalRoomDoc(id)
        .update({'users': _globalRoom.users, 'blockedUsers': _globalRoom.blockedUsers});

    /// Inform all users.
    await sendMessage(
        text: ChatProtocol.block, displayName: displayName, extra: {'userName': userName});
  }

  /// Add a moderator
  ///
  /// Only moderator can add a user to moderator.
  /// The user must be included in `users` array.
  ///
  Future<void> addModerator(String uid, {String userName}) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    List<String> moderators = _globalRoom.moderators;
    if (moderators.contains(loginUserUid) == false) throw YOU_ARE_NOT_MODERATOR;
    if (_globalRoom.users.contains(uid) == false) throw MODERATOR_NOT_EXISTS_IN_USERS;
    moderators.add(uid);
    await globalRoomDoc(id).update({'moderators': moderators});
    await sendMessage(
        text: ChatProtocol.addModerator,
        displayName: displayName,
        extra: {'userName': userName ?? uid});
  }

  /// Remove a moderator.
  ///
  /// Only moderator can remove a moderator.
  Future<void> removeModerator(String uid, {String userName}) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    List<String> moderators = _globalRoom.moderators;
    moderators.remove(uid);
    await globalRoomDoc(id).update({'moderators': moderators});

    await sendMessage(
        text: ChatProtocol.removeModerator,
        displayName: displayName,
        extra: {'userName': userName ?? uid});
  }

  /// User go out of a room. The user is no longer part of the room
  ///
  /// Once a user has left, the user will not be able to update last message of
  /// room users. So, before leave, it should update 'leave' last message of room users.
  ///
  /// For moderator to block user, see [chatBlockUser]
  ///
  /// [roomId] is the chat room id.
  /// [uid] is the user to be kicked out by moderator.
  /// [userName] is the userName to leave or to be kicked out. and it is required.
  /// [text] is the text to send to all users.
  ///
  /// This method throws permission error when a user try to remove another user.
  /// But admin can remove other users.
  ///
  ///
  /// then move the room information from /chat/info/room-list to /chat/info/deleted-room-list.
  Future<void> leave() async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);

    // If there is only one user left (which is himself), then he can leave without setting other user to admin.

    // if the last moderator tries to leave, ask the moderator to add another user to moderator.
    // if (_globalRoom.moderators.contains(loginUserUid) && _globalRoom.moderators.length == 1) {
    //   throw ADD_NEW_MODERATOR_BEFORE_YOU_LEAVE;
    // }

    // Update last message of room users that the user is leaving.
    await sendMessage(
        text: ChatProtocol.leave, displayName: displayName, extra: {'userName': loginUserUid});

    /// remove the login user from [_globalRoom.users] users array.
    _globalRoom.users.remove(loginUserUid);

    // A moderator leaves the room?
    if (_globalRoom.moderators.contains(loginUserUid)) {
      // There is no more moderator for the room? but there are more than 2 uesrs?
      if (_globalRoom.moderators.length == 1 && _globalRoom.users.length >= 2) {
        // Then, set the first one (not the moderator) to moderator.
        await addModerator(_globalRoom.users.first);
      }
      // Then, remove himself from moderator.
      await removeModerator(loginUserUid);
    }

    // Update users after removing himself.
    await globalRoomDoc(_globalRoom.roomId).update({'users': _globalRoom.users});

    // Delete the room that the user is leaving from. (Not the global room.)
    await myRoom(id).delete();

    // This will cause `null` for room existence check on currentRoom.snapshot().listener(...);
    unsubscribe();
    ChatUserRoomList.instance.unsubscribeUserRoom(_globalRoom);
  }

  /// Kicks a user out of the room.
  ///
  /// The user who was kicked can enter room again by himself. Somebody must add
  /// him.
  /// Only moderator can kick a user out.
  Future<void> kickout(String uid, String userName) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);

    if (_globalRoom.moderators.contains(loginUserUid) == false) throw YOU_ARE_NOT_MODERATOR;
    if (_globalRoom.users.contains(uid) == false) throw USER_NOT_EXIST_IN_ROOM;
    _globalRoom.users.remove(uid);

    // Update users after removing himself.
    await globalRoomDoc(_globalRoom.roomId).update({'users': _globalRoom.users});

    await sendMessage(
        text: ChatProtocol.kickout, displayName: displayName, extra: {'userName': userName});
  }

  /// Returns a room of a user.
  Future<ChatUserRoom> getMyRoomInfo(String uid, String roomId) async {
    DocumentSnapshot snapshot = await userRoomDoc(uid, roomId).get();
    if (snapshot.exists) {
      return ChatUserRoom.fromSnapshot(snapshot);
    } else {
      throw ROOM_NOT_EXISTS;
    }
  }

  Future<void> updateTitle(String title) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);

    if (_globalRoom.moderators.contains(loginUserUid) == false) throw YOU_ARE_NOT_MODERATOR;

    // Update users after removing himself.
    await globalRoomDoc(_globalRoom.roomId).update({'title': title});

    await sendMessage(
        text: ChatProtocol.titleChanged, displayName: displayName, extra: {'newTitle': title});
  }

  editMessage(ChatMessage message) {
    print('editMessage');
    textController.text = message.text;
    isMessageEdit = message;
    changes.add(message);
  }

  bool isMessageOnEdit(ChatMessage message) {
    if (isCreate) return false;
    if (!message.isMine) return false;
    return message.id == isMessageEdit.id;
  }

  cancelEdit() {
    textController.text = '';
    isMessageEdit = null;
    changes.add(null);
  }

  deleteMessage(ChatMessage message) {
    messagesCol(id).doc(message.id).delete();
  }

  @Deprecated('Use [userRoom]')
  Future<ChatUserRoom> get lastMessage => getMyRoomInfo(loginUserUid, id);

  /// Get the document of user's current chat room which has the last message.
  ///
  /// User's private room has all the information of last chat.
  ///
  /// Note that `getMyRoomInfo()` returns `ChatRoomInfo` while `myRoom()`
  /// returns document reference.
  Future<ChatUserRoom> get userRoom => getMyRoomInfo(loginUserUid, id);

  bool get atBottom {
    return scrollController.offset > (scrollController.position.maxScrollExtent - 640);
  }

  bool get atTop {
    return scrollController.position.pixels < 200;
  }

  /// The [scrolledUp] becomes true once the user scrolls up the chat room screen.
  /// Use this to determine if the user has scrolled up the screen.
  /// This may be used to control the screen to move downward to bottom when there are images on the messages.
  bool scrolledUp = false;
  bool get scrollUp {
    return scrollController.position.userScrollDirection == ScrollDirection.forward;
  }

  bool get scrollDown {
    return scrollController.position.userScrollDirection == ScrollDirection.reverse;
  }

  onImageLoadComplete(ChatMessage message) {
    // If the user didn't scroll up the screen (which means, it is really very first time entering the chat room),
    // then scroll to the bottom on every image load of the message(images).
    if (scrolledUp == false) {
      scrollToBottom();
    }

    // If the last message is image and it is shown to screen for the first time (which means, new image has uploaded/come),
    // then scroll to the bottom.
    // Since the image has rendered once it has screen down, when user scrolls up, it will not interrupt the scroll.
    bool lastMessage = message.id == messages.last.id;
    if (lastMessage && message.rendered == false) {
      message.rendered = true;
      ChatRoom.instance.scrollToBottom();
    }
  }
}
