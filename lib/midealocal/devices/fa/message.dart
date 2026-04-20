import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxFanSpeed = 26;
const int tiltingAngleGetByte = 25;
const int tiltingAngleSetByte = 24;

abstract class MessageFABase extends MessageRequest {
  MessageFABase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.fa,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageFABase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageSet extends MessageFABase {
  MessageSet({required int protocolVersion, required int subtype})
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      ) {
    _subtype = subtype;
  }

  late int _subtype;

  bool? power;
  bool? lock;
  int? mode;
  int? fanSpeed;
  bool? oscillate;
  int? oscillationAngle;
  int? oscillationMode;
  int? tiltingAngle;

  @override
  Uint8List buildBody() {
    late List<int> bodyReturn;
    if (_subtype >= 1 && _subtype <= 0x0A || _subtype == 0xA1) {
      bodyReturn = [
        0x00,
        0x00,
        0x00,
        0x80,
        0x00,
        0x00,
        0x00,
        0x80,
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
      ];
      if (_subtype != 0x0A) {
        bodyReturn[13] = 0xFF;
      }
    } else {
      bodyReturn = List<int>.filled(58, 0x00);
    }

    if (power != null) {
      if (power!) {
        bodyReturn[3] = 1;
      } else {
        bodyReturn[3] = 0;
      }
    }
    if (lock != null) {
      if (lock!) {
        bodyReturn[2] = 1;
      } else {
        bodyReturn[2] = 2;
      }
    }
    if (mode != null) {
      bodyReturn[3] = 1 | (((mode! + 1) << 1) & 0x1E);
    }
    if (fanSpeed != null && fanSpeed! >= 1 && fanSpeed! <= maxFanSpeed) {
      bodyReturn[4] = fanSpeed!;
    }
    if (oscillate != null) {
      if (oscillate!) {
        bodyReturn[7] = 1;
      } else {
        bodyReturn[7] = 0;
      }
    }
    if (oscillationAngle != null) {
      bodyReturn[7] = 1 | bodyReturn[7] | ((oscillationAngle! << 4) & 0x70);
    }
    if (oscillationMode != null) {
      bodyReturn[7] = 1 | bodyReturn[7] | ((oscillationMode! << 1) & 0x0E);
    }
    if (tiltingAngle != null && bodyReturn.length > tiltingAngleSetByte) {
      bodyReturn[24] = tiltingAngle!;
    }

    return Uint8List.fromList(bodyReturn);
  }
}

class FAGeneralMessageBody extends MessageBody {
  FAGeneralMessageBody(Uint8List data) : super(data);

  late bool childLock;
  late bool power;
  late int mode;
  late int fanSpeed;
  late bool oscillate;
  late int oscillationAngle;
  late int oscillationMode;
  late int tiltingAngle;
}

class MessageFAResponse extends MessageResponse {
  MessageFAResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        messageType == MessageType.notify1) {
      setBody(FAGeneralMessageBody(body));
      _parseBody();
    }
  }

  void _parseBody() {
    final bodyData = body;
    final lock = bodyData[3] & 0x03;
    childLock = lock == 1;
    power = (bodyData[4] & 0x01) > 0;
    final m = (bodyData[4] & 0x1E) >> 1;
    mode = m > 0 ? m - 1 : 0;
    final fs = bodyData[5];
    fanSpeed = fs >= 1 && fs <= maxFanSpeed ? fs : 0;
    oscillate = (bodyData[8] & 0x01) > 0;
    oscillationAngle = (bodyData[8] & 0x70) >> 4;
    oscillationMode = (bodyData[8] & 0x0E) >> 1;
    tiltingAngle = bodyData.length > tiltingAngleGetByte ? bodyData[25] : 0;
  }

  bool childLock = false;
  bool power = false;
  int mode = 0;
  int fanSpeed = 0;
  bool oscillate = false;
  int oscillationAngle = 0;
  int oscillationMode = 0;
  int tiltingAngle = 0;

  @override
  void setAttr() {}
}
