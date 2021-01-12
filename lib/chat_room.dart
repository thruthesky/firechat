part of 'firechat.dart';

/// Chat room message list helper class.
///
/// By defining this helper class, you may open more than one chat room at the same time.
/// todo separate this class to `chat.dart`
class ChatRoom extends ChatBase {
  /// [render] will be called to notify chat room listener to re-render the screen.
  ///
  /// For one chat message sending,
  /// - [render] will be invoked 2 times on message sender's device due to offline support.
  /// - [render] will be invoked 1 times on receiver's device.
  ///
  /// [globalRoomChange] will be invoked when global chat room changes.
  ChatRoom({
    @required String loginUserId,
    Function render,
    Function globalRoomChange,
  })  : _render = render,
        _globalRoomChange = globalRoomChange {
    this.loginUserId = loginUserId;
  }

  int _limit = 30;

  /// When user scrolls to top to view previous messages, the app fires the scroll event
  /// too much, so it fetches too many batches(pages) at one time.
  /// [_throttle] reduces the scroll event to relax the fetch racing.
  /// [_throttle] is working together with [_throttling]
  /// 1500ms is recommended.
  int _throttle = 1500;

  /// TODO overwrite this setting by Firestore setting.
  bool _throttling = false;

  ///
  Function _render;
  Function _globalRoomChange;

  StreamSubscription _chatRoomSubscription;
  StreamSubscription _currentRoomSubscription;
  StreamSubscription _globalRoomSubscription;

  /// Loaded the chat messages of current chat room.
  List<Map<String, dynamic>> messages = [];

  /// [loading] becomes true while the app is fetching more messages.
  /// The app should display loader while it is fetching.
  bool loading = false;

  /// Deprecated: since this produces flashing by rendering again.
  /// Most of the time, fetching finishes to quickly and users won't see the loader.
  /// This prevents loading disappearing too quickly.
  /// 500ms is recommended.
  // int _loadingTimeout = 500;

  /// Global room info (of current room)
  /// Use this to dipplay title or other information about the room.
  /// When `/chat/global/room-list/{roomId}` changes, it will be updated and calls render handler.
  ///
  ChatGlobalRoom global;

  /// Chat room properties
  String get id => global?.roomId;
  String get title => global?.title;
  List<String> get users => global?.users;
  List<String> get moderators => global?.moderators;
  List<String> get blockedUsers => global?.blockedUsers;
  Timestamp get createdAt => global.createdAt;

  /// push notification topic name
  String get topic => 'notifyChat-${this.id}';

  /// Enter chat room
  ///
  /// If [hatch] is set to true, then it will always create new room.
  /// null or empty string in [users] will be wiped out.
  Future<void> enter({String id, List<String> users, bool hatch = true}) async {
    String _id = id;

    if (users == null) users = [];
    // [users] has empty elem,ent, remove.
    users.removeWhere((element) => element == null || element == '');
    if (_id != null && users.length > 0) {
      throw 'ONE_OF_ID_OR_USERS_MUST_BE_NULL';
    }

    if (_id == null && users.length == 0) {
      throw 'ONE_OF_ID_OR_USERS_MUST_HAVE_VALUE';
    }

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
      users.add(loginUserId);
      users = users.toSet().toList();
      if (hatch) {
        // Always create new room
        await ___create(users: users);
      } else {
        // Create room named based on the user
        // Users array can contain no user or only one user, or even many users.
        users.sort();
        String uids = users.join('');
        _id = md5.convert(utf8.encode(uids)).toString();
        try {
          global = await getGlobalRoom(_id);
          if (global == null) {
            await ___create(id: _id, users: users);
          }
        } catch (e) {
          // If room does not exist(or it cannot read), then create.
          if (e.code == 'permission-denied') {
            // continue to create room
            await ___create(id: _id, users: users);
          } else {
            rethrow;
          }
        }
      }
    }

    // fetch latest messages
    fetchMessages();

    // Listening current global room for changes
    if (_globalRoomSubscription != null) _globalRoomSubscription.cancel();

    _globalRoomSubscription = globalRoomDoc(_id).snapshots().listen((event) {
      global = ChatGlobalRoom.fromSnapshot(event);
      if (_globalRoomChange != null) {
        _globalRoomChange();
      }
    });

