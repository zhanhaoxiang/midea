/// Midea local X40 device message. Mirrors midealocal/devices/x40/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxBlowSpeedLowFanSpeed = 30;

// ---------------------------------------------------------------------------
// MessageX40Base
// ---------------------------------------------------------------------------

abstract class MessageX40Base extends MessageRequest {
  MessageX40Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.x40,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageQuery
// ---------------------------------------------------------------------------

class MessageQuery extends MessageX40Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageX40Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x01,
      );

  Map<String, int> fields = {};
  bool light = false;
  int fanSpeed = 0;
  int direction = 0;
  bool ventilation = false;
  bool smellySensor = false;

  int readField(String field) {
    final value = fields[field] ?? 0;
    return value;
  }

  @override
  Uint8List buildBody() {
    final lightB = light ? 1 : 0;
    final blow = fanSpeed > 0 ? 1 : 0;
    final fanSpeedB = fanSpeed == 0 ? 0xFF : (fanSpeed == 1 ? 30 : 100);
    final ventilationB = ventilation ? 1 : 0;
    final smellySensorB = smellySensor ? 1 : 0;

    return Uint8List.fromList([
      lightB,
      readField('MAIN_LIGHT_BRIGHTNESS'),
      readField('NIGHT_LIGHT_ENABLE'),
      readField('NIGHT_LIGHT_BRIGHTNESS'),
      readField('RADAR_INDUCTION_ENABLE'),
      readField('RADAR_INDUCTION_CLOSING_TIME'),
      readField('LIGHT_INTENSITY_THRESHOLD'),
      readField('RADAR_SENSITIVITY'),
      readField('HEATING_ENABLE'),
      readField('HEATING_TEMPERATURE'),
      readField('HEATING_SPEED'),
      readField('HEATING_DIRECTION'),
      readField('BATH_ENABLE'),
      readField('BATH_HEATING_TIME'),
      readField('BATH_TEMPERATURE'),
      readField('BATH_SPEED'),
      readField('BATH_DIRECTION'),
      ventilationB,
      readField('VENTILATION_SPEED'),
      readField('VENTILATION_DIRECTION'),
      readField('DRYING_ENABLE'),
      readField('DRYING_TIME'),
      readField('DRYING_TEMPERATURE'),
      readField('DRYING_SPEED'),
      readField('DRYING_DIRECTION'),
      blow,
      fanSpeedB,
      direction,
      readField('DELAY_ENABLE'),
      readField('DELAY_TIME'),
      readField('SOFT_WIND_ENABLE'),
      readField('SOFT_WIND_TIME'),
      readField('SOFT_WIND_TEMPERATURE'),
      readField('SOFT_WIND_SPEED'),
      readField('SOFT_WIND_DIRECTION'),
      readField('WINDLESS_ENABLE'),
      readField('ANION_ENABLE'),
      smellySensorB,
      readField('SMELLY_THRESHOLD'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageX40Body
// ---------------------------------------------------------------------------

class MessageX40Body extends MessageBody {
  MessageX40Body(Uint8List body) : super(body) {
    light = body.length > 1 && body[1] > 0;
    fields['MAIN_LIGHT_BRIGHTNESS'] = MessageBody.readByte(body, 2);
    fields['NIGHT_LIGHT_ENABLE'] = MessageBody.readByte(body, 3);
    fields['NIGHT_LIGHT_BRIGHTNESS'] = MessageBody.readByte(body, 4);
    fields['RADAR_INDUCTION_ENABLE'] = MessageBody.readByte(body, 5);
    fields['RADAR_INDUCTION_CLOSING_TIME'] = MessageBody.readByte(body, 6);
    fields['LIGHT_INTENSITY_THRESHOLD'] = MessageBody.readByte(body, 7);
    fields['RADAR_SENSITIVITY'] = MessageBody.readByte(body, 8);
    fields['HEATING_ENABLE'] = MessageBody.readByte(body, 9);
    fields['HEATING_TEMPERATURE'] = MessageBody.readByte(body, 10);
    fields['HEATING_SPEED'] = MessageBody.readByte(body, 11);
    fields['HEATING_DIRECTION'] = MessageBody.readByte(body, 12);
    fields['BATH_ENABLE'] = MessageBody.readByte(body, 13);
    fields['BATH_HEATING_TIME'] = MessageBody.readByte(body, 14);
    fields['BATH_TEMPERATURE'] = MessageBody.readByte(body, 15);
    fields['BATH_SPEED'] = MessageBody.readByte(body, 16);
    fields['BATH_DIRECTION'] = MessageBody.readByte(body, 17);
    ventilation = MessageBody.readByte(body, 18) > 0;
    fields['VENTILATION_SPEED'] = MessageBody.readByte(body, 19);
    fields['VENTILATION_DIRECTION'] = MessageBody.readByte(body, 20);
    fields['DRYING_ENABLE'] = MessageBody.readByte(body, 21);
    fields['DRYING_TIME'] = MessageBody.readByte(body, 22);
    fields['DRYING_TEMPERATURE'] = MessageBody.readByte(body, 23);
    fields['DRYING_SPEED'] = MessageBody.readByte(body, 24);
    fields['DRYING_DIRECTION'] = MessageBody.readByte(body, 25);
    final blow = MessageBody.readByte(body, 26) > 0;
    final blowSpeed = MessageBody.readByte(body, 27);
    direction = MessageBody.readByte(body, 28);
    fields['DELAY_ENABLE'] = MessageBody.readByte(body, 29);
    fields['DELAY_TIME'] = MessageBody.readByte(body, 30);
    currentTemperature = MessageBody.readByte(body, 33);
    fields['SOFT_WIND_ENABLE'] = MessageBody.readByte(body, 38);
    fields['SOFT_WIND_TIME'] = MessageBody.readByte(body, 39);
    fields['SOFT_WIND_TEMPERATURE'] = MessageBody.readByte(body, 40);
    fields['SOFT_WIND_SPEED'] = MessageBody.readByte(body, 41);
    fields['SOFT_WIND_DIRECTION'] = MessageBody.readByte(body, 42);
    fields['WINDLESS_ENABLE'] = MessageBody.readByte(body, 43);
    fields['ANION_ENABLE'] = MessageBody.readByte(body, 44);
    smellySensor = MessageBody.readByte(body, 45);
    fields['SMELLY_THRESHOLD'] = MessageBody.readByte(body, 46);

    if (blow) {
      fanSpeed = blowSpeed <= maxBlowSpeedLowFanSpeed ? 1 : 2;
    } else {
      fanSpeed = 0;
    }
  }

  Map<String, int> fields = {};
  late bool light;
  late bool ventilation;
  late int direction;
  late int currentTemperature;
  late int fanSpeed;
  late int smellySensor;
}

// ---------------------------------------------------------------------------
// MessageX40Response
// ---------------------------------------------------------------------------

class MessageX40Response extends MessageResponse {
  MessageX40Response(Uint8List message) : super(message) {
    if (messageType == MessageType.set ||
        messageType == MessageType.notify1 ||
        messageType == MessageType.query) {
      if (bodyType == 0x01) {
        final x40Body = MessageX40Body(body);
        setBody(x40Body);
        _assignAttrs(x40Body);
      }
    }
    fields = {};
    setAttr();
  }

  Map<String, int> fields = {};
  bool light = false;
  late bool ventilation;
  late int direction;
  late int currentTemperature;
  late int fanSpeed;
  late int smellySensor;

  void _assignAttrs(MessageX40Body b) {
    fields = b.fields;
    light = b.light;
    ventilation = b.ventilation;
    direction = b.direction;
    currentTemperature = b.currentTemperature;
    fanSpeed = b.fanSpeed;
    smellySensor = b.smellySensor;
  }

  @override
  void setAttr() {}
}
