part of './firechat.dart';

/// todo put chat protocol into { protocol: ... }, not in { text: ... }
class ChatProtocol {
  static String enter = 'ChatProtocol.enter';
  static String add = 'ChatProtocol.add';
  static String leave = 'ChatProtocol.leave';
  static String kickout = 'ChatProtocol.kickout';
  static String block = 'ChatProtocol.block';
  static String roomCreated = 'ChatProtocol.roomCreated';
}
