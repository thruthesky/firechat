import 'dart:async';

import 'package:example/screens/chat.room.settings.screen.dart';
import 'package:example/services/defines.dart';
import 'package:flutter/material.dart';

import 'package:firechat/firechat.dart';
import 'package:firechat/widgets/chat.message.list.dart';

class ChatRoomScreen extends StatefulWidget {
  final List<String> users;
  final String id;
  final String senderDisplayName;
  final bool hatch;

  ChatRoomScreen({
    Key key,
    this.id,
    this.users,
    this.senderDisplayName = '',
    this.hatch = true,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  StreamSubscription chatRoomSubscription;

  @override
  void initState() {
    super.initState();
    enterChatRoom();
    chatRoomSubscription = ChatRoom.instance.changes.listen((value) {
      if (mounted) setState(() {});
    });
  }

  enterChatRoom() async {
    await ChatRoom.instance.enter(id: widget.id, users: widget.users, hatch: widget.hatch);
  }

  @override
  void dispose() {
    super.dispose();
    print('ChatRoomScreen::dispose()');
    ChatRoom.instance.unsubscribe();
    chatRoomSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // UserAvatar(
            //   api?.chat?.otherUser?.photoUrl ?? '',
            //   size: 34,
            // ),
            SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                ChatRoom.instance.title ?? ChatRoom.instance.id,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      body: ChatMessageListWidget(
        onError: (e) => print('handle on error'),
        onPressUploadIcon: () => print('handle file upload here'),
      ),
      endDrawer: ChatRoomDrawer(),
    );
  }
}

class ChatRoomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          margin: EdgeInsets.zero,
          child: Text('Chat Room Options'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        ),
        AddNewUser(),
        KickUser(),
        BlockUser(),
        AddModerator(),
        RemoveModerator(),
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit Room'),
          onTap: () {
            print('edit Room');
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomSettingsScreen(
                    chatRoom: ChatRoom.instance.global,
                  ),
                ));
          },
        ),
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Leave Room'),
          onTap: () {
            Navigator.pop(context);
            ChatRoom.instance.leave();
            Navigator.pop(context);
          },
        ),
      ],
    ));
  }
}

class AddNewUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: ListTile(
        leading: Icon(Icons.person_add),
        title: Text('Add User'),
      ),
      itemBuilder: (context) {
        return [
          for (var uid in users.keys)
            PopupMenuItem(
              child: TextButton(
                child: Text('Add ' + users[uid]),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ChatRoom.instance.addUser({uid: users[uid]});
                  } catch (e) {
                    print('addUser::error');
                    print(e);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
        ];
      },
    );
  }
}

class KickUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: ListTile(
        leading: Icon(Icons.person_remove),
        title: Text('Remove User'),
      ),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('KickOut ' + users[uid]),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ChatRoom.instance.kickout(uid, users[uid]);
                  } catch (e) {
                    print('kickout::error');
                    print(e);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
        ];
      },
    );
  }
}

class BlockUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: ListTile(
        leading: Icon(Icons.block),
        title: Text('Block User'),
      ),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('Block ' + users[uid]),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ChatRoom.instance.blockUser(uid, users[uid]);
                  } catch (e) {
                    print('blockUser::error');
                    print(e);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
        ];
      },
    );
  }
}

class AddModerator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: ListTile(
        leading: Icon(Icons.add_moderator),
        title: Text('Add Moderator'),
      ),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('Add Moderator ' + users[uid]),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ChatRoom.instance.addModerator(uid, userName: users[uid]);
                  } catch (e) {
                    print('addModerator::error');
                    print(e);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
        ];
      },
    );
  }
}

class RemoveModerator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: ListTile(
        leading: Icon(Icons.remove_moderator),
        title: Text('Remove Moderator'),
      ),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.moderators)
            PopupMenuItem(
              child: TextButton(
                child: Text('Remove Moderator ' + users[uid]),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ChatRoom.instance.removeModerator(uid, userName: users[uid]);
                  } catch (e) {
                    print('addModerator::error');
                    print(e);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
        ];
      },
    );
  }
}
