import 'dart:async';

import 'package:badges/badges.dart';
import 'package:example/screens/chat.room.list.screen.dart';
import 'package:example/screens/chat.room.screen.dart';
import 'package:example/services/defines.dart';
import 'package:firechat/firechat.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firechat/chat.test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Firechat Demo Login Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription globalRoomSubscription;
  StreamSubscription chatRoomSubscription;
  StreamSubscription chatRoomListSubscription;

  String get loginUserUid =>
      FirebaseAuth.instance.currentUser == null ? null : FirebaseAuth.instance.currentUser.uid;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((firebase) {
      // FireChatTest().runAllTests();
      // FireChatTest().chatWithMyself();
      // FireChatTest().sendMessageTestA();
      // FireChatTest().sendMessageTestB();
      // FireChatTest().leaveTest();
      // FireChatTest().userInvitationTest();
      // FireChatTest().addModeratorTest();
      // FireChatTest().removeModeratorTest();
      // FireChatTest().blockTest();
      // FireChatTest().kickoutTest();

      // () async {
      //   try {
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(senderDisplayName: 'A');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(senderDisplayName: 'B');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(senderDisplayName: 'C');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: dEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(senderDisplayName: 'D');
      //   } catch (e) {
      //     print(e);
      //   }
      // }();

      // / When room information of the current room where the login user is in changes, it will be handled here.

      FirebaseAuth.instance.authStateChanges().listen((User user) {
        if (user == null) {
          unsubscribeChat();
        } else {
          subscribeChat();
        }
      });
    });
  }

  unsubscribeChat() {
    if (globalRoomSubscription != null) {
      globalRoomSubscription.cancel();
      globalRoomSubscription = null;
    }
    if (chatRoomSubscription != null) {
      chatRoomSubscription.cancel();
      chatRoomSubscription = null;
    }

    if (chatRoomListSubscription != null) {
      chatRoomListSubscription.cancel();
      chatRoomListSubscription = null;
    }
  }

  subscribeChat() {
    globalRoomSubscription = ChatRoom.instance.globalRoomChanges.listen((rooms) {
      // print('global rooms;');
      // print(rooms);
    });

    chatRoomSubscription = ChatRoom.instance.changes.listen((value) {
      // print('room changes;');
      // print(value);
    });

    /// When any of the login user's rooms changes, it will be handled here.
    chatRoomListSubscription = ChatUserRoomList.instance.changes.listen((rooms) {
      // print('room list change;');
      // print(rooms);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: StreamBuilder(
                stream: ChatUserRoomList.instance.changes,
                builder: (_, snapshot) {
                  // if (snapshot.hasData == false) return SizedBox.shrink();
                  return Badge(
                    showBadge: ChatUserRoomList.instance.newMessages > 0,
                    badgeColor: Colors.yellow[700],
                    toAnimate: false,
                    badgeContent: Text(ChatUserRoomList.instance.newMessages.toString()),
                    child: Icon(Icons.chat),
                  );
                }),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomListScreen(),
                )),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Firechat Functionality\n'
                '- [Done] 1:1 chat with same room\n'
                '- [Done] 1:1 chat with new room\n'
                '- [Done] Multi user chat with same room\n'
                '- [Done] Multi user chat with new room\n'
                '- [Done] User invitation\n'
                '- [Done] Kicking out a user\n'
                '- [Done] Block a user\n'
                '- [Done] Set a user as admin\n'
                '- [Done] Listening changes of room list and showing new messages.\n'
                '- When admin leave the room, one of other user automatically becomes admin\n'
                '- Room information (like title) change.\n'
                '- Room password lock\n',
              ),
              Text(
                'User Signed in as '
                '${user?.displayName}'
                "-${user?.uid}",
              ),
              Column(
                children: [
                  Text('Login As'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: aEmail, password: password);
                          setState(() {});
                        },
                        child: Text('UserA'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: bEmail, password: password);
                          setState(() {});
                        },
                        child: Text('UserB'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: cEmail, password: password);
                          setState(() {});
                        },
                        child: Text('UserC'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: dEmail, password: password);
                          setState(() {});
                        },
                        child: Text('UserD'),
                      ),
                    ],
                  )
                ],
              ),
              Column(
                children: [
                  Text('Chat Same Room with'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  users: [a],
                                  senderDisplayName: 'User A',
                                  hatch: false,
                                ),
                              ));
                        },
                        child: Text('User A'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  users: [b],
                                  senderDisplayName: 'User B',
                                  hatch: false,
                                ),
                              ));
                        },
                        child: Text('User B'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  users: [c],
                                  senderDisplayName: 'User C',
                                  hatch: false,
                                ),
                              ));
                        },
                        child: Text('User C'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  users: [d],
                                  senderDisplayName: 'User D',
                                  hatch: false,
                                ),
                              ));
                        },
                        child: Text('User D'),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Chat New Room with'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoomScreen(users: [a], senderDisplayName: 'User A'),
                              ));
                        },
                        child: Text('User A'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoomScreen(users: [b], senderDisplayName: 'User B'),
                              ));
                        },
                        child: Text('User B'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoomScreen(users: [c], senderDisplayName: 'User C'),
                              ));
                        },
                        child: Text('User C'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoomScreen(users: [d], senderDisplayName: 'User D'),
                              ));
                        },
                        child: Text('User D'),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Group Chat with'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      users: [a, b, c, d],
                                      senderDisplayName: 'ABCD',
                                      hatch: false,
                                    ),
                                  ));
                            },
                            child: Text('ABCD Same Room'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Group Chat With'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      users: [a, b, c, d],
                                      senderDisplayName: 'ABCD',
                                    ),
                                  ));
                            },
                            child: Text('ABCD New Room'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomListScreen(),
                      ));
                },
                child: Text('My Room list'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  setState(() {});
                },
                child: Text('Log Out'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
