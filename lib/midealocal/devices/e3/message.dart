/// Midea local E3 device message. Mirrors midealocal/devices/e3/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const Map<String, int> newProtocolParams = {
  'none': 0x00,
  'zero_cold_water': 0x03,
  'zero_cold_pulse': 0x04,
  'smart_volume': 0x07,
  'target_temperature': 0x08,
};

const int additionalByte = 20;

// ---------------------------------------------------------------------------
// MessageE3Base
// ---------------------------------------------------------------------------

abstract class MessageE3Base extends MessageRequest {
  MessageE3Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.e3,
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

class MessageQuery extends MessageE3Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessagePower
// ---------------------------------------------------------------------------

class MessagePower extends MessageE3Base {
  MessagePower(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x02,
      );

  bool power = false;

  @override
  int get bodyType => power ? ListTypes.x01 : ListTypes.x02;

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageE3Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x04,
      );

  double targetTemperature = 0.0;
  bool zeroColdWater = false;
  int bathtubVolume = 0;
  bool protection = false;
  bool zeroColdPulse = false;
  bool smartVolume = false;

  @override
  Uint8List buildBody() {
    final zeroColdWaterByte = zeroColdWater ? 0x01 : 0x00;
    final protectionByte = protection ? 0x08 : 0x00;
    final zeroColdPulseByte = zeroColdPulse ? 0x10 : 0x00;
    final smartVolumeByte = smartVolume ? 0x20 : 0x00;
    final targetTemperatureByte = targetTemperature.toInt() & 0xFF;

    return Uint8List.fromList([
      0x01,
      zeroColdWaterByte | 0x02,
      protectionByte | zeroColdPulseByte | smartVolumeByte,
      0x00,
      targetTemperatureByte,
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

// ---------------------------------------------------------------------------
// MessageNewProtocolSet
// ---------------------------------------------------------------------------

class MessageNewProtocolSet extends MessageE3Base {
  MessageNewProtocolSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x24,
      );

  String key = 'none';
  dynamic value;

  @override
  Uint8List buildBody() {
    final keyValue = newProtocolParams[key] ?? 0x00;
    final valueByte = key == 'target_temperature'
        ? (value as double).toInt()
        : (value == true ? 0x01 : 0x00);

    return Uint8List.fromList([
      keyValue,
      valueByte,
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
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

// ---------------------------------------------------------------------------
// E3GeneralMessageBody
// ---------------------------------------------------------------------------

class E3GeneralMessageBody extends MessageBody {
  E3GeneralMessageBody(Uint8List body) : super(body) {
    power = (body[2] & 0x01) > 0;
    burningState = (body[2] & 0x02) > 0;
    zeroColdWater = (body[2] & 0x04) > 0;
    currentTemperature = body[5].toDouble();
    targetTemperature = body[6].toDouble();
    protection = (body[8] & 0x08) > 0;
    zeroColdPulse = body.length > additionalByte
        ? (body[20] & 0x01) > 0
        : false;
    smartVolume = body.length > additionalByte ? (body[20] & 0x02) > 0 : false;
  }

  late bool power;
  late bool burningState;
  late bool zeroColdWater;
  late double currentTemperature;
  late double targetTemperature;
  late bool protection;
  late bool zeroColdPulse;
  late bool smartVolume;
}

// ---------------------------------------------------------------------------
// MessageE3Response
// ---------------------------------------------------------------------------

class MessageE3Response extends MessageResponse {
  MessageE3Response(Uint8List message) : super(message) {
    if (_isValidResponse) {
      final msgBody = E3GeneralMessageBody(super.body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? burningState;
  bool? zeroColdWater;
  double? currentTemperature;
  double? targetTemperature;
  bool? protection;
  bool? zeroColdPulse;
  bool? smartVolume;

  bool get _isValidResponse {
    if (messageType == MessageType.query && bodyType == ListTypes.x01) {
      return true;
    }
    if (messageType == MessageType.set &&
        (bodyType == ListTypes.x01 ||
            bodyType == ListTypes.x02 ||
            bodyType == ListTypes.x04 ||
            bodyType == ListTypes.x24)) {
      return true;
    }
    if (messageType == MessageType.notify1 &&
        (bodyType == ListTypes.x00 || bodyType == ListTypes.x01)) {
      return true;
    }
    return false;
  }

  void _assignAttrs(E3GeneralMessageBody b) {
    power = b.power;
    burningState = b.burningState;
    zeroColdWater = b.zeroColdWater;
    currentTemperature = b.currentTemperature;
    targetTemperature = b.targetTemperature;
    protection = b.protection;
    zeroColdPulse = b.zeroColdPulse;
    smartVolume = b.smartVolume;
  }
}
