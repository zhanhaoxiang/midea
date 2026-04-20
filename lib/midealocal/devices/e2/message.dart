/// Midea local E2 device message. Mirrors midealocal/devices/e2/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int heatingPowerByte = 34;
const int protectionByte = 22;
const int waterConsumptionByte = 25;

abstract class MessageE2Base extends MessageRequest {
  MessageE2Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.e2,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageE2Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x01]);
  }
}

class MessagePower extends MessageE2Base {
  MessagePower(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x02,
      );

  bool power = false;

  @override
  int get bodyType {
    return power ? ListTypes.x01 : ListTypes.x02;
  }

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x01]);
  }
}

class MessageNewProtocolSet extends MessageE2Base {
  MessageNewProtocolSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x14,
      );

  double? targetTemperature;
  bool? variableHeating;
  bool? sterilization;
  bool? wholeTankHeating;
  bool? protect;
  bool? sleep;
  bool? bigWater;
  bool? autoOff;
  bool? safe;
  bool? screenOff;
  double? washTemperature;
  bool? alwaysFell;
  bool? smartSterilize;
  bool? uvSterilize;

  @override
  Uint8List buildBody() {
    var byte12 = 0x00;
    var byte13 = 0x00;
    if (targetTemperature != null) {
      byte12 = 0x07;
      byte13 = targetTemperature!.toInt() & 0xFF;
    } else if (wholeTankHeating != null) {
      byte12 = 0x04;
      byte13 = wholeTankHeating! ? 0x02 : 0x01;
    } else if (variableHeating != null) {
      byte12 = 0x10;
      byte13 = variableHeating! ? 0x01 : 0x00;
    } else if (sterilization != null) {
      byte12 = 0x0D;
      byte13 = sterilization! ? 0x01 : 0x00;
    } else if (protect != null) {
      byte12 = 0x05;
      byte13 = protect! ? 0x01 : 0x00;
    } else if (sleep != null) {
      byte12 = 0x0E;
      byte13 = sleep! ? 0x01 : 0x00;
    } else if (bigWater != null) {
      byte12 = 0x11;
      byte13 = bigWater! ? 0x01 : 0x00;
    } else if (autoOff != null) {
      byte12 = 0x14;
      byte13 = autoOff! ? 0x01 : 0x00;
    } else if (safe != null) {
      byte12 = 0x06;
      byte13 = safe! ? 0x01 : 0x00;
    } else if (screenOff != null) {
      byte12 = 0x0F;
      byte13 = screenOff! ? 0x01 : 0x00;
    } else if (washTemperature != null) {
      byte12 = 0x16;
      byte13 = washTemperature!.toInt() & 0xFF;
    } else if (smartSterilize != null) {
      byte12 = 0x1B;
      byte13 = smartSterilize! ? 0x01 : 0x00;
    } else if (uvSterilize != null) {
      byte12 = 0x1D;
      byte13 = uvSterilize! ? 0x01 : 0x00;
    }
    return Uint8List.fromList([byte12, byte13]);
  }
}

