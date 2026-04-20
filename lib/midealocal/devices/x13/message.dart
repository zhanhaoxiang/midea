/// Midea local X13 device message. Mirrors midealocal/devices/x13/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxEffect = 5;

abstract class Message13Base extends MessageRequest {
  Message13Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.x13,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );
}

class MessageQuery extends Message13Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x24,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
  }
}

class MessageSet extends Message13Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      );

  int? brightness;
  int? colorTemperature;
  int? effect;
  bool? power;

  @override
  Uint8List buildBody() {
    int bodyByte = 0x00;
    if (power != null) {
      bodyType = ListTypes.x01;
      bodyByte = power! ? 0x01 : 0x00;
    } else if (effect != null && effect! >= 1 && effect! <= 5) {
      bodyType = ListTypes.x01;
      bodyByte = effect! + 1;
    } else if (colorTemperature != null) {
      bodyType = ListTypes.x03;
      bodyByte = colorTemperature!;
    } else if (brightness != null) {
      bodyType = ListTypes.x04;
      bodyByte = brightness!;
    }
    return Uint8List.fromList([bodyByte, 0x00, 0x00, 0x00]);
  }
}

class MessageMainLightBody extends MessageBody {
  MessageMainLightBody(Uint8List body) : super(body) {
    brightness = body.length > 1 ? body[1] : 0;
    colorTemperature = body.length > 2 ? body[2] : 0;
    var tempEffect = (body.length > 3 ? body[3] : 0) - 1;
    if (tempEffect > maxEffect) {
      tempEffect = 1;
    }
    effect = tempEffect;
    power = body.length > 8 ? body[8] > 0 : false;
  }

  late int brightness;
  late int colorTemperature;
  late int effect;
  late bool power;
}

class MessageMainLightResponseBody extends MessageBody {
  MessageMainLightResponseBody(Uint8List body) : super(body) {
    controlSuccess = body.length > 1 ? body[1] > 0 : false;
  }

  late bool controlSuccess;
}

class Message13Response extends MessageResponse {
  Message13Response(Uint8List message) : super(message) {
    if (bodyType == ListTypes.xa4) {
      final msgBody = MessageMainLightBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    } else if (messageType == MessageType.set && bodyType > ListTypes.x80) {
      final msgBody = MessageMainLightResponseBody(body);
      setBody(msgBody);
      controlSuccess = msgBody.controlSuccess;
    }
  }

  int? brightness;
  int? colorTemperature;
  int? effect;
  bool? power;
  bool? controlSuccess;

  void _assignAttrs(MessageMainLightBody b) {
    brightness = b.brightness;
    colorTemperature = b.colorTemperature;
    effect = b.effect;
    power = b.power;
  }
}
