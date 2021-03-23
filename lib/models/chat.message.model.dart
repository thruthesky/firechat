part of '../firechat.dart';

/// [ChatMessage] presents the chat message under
/// `/chat/messages/{roomId}/{messageId}` collection.
///
/// [isImage] returns bool if the message is image or not.
class ChatMessage {
  String id;
  Timestamp createdAt;
  List<String> newUsers;
  String senderDisplayName;
  String senderPhotoURL;
  String senderUid;
  String text;
  bool isMine;
  bool isImage;
  Map<String, dynamic> data;

  ChatMessage({
    this.id,
    this.createdAt,
    this.newUsers,
    this.senderDisplayName,
    this.senderPhotoURL,
    this.senderUid,
    this.text,
    this.isMine,
    this.isImage,
    this.data,
  });
  factory ChatMessage.fromData(Map<String, dynamic> data) {
    bool isImage = false;
    if (data['text'] != null) {
      String t = data['text'];
      if (t.startsWith('http://') || t.startsWith('https://')) {
        if (t.endsWith('.jpg') || t.endsWith('.jpeg') || t.endsWith('.gif') || t.endsWith('.png')) {
          isImage = true;
        }
      }
    }
    return ChatMessage(
      id: data['id'] ?? '',
      createdAt: data['createdAt'],
      newUsers: List<String>.from(data['newUsers'] ?? []),
      senderDisplayName: data['senderDisplayName'] ?? '',
      senderPhotoURL: data['senderPhotoURL'] ?? '',
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      isMine: data['senderUid'] == ChatRoom.instance.loginUserUid,
      isImage: isImage,
      data: data,
    );
  }
}
