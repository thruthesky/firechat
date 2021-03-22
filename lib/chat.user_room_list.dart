part of './firechat.dart';

/// Chat room list helper class
///
/// This is a completely independent helper class to help to list login user's room list.
/// You may rewrite your own helper class.
class ChatUserRoomList extends ChatBase {
  /// Api Singleton
  static ChatUserRoomList _instance;
  static ChatUserRoomList get instance {
    if (_instance == null) {
      _instance = ChatUserRoomList._internal();
    }
    return _instance;
  }

  ChatUserRoomList._internal() {
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if (user == null) {
        _unsubscribe();
      } else {
        _reset();
        _listenRoomList();
      }
    });
  }

  // Function __render;

  BehaviorSubject changes = BehaviorSubject.seeded(null);

  StreamSubscription _myRoomListSubscription;
  Map<String, StreamSubscription> _roomSubscriptions = {};

  /// My room list including room id.
  List<ChatUserRoom> rooms = [];
  String _order = "createdAt";

  int newMessages = 0;

  _reset({String order}) {
    if (order != null) {
      _order = order;
    }
    newMessages = 0;
    rooms = [];
    if (_myRoomListSubscription != null) {
      _myRoomListSubscription.cancel();
      _myRoomListSubscription = null;
    }
  }

  /// Listen to global room updates.
  ///
  /// Listen for;
  /// - title changes,
  /// - users array changes,
  /// - and other properties change.
  _listenRoomList() {
    _myRoomListSubscription =
        myRoomListCol.orderBy(_order, descending: true).snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final roomInfo = ChatUserRoom.fromSnapshot(documentChange.doc);

        print(roomInfo.newMessages);
        if (documentChange.type == DocumentChangeType.added) {
          rooms.add(roomInfo);

          /// When room list is retreived for the first, it will be added to listener.
          /// This is where [changes] event happens many times when the app listens to room list.
          _roomSubscriptions[roomInfo.id] = globalRoomDoc(roomInfo.id).snapshots().listen(
            (DocumentSnapshot snapshot) {
              int found = rooms.indexWhere((r) => r.id == roomInfo.id);
              rooms[found].global = ChatGlobalRoom.fromSnapshot(snapshot);
              // snapshot.data();
              changes.add(null);
            },
          );
        } else if (documentChange.type == DocumentChangeType.modified) {
          int found = rooms.indexWhere((r) => r.id == roomInfo.id);
          // If global room information exists, copy it to updated object to
          // maintain global room information.
          final global = rooms[found].global;
          rooms[found] = roomInfo;
          rooms[found].global = global;
        } else if (documentChange.type == DocumentChangeType.removed) {
          final int i = rooms.indexWhere((r) => r.id == roomInfo.id);
          if (i > -1) {
            rooms.removeAt(i);
          }
        } else {
          assert(false, 'This is error');
        }
      });

      // // get total newMessages and can be use to display like badge.
      // myRoomListCol.where('newMessages', isGreaterThan: 0).get().then((snapshot) {
      //   print("myRoomListCol.where('newMessages', isGreaterThan: 0)");
      //   newMessages = 0;
      //   snapshot.docs.forEach((documentSnapshot) {
      //     final roomInfo = ChatUserRoom.fromSnapshot(documentSnapshot);
      //     newMessages += roomInfo.newMessages;
      //   });
      //   changes.add(null);
      // });

      newMessages = 0;
      rooms.forEach((roomInfo) {
        newMessages += roomInfo.newMessages;
      });

      changes.add(null);
    });
  }

  _unsubscribe() {
    if (_myRoomListSubscription != null) _myRoomListSubscription.cancel();
    if (_roomSubscriptions.isNotEmpty) {
      for (final key in _roomSubscriptions.keys) {
        _roomSubscriptions[key].cancel();
      }
      _roomSubscriptions = {};
      // _roomSubscriptions.foreach((element) {
      //    _roomSubscriptions[k].cancel();
      // });
    }
    newMessages = 0;
  }

  unsubscribeUserRoom(ChatGlobalRoom room) {
    if (_roomSubscriptions.isEmpty) return;
    if (_roomSubscriptions[room.roomId] == null) return;

    _roomSubscriptions[room.roomId].cancel();
    _roomSubscriptions.removeWhere((String key, dynamic value) => key == room.roomId);
  }
}
