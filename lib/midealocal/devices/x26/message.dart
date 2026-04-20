/// Midea local X26 device message. Mirrors midealocal/devices/x26/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxHeatLowTemp = 50;

const int maxByteValue = 255;

enum DeviceMode {
  off(0),
  heatHigh(1),
  heatLow(2),
  bath(3),
  blow(4),
  ventilation(5),
  dry(6);

  const DeviceMode(this.value);
  final int value;
}

abstract class Message26Base extends MessageRequest {
  Message26Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.x26,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends Message26Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageSet extends Message26Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x01,
      ) {
    fields = {};
    mainLight = false;
    nightLight = false;
    mode = 0;
    direction = 0xFD;
  }

  Map<String, int> fields = {};
  bool mainLight = false;
  bool nightLight = false;
  int mode = 0;
  int direction = 0xFD;

  int readField(String field) {
    final value = fields[field] ?? 0;
    return value != 0 ? value : 0;
  }

  @override
  Uint8List buildBody() {
    final heatMode =
        mode == DeviceMode.heatLow.value || mode == DeviceMode.heatHigh.value;
    final heatEnabled = heatMode ? 1 : 0;
    int heatTemp;
    if (!heatMode) {
      heatTemp = 0;
    } else if (mode == DeviceMode.heatHigh.value) {
      heatTemp = 55;
    } else {
      heatTemp = 30;
    }

    return Uint8List.fromList([
      mainLight ? 1 : 0,
      readField('MAIN_LIGHT_BRIGHTNESS'),
      nightLight ? 1 : 0,
      readField('NIGHT_LIGHT_BRIGHTNESS'),
      readField('RADAR_INDUCTION_ENABLE'),
      readField('RADAR_INDUCTION_CLOSING_TIME'),
      readField('LIGHT_INTENSITY_THRESHOLD'),
      readField('RADAR_SENSITIVITY'),
      heatEnabled,
      heatTemp,
      readField('HEATING_SPEED'),
      direction,
      mode == DeviceMode.bath.value ? 1 : 0,
      readField('BATH_HEATING_TIME'),
      readField('BATH_TEMPERATURE'),
      readField('BATH_SPEED'),
      direction,
      mode == DeviceMode.ventilation.value ? 1 : 0,
      readField('VENTILATION_SPEED'),
      direction,
      mode == DeviceMode.dry.value ? 1 : 0,
      readField('DRYING_TIME'),
      readField('DRYING_TEMPERATURE'),
      readField('DRYING_SPEED'),
      direction,
      mode == DeviceMode.blow.value ? 1 : 0,
      readField('BLOWING_SPEED'),
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
      readField('SMELLY_ENABLE'),
      readField('SMELLY_THRESHOLD'),
    ]);
  }
}

class Message26Body extends MessageBody {
  Message26Body(Uint8List body) : super(body) {
    fields = _genFields(body);
    mainLight = MessageBody.readByte(body, 1) > 0;
    nightLight = MessageBody.readByte(body, 3) > 0;
    final heatMode = MessageBody.readByte(body, 9) > 0;
    final heatTemp = MessageBody.readByte(body, 10);
    final heatDir = MessageBody.readByte(body, 12);
    final bathMode = MessageBody.readByte(body, 13) > 0;
    final bathDir = MessageBody.readByte(body, 17);
    final ventMode = MessageBody.readByte(body, 18) > 0;
    final ventDir = MessageBody.readByte(body, 20);
    final dryMode = MessageBody.readByte(body, 21) > 0;
    final dryDir = MessageBody.readByte(body, 25);
    final blowMode = MessageBody.readByte(body, 26) > 0;
    final blowDir = MessageBody.readByte(body, 28);

    final humidityByte = MessageBody.readByte(body, 31);
    currentHumidity = humidityByte != maxByteValue ? humidityByte : null;
    final radarByte = MessageBody.readByte(body, 32);
    currentRadar = radarByte != maxByteValue ? radarByte : null;
    final tempByte = MessageBody.readByte(body, 33);
    currentTemperature = tempByte != maxByteValue ? tempByte : null;

    mode = 0;
    direction = 0xFD;
    if (heatMode) {
      mode = heatTemp > maxHeatLowTemp ? 1 : 2;
      direction = heatDir;
    } else if (bathMode) {
      mode = 3;
      direction = bathDir;
    } else if (blowMode) {
      mode = 4;
      direction = blowDir;
    } else if (ventMode) {
      mode = 5;
      direction = ventDir;
    } else if (dryMode) {
      mode = 6;
      direction = dryDir;
    }
  }

