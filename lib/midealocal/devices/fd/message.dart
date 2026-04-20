/// Midea local FD device message. Mirrors midealocal/devices/fd/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int disinfectA0BodyLength = 29;
const int disinfectC8BodyLength = 36;
const int maxFanSpeed = 5;
const int maxMsgSerialNum = 254;

abstract class MessageFDBase extends MessageRequest {
  MessageFDBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.fd,
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
        if ((crc & 0x80) != 0) {
          crc = (crc << 1) ^ 0x31;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFF;
  }
}

class MessageQuery extends MessageFDBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      0x81,
      0x00,
      0xFF,
      0x03,
      0x00,
      0x00,
      0x02,
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

class MessageSet extends MessageFDBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x48,
      );

  bool power = false;
  int fanSpeed = 0;
  int targetHumidity = 50;
  bool promptTone = false;
  int screenDisplay = 0x07;
  int mode = 0x01;
  bool? disinfect;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x01 : 0x00;
    final promptToneB = promptTone ? 0x40 : 0x00;
    final disinfectB = disinfect == null ? 0 : (disinfect! ? 1 : 2);
    return Uint8List.fromList([
      powerB | promptToneB | 0x02,
      0x00,
      fanSpeed,
      0x00,
      0x00,
      0x00,
      targetHumidity,
      0x00,
      screenDisplay,
      mode,
      0x00,
      0x00,
      0x00,
      0x00,
      disinfectB,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

class FDC8MessageBody extends MessageBody {
  FDC8MessageBody(Uint8List body) : super(body) {
    power = ((body[1] & 0x01) > 0);
    fanSpeed = body[3] & 0x7F;
    targetHumidity = body[7];
    currentHumidity = body[16];
    currentTemperature = (body[17] - 50) / 2;
    tank = body[10];
    mode = (body[8] & 0x70) >> 4;
    screenDisplay = body[9] & 0x07;
    if (body.length > disinfectC8BodyLength) {
      final disinfectVal = body[34] & 0x03;
      if (disinfectVal != 0) {
        disinfect = disinfectVal == 1;
      }
    }
  }

  bool? power;
  int? fanSpeed;
  int? targetHumidity;
  int? currentHumidity;
  double? currentTemperature;
  int? tank;
  int? mode;
  int? screenDisplay;
  bool? disinfect;
}

class FDA0MessageBody extends MessageBody {
  FDA0MessageBody(Uint8List body) : super(body) {
    power = ((body[1] & 0x01) > 0);
    fanSpeed = body[3] & 0x7F;
    targetHumidity = body[7];
    currentHumidity = body[16];
    currentTemperature = (body[17] - 50) / 2;
    tank = body[10];
    mode = body[10] & 0x07;
    screenDisplay = body[9] & 0x07;
    if (body.length > disinfectA0BodyLength) {
      final disinfectVal = body[27] & 0x03;
      if (disinfectVal != 0) {
        disinfect = disinfectVal == 1;
      }
    }
  }

  bool? power;
  int? fanSpeed;
  int? targetHumidity;
  int? currentHumidity;
  double? currentTemperature;
  int? tank;
  int? mode;
  int? screenDisplay;
  bool? disinfect;
}

class MessageFDResponse extends MessageResponse {
  MessageFDResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        messageType == MessageType.notify1) {
      if (bodyType == 0xB0 || bodyType == 0xB1) {
        // pass
      } else if (bodyType == ListTypes.xa0) {
        setBody(FDA0MessageBody(body));
      } else if (bodyType == ListTypes.c8) {
        setBody(FDC8MessageBody(body));
      }
    }
    _parseBody();
  }

  bool? power;
  int? fanSpeed;
  int? targetHumidity;
  int? currentHumidity;
  double? currentTemperature;
  int? tank;
  int? mode;
  int? screenDisplay;
  bool? disinfect;

  void _parseBody() {
    if (body is FDC8MessageBody) {
      final b = body as FDC8MessageBody;
      fanSpeed = b.fanSpeed;
      if (fanSpeed != null && fanSpeed! < maxFanSpeed) {
        fanSpeed = 1;
      }
      power = b.power;
      targetHumidity = b.targetHumidity;
      currentHumidity = b.currentHumidity;
      currentTemperature = b.currentTemperature;
      tank = b.tank;
      mode = b.mode;
      screenDisplay = b.screenDisplay;
      disinfect = b.disinfect;
    } else if (body is FDA0MessageBody) {
      final b = body as FDA0MessageBody;
      fanSpeed = b.fanSpeed;
      if (fanSpeed != null && fanSpeed! < maxFanSpeed) {
        fanSpeed = 1;
      }
      power = b.power;
      targetHumidity = b.targetHumidity;
      currentHumidity = b.currentHumidity;
      currentTemperature = b.currentTemperature;
      tank = b.tank;
      mode = b.mode;
      screenDisplay = b.screenDisplay;
      disinfect = b.disinfect;
    }
  }

  @override
  void setAttr() {}
}
