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

- Make chat room and chat list singleton.
- Use rxdart to notify all the event. No more render!

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
