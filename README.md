# Firechat

Firebase chat package for Flutter

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

# Security Rules

```


    /// Chat
    match /chat {
      match /my-room-list/{uid}/{roomId} {
        // User can read his own chat room list.
        allow read: if request.auth.uid == uid;
        // Only chat room users can update the room info(last message) of (room list of) users who are in the same room.
        allow create, update: if request.auth.uid == uid
        || request.auth.uid in get(/databases/$(database)/documents/chat/global/room-list/$(roomId)).data.users;
        allow delete: if request.auth.uid == uid;
      }



      match /global/room-list/{roomId} {
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
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chat/global/room-list/$(roomId)).data.users;
        // Room users can write his own message.
        allow write: if request.auth.uid in get(/databases/$(database)/documents/chat/global/room-list/$(roomId)).data.users && request.resource.data.senderUid == request.auth.uid;
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
