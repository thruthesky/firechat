import 'package:firebase_auth/firebase_auth.dart';

/// Chat Test
/// How to test
/// - Call test methods only after Firebase initilization.
/// - Prepare 4 UIDs a, b, c, d. If there is no user exists, then create them.
/// - And the 4 email address of the UID.
/// - Password must be '12345a'

import 'package:firechat/firechat.dart';

class FireChatTest {
  // final String a = 'YWBpfbnvuPgYEUZnhKuaR1DtF7D2';
  // final String b = 'NrDUfFBQ2UhJosS0d9zKuQiViAR2';
  // final String c = '3ZvCelL3jVU9eV2OiBFa4Ti3Cwx2';
  // final String d = 'et5kxG7vgFcM2oOI9flQQbHkfTq2';

  /// v1.test.firechat
  final String a = '7kYRMUhRJGPV47u2hCDrauoHSMk1';
  final String b = '4MB8M3mbLlQ9J70Mbp5BW5p3fnD2';
  final String c = 'yUzkXHvNPTVgYiE21rn78aWURZF3';
  final String d = 'FvLmXDDpUkfYvHlLnm61KuEDpGC2';
  final String aEmail = 'aaaa@test.com';
  final String bEmail = 'bbbb@test.com';
  final String cEmail = 'cccc@test.com';
  final String dEmail = 'dddd@test.com';
  final String password = '12345a';

  final String textABC = 'ABC ROOM MESSAGE';

  runAllTests() async {
    await inputTest();
    await chatWithMyself();
    await chatMyselfWithHatch();
    await roomCreateTest();
    await sendMessageTestA();
    await sendMessageTestB();

    print('ERROR: [ $_countError ]');
  }

  /// @todo begin from here https://github.com/thruthesky/fireflutter-firebase Unit Test on Firebase Security Rules.

