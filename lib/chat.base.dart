part of './firechat.dart';

class ChatBase {
  String get loginUserUid =>
      FirebaseAuth.instance.currentUser == null ? null : FirebaseAuth.instance.currentUser.uid;
  FirebaseFirestore get db => FirebaseFirestore.instance;

  int page = 0;

  /// [noMoreMessage] becomes true when there is no more old messages to view.
  /// The app should display 'no more message' to user.
  bool noMoreMessage = false;

  /// Returns the global chat room collection
  ///
  ///
  CollectionReference get globalRoomListCol {
    return db.collection('chat').doc('global').collection('room-list');
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

  /// Returns my room list collection `/chat/my-room-list/{user-id}` reference.
  ///
  CollectionReference userRoomListCol(String userId) {
    return db.collection('chat').doc('my-room-list').collection(userId);
  }

  /// Returns my room (that has last message of the room) document
  /// reference.
  DocumentReference userRoomDoc(String userId, String roomId) {
    return userRoomListCol(userId).doc(roomId);
  }

  /// Returns `/chat/global/roomList/{roomId}` document reference
  ///
  DocumentReference globalRoomDoc(String roomId) {
    return globalRoomListCol.doc(roomId);
  }

  /// Returns document reference of my room (that has last message of the room)
  ///
  /// `/chat/my-room-list/my-id/{roomId}`
  DocumentReference myRoom(String roomId) {
    return myRoomListCol.doc(roomId);
  }

  text(Map<String, dynamic> message) {
    String text = message['text'] ?? '';

    if (text == ChatProtocol.roomCreated) {
      text = 'Chat room created. ';
    }

    /// Display `no more messages` only when user scrolled up to see more messages.
    else if (page > 1 && noMoreMessage) {
      text = 'No more messages. ';
    } else if (text == ChatProtocol.enter) {
      // print(message);
      text = "${message['senderDisplayName']} invited ${message['newUsers']}";
    }
    return text;
  }

  /// Returns the room list info `/chat/room/list/{roomId}` document.
  ///
  /// If the room does exists, it returns null.
  /// The return value has `id` as its room id.
  ///
  /// Todo move this method to `ChatRoom`
  Future<ChatGlobalRoom> getGlobalRoom(String roomId) async {
    DocumentSnapshot snapshot = await globalRoomDoc(roomId).get();
    return ChatGlobalRoom.fromSnapshot(snapshot);
  }
}