  late Map<String, int> fields;
  late bool mainLight;
  late bool nightLight;
  int? currentHumidity;
  int? currentRadar;
  int? currentTemperature;
  int mode = 0;
  int direction = 0xFD;

  Map<String, int> _genFields(Uint8List body) {
    return {
      'MAIN_LIGHT_BRIGHTNESS': MessageBody.readByte(body, 2),
      'NIGHT_LIGHT_BRIGHTNESS': MessageBody.readByte(body, 4),
      'RADAR_INDUCTION_ENABLE': MessageBody.readByte(body, 5),
      'RADAR_INDUCTION_CLOSING_TIME': MessageBody.readByte(body, 6),
      'LIGHT_INTENSITY_THRESHOLD': MessageBody.readByte(body, 7),
      'RADAR_SENSITIVITY': MessageBody.readByte(body, 8),
      'HEATING_SPEED': MessageBody.readByte(body, 11),
      'BATH_HEATING_TIME': MessageBody.readByte(body, 14),
      'BATH_TEMPERATURE': MessageBody.readByte(body, 15),
      'BATH_SPEED': MessageBody.readByte(body, 16),
      'VENTILATION_SPEED': MessageBody.readByte(body, 19),
      'DRYING_TIME': MessageBody.readByte(body, 22),
      'DRYING_TEMPERATURE': MessageBody.readByte(body, 23),
      'DRYING_SPEED': MessageBody.readByte(body, 24),
      'BLOWING_SPEED': MessageBody.readByte(body, 27),
      'DELAY_ENABLE': MessageBody.readByte(body, 29),
      'DELAY_TIME': MessageBody.readByte(body, 30),
      'SOFT_WIND_ENABLE': MessageBody.readByte(body, 38),
      'SOFT_WIND_TIME': MessageBody.readByte(body, 39),
      'SOFT_WIND_TEMPERATURE': MessageBody.readByte(body, 40),
      'SOFT_WIND_SPEED': MessageBody.readByte(body, 41),
      'SOFT_WIND_DIRECTION': MessageBody.readByte(body, 42),
      'WINDLESS_ENABLE': MessageBody.readByte(body, 43),
      'ANION_ENABLE': MessageBody.readByte(body, 44),
      'SMELLY_ENABLE': MessageBody.readByte(body, 45),
      'SMELLY_THRESHOLD': MessageBody.readByte(body, 46),
    };
  }
}

class Message26Response extends MessageResponse {
  Message26Response(Uint8List message) : super(message) {
    if (messageType == MessageType.set ||
        messageType == MessageType.notify1 ||
        messageType == MessageType.query) {
      if (bodyType == ListTypes.x01) {
        final msgBody = Message26Body(body);
        setBody(msgBody);
        _assignAttrs(msgBody);
      }
    }
  }

  late Map<String, int> fields;
  bool? mainLight;
  bool? nightLight;
  int? mode;
  int? direction;
  int? currentHumidity;
  int? currentRadar;
  int? currentTemperature;

  void _assignAttrs(Message26Body b) {
    fields = b.fields;
    mainLight = b.mainLight;
    nightLight = b.nightLight;
    mode = b.mode;
    direction = b.direction;
    currentHumidity = b.currentHumidity;
    currentRadar = b.currentRadar;
    currentTemperature = b.currentTemperature;
  }
}