  inputTest() async {
    final chat = ChatRoom.instance;

    // logout
    await FirebaseAuth.instance.signOut();
    try {
      await chat.enter(users: [chat.loginUserUid]);
      failure('Must be error of : ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    } catch (e) {
      isTrue(e == LOGIN_FIRST, 'Expected: ' + LOGIN_FIRST);
      // print(e);
    }

    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);

    // input test
    try {
      await chat.enter();
      failure('Must be error of : ' + EMPTY_ID_AND_USERS);
    } catch (e) {
      isTrue(e == EMPTY_ID_AND_USERS, 'Expected: ' + EMPTY_ID_AND_USERS + 'But got: ');
      print(e);
    }

    // input test
    try {
      await chat.enter(id: 'abc', users: [a, b]);
      failure('Must be error of : ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    } catch (e) {
      isTrue(e == BOTH_OF_ID_AND_USERS_HAVE_VALUE, 'Expected: ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    }
  }

  chatWithMyself() async {
    final chat = ChatRoom.instance;

    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);

    // return;
    // chat with my self
    try {
      await chat.enter(users: [chat.loginUserUid]);
      ChatUserRoom room = await chat.userRoom;
      isTrue(room.text == ChatProtocol.roomCreated, 'Expected: ' + ChatProtocol.roomCreated);
      isTrue(room.senderUid == chat.loginUserUid,
          'Expected: ' + room.senderUid + " == " + chat.loginUserUid);
      isTrue(room.id == chat.global.roomId, 'Expected: ' + room.id + " == " + chat.global.roomId);
      isTrue(chat.users.length == 1, 'Expected: ' + "${chat.users.length} == 1");
      isTrue(chat.users.first == chat.loginUserUid, 'Expected: ' + "${chat.loginUserUid}");
    } catch (e) {
      failure('Must be success of but: ');
      print(e);
    }
  }

  chatMyselfWithHatch() async {
    final chat = ChatRoom.instance;
    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    try {
      await chat.enter(users: [chat.loginUserUid]);
      final oldChatId = chat.id;
      await chat.enter(users: [chat.loginUserUid]);
      isTrue(oldChatId != chat.id, 'Expected: not equal ' + "$oldChatId != ${chat.id}");

      // hatch test
      await chat.enter(users: [chat.loginUserUid], hatch: false);
      final newChatId = chat.id;
      await chat.enter(users: [chat.loginUserUid], hatch: false);
      isTrue(newChatId == chat.id, 'Expected: equal ' + "$newChatId == ${chat.id}");
    } catch (e) {
      failure('Must be success of but: ');
      print(e);
    }
  }

  roomCreateTest() async {
    final chat = ChatRoom.instance;

    // chat with user b
    String abId;
    try {
      await chat.enter(users: [b]);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(chat.users.contains(c) == false, 'Expected: ' + "$c doesnt exist on user list");

      // hatch false
      await chat.enter(users: [b], hatch: false);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      // Save chat room id for test later.
      abId = chat.id;
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }

    // b login and chat with user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
    try {
      await chat.enter(users: [a]);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");

      // hatch false with user a.
      // Expect: use existing chat room.
      await chat.enter(users: [a], hatch: false);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(abId == chat.id, 'Expected: ' + "hatch false option $abId = ${chat.id}");

      // hatch false user a and b
      // Expect: use existing chat room.
      await chat.enter(users: [a, b], hatch: false);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(abId == chat.id, 'Expected: ' + "hatch false option $abId = ${chat.id}");
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }

    // a login
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);

    try {
      await chat.enter(users: [a, b, c], hatch: false);
      final abcId = chat.id;
      isTrue(chat.users.length == 3, 'Expected: ' + "${chat.users.length} == 3");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");

      // hatch false user a enter room b,c
      await chat.enter(users: [b, c], hatch: false);
      final aLoginWithBC = chat.id;
      isTrue(chat.users.length == 3, 'Expected: ' + "${chat.users.length} == 3");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(abcId == aLoginWithBC, 'Expected: ' + "hatch false option $abcId = $aLoginWithBC");

      // hatch false user a,b,c,d
      await chat.enter(users: [a, b, c, d], hatch: false);
      final aLgoinWithBCD = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      // hatch false user [a, a, b, b, c, c, d]
      await chat.enter(users: [a, a, b, b, c, c, d], hatch: false);
      final aLoginWithAABBCCD = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      isTrue(aLgoinWithBCD == aLoginWithAABBCCD,
          'Expected: ' + "hatch false option $aLgoinWithBCD = $aLoginWithAABBCCD");

      // hatch false user [b, c, a, c, d, a, b]
      await chat.enter(users: [b, c, a, c, d, a, b], hatch: false);
      final aLoginWithBCACDAB = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      isTrue(aLgoinWithBCD == aLoginWithBCACDAB,
          'Expected: ' + "hatch false option $aLgoinWithBCD = $aLoginWithBCACDAB");
      isTrue(aLoginWithAABBCCD == aLoginWithBCACDAB,
          'Expected: ' + "hatch false option $aLoginWithAABBCCD = $aLoginWithBCACDAB");
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }
  }

  sendMessageTestA() async {
    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    // create/enter abc room
    try {
      await chat.enter(users: [b, c]);
      ChatUserRoom room = await chat.userRoom;
      isTrue(room.text == ChatProtocol.roomCreated, 'abc roomCreated');
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    try {
      await chat.sendMessage(text: textABC, displayName: chat.loginUserUid);
      final ChatUserRoom lastMessageA = await chat.userRoom;
      isTrue(lastMessageA.text == textABC, 'Got last message for ABC chat room');
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    try {
      // login user b
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
      await chat.enter(id: chat.id);
      final ChatUserRoom lastMessageB = await chat.userRoom;
      isTrue(lastMessageB.text == textABC, 'b Got last message fror abc room');
    } catch (e) {
      failure('Must be success of b login and got abc room: ');
      print(e);
    }

    try {
      // login user c
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);
      await chat.enter(id: chat.id);
      final ChatUserRoom lastMessageC = await chat.userRoom;
      isTrue(lastMessageC.text == textABC, 'c login Got last message fror abc room');
    } catch (e) {
      failure('Must be success of c login and got message from abc room: ');
      print(e);
    }
  }

  // sending message with hatch option false
  sendMessageTestB() async {
    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    // create/enter abc room
    try {
      await chat.enter(users: [b, c], hatch: false);
      ChatUserRoom room = await chat.userRoom;
      isTrue(room.text == ChatProtocol.roomCreated || room.text == textABC,
          'hatch false abc roomCreated');
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    try {
      await chat.sendMessage(text: textABC, displayName: chat.loginUserUid);
      final ChatUserRoom lastMessageA = await chat.userRoom;
      isTrue(lastMessageA.text == textABC, 'hatch false Got last message for ABC chat room');
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    try {
      // login user b
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
      await chat.enter(users: [a, c], hatch: false);
      final ChatUserRoom lastMessageB = await chat.userRoom;
      isTrue(lastMessageB.text == textABC, 'hatch false b Got last message fror abc room');
    } catch (e) {
      failure('Must be success of b login and got abc room: ');
      print(e);
    }

    try {
      // login user c
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);
      await chat.enter(users: [a, b], hatch: false);
      final ChatUserRoom lastMessageC = await chat.userRoom;
      isTrue(lastMessageC.text == textABC, 'c login Got last message fror abc room');
    } catch (e) {
      failure('Must be success of c login and got message from abc room: ');
      print(e);
    }
  }

  success(String message) {
    print("[S] $message");
  }

  int _countError = 0;
  failure(String message) {
    print("\n-\n[FAILURE] $message ---------------------------------------------\n-\n");
    _countError++;
  }

  isTrue(bool re, [String message]) {
    if (re)
      success(message);
    else
      failure(message);
  }
}
