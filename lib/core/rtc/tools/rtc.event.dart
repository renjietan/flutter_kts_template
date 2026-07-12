import 'rtc.event.type.dart';

class RtcEvent {
  final RtcEventType type;
  final String? remotePeer;
  final String? msg;

  const RtcEvent({required this.type, this.remotePeer, this.msg});

  @override
  String toString() =>
      'RtcEvent(type: $type, deviceName: $remotePeer, msg： $msg)';
}
