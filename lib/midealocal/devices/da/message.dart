/// Midea local DA device message. Mirrors midealocal/devices/da/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// MessageDABase
// ---------------------------------------------------------------------------

abstract class MessageDABase extends MessageRequest {
  MessageDABase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.da,
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

class MessageQuery extends MessageDABase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x03,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessagePower
// ---------------------------------------------------------------------------

class MessagePower extends MessageDABase {
  MessagePower(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x02,
      );

  bool power = false;

  @override
  Uint8List buildBody() {
    final p = power ? 0x01 : 0x00;
    return Uint8List.fromList([p, 0xFF]);
  }
}

// ---------------------------------------------------------------------------
// MessageStart
// ---------------------------------------------------------------------------

class MessageStart extends MessageDABase {
  MessageStart(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x02,
      );

  bool start = false;
  Uint8List washingData = Uint8List(0);

  @override
  Uint8List buildBody() {
    if (start) {
      return Uint8List.fromList([0xFF, 0x01, ...washingData]);
    }
    return Uint8List.fromList([0xFF, 0x00]);
  }
}

// ---------------------------------------------------------------------------
// DAGeneralMessageBody
// ---------------------------------------------------------------------------

class DAGeneralMessageBody extends MessageBody {
  DAGeneralMessageBody(Uint8List body) : super(body) {
    power = body[1] > 0;
    start = body[2] == 2 || body[2] == 6;
    errorCode = body[24];
    program = body[4];
    washTime = body[9];
    soakTime = body[12];
    dehydrationTime = (body[10] & 0xF0) >> 4;
    dehydrationSpeed = (body[6] & 0xF0) >> 4;
    rinseCount = body[10] & 0xF;
    rinseLevel = (body[5] & 0xF0) >> 4;
    washLevel = body[5] & 0xF;
    washStrength = body[6] & 0xF;
    softener = (body[8] & 0xF0) >> 4;
    detergent = body[8] & 0x0F;
    washingData = body.sublist(3, 15);
    progress = 0;
    for (var i = 1; i < 7; i++) {
      if ((body[16] & (1 << i)) > 0) {
        progress = i;
        break;
      }
    }

    timeRemaining = null;
    if (power) {
      timeRemaining = body[17] + (body[18] * 60);
    }
  }

  late bool power;
  late bool start;
  late int errorCode;
  late int program;
  late int washTime;
  late int soakTime;
  late int dehydrationTime;
  late int dehydrationSpeed;
  late int rinseCount;
  late int rinseLevel;
  late int washLevel;
  late int washStrength;
  late int softener;
  late int detergent;
  late Uint8List washingData;
  late int progress;
  int? timeRemaining;
}

// ---------------------------------------------------------------------------
// MessageDAResponse
// ---------------------------------------------------------------------------

class MessageDAResponse extends MessageResponse {
  MessageDAResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        (messageType == MessageType.notify1 && bodyType == ListTypes.x04)) {
      final msgBody = DAGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? start;
  int? errorCode;
  int? program;
  int? washTime;
  int? soakTime;
  int? dehydrationTime;
  int? dehydrationSpeed;
  int? rinseCount;
  int? rinseLevel;
  int? washLevel;
  int? washStrength;
  int? softener;
  int? detergent;
  Uint8List? washingData;
  int? progress;
  int? timeRemaining;

  void _assignAttrs(DAGeneralMessageBody b) {
    power = b.power;
    start = b.start;
    errorCode = b.errorCode;
    program = b.program;
    washTime = b.washTime;
    soakTime = b.soakTime;
    dehydrationTime = b.dehydrationTime;
    dehydrationSpeed = b.dehydrationSpeed;
    rinseCount = b.rinseCount;
    rinseLevel = b.rinseLevel;
    washLevel = b.washLevel;
    washStrength = b.washStrength;
    softener = b.softener;
    detergent = b.detergent;
    washingData = b.washingData;
    progress = b.progress;
    timeRemaining = b.timeRemaining;
  }
}
