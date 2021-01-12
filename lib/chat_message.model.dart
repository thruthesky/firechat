part of 'firechat.dart';

enum MessageType { image, text }

/// [ChatMessage] presents the chat message under
/// `/chat/messages/{roomId}/{messageId}` collection.
/// 
/// [type] is the type of the message. it can be `image` or `text`.
class ChatMessage {
  Timestamp createdAt;
  List<dynamic> newUsers;
  String senderDisplayName;
  String senderPhotoURL;
  String senderUid;
  String text;
  MessageType type;
  bool isMine(String loginUserId) => senderUid == loginUserId;
  ChatMessage({
    this.createdAt,
    this.newUsers,
    this.senderDisplayName,
    this.senderPhotoURL,
    this.senderUid,
    this.text,
    this.type,
  });
  factory ChatMessage.fromData(Map<String, dynamic> data) {
    return ChatMessage(
      createdAt: data['createdAt'],
      newUsers: data['newUsers'],
      senderDisplayName: data['senderDisplayName'],
      senderPhotoURL: data['senderPhotoURL'],
      senderUid: data['senderUid'],
      text: data['text'],
      type: MessageType.values[data['type']],
    );
  }
}
