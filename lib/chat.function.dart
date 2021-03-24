part of './firechat.dart';

String otherUserUid(List<String> users) {
  if (users == null) return '';
  return users.firstWhere((uid) => uid != ChatRoom.instance.loginUserUid);
}

List<String> otherUsersUid(List<String> users) {
  if (users == null) return [];
  return users.where((uid) => uid != ChatRoom.instance.loginUserUid).toList();
}

bool isImageUrl(String t) {
  if (t == null || t == '') return false;
  if (t.startsWith('http://') || t.startsWith('https://')) {
    if (t.endsWith('.jpg') ||
        t.endsWith('.jpeg') ||
        t.endsWith('.gif') ||
        t.endsWith('.png') ||
        t.contains('f=jpg') ||
        t.contains('f=jpeg') ||
        t.contains('f=gif') ||
        t.contains('f=png')) {
      return true;
    }
  }
  return false;
}