    // Listening current room in my room list.
    //
    // This will be notify chat room listener when chat room title changes, or new users enter, etc.
    if (_currentRoomSubscription != null) _currentRoomSubscription.cancel();
    _currentRoomSubscription = currentRoom.snapshots().listen((DocumentSnapshot doc) {
      // If the user got a message from a chat room where the user is currently in,
      // then, set `newMessages` to 0.
      final data = ChatUserRoom.fromSnapshot(doc);
      if (data.newMessages > 0 && data.createdAt != null) {
        currentRoom.update({'newMessages': 0});
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
      moderators: [loginUserId],
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

    await sendMessage(text: ChatProtocol.roomCreated, displayName: loginUserId);
  }

  /// Notify chat room listener to re-render the screen.
  _notify() {
    if (_render != null) _render();
  }

  /// Fetch previous messages
  fetchMessages() {
    if (_throttling || noMoreMessage) return;
    loading = true;
    _throttling = true;

    page++;
    if (page == 1) {
      // don't wait
      myRoom(global.roomId).set({'newMessages': 0}, SetOptions(merge: true));
    }

    /// Get messages for the chat room
    Query q = messagesCol(global.roomId)
        .orderBy('createdAt', descending: true)

        /// todo make it optional from firestore settings.
        .limit(_limit); // 몇 개만 가져온다.

    if (messages.isNotEmpty) {
      q = q.startAfter([messages.first['createdAt']]);
    }

    _chatRoomSubscription = q.snapshots().listen((snapshot) {
      // print('fetchMessage() -> done: _page: $_page');
      // Block loading previous messages for some time.

      loading = false;
      Timer(Duration(milliseconds: _throttle), () => _throttling = false);
      // Timer(Duration(milliseconds: _loadingTimeout), () {
      //   loading = false;
      //   _notify();
      // });

      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final message = documentChange.doc.data();

        message['id'] = documentChange.doc.id;

        // print('type: ${documentChange.type}. ${message['text']}');

        /// 새로 채팅을 하거나, 이전 글을 가져 올 때, 새 채팅(생성)뿐만 아니라, 이전 채팅 글을 가져올 때에도 added 이벤트 발생.
        if (documentChange.type == DocumentChangeType.added) {
          // Two events will be fired on the sender's device.
          // First event has null of FieldValue.serverTimestamp()
          // Only one event will be fired on other user's devices.
          if (message['createdAt'] == null) {
            messages.add(message);
          }

          /// if it's new message, add at bottom.
          else if (messages.length > 0 &&
              messages[0]['createdAt'] != null &&
              message['createdAt'].microsecondsSinceEpoch > messages[0]['createdAt'].microsecondsSinceEpoch) {
            messages.add(message);
          } else {
            // if it's old message, add on top.
            messages.insert(0, message);
          }

          // if it is loading old messages
          // and if it has less messages than the limit
          // check if it is the very first message.
          if (message['createdAt'] != null) {
            if (snapshot.docs.length < _limit) {
              if (message['text'] == ChatProtocol.roomCreated) {
                noMoreMessage = true;
                // print('-----> noMoreMessage: $noMoreMessage');
              }
            }
          }
        } else if (documentChange.type == DocumentChangeType.modified) {
          final int i = messages.indexWhere((r) => r['id'] == message['id']);
          if (i > -1) {
            messages[i] = message;
          }
        } else if (documentChange.type == DocumentChangeType.removed) {
          final int i = messages.indexWhere((r) => r['id'] == message['id']);
          if (i > -1) {
            messages.removeAt(i);
          }
        } else {
          assert(false, 'This is error');
        }
      });
      _notify();
    });
  }

  unsubscribe() {
    _chatRoomSubscription.cancel();
    _currentRoomSubscription.cancel();
    _globalRoomSubscription.cancel();
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
      'senderUid': loginUserId,
      'senderDisplayName': displayName,
      'senderPhotoURL': photoURL,
      'text': text,

      // Time that this message(or last message) was created.
      'createdAt': FieldValue.serverTimestamp(),

      // Make [newUsers] empty string for re-setting(removing) from previous
      // message.
      'newUsers': [],

      if (extra != null) ...extra,
    };

    // message = mergeMap([message, extra]);

    // print('my uid: ${f.user.uid}');
    // print('users: ${this.users}');
    // print('extra: $extra');
    // print(message);
    // print(messagesCol(id).path);
    await messagesCol(global.roomId).add(message);
    // print(message);
    message['newMessages'] = FieldValue.increment(1); // To increase, it must be an udpate.
    List<Future<void>> messages = [];

    /// Just incase there are duplicated UIDs.
    List<String> newUsers = [...global.users.toSet()];

    /// Send a message to all users in the room.
    for (String uid in newUsers) {
      // print(chatUserRoomDoc(uid, info['id']).path);
      messages.add(userRoomDoc(uid, global.roomId).set(message, SetOptions(merge: true)));
    }
    // print('send messages to: ${messages.length}');
    await Future.wait(messages);

