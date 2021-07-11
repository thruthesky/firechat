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
  bool isVideo;
  Map<String, dynamic> data;
  bool rendered = false;

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
    this.isVideo,
    this.data,
  });
  bool get isMovie {
    final String t = text.toLowerCase();
    if (t.startsWith('http') && (t.endsWith('.mov') || t.endsWith('.mp4'))) return true;
    return false;
  }

  factory ChatMessage.fromData(Map<String, dynamic> data, {String id}) {
    bool isImage = false;
    bool isVideo = false;

    // print('ChatMessage data: $data');

    if (data['text'] != null && isImageUrl(data['text'])) {
      isImage = true;
    }
    return ChatMessage(
      id: data['id'] ?? id ?? '',
      createdAt: data['createdAt'],
      newUsers: List<String>.from(data['newUsers'] ?? []),
      senderDisplayName: data['senderDisplayName'] ?? '',
      senderPhotoURL: data['senderPhotoURL'] ?? '',
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      isMine: data['senderUid'] == ChatRoom.instance.loginUserUid,
      isImage: isImage,
      isVideo: isVideo,
      data: data,
    );
  }
}
