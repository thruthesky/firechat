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
  }

  Function __render;

  StreamSubscription _myRoomListSubscription;
  List<StreamSubscription> _roomSubscriptions = [];

  /// [fetched] becomes true after it fetches the room list. the room list might
  /// be empty if there is no chat room for the user.
  ///
  /// ```dart
  /// myRoomList?.fetched != true ? Spinner() : ListView.builder( ... );
  /// ```
  bool fetched = false;

  /// My room list including room id.
  List<ChatUserRoom> rooms = [];
  String _order = "";
  ChatUserRoomList({
    @required Function render,
    @required String loginUserId,
    String order = "createdAt",
  })  : __render = render,
        _order = order {
    listenRoomList();
  }

  _notify() {
    if (__render != null) __render();
  }

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
      fetched = true;
      _notify();
      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final roomInfo = ChatUserRoom.fromSnapshot(documentChange.doc);

        if (documentChange.type == DocumentChangeType.added) {
          rooms.add(roomInfo);

          /// Listen and merge global room settings into private room info.
          _roomSubscriptions.add(
            globalRoomDoc(roomInfo.id).snapshots().listen(
              (DocumentSnapshot snapshot) {
                int found = rooms.indexWhere((r) => r.id == roomInfo.id);
                rooms[found].global = ChatGlobalRoom.fromSnapshot(snapshot);
                // snapshot.data();
                _notify();
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
      _notify();
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
