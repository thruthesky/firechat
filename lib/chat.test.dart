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
      failture('Must be error of : ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    } catch (e) {
      isTrue(e == LOGIN_FIRST, 'Expected: ' + LOGIN_FIRST);
      print(e);
    }

    // login
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);

    // input test
    try {
      await chat.enter();
      failture('Must be error of : ' + EMPTY_ID_AND_USERS);
    } catch (e) {
      isTrue(e == EMPTY_ID_AND_USERS, 'Expected: ' + EMPTY_ID_AND_USERS + 'But got: ');
      print(e);
    }

    // input test
    try {
      await chat.enter(id: 'abc', users: ['a', 'b']);
      failture('Must be error of : ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    } catch (e) {
      isTrue(e == BOTH_OF_ID_AND_USERS_HAVE_VALUE, 'Expected: ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    }

    // chat with my self
    try {
      await chat.enter(users: [chat.loginUserUid]);
      failture('Must be error of : ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    } catch (e) {
      print(e);
      isTrue(e == BOTH_OF_ID_AND_USERS_HAVE_VALUE, 'Expected: ' + BOTH_OF_ID_AND_USERS_HAVE_VALUE);
    }
  }

  success(String message) {
    print("[S] $message");
  }

  int _countError = 0;
  failture(String message) {
    print("[FAILURE] $message");
    _countError++;
  }

  isTrue(bool re, [String message]) {
    if (re)
      success(message);
    else
      failture(message);
  }
}
