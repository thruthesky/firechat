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
    print('=> ChatUserRoomList._internal(). This must be called only once.');
    if (isLogin) listenRoomList();
  }

  // Function __render;

  BehaviorSubject changes = BehaviorSubject.seeded(null);

  StreamSubscription _myRoomListSubscription;
  List<StreamSubscription> _roomSubscriptions = [];

  /// My room list including room id.
  List<ChatUserRoom> rooms = [];
  String _order = "createdAt";

  int newMessages = 0;

  reset({String order}) {
    if (order != null) {
      _order = order;
    }

    rooms = [];
    _myRoomListSubscription.cancel();

    listenRoomList();
  }

  /// Listen to global room updates.
  ///
  /// Listen for;
  /// - title changes,
  /// - users array changes,
  /// - and other properties change.
  listenRoomList() {
    _myRoomListSubscription =
        myRoomListCol.orderBy(_order, descending: true).snapshots().listen((snapshot) {
      // fetched = true;
      newMessages = 0;
      changes.add(null);

      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final roomInfo = ChatUserRoom.fromSnapshot(documentChange.doc);

        if (documentChange.type == DocumentChangeType.added) {
          rooms.add(roomInfo);
          newMessages += roomInfo.newMessages;

          /// When room list is retreived for the first, it will be added to listener.
          /// This is where [changes] event happens many times when the app listens to room list.
          _roomSubscriptions.add(
            globalRoomDoc(roomInfo.id).snapshots().listen(
              (DocumentSnapshot snapshot) {
                int found = rooms.indexWhere((r) => r.id == roomInfo.id);
                rooms[found].global = ChatGlobalRoom.fromSnapshot(snapshot);
                // snapshot.data();
                changes.add(null);
              },
            ),
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
      changes.add(null);
    });
  }

  leave() {
    if (_myRoomListSubscription != null) _myRoomListSubscription.cancel();
    if (_roomSubscriptions.isNotEmpty) {
      _roomSubscriptions.forEach((element) {
        element.cancel();
      });
    }
  }
}
