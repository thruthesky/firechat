# Firechat

This is a complete Firebase chat package that has the following functions;

- 1:1 chat with same room
- 1:1 chat with new room
- Multi user chat with same room
- Multi user chat with new room
- Room information (like title) change.
- User invitation
- Kicking out a user
- Block a user
- Set a user as admin
- When admin leave the room, one of other user automatically becomes admin
- Listening changes of room list and showing new messages.
- Room password lock

# Reference

- Most of the code is coming from [FireFlutter](https://github.com/thruthesky/fireflutter#chat).
- See the [test code of FireFlutter](https://github.com/thruthesky/fireflutter/blob/main/test/chat.tests.v2.dart).

# TODOs

- Hide keypad automatically when user scroll the keypad only if the keypad is empty.

# Overview

- Firechat does not support for file uploading since every app has different backends.
  - But it provides an interface for uploading photo and it should be very simple.

# Resources

- Most of the code is coming from [FireFlutter](https://pub.dev/packages/fireflutter). It's worthy to check out FireFlutter README file.

# Installation

# Packages

- `crypto` is for encrypting user id list for a room id.

# Firebase Auth

- User must login Firebase before using any of firechat code.

# Global Rooms and User Rooms

- Global rooms are the room information documents that are saved under `/chat/global-rooms/list` collection.
- User rooms are the documents that has a room information for a single user.
- The differnces of global and user rooms are;

  - A global room has room informations like admins, password(to enter the room), room title, blocked user list, and more of the room itself.
  - A user room has information of the relation between the user and the room. Like no of new messages, last message of the room, etc.

# Logic of Chat Room Create

- Create global room
- Send welcome messages to users (by creating user's room) in the global room.

# Security Rules

- It's in `firebase/firestore.rules`

## Test on Security Rules

- First setup Firebase project.

- Then, install Firebase tools and login.
  `% npm install -g firebase-tools`

- Then, log into Firebase
  `% firebase login`

- Then, install npm for testing.

```
% cd firebase
% npm init -y
% npm i -D @firebase/rules-unit-testing
% npm i -D firebase-admin
% npm i -D mocha
```

- Then, run Firestore emualtor

```sh
firebase emulators:start --only firestore   ; run firebase emulator
```

- Then, edit `MY_PROJECT_ID` with your Firebase project ID in `chat.js`.

- Then, run the test

```sh
./node_modules/.bin/mocha tests/chat.js
```

# Developer Guideline

## Global varaibles

```dart
room() {
  return ChatRoom.instance;
}
roomList() {
  return ChatRoomList.instance;
}

room().listen(() { ... });
```

# Tests

- Read the comments on top of `chat.test.dart` to know how to run test code.
- Run the test code like below

```dart
import 'package:firechat/chat.test.dart';
a.firebaseInitialized.listen((ready) { // when firebase initialized,
  if (ready == false) return;
  FireChatTest().roomCreateTest(); // call test.
});
```

Known Issues

git error

```error
fatal: filename in tree entry contains backslash: 'build\ios'
```

solution

```
git config --global core.protectNTFS false
```

# Known Problems

- You may see permission error when user logs out and logs into another accounts. And simply ignore that error.

- When user scrolls up the chat room screen, the app will fetch next(previous) bunch of messages and it leads a sundden insertion of messages into chat room message list. And that causes the scroll position change a bit. And we accept it as a normal action.

# Push notification

- The code below opens the chat room.
  - When the app is terminated, and there is a chat message arrived as a push notification. And when user tap on it, the app will boot and wait for the user login to firebase and opens the chat room.

```dart
  /// This will be invoked when the app is opened from terminated state.
  ///
  /// Test on both Android device, Emulator, and iOS device. Simulator is not working.
  onMessageOpenedFromTermiated(RemoteMessage message) {
    // If it the message has data, then do some exttra work based on the data.
    onMessageOpenedShowMessage(message);
  }

  /// This will be invoked when the app is opened from backgroun state.
  ///
  /// Test on both Android device, Emulator, and iOS device. Simulator is not working.
  onMessageOpenedFromBackground(RemoteMessage message) {
    onMessageOpenedShowMessage(message);
  }

  onMessageOpenedShowMessage(RemoteMessage message) {
    /**
     * return if the the sender is also the current loggedIn user.
     */
    if (api.loggedIn && message?.data['senderIdx'] == "${api.user.idx}") return;

    /**
     * If the type is post then move it to a specific post.
     */
    if (message?.data['type'] == 'post') {
      open(
        RouteNames.forumList,
        arguments: {'postIdx': int.parse("${message.data['idx']}")},
        preventDuplicates: false,
      );
    }

    /**
     * If the type is chat then move it to chat room.
     */
    if (message?.data['type'] == 'chat') {
      api.firebaseAuth.authStateChanges().where((user) => user != null).take(1).listen((user) {
        openChatRoom(roomId: message.data['roomId']);
      });
    }
  }
```
