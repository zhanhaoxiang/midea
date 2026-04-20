/// Midea local CC message. Mirrors midealocal/devices/cc/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

enum CCHeatStatus {
  x10(1),
  x20(2);

  const CCHeatStatus(this.value);
  final int value;
}

abstract class MessageCCBase extends MessageRequest {
  MessageCCBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.cc,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageCCBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList(List.filled(23, 0));
  }
}

class MessageSet extends MessageCCBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.c3,
      );

  bool power = false;
  int mode = 4;
  int fanSpeed = 0x80;
  double targetTemperature = 26.0;
  bool ecoMode = false;
  bool sleepMode = false;
  bool nightLight = false;
  bool ventilation = false;
  int auxHeatStatus = 0;
  bool autoAuxHeatRunning = false;
  bool swing = false;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x80 : 0;
    final modeB = 1 << (mode - 1);
    final fanSpeedB = fanSpeed;
    final temperatureInteger = targetTemperature.toInt() & 0xFF;
    final ecoModeB = ecoMode ? 0x01 : 0;
    int auxHeating;
    if (auxHeatStatus == CCHeatStatus.x10.value) {
      auxHeating = 0x10;
    } else if (auxHeatStatus == CCHeatStatus.x20.value) {
      auxHeating = 0x20;
    } else {
      auxHeating = 0;
    }
    final swingB = swing ? 0x04 : 0;
    final ventilationB = ventilation ? 0x08 : 0;
    final sleepModeB = sleepMode ? 0x10 : 0;
    final nightLightB = nightLight ? 0x08 : 0;
    final temperatureDot =
        ((targetTemperature - temperatureInteger) * 10).toInt() & 0xFF;

    return Uint8List.fromList([
      powerB | modeB,
      fanSpeedB,
      temperatureInteger,
      0x00,
      0x00,
      ecoModeB | ventilationB | swingB | auxHeating,
      0xFF,
      sleepModeB | nightLightB,
      0x00,
      0x00,
      temperatureDot,
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

class CCGeneralMessageBody extends MessageBody {
  CCGeneralMessageBody(super.data);

  bool power = false;
  int mode = 0;
  int fanSpeed = 0;
  double targetTemperature = 0;
  double indoorTemperature = 0;
  bool ecoMode = false;
  bool sleepMode = false;
  bool nightLight = false;
  bool ventilation = false;
  int auxHeatStatus = 0;
  bool autoAuxHeatRunning = false;
  bool fanSpeedLevel = false;
  double temperaturePrecision = 1;
  bool swing = false;
  bool tempFahrenheit = false;

  void parse(int bodyLength) {
    final body = data;
    if (bodyLength < 20) return;
    power = (body[1] & 0x80) > 0;
    double tempMode = (body[1] & 0x1F).toDouble();
    mode = 0;
    while (tempMode >= 1) {
      tempMode = tempMode / 2;
      mode++;
    }
    fanSpeed = body[2];
    targetTemperature = body[3] + body[19] / 10;
    indoorTemperature = (body[4] - 40) / 2;
    ecoMode = (body[13] & 0x01) > 0;
    sleepMode = (body[14] & 0x10) > 0;
    nightLight = (body[14] & 0x08) > 0;
    ventilation = (body[13] & 0x08) > 0;
    auxHeatStatus = (body[14] & 0x60) >> 5;
    autoAuxHeatRunning = (body[13] & 0x02) > 0;
    fanSpeedLevel = (body[13] & 0x40) > 0;
    temperaturePrecision = (body[14] & 0x80) > 0 ? 1 : 0.5;
    swing = (body[13] & 0x04) > 0;
    tempFahrenheit = (body[20] & 0x80) > 0;
  }
}

class MessageCCResponse extends MessageResponse {
  MessageCCResponse(Uint8List message) : super(message) {
    if (_checkMessageType()) {
      final body = CCGeneralMessageBody(super.body);
      _ccBody = body;
      body.parse(super.body.length);
    }
  }

  late CCGeneralMessageBody _ccBody;

  bool _checkMessageType() {
    final isQuery =
        messageType == MessageType.query && bodyType == ListTypes.x01;
    final isNotify =
        (messageType == MessageType.notify1 ||
            messageType == MessageType.notify2) &&
        bodyType == ListTypes.x01;
    final isSet = messageType == MessageType.set && bodyType == ListTypes.c3;
    return isQuery || isNotify || isSet;
  }

  bool get power => _ccBody.power;
  int get mode => _ccBody.mode;
  int get fanSpeed => _ccBody.fanSpeed;
  double get targetTemperature => _ccBody.targetTemperature;
  double get indoorTemperature => _ccBody.indoorTemperature;
  bool get ecoMode => _ccBody.ecoMode;
  bool get sleepMode => _ccBody.sleepMode;
  bool get nightLight => _ccBody.nightLight;
  bool get ventilation => _ccBody.ventilation;
  int get auxHeatStatus => _ccBody.auxHeatStatus;
  bool get autoAuxHeatRunning => _ccBody.autoAuxHeatRunning;
  bool get fanSpeedLevel => _ccBody.fanSpeedLevel;
  double get temperaturePrecision => _ccBody.temperaturePrecision;
  bool get swing => _ccBody.swing;
  bool get tempFahrenheit => _ccBody.tempFahrenheit;
}
