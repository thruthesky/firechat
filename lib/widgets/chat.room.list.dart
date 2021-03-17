import 'dart:async';

import 'package:firechat/firechat.dart';
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
  StreamSubscription chatUserRoomListSubscription;

  @override
  void initState() {
    super.initState();
    ChatUserRoomList.instance.reset();

    /// When any of the login user's rooms changes, it will be handled here.
    chatUserRoomListSubscription = ChatUserRoomList.instance.changes.listen((rooms) {
      print('ChatRoomList:: room list change;');
      // print(ChatUserRoomList.instance.rooms);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    print('ChatRoomScreen::dispose()');
    chatUserRoomListSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ChatUserRoomList.instance.rooms;
    return rooms.length > 0
        ? ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (_, i) {
              // return ListTile(title: Text('i: $i'));

              final ChatUserRoom room = rooms[i];
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
