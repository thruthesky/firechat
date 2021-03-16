import 'package:flutter/material.dart';

import 'package:firechat/widgets/chat.room.list.dart';

class ChatRoomListScreen extends StatefulWidget {
  @override
  _ChatRoomListScreenState createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Room List')),
      body: ChatRoomListWidget(
        onChatRoomTap: (room) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Text('Chat Message'),
              ));
        },
      ),
    );
  }
}
