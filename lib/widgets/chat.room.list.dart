import 'package:firechat/widgets/chat.room.view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatRoomListWidget extends StatefulWidget {
  ChatRoomListWidget({
    @required this.onChatRoomTap,
  });

  final Function onChatRoomTap;
  @override
  _ChatRoomListWidgetState createState() => _ChatRoomListWidgetState();
}

class _ChatRoomListWidgetState extends State<ChatRoomListWidget> {
  bool fetched = true;
  List<dynamic> roomList = [
    {
      'displayName': 'userA',
      'profilePhotoUrl': '',
      'newMessages': 0,
      'text': 'hello',
      'createdAt': 1,
      'userIdx': 2
    },
    {
      'displayName': 'userB',
      'profilePhotoUrl': '',
      'newMessages': 0,
      'text': 'hi',
      'createdAt': 2,
      'userIdx': 3
    },
    {
      'displayName': 'userC',
      'profilePhotoUrl': '',
      'newMessages': 0,
      'text': 'hiyyyy',
      'createdAt': 3,
      'userIdx': 4
    },
  ];

  @override
  Widget build(BuildContext context) {
    return fetched != true
        ? Text('fetching messages')
        : roomList.length > 0
            ? ListView.builder(
                itemCount: roomList.length,
                itemBuilder: (_, i) {
                  dynamic room = roomList[i];
                  return ChatRoomViewWidget(room, onTap: () {
                    if (widget.onChatRoomTap != null) widget.onChatRoomTap(room);
                  });
                },
              )
            : Center(
                child: Text('No Chats...'),
              );
  }
}