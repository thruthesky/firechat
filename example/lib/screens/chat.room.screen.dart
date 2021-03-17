import 'dart:async';

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
                  ChatRoom.instance.id ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          actions: [
            AddNewUser(),
            KickUser(),
            BlockUser(),
            AddModerator(),
            RemoveModerator(),
            IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: () {
                  ChatRoom.instance.leave();
                  Navigator.pop(context);
                }),
          ]),
      body: ChatMessageListWidget(
        onImageRenderCompelete: () {},
        onError: (e) => print(e),
      ),
    );
  }
}

class AddNewUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.person_add),
      itemBuilder: (context) {
        return [
          // PopupMenuItem(
          //   child: Text('Add New User'),
          // ),
          for (var uid in users.keys)
            PopupMenuItem(
              child: TextButton(
                child: Text('Add ' + users[uid]),
                onPressed: () async {
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
      icon: Icon(Icons.person_remove),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('KickOut ' + users[uid]),
                onPressed: () async {
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
      icon: Icon(Icons.block),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('Block ' + users[uid]),
                onPressed: () async {
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
      icon: Icon(Icons.add_moderator),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.users)
            PopupMenuItem(
              child: TextButton(
                child: Text('Add Moderator ' + users[uid]),
                onPressed: () async {
                  try {
                    await ChatRoom.instance.addModerator(uid);
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
      icon: Icon(Icons.remove_moderator),
      itemBuilder: (context) {
        return [
          for (var uid in ChatRoom.instance.global.moderators)
            PopupMenuItem(
              child: TextButton(
                child: Text('Remove Moderator ' + users[uid]),
                onPressed: () async {
                  try {
                    await ChatRoom.instance.removeModerator(uid);
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
