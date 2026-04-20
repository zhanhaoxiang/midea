/// Midea local BF device message. Mirrors midealocal/devices/bf/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int maxByteValue = 255;

// ---------------------------------------------------------------------------
// MessageBFBase
// ---------------------------------------------------------------------------

abstract class MessageBFBase extends MessageRequest {
  MessageBFBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.bf,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

// ---------------------------------------------------------------------------
// MessageQuery
// ---------------------------------------------------------------------------

class MessageQuery extends MessageBFBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageBFBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x02,
      );

  bool? power;
  bool? childLock;

  @override
  Uint8List buildBody() {
    final powerB = power == null ? 0xFF : (power! ? 0x11 : 0x01);
    final childLockB = childLock == null ? 0xFF : (childLock! ? 0x01 : 0x00);
    return Uint8List.fromList([
      powerB,
      childLockB,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageBFBody
// ---------------------------------------------------------------------------

class MessageBFBody extends MessageBody {
  MessageBFBody(Uint8List body) : super(body) {
    status = body[31];
    final hours = body[22] == maxByteValue ? 0 : body[22];
    final minutes = body[23] == maxByteValue ? 0 : body[23];
    final seconds = body[24] == maxByteValue ? 0 : body[24];
    timeRemaining = hours * 3600 + minutes * 60 + seconds;
    var curTemperature = body[25] * 256 + body[26];
    if (curTemperature == 0) {
      curTemperature = body[27] * 256 + body[28];
    }
    currentTemperature = curTemperature;
    childLock = (body[32] & 0x01) > 0;
    door = (body[32] & 0x02) > 0;
    tankEjected = (body[32] & 0x04) > 0;
    waterShortage = (body[32] & 0x08) > 0;
    waterChangeReminder = (body[32] & 0x10) > 0;
  }

  late int status;
  late int timeRemaining;
  late int currentTemperature;
  late bool childLock;
  late bool door;
  late bool tankEjected;
  late bool waterShortage;
  late bool waterChangeReminder;
}

// ---------------------------------------------------------------------------
// MessageBFResponse
// ---------------------------------------------------------------------------

class MessageBFResponse extends MessageResponse {
  MessageBFResponse(Uint8List message) : super(message) {
    if ((messageType == MessageType.set ||
            messageType == MessageType.notify1 ||
            messageType == MessageType.query) &&
        bodyType == ListTypes.x01) {
      final msgBody = MessageBFBody(body);
      setBody(msgBody);
      status = msgBody.status;
      timeRemaining = msgBody.timeRemaining;
      currentTemperature = msgBody.currentTemperature;
      childLock = msgBody.childLock;
      door = msgBody.door;
      tankEjected = msgBody.tankEjected;
      waterShortage = msgBody.waterShortage;
      waterChangeReminder = msgBody.waterChangeReminder;
    }
  }

  int? status;
  int? timeRemaining;
  int? currentTemperature;
  bool? childLock;
  bool? door;
  bool? tankEjected;
  bool? waterShortage;
  bool? waterChangeReminder;
}
