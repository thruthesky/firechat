# Firechat

Firebase chat package for Flutter

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

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {


    /// Chat
    match /chat {
      match /userRooms/{uid}/{roomId} {
        // User can read his own chat room list.
        allow read: if request.auth.uid == uid;
        // Only chat room users can update the room info(last message) of (room list of) users who are in the same room.
        allow create, update: if request.auth.uid == uid
        || request.auth.uid in get(/databases/$(database)/documents/chat/globalRooms/roomList/$(roomId)).data.users;
        allow delete: if request.auth.uid == uid;
      }



      match /globalRooms/roomList/{roomId} {
        // Only room users can read the room information.
        allow read: if request.auth.uid in resource.data.users;
        // Anyone can create room.
        allow create: if true;
        // Room users can add another users and none of them must not be in `blockedUsers`
        // User cannot remove other user but himself. and cannot update other fields.
        // Moderators can remove a user and can update any fields.
        allow update: if
        (
          (
          request.auth.uid in resource.data.users
          && onlyUpdating(['users'])
          && request.resource.data.users.hasAll(resource.data.users.removeAll([request.auth.uid])) // remove my self or add users.
          )
          ||
          // Moderators can edit all the fields. This includes
          // - removing users by updating users: []
          // - blocking users by updating blockedUsers: []
          // - adding another user to moderator by updating moderators: []
          // - and all the work.
          (
          'moderators' in resource.data && request.auth.uid in resource.data.moderators
          )
        )
        &&
        (
          !('blockedUsers' in resource.data)
          ||
          resource.data.blockedUsers == null
          ||
          !(request.resource.data.users.hasAny(resource.data.blockedUsers))
        )
        // ! ('blockedUsers' in resource.data && request.resource.data.users.hasAny(resource.data.blockedUsers)) // stop adding users who are in block list.
        ;
      }

      match /messages/{roomId}/{message} {
        // Room users can read room messages.
        // allow read: if false;
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chat/globalRooms/roomList/$(roomId)).data.users;
        // Room users can write his own message.
        allow write: if request.auth.uid in get(/databases/$(database)/documents/chat/globalRooms/roomList/$(roomId)).data.users && request.resource.data.senderUid == request.auth.uid;
      }
    }
  }
}
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
