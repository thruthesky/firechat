part of 'firechat.dart';

/// [ChatMessage] presents the chat message under
/// `/chat/messages/{roomId}/{messageId}` collection.
class ChatMessage {
  Timestamp createdAt;
  List<dynamic> newUsers;
  String senderDisplayName;
  String senderPhotoURL;
  String senderUid;
  String text;
  bool isMine(String loginUserId) => senderUid == loginUserId;
  ChatMessage({
    this.createdAt,
    this.newUsers,
    this.senderDisplayName,
    this.senderPhotoURL,
    this.senderUid,
    this.text,
  });
  factory ChatMessage.fromData(Map<String, dynamic> data) {
    return ChatMessage(
      createdAt: data['createdAt'],
      newUsers: data['newUsers'],
      senderDisplayName: data['senderDisplayName'],
      senderPhotoURL: data['senderPhotoURL'],
      senderUid: data['senderUid'],
      text: data['text'],
    );
  }
}
