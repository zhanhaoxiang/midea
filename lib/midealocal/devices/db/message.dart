/// Midea local DB device message. Mirrors midealocal/devices/db/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// MessageDBBase
// ---------------------------------------------------------------------------

abstract class MessageDBBase extends MessageRequest {
  MessageDBBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.db,
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

class MessageQuery extends MessageDBBase {
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

class MessagePower extends MessageDBBase {
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
    return Uint8List.fromList([
      p,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
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
// MessageStart
// ---------------------------------------------------------------------------

class MessageStart extends MessageDBBase {
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
// DBGeneralMessageBody
// ---------------------------------------------------------------------------

class DBGeneralMessageBody extends MessageBody {
  DBGeneralMessageBody(Uint8List body) : super(body) {
    power = body[1] > 0;
    start = body[2] == 2 || body[2] == 6;
    washingData = body.sublist(3, 16);
    status = body[2];
    mode = body[3];
    program = body[4];
    waterLevel = body[5];
    temperature = body[7];
    dehydrationSpeed = body[8];
    washTime = body[9];
    dehydrationTime = body[10];
    detergent = body[11];
    softener = body[12];

    progress = 0;
    for (var i = 0; i < 7; i++) {
      if ((body[16] & (1 << i)) > 0) {
        progress = i + 1;
        break;
      }
    }

    stains = body.length > 26 ? body[26] : 0;
    washTimeValue = body.length > 27 ? body[27] : 0;
    dehydrationTimeValue = body.length > 28 ? body[28] : 0;
    dirtyDegree = body.length > 30 ? body[30] : 0;

    timeRemaining = null;
    if (power) {
      timeRemaining = body.length > 18 ? body[17] + (body[18] << 8) : null;
    }
  }

  late bool power;
  late bool start;
  late Uint8List washingData;
  late int status;
  late int mode;
  late int program;
  late int waterLevel;
  late int temperature;
  late int dehydrationSpeed;
  late int washTime;
  late int dehydrationTime;
  late int detergent;
  late int softener;
  late int progress;
  late int stains;
  late int washTimeValue;
  late int dehydrationTimeValue;
  late int dirtyDegree;
  int? timeRemaining;
}

// ---------------------------------------------------------------------------
// MessageDBResponse
// ---------------------------------------------------------------------------

class MessageDBResponse extends MessageResponse {
  MessageDBResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        (messageType == MessageType.notify1 && bodyType == ListTypes.x04)) {
      final msgBody = DBGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? start;
  Uint8List? washingData;
  int? status;
  int? mode;
  int? program;
  int? waterLevel;
  int? temperature;
  int? dehydrationSpeed;
  int? washTime;
  int? dehydrationTime;
  int? detergent;
  int? softener;
  int? progress;
  int? stains;
  int? washTimeValue;
  int? dehydrationTimeValue;
  int? dirtyDegree;
  int? timeRemaining;

  void _assignAttrs(DBGeneralMessageBody b) {
    power = b.power;
    start = b.start;
    washingData = b.washingData;
    status = b.status;
    mode = b.mode;
    program = b.program;
    waterLevel = b.waterLevel;
    temperature = b.temperature;
    dehydrationSpeed = b.dehydrationSpeed;
    washTime = b.washTime;
    dehydrationTime = b.dehydrationTime;
    detergent = b.detergent;
    softener = b.softener;
    progress = b.progress;
    stains = b.stains;
    washTimeValue = b.washTimeValue;
    dehydrationTimeValue = b.dehydrationTimeValue;
    dirtyDegree = b.dirtyDegree;
    timeRemaining = b.timeRemaining;
  }
}
