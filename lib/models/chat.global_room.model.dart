part of '../firechat.dart';

/// [ChatGloalRoom] is a model (extending [ChatBase]) that represents the chat room under `/chat-global` collection.
/// All the chat room resides under this collection.
class ChatGlobalRoom extends ChatBase {
  String roomId;
  String title;
  List<String> users;
  List<String> moderators;
  List<String> blockedUsers;
  dynamic createdAt;
  dynamic updatedAt;

  String get otherUserId {
    // If there is no other user.
    return users.firstWhere(
      (el) => el != loginUserUid,
      orElse: () => null,
    );
  }

  ChatGlobalRoom({
    this.roomId,
    this.title,
    this.users,
    this.moderators,
    this.blockedUsers,
    this.createdAt,
  });

  factory ChatGlobalRoom.fromSnapshot(DocumentSnapshot snapshot) {
    if (snapshot.exists == false) return null;
    Map<String, dynamic> info = snapshot.data();
    return ChatGlobalRoom.fromData(info, snapshot.id);
  }

  factory ChatGlobalRoom.fromData(Map<String, dynamic> info, String id) {
    if (info == null) return ChatGlobalRoom();

    return ChatGlobalRoom(
      roomId: id,
      title: info['title'],
      users: List<String>.from(info['users'] ?? []),
      moderators: List<String>.from(info['moderators'] ?? []),
      blockedUsers: List<String>.from(info['blockedUsers'] ?? []),
      createdAt: info['createdAt'],
    );
  }

  Map<String, dynamic> get data {
    return {
      'title': this.title,
      'users': this.users,
      'moderators': this.moderators,
      'blockedUsers': this.blockedUsers,
      'createdAt': this.createdAt,
    };
  }

  @override
  String toString() {
    return data.toString();
  }
}