    // TODO: Sending notification should be handled outside of firechat.

    // await __ff.sendNotification(
    //   '$displayName send you message.',
    //   text,
    //   id: id,
    //   screen: 'chatRoom',
    //   topic: topic,
    // );

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
    // print('users:');
    // print(newUsers);
    final doc = globalRoomDoc(_globalRoom.roomId);
    // print(doc.path);
    // print('my uid: ${f.user.uid}');
    // print(newUsers);
    // print((await doc.get()).data());
    await doc.update({'users': newUsers});

    /// Update last message of room users.
    // print('newUserNames:');
    // print(users.values.toList());
    // TODO: display name.
    await sendMessage(text: ChatProtocol.add, displayName: loginUserId, extra: {
      'newUsers': users.values.toList(),
    });
  }

  /// Returns a user's room (that has last message of the room) document
  /// reference.
  DocumentReference userRoomDoc(String uid, String roomId) {
    return userRoomListCol(uid).doc(roomId);
  }

  /// Moderator removes a user
  ///
  /// TODO [roomId] should be omitted.
  Future<void> blockUser(String uid, String userName) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    _globalRoom.users.remove(uid);

    // List<String> blocked = info.blocked ?? [];
    _globalRoom.blockedUsers.add(uid);

    /// Update users and blockedUsers first to inform by sending a message.
    await globalRoomDoc(id).update({'users': _globalRoom.users, 'blockedUsers': _globalRoom.blockedUsers});

    /// Inform all users.
    await sendMessage(text: ChatProtocol.block, displayName: uid, extra: {'userName': userName});
  }

  /// Add a moderator
  ///
  /// Only moderator can add a user to moderator.
  /// The user must be included in `users` array.
  ///
  /// Todo move this method to `ChatRoom`
  Future<void> addModerator(String uid) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    List<String> moderators = _globalRoom.moderators;
    if (moderators.contains(loginUserId) == false) throw YOU_ARE_NOT_MODERATOR;
    if (_globalRoom.users.contains(uid) == false) throw MODERATOR_NOT_EXISTS_IN_USERS;
    moderators.add(uid);
    await globalRoomDoc(id).update({'moderators': moderators});
  }

  /// Remove a moderator.
  ///
  /// Only moderator can remove a moderator.
  ///
  /// Todo move this method to `ChatRoom`
  Future<void> removeModerator(String uid) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    List<String> moderators = _globalRoom.moderators;
    moderators.remove(uid);
    await globalRoomDoc(id).update({'moderators': moderators});

    // TODO inform it to all users by sending message
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
  /// TODO if moderator is leaving, it needs to remove the uid from moderator.
  /// TODO if the last moderator tries to leave, ask the moderator to add another user to moderator.
  /// TODO When a user(or a moderator) leaves the room and there is no user left in the room,
  /// then move the room information from /chat/info/room-list to /chat/info/deleted-room-list.
  Future<void> leave() async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);
    _globalRoom.users.remove(loginUserId);

    // Update last message of room users that the user is leaving.
    await sendMessage(text: ChatProtocol.leave, displayName: loginUserId, extra: {'userName': loginUserId});

    // Update users after removing himself.
    await globalRoomDoc(_globalRoom.roomId).update({'users': _globalRoom.users});

    // If I am the one who is willingly leave the room, then remove the
    // room in my-room-list.
    // print(chatMyRoom(roomId).path);
    await myRoom(id).delete();
  }

  /// Kicks a user out of the room.
  ///
  /// The user who was kicked can enter room again by himself. Somebody must add
  /// him.
  /// Only moderator can kick a user out.
  Future<void> kickout(String uid, String userName) async {
    ChatGlobalRoom _globalRoom = await getGlobalRoom(id);

    if (_globalRoom.moderators.contains(loginUserId) == false) throw YOU_ARE_NOT_MODERATOR;
    if (_globalRoom.users.contains(uid) == false) throw USER_NOT_EXIST_IN_ROOM;
    _globalRoom.users.remove(uid);

    // Update users after removing himself.
    await globalRoomDoc(_globalRoom.roomId).update({'users': _globalRoom.users});

    await sendMessage(text: ChatProtocol.leave, displayName: loginUserId, extra: {'userName': loginUserId});
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

  /// Returns the last message of current room.
  ///
  /// User's private room has all the information of last chat.
  ///
  /// Note that `getMyRoomInfo()` returns `ChatRoomInfo` while `myRoom()`
  /// returns document reference.
  Future<ChatUserRoom> get lastMessage => getMyRoomInfo(loginUserId, id);
}
