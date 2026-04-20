/// Midea local B4 device message. Mirrors midealocal/devices/b4/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxByteValue = 0xFF;

class MessageDeviceAttributes {
  static const String timeRemaining = 'time_remaining';
  static const String currentTemperature = 'current_temperature';
  static const String status = 'status';
  static const String door = 'door';
  static const String tankEjected = 'tank_ejected';
  static const String waterShortage = 'water_shortage';
  static const String waterChangeReminder = 'water_change_reminder';
}

abstract class MessageB4Base extends MessageRequest {
  MessageB4Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b4,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQuery extends MessageB4Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );
}

class B4MessageBody {
  B4MessageBody(Uint8List body) {
    final hour = body[22];
    final minute = body[23];
    final second = body[24];
    timeRemaining =
        (hour == maxByteValue ? 0 : hour) * 3600 +
        (minute == maxByteValue ? 0 : minute) * 60 +
        (second == maxByteValue ? 0 : second);

    final temp = (body[25] << 8) + body[26];
    if (temp == 0) {
      currentTemperature = ((body[27] << 8) + body[28]);
    } else {
      currentTemperature = temp;
    }

    status = body[31];
    door = (body[32] & 0x02) > 0;
    tankEjected = (body[16] & 0x04) > 0;
    waterShortage = (body[16] & 0x08) > 0;
    waterChangeReminder = (body[16] & 0x10) > 0;
  }

  late int timeRemaining;
  late int currentTemperature;
  late int status;
  late bool door;
  late bool tankEjected;
  late bool waterShortage;
  late bool waterChangeReminder;
}

class MessageB4Response extends MessageResponse {
  MessageB4Response(Uint8List message) : super(message) {
    if (_isValidMessage) {
      final bodyData = MessageBody(super.body);
      setBody(bodyData);
      _parseBody(bodyData.data);
    }
  }

  late int timeRemaining;
  late int currentTemperature;
  late int status;
  late bool door;
  late bool tankEjected;
  late bool waterShortage;
  late bool waterChangeReminder;

  bool get _isValidMessage =>
      (messageType == MessageType.notify1 ||
          messageType == MessageType.query ||
          messageType == MessageType.set) &&
      bodyType == ListTypes.x01;

  void setBody(MessageBody body) {}

  bool hasAttribute(String attr) {
    return attr == MessageDeviceAttributes.timeRemaining ||
        attr == MessageDeviceAttributes.currentTemperature ||
        attr == MessageDeviceAttributes.status ||
        attr == MessageDeviceAttributes.door ||
        attr == MessageDeviceAttributes.tankEjected ||
        attr == MessageDeviceAttributes.waterShortage ||
        attr == MessageDeviceAttributes.waterChangeReminder;
  }

  dynamic getAttribute(String attr) {
    if (attr == MessageDeviceAttributes.timeRemaining) return timeRemaining;
    if (attr == MessageDeviceAttributes.currentTemperature)
      return currentTemperature;
    if (attr == MessageDeviceAttributes.status) return status;
    if (attr == MessageDeviceAttributes.door) return door;
    if (attr == MessageDeviceAttributes.tankEjected) return tankEjected;
    if (attr == MessageDeviceAttributes.waterShortage) return waterShortage;
    if (attr == MessageDeviceAttributes.waterChangeReminder)
      return waterChangeReminder;
    return null;
  }

  void _parseBody(Uint8List body) {
    final parsed = B4MessageBody(body);
    timeRemaining = parsed.timeRemaining;
    currentTemperature = parsed.currentTemperature;
    status = parsed.status;
    door = parsed.door;
    tankEjected = parsed.tankEjected;
    waterShortage = parsed.waterShortage;
    waterChangeReminder = parsed.waterChangeReminder;
  }
}
