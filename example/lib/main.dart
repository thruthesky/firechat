import 'package:example/screens/chat.room.list.screen.dart';
import 'package:example/screens/chat.room.screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firechat/chat.test.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'User Signin ' +
                  "${FirebaseAuth.instance.currentUser == null ? '' : FirebaseAuth.instance.currentUser.uid}",
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance
                    .signInWithEmailAndPassword(email: aEmail, password: password);
                setState(() {});
              },
              child: Text('Login UserA'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance
                    .signInWithEmailAndPassword(email: bEmail, password: password);
                setState(() {});
              },
              child: Text('Login UserB'),
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
    );
  }
}
