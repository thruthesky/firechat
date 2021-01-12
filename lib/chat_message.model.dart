part of 'firechat.dart';

/// [ChatMessage] presents the chat message under
/// `/chat/messages/{roomId}/{messageId}` collection.
///
/// [isImage] returns bool if the message is image or not.
class ChatMessage {
  Timestamp createdAt;
  List<dynamic> newUsers;
  String senderDisplayName;
  String senderPhotoURL;
  String senderUid;
  String text;
  String type;
  bool isMine(String loginUserId) => senderUid == loginUserId;

  bool get isImage => text.contains('.')
      ? ['jpg', 'jpeg', 'png', 'gif'].contains(
          text.split('.').last.toLowerCase(),
        )
      : false;

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
    );
  }
}
