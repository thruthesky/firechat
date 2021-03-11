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
    await leaveTest(); // double check the logic since it shows different result from time to time

    await userInvitationTest();
    // await addModeratorTest();
    // await removeModeratorTest();
    // await blockTest();
    // await kickoutTest();
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

  leaveTest() async {
    // login user a
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    // create/enter abc room
    try {
      await chat.enter(users: [b, c]); //
      ChatUserRoom room = await chat.userRoom;
      isTrue(room.text == ChatProtocol.roomCreated, 'abc roomCreated');
      await chat.unsubscribe();
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    // login user b
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
    // user b enter chat room abc
    try {
      await chat.enter(id: chat.id); //
    } catch (e) {
      failure('Must success on enter(): but;');
      print(e);
    }

    try {
      // before user leave chat room abc
      isTrue(chat.users.length == 3, 'Expected: Three in the room. ' + "${chat.users.length} == 3");
      // user b leave chat room abc
      await chat.leave();
      // after leave check if myroom is still exist
      // final got = await chat.currentRoom.get();
      // isTrue(got.exists == false, 'The room had been deleted after leave()');

      isTrue(chat.users.length == 2,
          'Expected: Should be two in the room. ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(b) == false, 'Expected: ' + "$b doesnt on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
    } catch (e) {
      failure('Must be success of create abc room: ');
      print(e);
    }

    // user a login again
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);

    try {
      // enter chat room abc
      await chat.enter(id: chat.id);
      isTrue(chat.users.length == 2, 'Expected: Three in the room. ' + "${chat.users.length} == 2");
      final lastMessage = await chat.userRoom;
      isTrue(lastMessage.text == ChatProtocol.leave, 'leave checked by a');
      isTrue(chat.users.length == 2,
          'Expected: Should be two in the room. ' + "${chat.users.length} == 2");
      isTrue(chat.users.contains(a), 'Expected: ' + "$a exist on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c doesnt exist on user list");
      isTrue(chat.users.contains(b) == false, 'Expected: ' + "$b doesnt on user list");
    } catch (e) {
      failure('Must be success of a checking last message that b has left the room: ');
      print(e);
    }

    try {
      // before user leave chat room abc
      isTrue(
          chat.users.length == 2, 'Expected: a and c in the room. ' + "${chat.users.length} == 2");
      // user a leave chat room abc
      await chat.leave();
      // after leave check if myroom is still exist
      final got = await chat.currentRoom.get();
      isTrue(got.exists == false, 'The room had been deleted after leave()');

      print(chat.users);
      isTrue(chat.users.length == 1,
          'Expected: Should be two in the room. ' + "${chat.users.length} == 1");
      isTrue(chat.users.contains(a) == false, 'Expected: ' + "$a doesnt exist on user list");
      isTrue(chat.users.contains(b) == false, 'Expected: ' + "$b doesnt on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
    } catch (e) {
      failure('Must be success of A leaving the room abc: ');
      print(e);
    }

    // user c login
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);

    try {
      // enter chat room abc
      await chat.enter(id: chat.id);
      isTrue(chat.users.length == 1, 'Expected: One in the room. ' + "${chat.users.length} == 1");
      final lastMessage = await chat.userRoom;
      isTrue(lastMessage.text == ChatProtocol.leave, 'leave checked by c');
      isTrue(chat.users.length == 1,
          'Expected: Should be one in the room. ' + "${chat.users.length} == 1");
      isTrue(chat.users.contains(a) == false, 'Expected: ' + "$a doesnt exist on user list");
      isTrue(chat.users.contains(b) == false, 'Expected: ' + "$b doesnt on user list");
      isTrue(chat.users.contains(c), 'Expected: ' + "$c exist on user list");
      await chat.unsubscribe();
    } catch (e) {
      failure('Must be success of c checking last message that b and a has left the room: ');
      print(e);
    }

    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    try {
      final got = await chat.currentRoom.get();
      isTrue(got.exists == false, 'The room had been deleted after leave()');
    } catch (e) {
      isTrue(e == ROOM_NOT_EXISTS, 'room not exist after leave');
      print(e);
    }
  }

  userInvitationTest() async {
    // user c login
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    await chat.enter(users: [a]);
    await chat.addUser({b: 'B'});
    final lastMassage = await chat.userRoom;
    isTrue(lastMassage.text == ChatProtocol.add, 'b added');
    isTrue(lastMassage.newUsers.length == 1, 'one user added');
    isTrue(lastMassage.newUsers.first == 'B', 'The user is B');

    chat.unsubscribe();

    // // ? Strange action: It produce permission-error here if it does not read
    // // ? updated room. The security rule is very clean.
    await chat.getGlobalRoom(chat.id);
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
    await chat.enter(id: chat.id);
    await chat.addUser({c: 'C', d: 'D'});

    final lastMassageB = await chat.userRoom;
    isTrue(lastMassageB.text == ChatProtocol.add, 'C & D added');
    isTrue(lastMassageB.newUsers.length == 2, 'One user added');
    isTrue(lastMassageB.newUsers.contains('C'), 'The user C is included');
    isTrue(lastMassageB.newUsers.contains('D'), 'The user D is included');

    final room = await chat.getGlobalRoom(chat.id);
    isTrue(room.users.length == 4, 'Four users are in the room');
    isTrue(room.users.contains(a), 'A is included');
    isTrue(room.users.contains(b), 'B is included');
    isTrue(room.users.contains(c), 'C is included');
    isTrue(room.users.contains(d), 'D is included');

    chat.leave();
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);

    await chat.enter(id: chat.id);
    final cRoom = await chat.getGlobalRoom(chat.id);

    isTrue(cRoom.users.length == 3, 'Four users are in the room');
    isTrue(cRoom.users.contains(a), 'A is included');
    isTrue(cRoom.users.contains(b) == false, 'B is NOT included');
    isTrue(cRoom.users.contains(c), 'C is included');
    isTrue(cRoom.users.contains(d), 'D is included');
  }

  addModeratorTest() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    await chat.enter(users: [b, c]);
    await chat.addModerator(b);
    var room = await chat.getGlobalRoom(chat.id);
    print(room);
    isTrue(room.moderators.length == 2, '2 moderators are in the room');
    isTrue(room.moderators.contains(a), 'A is included as moderator');
    isTrue(room.moderators.contains(b), 'B is included as moderator');

    try {
      await chat.addModerator(d);
      failure('await chat.addModerator(c);');
    } catch (e) {
      isTrue(e == MODERATOR_NOT_EXISTS_IN_USERS, 'moderator must exists in users');
    }

    chat.unsubscribe();
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: cEmail, password: password);

    await chat.enter(id: chat.id);
    await chat.addUser({d: 'User D'});

    try {
      await chat.addModerator(d);
      failure('You are not moderator');
    } catch (e) {
      isTrue(e == YOU_ARE_NOT_MODERATOR, 'Only moderator can add another moderator');
    }

    // room = await chat.getGlobalRoom(chat.id);
    // print(room);
  }

  removeModeratorTest() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    await chat.enter(users: [b, c]);
    await chat.addModerator(b);
    var room = await chat.getGlobalRoom(chat.id);
    isTrue(room.moderators.length == 2, '2 moderators are in the room');
    isTrue(room.moderators.contains(a), 'A is included as moderator');
    isTrue(room.moderators.contains(b), 'B is included as moderator');

    await chat.removeModerator(b);
    room = await chat.getGlobalRoom(chat.id);
    isTrue(room.moderators.length == 1, '2 moderators are in the room');
    isTrue(room.moderators.contains(a), 'A is included as moderator');
    isTrue(room.moderators.contains(b) == false, 'B is NOT included as moderator');
  }

  blockTest() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    await chat.enter(users: [b, c]);
    await chat.blockUser(b, 'Name of B');
    var room = await chat.getGlobalRoom(chat.id);
    isTrue(room.users.length == 2, '2 user is in the room');
    isTrue(room.blockedUsers.length == 1, '1 user is in block list');
    isTrue(room.blockedUsers.first == b, 'b is blocked');

    try {
      await chat.addUser({b: 'Name of B'});
      failure("await chat.addUser({b: 'Name of B'});");
    } catch (e) {
      isTrue(e == ONE_OF_USERS_ARE_BLOCKED, 'One of users are in block list');
    }
  }

  kickoutTest() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    final chat = ChatRoom.instance;
    await chat.enter(users: [b, c]);

    await FirebaseAuth.instance.signInWithEmailAndPassword(email: bEmail, password: password);
    await chat.enter(id: chat.id);

    try {
      await chat.kickout(c, 'Name of C');
      failure("await bChat.kickout(c, 'Name of C');");
    } catch (e) {
      isTrue(e == YOU_ARE_NOT_MODERATOR, 'Only moderator can kick a user out');
    }

    chat.unsubscribe();
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: aEmail, password: password);
    try {
      await chat.enter(id: chat.id);
      await chat.kickout(c, 'Name of C');
      isTrue(true, "await Chat.kickout(c, 'Name of C'); must be success");
    } catch (e) {
      failure('must success, A is a moderator');
    }

    var room = await chat.getGlobalRoom(chat.id);
    isTrue(room.users.length == 2, '2 user is in the room');

    isTrue(room.users.contains(a), 'A is included');
    isTrue(room.users.contains(b), 'B is included');
    isTrue(room.users.contains(c) == false, 'C is NOT included');
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
