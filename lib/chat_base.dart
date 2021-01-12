part of './firechat.dart';

class ChatBase {
  String loginUserId;
  FirebaseFirestore get db => FirebaseFirestore.instance;

  int page = 0;

  /// [noMoreMessage] becomes true when there is no more old messages to view.
  /// The app should display 'no more message' to user.
  bool noMoreMessage = false;

  /// Returns the room collection reference of `/chat/rooms/global`
  ///
  ///
  CollectionReference get globalRoomListCol {
    return db.collection('chat').doc('rooms').collection('global');
  }

  /// Returns login user's room list collection `/chat/my-room-list/my-uid` reference.
  ///
  ///
  CollectionReference get myRoomListCol {
    return userRoomListCol(loginUserId);
  }

  /// Return the collection of messages of the room id.
  CollectionReference messagesCol(String roomId) {
    return db.collection('chat').doc('messages').collection(roomId);
  }

  /// Returns my room list collection `/chat/rooms/{user-id}` reference.
  ///
  CollectionReference userRoomListCol(String userId) {
    return db.collection('chat').doc('rooms').collection(userId);
  }

  /// Returns my room (that has last message of the room) document
  /// reference.
  DocumentReference userRoomDoc(String userId, String roomId) {
    return userRoomListCol(userId).doc(roomId);
  }

  /// Returns `/chat/rooms/global/{roomId}` document reference
  ///
  DocumentReference globalRoomDoc(String roomId) {
    return globalRoomListCol.doc(roomId);
  }

  /// Returns document reference of my room (that has last message of the room)
  ///
  /// `/chat/rooms/my-id/{roomId}`
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
