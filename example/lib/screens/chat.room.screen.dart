import 'package:flutter/material.dart';

import 'package:firechat/firechat.dart';
import 'package:firechat/widgets/chat.message.list.dart';

class ChatRoomScreen extends StatefulWidget {
  final String uid;
  final String displayName;

  ChatRoomScreen({
    Key key,
    @required this.uid,
    this.displayName = '',
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  ChatRoom chat = ChatRoom.instance;

  String userId;

  int count = 0;

  @override
  void initState() {
    super.initState();
    enterChatRoom();
    ChatRoom.instance.changes.listen((value) {
      if (mounted) setState(() {});
    });
  }

  enterChatRoom() async {
    await chat.enter(users: [widget.uid], hatch: false);
    print(chat);
  }

  @override
  void dispose() {
    super.dispose();
    print('ChatRoomScreen::dispose()');
    ChatRoom.instance.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // UserAvatar(
            //   api?.chat?.otherUser?.photoUrl ?? '',
            //   size: 34,
            // ),
            SizedBox(
              width: 8,
            ),
            // Text(ChatRoom.instance.otherUser?.nickname ?? ''),
            Text(widget.displayName),
          ],
        ),
      ),
      body: ChatMessageListWidget(
        onImageRenderCompelete: () {},
        onError: (e) => print(e),
      ),
    );
  }
}
