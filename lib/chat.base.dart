part of './firechat.dart';

class ChatBase {
  String get loginUserUid =>
      FirebaseAuth.instance.currentUser == null ? null : FirebaseAuth.instance.currentUser.uid;

  bool get isLogin => FirebaseAuth.instance.currentUser != null;
  FirebaseFirestore get db => FirebaseFirestore.instance;

  int page = 0;

  /// [noMoreMessage] becomes true when there is no more old messages to view.
  /// The app should display 'no more message' to user.
  bool noMoreMessage = false;

  /// Returns the global chat room collection
  ///
  ///
  CollectionReference get globalRoomListCol {
    return db.collection('chat').doc('global-rooms').collection('list');
  }

  /// Returns login user's room list collection `/chat/my-room-list/{my-uid}` reference.
  ///
  ///
  CollectionReference get myRoomListCol {
    return userRoomListCol(loginUserUid);
  }

  /// Return the collection of messages of the room id.
  CollectionReference messagesCol(String roomId) {
    return db.collection('chat').doc('messages').collection(roomId);
  }

  /// Returns my room list collection `/chat/user-rooms/{uid}` reference.
  ///
  CollectionReference userRoomListCol(String userId) {
    return db.collection('chat').doc('user-rooms').collection(userId);
  }

  /// Returns my room (that has last message of the room) document
  /// reference.
  DocumentReference userRoomDoc(String userId, String roomId) {
    return userRoomListCol(userId).doc(roomId);
  }

  /// Returns `/chat/global-rooms/list/{roomId}` document reference
  ///
  DocumentReference globalRoomDoc(String roomId) {
    return globalRoomListCol.doc(roomId);
  }

  /// Returns document reference of my room (that has last message of the room)
  ///
  /// `/chat/user-rooms/uid/{roomId}`
  DocumentReference myRoom(String roomId) {
    return myRoomListCol.doc(roomId);
  }

  text(ChatMessage message) {
    String text = message.text ?? '';

    if (text == ChatProtocol.roomCreated) {
      text = message.senderDisplayName + '님이 채팅방을 개설했습니다.';
    }
    if (text == ChatProtocol.add) {
      text = message.senderDisplayName + ' added ' + message.newUsers.join(',');
    }
    if (text == ChatProtocol.kickout) {
      text = message.senderDisplayName + ' kicked ' + message.data['userName'];
    }
    if (text == ChatProtocol.block) {
      text = message.senderDisplayName + ' block  ' + message.data['userName'];
    }

    if (text == ChatProtocol.addModerator) {
      text = message.senderDisplayName + ' add moderator ' + message.data['userName'];
    }
    if (text == ChatProtocol.removeModerator) {
      text = message.senderDisplayName + ' remove moderator ' + message.data['userName'];
    }

    if (text == ChatProtocol.titleChanged) {
      text = message.senderDisplayName + ' change room title ';
      text += message.data['newTitle'] != null ? 'to ' + message.data['newTitle'] : '';
    }

    if (text == ChatProtocol.enter) {
      // print(message);
      text = "${message.senderDisplayName} invited ${message.newUsers}";
    }
    return text;
  }

  /// Returns the room list info `/chat/global-rooms/list/{roomId}` document.
  ///
  /// If the room does not exists, it returns null.
  /// The return value has `id` as its room id.
  ///
  /// Todo move this method to `ChatRoom`
  Future<ChatGlobalRoom> getGlobalRoom(String roomId) async {
    DocumentSnapshot snapshot = await globalRoomDoc(roomId).get();
    return ChatGlobalRoom.fromSnapshot(snapshot);
  }
}
