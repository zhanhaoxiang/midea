/// Midea local E1 device message. Mirrors midealocal/devices/e1/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int brightByte = 24;
const int storageRemainingByte = 18;
const int humidityByte = 33;

abstract class MessageE1Base extends MessageRequest {
  MessageE1Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.e1,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessagePower extends MessageE1Base {
  MessagePower(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x08,
      );

  bool power = false;

  @override
  Uint8List buildBody() {
    final p = power ? 0x01 : 0x00;
    return Uint8List.fromList([p, 0x00, 0x00, 0x00]);
  }
}

class MessageWork extends MessageE1Base {
  MessageWork(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x08,
      );

  int workStatus = 0x03;
  int mode = 0;

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([workStatus, mode, 0x00, 0x00]);
  }
}

class MessageLock extends MessageE1Base {
  MessageLock(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x83,
      );

  bool lock = false;

  @override
  Uint8List buildBody() {
    final l = lock ? 0x03 : 0x04;
    return Uint8List.fromList([l, ...List.filled(36, 0)]);
  }
}

class MessageStorage extends MessageE1Base {
  MessageStorage(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x81,
      );

  bool storage = false;

  @override
  Uint8List buildBody() {
    final s = storage ? 0x01 : 0x00;
    return Uint8List.fromList([
      0x00,
      0x00,
      0x00,
      s,
      ...List.filled(6, 0xFF),
      ...List.filled(27, 0x00),
    ]);
  }
}

class MessageQuery extends MessageE1Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class E1GeneralMessageBody extends MessageBody {
  E1GeneralMessageBody(Uint8List body) : super(body) {
    power = body[1] > 0;
    status = body[1];
    mode = body[2];
    additional = body[3];
    door = (body[5] & 0x01) == 0;
    rinseAid = (body[5] & 0x02) > 0;
    salt = (body[5] & 0x04) > 0;
    final startPause = (body[5] & 0x08) > 0;
    if (startPause) {
      start = true;
    } else if (status == 2 || status == 3) {
      start = false;
    }
    lackBright = (body[5] & 0x02) > 0;
    lackSoftwater = (body[5] & 0x04) > 0;
    diyflag = (body[4] & 0x08) > 0;
    childLock = (body[5] & 0x10) > 0;
    uv = (body[4] & 0x02) > 0;
    dry = (body[4] & 0x10) > 0;
    dryStatus = (body[4] & 0x20) > 0;
    storage = (body[5] & 0x20) > 0;
    storageStatus = (body[5] & 0x40) > 0;
    timeRemaining = body[6];
    if (body.length > humidityByte) {
      final leftTimeHigh = body[32];
      if (leftTimeHigh != 0) {
        timeRemaining = leftTimeHigh * 256 + timeRemaining;
      }
    }
    progress = body[9];
    storageSetTime = body.length > storageRemainingByte ? body[17] : null;
    storageRemaining = body.length > storageRemainingByte ? body[18] : null;
    temperature = body[11];
    humidity = body.length > humidityByte ? body[33] : null;
    doorSwitch = (body[5] & 0x01) > 0;
    drySwitch = (body[5] & 0x10) > 0;
    dryStatusSwitch = (body[5] & 0x20) > 0;
    waterSwitch = (body[4] & 0x04) > 0;
    waterLack = (body[5] & 0x80) > 0;
    dryStepSwitch = (body[4] & 0x01) > 0;
    uvSwitch = (body[4] & 0x02) > 0;
    errorCode = body[10];
    softwater = body[13];
    wrongOperation = body[16];
    bright = body.length > brightByte ? body[24] : null;
  }

  late bool power;
  late int status;
  late int mode;
  late int additional;
  late bool door;
  late bool rinseAid;
  late bool salt;
  bool? start;
  late bool lackBright;
  late bool lackSoftwater;
  late bool diyflag;
  late bool childLock;
  late bool uv;
  late bool dry;
  late bool dryStatus;
  late bool storage;
  late bool storageStatus;
  late int timeRemaining;
  late int progress;
  int? storageSetTime;
  int? storageRemaining;
  late int temperature;
  int? humidity;
  late bool doorSwitch;
  late bool drySwitch;
  late bool dryStatusSwitch;
  late bool waterSwitch;
  late bool waterLack;
  late bool dryStepSwitch;
  late bool uvSwitch;
  late int errorCode;
  late int softwater;
  late int wrongOperation;
  int? bright;
}

class MessageE1Response extends MessageResponse {
  MessageE1Response(Uint8List message) : super(message) {
    if ((messageType == MessageType.set && 0 <= bodyType && bodyType <= 0x07) ||
        ((messageType == MessageType.query ||
                messageType == MessageType.notify1) &&
            bodyType == 0)) {
      final msgBody = E1GeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  int? status;
  int? mode;
  int? additional;
  bool? door;
  bool? rinseAid;
  bool? salt;
  bool? start;
  bool? childLock;
  bool? uv;
  bool? dry;
  bool? dryStatus;
  bool? storage;
  bool? storageStatus;
  int? timeRemaining;
  int? storageRemaining;
  int? temperature;
  int? humidity;
  bool? waterswitch;
  bool? waterLack;
  int? progress;
  int? errorCode;
  int? softwater;
  int? wrongOperation;
  int? bright;

  void _assignAttrs(E1GeneralMessageBody b) {
    power = b.power;
    status = b.status;
    mode = b.mode;
    additional = b.additional;
    door = b.door;
    rinseAid = b.rinseAid;
    salt = b.salt;
    start = b.start;
    childLock = b.childLock;
    uv = b.uv;
    dry = b.dry;
    dryStatus = b.dryStatus;
    storage = b.storage;
    storageStatus = b.storageStatus;
    timeRemaining = b.timeRemaining;
    storageRemaining = b.storageRemaining;
    temperature = b.temperature;
    humidity = b.humidity;
    waterswitch = b.waterSwitch;
    waterLack = b.waterLack;
    progress = b.progress;
    errorCode = b.errorCode;
    softwater = b.softwater;
    wrongOperation = b.wrongOperation;
    bright = b.bright;
  }
}
