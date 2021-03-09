import 'package:firebase_auth/firebase_auth.dart';

/// Chat Test
/// How to test
/// - Call test methods only after Firebase initilization.
/// - Prepare 4 UIDs a, b, c, d. If there is no user exists, then create them.
/// - And the 4 email address of the UID.
/// - Password must be '12345a'

import 'package:firechat/firechat.dart';

class FireChatTest {
  final String a = 'YWBpfbnvuPgYEUZnhKuaR1DtF7D2';
  final String b = 'NrDUfFBQ2UhJosS0d9zKuQiViAR2';
  final String c = '3ZvCelL3jVU9eV2OiBFa4Ti3Cwx2';
  final String d = 'et5kxG7vgFcM2oOI9flQQbHkfTq2';
  final String aEmail = 'aaaa@test.com';
  final String bEmail = 'bbbb@test.com';
  final String cEmail = 'cccc@test.com';
  final String dEmail = 'dddd@test.com';
  final String password = '12345a';

  runAllTests() async {
    await roomCreateTest();

    print('ERROR: [ $_countError ]');
  }

  roomCreateTest() async {
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

    // chat with my self
    try {
      await chat.enter(users: [chat.loginUserUid]);
      ChatUserRoom info = await chat.lastMessage;
      isTrue(info.text == ChatProtocol.roomCreated, 'Expected: ' + ChatProtocol.roomCreated);
      isTrue(info.senderUid == chat.loginUserUid,
          'Expected: ' + info.senderUid + " == " + chat.loginUserUid);
      isTrue(info.id == chat.global.roomId, 'Expected: ' + info.id + " == " + chat.global.roomId);
      isTrue(chat.users.length == 1, 'Expected: ' + "${chat.users.length} == 1");
      isTrue(chat.users.first == chat.loginUserUid, 'Expected: ' + "${chat.loginUserUid}");

      final oldChatId = chat.id;
      await chat.enter(users: [chat.loginUserUid]);
      isTrue(oldChatId != chat.id, 'Expected: not equal ' + "${oldChatId} != ${chat.id}");

      await chat.enter(users: [chat.loginUserUid], hatch: false);
      final newChatId = chat.id;
      await chat.enter(users: [chat.loginUserUid], hatch: false);
      isTrue(newChatId == chat.id, 'Expected: equal ' + "${newChatId} == ${chat.id}");
    } catch (e) {
      print(e);
      failure('Must be success of : ');
    }

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
      abId = chat.id;
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }

    // login with user b and chat user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
    try {
      await chat.enter(users: [a]);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");

      // hatch false user a
      await chat.enter(users: [a], hatch: false);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(abId == chat.id, 'Expected: ' + "hatch false option $abId = ${chat.id}");

      // hatch false user a and b
      await chat.enter(users: [a, b], hatch: false);
      isTrue(chat.users.length == 2, 'Expected: ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(abId == chat.id, 'Expected: ' + "hatch false option $abId = ${chat.id}");
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }

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
      final alogin_bcId = chat.id;
      isTrue(chat.users.length == 3, 'Expected: ' + "${chat.users.length} == 3");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b), 'Expected: ' + "$b exist on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(abcId == alogin_bcId, 'Expected: ' + "hatch false option $abcId = $alogin_bcId");

      // hatch false user a,b,c,d
      await chat.enter(users: [a, b, c, d], hatch: false);
      final alogin_bcdId = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      // hatch false user [a, a, b, b, c, c, d]
      await chat.enter(users: [a, a, b, b, c, c, d], hatch: false);
      final alogin_aabbccd = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      isTrue(alogin_bcdId == alogin_aabbccd,
          'Expected: ' + "hatch false option $alogin_bcdId = $alogin_aabbccd");

      // hatch false user [b, c, a, c, d, a, b]
      await chat.enter(users: [b, c, a, c, d, a, b], hatch: false);
      final alogin_bcacdab = chat.id;
      isTrue(chat.users.length == 4, 'Expected: ' + "${chat.users.length} == 4");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      isTrue(chat.users.contains(d), 'Expected: ' + "$d exist on user list");
      isTrue(alogin_bcdId == alogin_bcacdab,
          'Expected: ' + "hatch false option $alogin_bcdId = $alogin_bcacdab");
      isTrue(alogin_aabbccd == alogin_bcacdab,
          'Expected: ' + "hatch false option $alogin_aabbccd = $alogin_bcacdab");
    } catch (e) {
      print(e);
      failure('Must be success of chat with user b');
    }
  }

  success(String message) {
    print("[S] $message");
  }

  int _countError = 0;
  failure(String message) {
    print("[FAILURE] $message");
    _countError++;
  }

  isTrue(bool re, [String message]) {
    if (re)
      success(message);
    else
      failure(message);
  }
}
