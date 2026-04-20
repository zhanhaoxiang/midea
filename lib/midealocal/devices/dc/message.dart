/// Midea local DC device message. Mirrors midealocal/devices/dc/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// MessageDCBase
// ---------------------------------------------------------------------------

abstract class MessageDCBase extends MessageRequest {
  MessageDCBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.dc,
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

class MessageQuery extends MessageDCBase {
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

class MessagePower extends MessageDCBase {
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

class MessageStart extends MessageDCBase {
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
// DCGeneralMessageBody
// ---------------------------------------------------------------------------

class DCGeneralMessageBody extends MessageBody {
  DCGeneralMessageBody(Uint8List body) : super(body) {
    power = body[1] > 0;
    start = body[2] == 2 || body[2] == 6;
    status = body[2];
    washingData = body.sublist(3, 15);
    program = body[4];
    intensity = body[9];
    drynessLevel = body[10];
    dryTemperature = body[10];
    errorCode = body[24];
    doorWarn = body[25];
    aiSwitch = body[27];
    material = body[28];
    waterBox = body[29];

    progress = 0;
    for (var i = 0; i < 7; i++) {
      if ((body[16] & (1 << i)) > 0) {
        progress = i + 1;
        break;
      }
    }

    timeRemaining = null;
    if (power) {
      timeRemaining = body[17] + (body[18] << 8);
    }
  }

  late bool power;
  late bool start;
  late int status;
  late Uint8List washingData;
  late int program;
  late int intensity;
  late int drynessLevel;
  late int dryTemperature;
  late int errorCode;
  late int doorWarn;
  late int aiSwitch;
  late int material;
  late int waterBox;
  late int progress;
  int? timeRemaining;
}

// ---------------------------------------------------------------------------
// MessageDCResponse
// ---------------------------------------------------------------------------

class MessageDCResponse extends MessageResponse {
  MessageDCResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        (messageType == MessageType.notify1 && bodyType == ListTypes.x04)) {
      final msgBody = DCGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? start;
  int? status;
  Uint8List? washingData;
  int? program;
  int? intensity;
  int? drynessLevel;
  int? dryTemperature;
  int? errorCode;
  int? doorWarn;
  int? aiSwitch;
  int? material;
  int? waterBox;
  int? progress;
  int? timeRemaining;

  void _assignAttrs(DCGeneralMessageBody b) {
    power = b.power;
    start = b.start;
    status = b.status;
    washingData = b.washingData;
    program = b.program;
    intensity = b.intensity;
    drynessLevel = b.drynessLevel;
    dryTemperature = b.dryTemperature;
    errorCode = b.errorCode;
    doorWarn = b.doorWarn;
    aiSwitch = b.aiSwitch;
    material = b.material;
    waterBox = b.waterBox;
    progress = b.progress;
    timeRemaining = b.timeRemaining;
  }
}
