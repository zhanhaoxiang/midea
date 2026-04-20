/// Midea local A1 device message. Mirrors midealocal/devices/a1/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxMsgSerialNum = 100;
const int minTargetHumidity = 35;
const int minFanSpeed = 5;

class NewProtocolTags {
  static const int light = 0x005B;
}

// ---------------------------------------------------------------------------
// MessageA1Base
// ---------------------------------------------------------------------------

abstract class MessageA1Base extends MessageRequest {
  MessageA1Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.a1,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       ) {
    _messageSerial = (_messageSerial + 1) % maxMsgSerialNum;
    if (_messageSerial == 0) _messageSerial = 1;
    _messageId = _messageSerial;
  }

  static int _messageSerial = 0;
  int _messageId = 0;

  @override
  Uint8List buildBody();

  @override
  Uint8List get body {
    final result = <int>[];
    result.add(bodyType);
    result.addAll(buildBody());
    result.add(_messageId);
    result.add(_crc8(result));
    return Uint8List.fromList(result);
  }

  static int _crc8(List<int> data) {
    var crc = 0;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        if (crc & 0x80 != 0) {
          crc = (crc << 1) ^ 0x31;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFF;
  }
}

// ---------------------------------------------------------------------------
// MessageQuery
// ---------------------------------------------------------------------------

class MessageQuery extends MessageA1Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      0x81,
      0x00,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageA1Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0x48,
      );

  bool power = false;
  bool promptTone = false;
  int mode = 1;
  int fanSpeed = 40;
  bool childLock = false;
  int targetHumidity = 40;
  bool swing = false;
  bool anion = false;
  int waterLevelSet = 50;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x01 : 0x00;
    final promptB = promptTone ? 0x40 : 0x00;
    final childB = childLock ? 0x80 : 0x00;
    final anionB = anion ? 0x40 : 0x00;
    final swingB = swing ? 0x08 : 0x00;

    return Uint8List.fromList([
      powerB | promptB | 0x02,
      mode,
      fanSpeed,
      0x00,
      0x00,
      0x00,
      targetHumidity,
      childB,
      anionB,
      swingB,
      0x00,
      0x00,
      waterLevelSet,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

// ---------------------------------------------------------------------------
// A1GeneralMessageBody
// ---------------------------------------------------------------------------

class A1GeneralMessageBody extends MessageBody {
  A1GeneralMessageBody(Uint8List body) : super(body) {
    power = (body[1] & 0x01) > 0;
    mode = body[2] & 0x0F;
    fanSpeed = body[3] & 0x7F;
    targetHumidity = body[7] < minTargetHumidity ? minTargetHumidity : body[7];
    childLock = (body[8] & 0x80) > 0;
    anion = (body[9] & 0x40) > 0;
    tank = body[10] & 0x7F;
    waterLevelSet = body[15];
    currentHumidity = body[16];
    currentTemperature = (body[17] - 50) / 2;
    swing = (body[19] & 0x20) > 0;
    if (fanSpeed < minFanSpeed) {
      fanSpeed = 1;
    }
    filterCleaningReminder = (body[9] & 0x80) > 0;
  }

  late bool power;
  late int mode;
  late int fanSpeed;
  late int targetHumidity;
  late bool childLock;
  late bool anion;
  late int tank;
  late int waterLevelSet;
  late int currentHumidity;
  late double currentTemperature;
  late bool swing;
  late bool filterCleaningReminder;
}

// ---------------------------------------------------------------------------
// MessageA1Response
// ---------------------------------------------------------------------------

class MessageA1Response extends MessageResponse {
  MessageA1Response(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        messageType == MessageType.notify1) {
      final msgBody = A1GeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? promptTone;
  bool? childLock;
  int? mode;
  int? fanSpeed;
  bool? swing;
  int? targetHumidity;
  bool? anion;
  int? tank;
  int? waterLevelSet;
  bool? tankFull;
  int? currentHumidity;
  double? currentTemperature;
  bool? filterCleaningReminder;

  void _assignAttrs(A1GeneralMessageBody b) {
    power = b.power;
    promptTone = null;
    childLock = b.childLock;
    mode = b.mode;
    fanSpeed = b.fanSpeed;
    swing = b.swing;
    targetHumidity = b.targetHumidity;
    anion = b.anion;
    tank = b.tank;
    waterLevelSet = b.waterLevelSet;
    currentHumidity = b.currentHumidity;
    currentTemperature = b.currentTemperature;
    filterCleaningReminder = b.filterCleaningReminder;
  }
}
