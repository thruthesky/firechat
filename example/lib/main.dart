import 'package:example/screens/chat.room.list.screen.dart';
import 'package:example/screens/chat.room.screen.dart';
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
  final String a = '7kYRMUhRJGPV47u2hCDrauoHSMk1';
  final String b = '4MB8M3mbLlQ9J70Mbp5BW5p3fnD2';
  final String c = 'yUzkXHvNPTVgYiE21rn78aWURZF3';
  final String d = 'FvLmXDDpUkfYvHlLnm61KuEDpGC2';
  final String aEmail = 'aaaa@test.com';
  final String bEmail = 'bbbb@test.com';
  final String cEmail = 'cccc@test.com';
  final String dEmail = 'dddd@test.com';
  final String password = '12345a';

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((x) {
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
      //     await FirebaseAuth.instance.currentUser.updateProfile(displayName: 'A');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(displayName: 'B');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(displayName: 'C');
      //     await FirebaseAuth.instance.signInWithEmailAndPassword(email: dEmail, password: password);
      //     await FirebaseAuth.instance.currentUser.updateProfile(displayName: 'D');
      //   } catch (e) {
      //     print(e);
      //   }
      // }();

      /// When room information of the current room where the login user is in changes, it will be handled here.
      ChatRoom.instance.globalRoomChanges.listen((rooms) {
        print('global rooms;');
        print(rooms);
      });

      ChatRoom.instance.changes.listen((value) {
        print('room changes;');
        print(value);
      });

      /// When any of the login user's rooms changes, it will be handled here.
      ChatUserRoomList.instance.changes.listen((rooms) {
        print('room list change;');
        print(rooms);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Firechat Functionality\n'
                '- [Done] 1:1 chat with same room\n'
                '- 1:1 chat with new room\n'
                '- Multi user chat with same room\n'
                '- Multi user chat with new room\n'
                '- Room information (like title) change.\n'
                '- User invitation\n'
                '- Kicking out a user\n'
                '- [Done] Block a user\n'
                '- Set a user as admin\n'
                '- When admin leave the room, one of other user automatically becomes admin\n'
                '- [Done] Listening changes of room list and showing new messages.'
                '- Room password lock\n',
              ),
              Text(
                'User Signed in as '
                '${user?.displayName}'
                "-${user?.uid}",
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance
                      .signInWithEmailAndPassword(email: aEmail, password: password);
                  setState(() {});
                },
                child: Text('Login as UserA'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance
                      .signInWithEmailAndPassword(email: bEmail, password: password);
                  setState(() {});
                },
                child: Text('Login as UserB'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance
                      .signInWithEmailAndPassword(email: cEmail, password: password);
                  setState(() {});
                },
                child: Text('Login as UserC'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance
                      .signInWithEmailAndPassword(email: dEmail, password: password);
                  setState(() {});
                },
                child: Text('Login as UserD'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(uid: a, displayName: 'User A'),
                      ));
                },
                child: Text('Chat User A'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(uid: b, displayName: 'User B'),
                      ));
                },
                child: Text('Chat User B'),
              ),
              TextButton(
                onPressed: () async {
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
