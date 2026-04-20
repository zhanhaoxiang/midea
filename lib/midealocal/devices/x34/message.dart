/// Midea local X34 device message. Mirrors midealocal/devices/x34/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int humidityByte = 33;
const int storageRemainingByte = 18;

// ---------------------------------------------------------------------------
// Message34Base
// ---------------------------------------------------------------------------

abstract class Message34Base extends MessageRequest {
  Message34Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.x34,
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

class MessageQuery extends Message34Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessagePower
// ---------------------------------------------------------------------------

class MessagePower extends Message34Base {
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

// ---------------------------------------------------------------------------
// MessageLock
// ---------------------------------------------------------------------------

class MessageLock extends Message34Base {
  MessageLock(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x83,
      );

  bool lock = false;

  @override
  Uint8List buildBody() {
    final lockValue = lock ? 0x03 : 0x04;
    return Uint8List.fromList([lockValue, ...List.filled(36, 0)]);
  }
}

// ---------------------------------------------------------------------------
// MessageStorage
// ---------------------------------------------------------------------------

class MessageStorage extends Message34Base {
  MessageStorage(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x81,
      );

  bool storage = false;

  @override
  Uint8List buildBody() {
    final storageValue = storage ? 0x01 : 0x00;
    return Uint8List.fromList([
      0x00,
      0x00,
      0x00,
      storageValue,
      ...List.filled(6, 0xFF),
      ...List.filled(27, 0x00),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Message34Body
// ---------------------------------------------------------------------------

class Message34Body extends MessageBody {
  Message34Body(Uint8List body) : super(body) {
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
    childLock = (body[5] & 0x10) > 0;
    uv = (body[4] & 0x02) > 0;
    dry = (body[4] & 0x10) > 0;
    dryStatus = (body[4] & 0x20) > 0;
    storage = (body[5] & 0x20) > 0;
    storageStatus = (body[5] & 0x40) > 0;
    timeRemaining = body[6];
    progress = body[9];
    storageRemaining = body.length > storageRemainingByte
        ? body[storageRemainingByte]
        : null;
    temperature = body[11];
    humidity = body.length > humidityByte ? body[humidityByte] : null;
    waterswitch = (body[4] & 0x04) > 0;
    waterLack = (body[5] & 0x80) > 0;
    errorCode = body[10];
    softwater = body[13];
    wrongOperation = body[16];
    bright = body[24];
  }

  late bool power;
  late int status;
  late int mode;
  late int additional;
  late bool door;
  late bool rinseAid;
  late bool salt;
  late bool? start;
  late bool childLock;
  late bool uv;
  late bool dry;
  late bool dryStatus;
  late bool storage;
  late bool storageStatus;
  late int timeRemaining;
  late int progress;
  int? storageRemaining;
  late int temperature;
  int? humidity;
  late bool waterswitch;
  late bool waterLack;
  late int errorCode;
  late int softwater;
  late int wrongOperation;
  late int bright;
}

// ---------------------------------------------------------------------------
// Message34Response
// ---------------------------------------------------------------------------

class Message34Response extends MessageResponse {
  Message34Response(Uint8List message) : super(message) {
    final isValidQuery =
        messageType == MessageType.query || messageType == MessageType.notify1;
    final isValidSet =
        messageType == MessageType.set && bodyType >= 0 && bodyType <= 0x07;

    if ((isValidSet) || (isValidQuery && bodyType == 0)) {
      final msgBody = Message34Body(body);
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
  int? progress;
  int? storageRemaining;
  int? temperature;
  int? humidity;
  bool? waterswitch;
  bool? waterLack;
  int? errorCode;
  int? softwater;
  int? wrongOperation;
  int? bright;

  void _assignAttrs(Message34Body b) {
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
    progress = b.progress;
    storageRemaining = b.storageRemaining;
    temperature = b.temperature;
    humidity = b.humidity;
    waterswitch = b.waterswitch;
    waterLack = b.waterLack;
    errorCode = b.errorCode;
    softwater = b.softwater;
    wrongOperation = b.wrongOperation;
    bright = b.bright;
  }
}