class MessageSet extends MessageE2Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x04,
      );

  double targetTemperature = 0.0;
  bool variableHeating = false;
  bool wholeTankHeating = false;
  bool protection = false;

  @override
  Uint8List buildBody() {
    final protectionValue = protection ? 0x04 : 0x00;
    final wholeTankHeatingValue = wholeTankHeating ? 0x02 : 0x01;
    final targetTemperatureValue = targetTemperature.toInt() & 0xFF;
    final variableHeatingValue = variableHeating ? 0x10 : 0x00;
    return Uint8List.fromList([
      0x01,
      0x00,
      0x80,
      wholeTankHeatingValue | protectionValue,
      targetTemperatureValue,
      0x00,
      0x00,
      0x00,
      variableHeatingValue,
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

class E2GeneralMessageBody {
  E2GeneralMessageBody(List<int> body) {
    power = (body[2] & 0x01) > 0;
    fastHotPower = (body[2] & 0x02) > 0;
    heating = (body[2] & 0x04) > 0;
    keepWarm = (body[2] & 0x08) > 0;
    waterFlow = (body[2] & 0x10) > 0;
    sterilization = (body[2] & 0x40) > 0;
    variableHeating = (body[2] & 0x80) > 0;
    currentTemperature = body[4].toDouble();
    heatWaterLevel = body[5];
    eplus = (body[7] & 0x01) > 0;
    fastWash = (body[7] & 0x02) > 0;
    halfHeat = (body[7] & 0x04) > 0;
    wholeTankHeating = (body[7] & 0x08) > 0;
    summer = (body[7] & 0x10) > 0;
    winter = (body[7] & 0x20) > 0;
    efficient = (body[7] & 0x40) > 0;
    night = (body[7] & 0x80) > 0;
    screenOff = (body[8] & 0x08) > 0;
    sleep = (body[8] & 0x10) > 0;
    cloud = (body[8] & 0x20) > 0;
    appointWash = (body[8] & 0x40) > 0;
    nowWash = (body[8] & 0x80) > 0;
    heatingTimeRemaining = body[9] * 60 + body[10];
    targetTemperature = body[11].toDouble();
    smartSterilize = (body[12] & 0x20) > 0;
    sterilizeHighTemp = (body[12] & 0x40) > 0;
    uvSterilize = (body[12] & 0x80) > 0;
    dischargeStatus = body[13];
    topTemp = body[14];
    bottomHeat = (body[15] & 0x01) > 0;
    topHeat = (body[15] & 0x02) > 0;
    waterCyclic = (body[15] & 0x80) > 0;
    waterSystem = body[16];
    if (body.length > protectionByte) {
      inTemperature = body[18].toDouble();
      protection = ((body[22] & 0x02) > 0);
    }
    if (body.length > waterConsumptionByte) {
      dayWaterConsumption = body[20] + (body[21] << 8);
    }
    if (body.length > waterConsumptionByte) {
      waterConsumption = body[24] + (body[25] << 8);
    }
    if (body.length > heatingPowerByte) {
      volume = body[27];
    }
    if (body.length > heatingPowerByte) {
      rate = body[28] * 100;
    }
    if (body.length > heatingPowerByte) {
      heatingPower = body[34] * 100;
    }
  }

  late bool power;
  late bool fastHotPower;
  late bool heating;
  late bool keepWarm;
  late bool waterFlow;
  late bool sterilization;
  late bool variableHeating;
  late double currentTemperature;
  late int heatWaterLevel;
  late bool eplus;
  late bool fastWash;
  late bool halfHeat;
  late bool wholeTankHeating;
  late bool summer;
  late bool winter;
  late bool efficient;
  late bool night;
  late bool screenOff;
  late bool sleep;
  late bool cloud;
  late bool appointWash;
  late bool nowWash;
  late int heatingTimeRemaining;
  late double targetTemperature;
  late bool smartSterilize;
  late bool sterilizeHighTemp;
  late bool uvSterilize;
  late int dischargeStatus;
  late int topTemp;
  late bool bottomHeat;
  late bool topHeat;
  late bool waterCyclic;
  late int waterSystem;
  late double? inTemperature;
  late bool protection;
  late int? dayWaterConsumption;
  late int? waterConsumption;
  late int? volume;
  late int? rate;
  late double? heatingPower;
}

class MessageE2Response {
  MessageE2Response(Uint8List message) {
    _header = Uint8List.fromList(message.sublist(0, 10));
    protocolVersion = _header[8];
    messageType = MessageType.fromInt(_header[9]) ?? MessageType.defaultType;
    deviceType = DeviceType.fromInt(_header[2]) ?? DeviceType.x00;
    final bodyData = Uint8List.fromList(
      message.sublist(10, message.length - 1),
    );
    this.bodyType = bodyData.isNotEmpty ? bodyData[0] : 0;
    bodyList = bodyData.sublist(1);

    if ((messageType == MessageType.query ||
                messageType == MessageType.notify1) &&
            this.bodyType == 0x01 ||
        messageType == MessageType.set &&
            (this.bodyType == 0x01 ||
                this.bodyType == 0x02 ||
                this.bodyType == 0x04 ||
                this.bodyType == 0x14)) {
      bodyData2 = E2GeneralMessageBody(bodyList);
      final bd = bodyData2!;
      _attributes['power'] = bd.power;
      _attributes['fast_hot_power'] = bd.fastHotPower;
      _attributes['heating'] = bd.heating;
      _attributes['keep_warm'] = bd.keepWarm;
      _attributes['water_flow'] = bd.waterFlow;
      _attributes['sterilization'] = bd.sterilization;
      _attributes['variable_heating'] = bd.variableHeating;
      _attributes['current_temperature'] = bd.currentTemperature;
      _attributes['heat_water_level'] = bd.heatWaterLevel;
      _attributes['eplus'] = bd.eplus;
      _attributes['fast_wash'] = bd.fastWash;
      _attributes['half_heat'] = bd.halfHeat;
      _attributes['whole_tank_heating'] = bd.wholeTankHeating;
      _attributes['summer'] = bd.summer;
      _attributes['winter'] = bd.winter;
      _attributes['efficient'] = bd.efficient;
      _attributes['night'] = bd.night;
      _attributes['screen_off'] = bd.screenOff;
      _attributes['sleep'] = bd.sleep;
      _attributes['cloud'] = bd.cloud;
      _attributes['appoint_wash'] = bd.appointWash;
      _attributes['now_wash'] = bd.nowWash;
      _attributes['heating_time_remaining'] = bd.heatingTimeRemaining;
      _attributes['target_temperature'] = bd.targetTemperature;
      _attributes['smart_sterilize'] = bd.smartSterilize;
      _attributes['sterilize_high_temp'] = bd.sterilizeHighTemp;
      _attributes['uv_sterilize'] = bd.uvSterilize;
      _attributes['discharge_status'] = bd.dischargeStatus;
      _attributes['top_temp'] = bd.topTemp;
      _attributes['bottom_heat'] = bd.bottomHeat;
      _attributes['top_heat'] = bd.topHeat;
      _attributes['water_cyclic'] = bd.waterCyclic;
      _attributes['water_system'] = bd.waterSystem;
      if (bd.inTemperature != null) {
        _attributes['in_temperature'] = bd.inTemperature;
      }
      _attributes['protection'] = bd.protection;
      if (bd.dayWaterConsumption != null) {
        _attributes['day_water_consumption'] = bd.dayWaterConsumption;
      }
      if (bd.waterConsumption != null) {
        _attributes['water_consumption'] = bd.waterConsumption;
      }
      if (bd.volume != null) {
        _attributes['volume'] = bd.volume;
      }
      if (bd.rate != null) {
        _attributes['rate'] = bd.rate;
      }
      if (bd.heatingPower != null) {
        _attributes['heating_power'] = bd.heatingPower;
      }
    }
  }

  late Uint8List _header;
  late int protocolVersion;
  late MessageType messageType;
  late DeviceType deviceType;
  late int bodyType;
  late List<int> bodyList;
  final Map<String, dynamic> _attributes = {};
  E2GeneralMessageBody? bodyData2;

  bool hasAttribute(String attr) => _attributes.containsKey(attr);

  dynamic getAttribute(String attr) => _attributes[attr];
}
