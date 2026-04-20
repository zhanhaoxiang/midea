/// Midea local EC device message. Mirrors midealocal/devices/ec/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// MessageECBase
// ---------------------------------------------------------------------------

abstract class MessageECBase extends MessageRequest {
  MessageECBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ec,
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

class MessageQuery extends MessageECBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([
    0xAA,
    0x55,
    0x01,
    0x03,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ]);
}

// ---------------------------------------------------------------------------
// ECGeneralMessageBody
// ---------------------------------------------------------------------------

class ECGeneralMessageBody extends MessageBody {
  ECGeneralMessageBody(Uint8List body) : super(body) {
    mode = body[4] + (body[5] << 8);
    progress = body[8];
    cooking = progress == 1;
    timeRemaining = body[12] * 60 + body[13];
    keepWarmTime = body[16] * 60 + body[17];
    topTemperature = body[21];
    bottomTemperature = body[22];
    withPressure = (body[23] & 0x04) > 0;
  }

  late int mode;
  late int progress;
  late bool cooking;
  late int timeRemaining;
  late int keepWarmTime;
  late int topTemperature;
  late int bottomTemperature;
  late bool withPressure;
}

// ---------------------------------------------------------------------------
// ECBodyNew
// ---------------------------------------------------------------------------

class ECBodyNew extends MessageBody {
  ECBodyNew(Uint8List body) : super(body) {
    progress = body[11];
    cooking = progress == 1;
    timeRemaining = body[16] * 60 + body[17];
    keepWarmTime = body[19] * 60 + body[20];
    topTemperature = body[48];
    bottomTemperature = body[49];
    withPressure = body[33] > 0;
  }

  late int progress;
  late bool cooking;
  late int timeRemaining;
  late int keepWarmTime;
  late int topTemperature;
  late int bottomTemperature;
  late bool withPressure;
}

// ---------------------------------------------------------------------------
// MessageECResponse
// ---------------------------------------------------------------------------

class MessageECResponse extends MessageResponse {
  MessageECResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.notify1 && body[3] == 0x01) {
      final msgBody = ECBodyNew(body);
      setBody(msgBody);
      assignAttrsFromNew(msgBody);
    } else if ((messageType == MessageType.set && body[3] == 0x02) ||
        (messageType == MessageType.query && body[3] == 0x03) ||
        (messageType == MessageType.notify1 && body[3] == 0x04) ||
        (messageType == MessageType.notify1 && body[3] == 0x3D)) {
      final msgBody = ECGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    } else if (messageType == MessageType.notify1 && body[3] == 0x06) {
      mode = body[4] + (body[5] << 8);
    }
  }

  bool? cooking;
  int? mode;
  int? progress;
  int? timeRemaining;
  int? keepWarmTime;
  int? topTemperature;
  int? bottomTemperature;
  bool? withPressure;

  void _assignAttrs(ECGeneralMessageBody b) {
    mode = b.mode;
    progress = b.progress;
    cooking = b.cooking;
    timeRemaining = b.timeRemaining;
    keepWarmTime = b.keepWarmTime;
    topTemperature = b.topTemperature;
    bottomTemperature = b.bottomTemperature;
    withPressure = b.withPressure;
  }

  void assignAttrsFromNew(ECBodyNew b) {
    mode = null;
    progress = b.progress;
    cooking = b.cooking;
    timeRemaining = b.timeRemaining;
    keepWarmTime = b.keepWarmTime;
    topTemperature = b.topTemperature;
    bottomTemperature = b.bottomTemperature;
    withPressure = b.withPressure;
  }
}
