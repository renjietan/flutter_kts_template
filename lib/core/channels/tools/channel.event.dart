import 'channel.event.type.dart';

class ChannelEvent {
  final ChannelEventType type;
  final String? deviceName;
  final String? msg;

  const ChannelEvent({required this.type, this.deviceName, this.msg});

  @override
  String toString() =>
      'ChannelEvent(type: $type, deviceName: $deviceName, msg： $msg)';
}
