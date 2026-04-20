/// Midea local C3 device message. Mirrors midealocal/devices/c3/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// C3ListTypes
// ---------------------------------------------------------------------------

class C3ListTypes {
  static const int x01 = 0x01;
  static const int x05 = 0x05;
  static const int x07 = 0x07;
  static const int x09 = 0x09;
  static const int x10 = 0x10;
}

// ---------------------------------------------------------------------------
// C3SilentLevel
// ---------------------------------------------------------------------------

enum C3SilentLevel {
  off(0x0),
  silent(0x1),
  superSilent(0x3);

  const C3SilentLevel(this.value);
  final int value;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int tempNegValue = 127;

// ---------------------------------------------------------------------------
// MessageC3Base
// ---------------------------------------------------------------------------

abstract class MessageC3Base extends MessageRequest {
  MessageC3Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.c3,
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

class MessageQuery extends MessageC3Base {
  MessageQuery(int protocolVersion, int bodyType)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: bodyType,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageQueryBasic
// ---------------------------------------------------------------------------

class MessageQueryBasic extends MessageQuery {
  MessageQueryBasic(int protocolVersion)
    : super(protocolVersion, C3ListTypes.x01);
}

// ---------------------------------------------------------------------------
// MessageQuerySilence
// ---------------------------------------------------------------------------

class MessageQuerySilence extends MessageQuery {
  MessageQuerySilence(int protocolVersion)
    : super(protocolVersion, C3ListTypes.x05);
}

// ---------------------------------------------------------------------------
// MessageQueryECO
// ---------------------------------------------------------------------------

class MessageQueryECO extends MessageQuery {
  MessageQueryECO(int protocolVersion)
    : super(protocolVersion, C3ListTypes.x07);
}

// ---------------------------------------------------------------------------
// MessageQueryDisinfect
// ---------------------------------------------------------------------------

class MessageQueryDisinfect extends MessageQuery {
  MessageQueryDisinfect(int protocolVersion)
    : super(protocolVersion, C3ListTypes.x09);
}

// ---------------------------------------------------------------------------
// MessageQueryUnitPara
// ---------------------------------------------------------------------------

class MessageQueryUnitPara extends MessageQuery {
  MessageQueryUnitPara(int protocolVersion)
    : super(protocolVersion, C3ListTypes.x10);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageC3Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: C3ListTypes.x01,
      );

  bool zone1Power = false;
  bool zone2Power = false;
  bool dhwPower = false;
  int mode = 0;
  List<double> zoneTargetTemp = [25.0, 25.0];
  double dhwTargetTemp = 40.0;
  double roomTargetTemp = 25.0;
  bool zone1Curve = false;
  bool zone2Curve = false;
  bool fastDhw = false;
  bool tbh = false;

  @override
  Uint8List buildBody() {
    final zone1PowerVal = zone1Power ? 0x01 : 0x00;
    final zone2PowerVal = zone2Power ? 0x02 : 0x00;
    final dhwPowerVal = dhwPower ? 0x04 : 0x00;
    final zone1CurveVal = zone1Curve ? 0x01 : 0x00;
    final zone2CurveVal = zone2Curve ? 0x02 : 0x00;
    final tbhVal = tbh ? 0x04 : 0x00;
    final fastDhwVal = fastDhw ? 0x08 : 0x00;
    final roomTargetTempVal = (roomTargetTemp * 2).toInt();
    final zone1TargetTempVal = zoneTargetTemp[0].toInt();
    final zone2TargetTempVal = zoneTargetTemp[1].toInt();
    final dhwTargetTempVal = dhwTargetTemp.toInt();
    return Uint8List.fromList([
      zone1PowerVal | zone2PowerVal | dhwPowerVal,
      mode,
      zone1TargetTempVal,
      zone2TargetTempVal,
      dhwTargetTempVal,
      roomTargetTempVal,
      zone1CurveVal | zone2CurveVal | tbhVal | fastDhwVal,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageSetSilent
// ---------------------------------------------------------------------------

class MessageSetSilent extends MessageC3Base {
  MessageSetSilent(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: C3ListTypes.x05,
      );

  bool silentMode = false;
  C3SilentLevel silentLevel = C3SilentLevel.off;

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      silentMode ? silentLevel.value : C3SilentLevel.off.value,
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
// MessageSetECO
// ---------------------------------------------------------------------------

class MessageSetECO extends MessageC3Base {
  MessageSetECO(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: C3ListTypes.x07,
      );

  bool ecoMode = false;

  @override
  Uint8List buildBody() {
    final ecoModeVal = ecoMode ? 0x01 : 0x00;
    return Uint8List.fromList([ecoModeVal, 0x00, 0x00, 0x00, 0x00, 0x00]);
  }
}

// ---------------------------------------------------------------------------
// MessageSetDisinfect
// ---------------------------------------------------------------------------

class MessageSetDisinfect extends MessageC3Base {
  MessageSetDisinfect(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: C3ListTypes.x09,
      );

  bool disinfect = false;

  @override
  Uint8List buildBody() {
    final disinfectVal = disinfect ? 0x01 : 0x00;
    return Uint8List.fromList([disinfectVal, 0x00, 0x00, 0x00]);
  }
}

// ---------------------------------------------------------------------------
// C3BasicBody
// ---------------------------------------------------------------------------

class C3BasicBody extends MessageBody {
  C3BasicBody(Uint8List body) : super(body) {
    zone1Power = body[0] & 0x01 > 0;
    zone2Power = body[0] & 0x02 > 0;
    dhwPower = body[0] & 0x04 > 0;
    zone1Curve = body[0] & 0x08 > 0;
    zone2Curve = body[0] & 0x10 > 0;
    tbh = body[0] & 0x20 > 0;
    fastDhw = body[0] & 0x40 > 0;
    remoteOnOff = body[0] & 0x80 > 0;
    heat = body[1] & 0x01 > 0;
    cool = body[1] & 0x02 > 0;
    dhw = body[1] & 0x04 > 0;
    doubleZone = body[1] & 0x08 > 0;
    zoneTempType = [body[1] & 0x10 > 0, body[1] & 0x20 > 0];
    roomThermalSupport = body[1] & 0x40 > 0;
    roomThermalState = body[1] & 0x80 > 0;
    timeSet = body[2] & 0x01 > 0;
    silentMode = body[2] & 0x02 > 0;
    holidayOn = body[2] & 0x04 > 0;
    ecoMode = body[2] & 0x08 > 0;
    zoneTerminalType = body[2];
    mode = body[3];
    modeAuto = body[4];
    zoneTargetTemp = [body[5].toDouble(), body[6].toDouble()];
    dhwTargetTemp = body[7].toDouble();
    roomTargetTemp = body[8] / 2;
    zoneHeatingTempMax = [body[9].toDouble(), body[13].toDouble()];
    zoneHeatingTempMin = [body[10].toDouble(), body[14].toDouble()];
    zoneCoolingTempMax = [body[11].toDouble(), body[15].toDouble()];
    zoneCoolingTempMin = [body[12].toDouble(), body[16].toDouble()];
    roomTempMax = body[17] / 2;
    roomTempMin = body[18] / 2;
    dhwTempMax = body[19].toDouble();
    dhwTempMin = body[20].toDouble();
    tankActualTemperature = body[21].toDouble();
    errorCode = body[22];
    tbhControl = body[23] & 0x80 > 0;
    sysEnergyAnaEn = body[23] & 0x20 > 0;
    hmiEnergyAnaSetEn = body[23] & 0x40 > 0;
  }

  late bool zone1Power;
  late bool zone2Power;
  late bool dhwPower;
  late bool zone1Curve;
  late bool zone2Curve;
  late bool tbh;
  late bool fastDhw;
  late bool remoteOnOff;
  late bool heat;
  late bool cool;
  late bool dhw;
  late bool doubleZone;
  late List<bool> zoneTempType;
  late bool roomThermalSupport;
  late bool roomThermalState;
  late bool timeSet;
  late bool silentMode;
  late bool holidayOn;
  late bool ecoMode;
  late int zoneTerminalType;
  late int mode;
  late int modeAuto;
  late List<double> zoneTargetTemp;
  late double dhwTargetTemp;
  late double roomTargetTemp;
  late List<double> zoneHeatingTempMax;
  late List<double> zoneHeatingTempMin;
  late List<double> zoneCoolingTempMax;
  late List<double> zoneCoolingTempMin;
  late double roomTempMax;
  late double roomTempMin;
  late double dhwTempMax;
  late double dhwTempMin;
  late double tankActualTemperature;
  late int errorCode;
  late bool tbhControl;
  late bool sysEnergyAnaEn;
  late bool hmiEnergyAnaSetEn;
}

// ---------------------------------------------------------------------------
// C3EnergyBody
// ---------------------------------------------------------------------------

class C3EnergyBody extends MessageBody {
  C3EnergyBody(Uint8List body) : super(body) {
    final statusByte = body[0];
    statusHeating = (statusByte & 0x01) > 0;
    statusCool = (statusByte & 0x02) > 0;
    statusDhw = (statusByte & 0x04) > 0;
    statusTbh = (statusByte & 0x08) > 0;
    statusIbh = (statusByte & 0x10) > 0;
    totalEnergyConsumption =
        (body[1] << 32) + (body[2] << 16) + (body[3] << 8) + body[4];
    totalProducedEnergy =
        (body[5] << 32) + (body[6] << 16) + (body[7] << 8) + body[8];
    final baseValue = body[9];
    outdoorTemperature = baseValue > tempNegValue
        ? (baseValue - 256).toDouble()
        : baseValue.toDouble();
    zone1TempSet = body[10].toDouble();
    zone2TempSet = body[11].toDouble();
    t5s = body[12];
    tas = body[13];
  }

  late bool statusHeating;
  late bool statusCool;
  late bool statusDhw;
  late bool statusTbh;
  late bool statusIbh;
  late int totalEnergyConsumption;
  late int totalProducedEnergy;
  late double outdoorTemperature;
  late double zone1TempSet;
  late double zone2TempSet;
  late int t5s;
  late int tas;
}

// ---------------------------------------------------------------------------
// C3SilenceBody
// ---------------------------------------------------------------------------

class C3SilenceBody extends MessageBody {
  C3SilenceBody(Uint8List body) : super(body) {
    silentMode = body[0] & 0x1 > 0;
    final silentLevelVal = silentMode
        ? ((body[0] & 0x1) + ((body[0] & 0x8) >> 2))
        : C3SilentLevel.off.value;
    silentLevel = C3SilentLevel.values
        .firstWhere(
          (e) => e.value == silentLevelVal,
          orElse: () => C3SilentLevel.off,
        )
        .name;
  }

  late bool silentMode;
  late String silentLevel;
}

// ---------------------------------------------------------------------------
// C3ECOBody
// ---------------------------------------------------------------------------

class C3ECOBody extends MessageBody {
  C3ECOBody(Uint8List body) : super(body) {
    ecoFunctionState = body[0] & 0x01 > 0;
    ecoTimerState = body[0] & 0x02 > 0;
  }

  late bool ecoFunctionState;
  late bool ecoTimerState;
}

// ---------------------------------------------------------------------------
// C3DisinfectBody
// ---------------------------------------------------------------------------

class C3DisinfectBody extends MessageBody {
  C3DisinfectBody(Uint8List body) : super(body) {
    disinfect = body[0] & 0x01 > 0;
    disinfectRun = body[0] & 0x02 > 0;
    disinfectSetWeekday = body[1];
    disinfectStartHour = body[2];
    disinfectStartMinutes = body[3];
  }

  late bool disinfect;
  late bool disinfectRun;
  late int disinfectSetWeekday;
  late int disinfectStartHour;
  late int disinfectStartMinutes;
}

// ---------------------------------------------------------------------------
// C3UnitParaBody
// ---------------------------------------------------------------------------

class C3UnitParaBody extends MessageBody {
  C3UnitParaBody(Uint8List body) : super(body) {
    compRunFreq = body[0];
    unitModeRun = body[1];
    fanSpeed = body[3] * 10;
    fgCapacityNeed = body[5];
    tempT3 = body[6];
    tempT4 = body[7];
    tempTp = body[8];
    tempTwIn = body[9];
    tempTwOut = body[10];
    tempTsolar = body[11];
    hydboxSubtype = body[12];
    fgUsbInfoConnect = body[13];
    oduVoltage = body[17] * 256 + body[18];
    exvCurrent = body[19] * 256 + body[20];
    oduModel = body[21];
    tempT1 = body[33];
    tempTw2 = body[34];
    tempT2 = body[35];
    tempT2b = body[36];
    tempT5 = body[37];
    tempTa = body[38];
    tempTbT1 = body[39];
    tempTbT2 = body[40];
    hydroboxCapacity = body[41];
    pressureHigh = body[42] * 256 + body[43];
    pressureLow = body[44] * 256 + body[45];
    tempTh = body[46];
    machineType = body[47];
    oduTargetFre = body[48];
    dcCurrent = body[49];
    tempTf = body[51];
    iduT1s1 = body[52];
    iduT1s2 = body[53];
    waterFlower = body[54] * 256 + body[55];
    oduPlanVolLmt = body[56];
    currentUnitCapacity = body[57];
    spheraAhsvoltage = body[59];
    tempT4aVer = body[60];
    waterPressure = body[61] * 256 + body[62];
    roomRelHum = body[63];
    pwmPumpOut = body[63];
    totalElectricity0 =
        (body[66] << 32) + (body[67] << 16) + (body[68] << 8) + body[69];
    totalThermal0 =
        (body[70] << 32) + (body[71] << 16) + (body[72] << 8) + body[73];
    heatElecTotalConsum0 =
        (body[74] << 32) + (body[75] << 16) + (body[76] << 8) + body[77];
    heatElecTotalCapacity0 =
        (body[78] << 32) + (body[79] << 16) + (body[80] << 8) + body[81];
    instantPower0 = (body[82] << 8) + body[83];
    instantRenewPower0 = (body[84] << 8) + body[85];
    totalRenewPower0 = (body[84] << 8) + body[85];
  }

  late int compRunFreq;
  late int unitModeRun;
  late int fanSpeed;
  late int fgCapacityNeed;
  late int tempT3;
  late int tempT4;
  late int tempTp;
  late int tempTwIn;
  late int tempTwOut;
  late int tempTsolar;
  late int hydboxSubtype;
  late int fgUsbInfoConnect;
  late int oduVoltage;
  late int exvCurrent;
  late int oduModel;
  late int tempT1;
  late int tempTw2;
  late int tempT2;
  late int tempT2b;
  late int tempT5;
  late int tempTa;
  late int tempTbT1;
  late int tempTbT2;
  late int hydroboxCapacity;
  late int pressureHigh;
  late int pressureLow;
  late int tempTh;
  late int machineType;
  late int oduTargetFre;
  late int dcCurrent;
  late int tempTf;
  late int iduT1s1;
  late int iduT1s2;
  late int waterFlower;
  late int oduPlanVolLmt;
  late int currentUnitCapacity;
  late int spheraAhsvoltage;
  late int tempT4aVer;
  late int waterPressure;
  late int roomRelHum;
  late int pwmPumpOut;
  late int totalElectricity0;
  late int totalThermal0;
  late int heatElecTotalConsum0;
  late int heatElecTotalCapacity0;
  late int instantPower0;
  late int instantRenewPower0;
  late int totalRenewPower0;
}

// ---------------------------------------------------------------------------
// MessageC3Response
// ---------------------------------------------------------------------------

class MessageC3Response extends MessageResponse {
  MessageC3Response(Uint8List message) : super(message) {
    if ((messageType == MessageType.set ||
                messageType == MessageType.notify1 ||
                messageType == MessageType.query) &&
            bodyType == C3ListTypes.x01 ||
        messageType == MessageType.notify2) {
      final msgBody = C3BasicBody(body.sublist(1));
      _assignBasicAttrs(msgBody);
    } else if (messageType == MessageType.notify1 &&
        bodyType == ListTypes.x04) {
      final msgBody = C3EnergyBody(body.sublist(1));
      _assignEnergyAttrs(msgBody);
    } else if (messageType == MessageType.query &&
        bodyType == C3ListTypes.x05) {
      final msgBody = C3SilenceBody(body.sublist(1));
      _assignSilenceAttrs(msgBody);
    } else if (bodyType == C3ListTypes.x07) {
      final msgBody = C3ECOBody(body.sublist(1));
      _assignEcoAttrs(msgBody);
    } else if (bodyType == C3ListTypes.x09) {
      final msgBody = C3DisinfectBody(body.sublist(1));
      _assignDisinfectAttrs(msgBody);
    } else if (bodyType == C3ListTypes.x10) {
      final msgBody = C3UnitParaBody(body.sublist(1));
      _assignUnitParaAttrs(msgBody);
    }
  }

  bool? zone1Power;
  bool? zone2Power;
  bool? dhwPower;
  bool? zone1Curve;
  bool? zone2Curve;
  bool? tbh;
  bool? fastDhw;
  bool? heat;
  bool? cool;
  bool? dhw;
  bool? doubleZone;
  List<bool?>? zoneTempType;
  bool? roomThermalSupport;
  bool? roomThermalState;
  bool? timeSet;
  bool? silentMode;
  bool? holidayOn;
  bool? ecoMode;
  int? zoneTerminalType;
  int? mode;
  int? modeAuto;
  List<double?>? zoneTargetTemp;
  double? dhwTargetTemp;
  double? roomTargetTemp;
  List<double?>? zoneHeatingTempMax;
  List<double?>? zoneHeatingTempMin;
  List<double?>? zoneCoolingTempMax;
  List<double?>? zoneCoolingTempMin;
  double? roomTempMax;
  double? roomTempMin;
  double? dhwTempMax;
  double? dhwTempMin;
  double? tankActualTemperature;
  int? errorCode;
  bool? tbhControl;
  bool? statusHeating;
  bool? statusCool;
  bool? statusDhw;
  bool? statusTbh;
  bool? statusIbh;
  int? totalEnergyConsumption;
  int? totalProducedEnergy;
  double? outdoorTemperature;
  double? zone1TempSet;
  double? zone2TempSet;
  int? t5s;
  int? tas;
  String? silentLevel;
  bool? disinfect;
  double? tempTwIn;
  double? tempTwOut;
  int? instantPower0;

  void _assignBasicAttrs(C3BasicBody b) {
    zone1Power = b.zone1Power;
    zone2Power = b.zone2Power;
    dhwPower = b.dhwPower;
    zone1Curve = b.zone1Curve;
    zone2Curve = b.zone2Curve;
    tbh = b.tbh;
    fastDhw = b.fastDhw;
    heat = b.heat;
    cool = b.cool;
    dhw = b.dhw;
    doubleZone = b.doubleZone;
    zoneTempType = b.zoneTempType;
    roomThermalSupport = b.roomThermalSupport;
    roomThermalState = b.roomThermalState;
    timeSet = b.timeSet;
    silentMode = b.silentMode;
    holidayOn = b.holidayOn;
    ecoMode = b.ecoMode;
    zoneTerminalType = b.zoneTerminalType;
    mode = b.mode;
    modeAuto = b.modeAuto;
    zoneTargetTemp = b.zoneTargetTemp;
    dhwTargetTemp = b.dhwTargetTemp;
    roomTargetTemp = b.roomTargetTemp;
    zoneHeatingTempMax = b.zoneHeatingTempMax;
    zoneHeatingTempMin = b.zoneHeatingTempMin;
    zoneCoolingTempMax = b.zoneCoolingTempMax;
    zoneCoolingTempMin = b.zoneCoolingTempMin;
    roomTempMax = b.roomTempMax;
    roomTempMin = b.roomTempMin;
    dhwTempMax = b.dhwTempMax;
    dhwTempMin = b.dhwTempMin;
    tankActualTemperature = b.tankActualTemperature;
    errorCode = b.errorCode;
    tbhControl = b.tbhControl;
  }

  void _assignEnergyAttrs(C3EnergyBody b) {
    statusHeating = b.statusHeating;
    statusCool = b.statusCool;
    statusDhw = b.statusDhw;
    statusTbh = b.statusTbh;
    statusIbh = b.statusIbh;
    totalEnergyConsumption = b.totalEnergyConsumption;
    totalProducedEnergy = b.totalProducedEnergy;
    outdoorTemperature = b.outdoorTemperature;
    zone1TempSet = b.zone1TempSet;
    zone2TempSet = b.zone2TempSet;
    t5s = b.t5s;
    tas = b.tas;
  }

  void _assignSilenceAttrs(C3SilenceBody b) {
    silentMode = b.silentMode;
    silentLevel = b.silentLevel;
  }

  void _assignEcoAttrs(C3ECOBody b) {
    ecoMode = b.ecoFunctionState;
  }

  void _assignDisinfectAttrs(C3DisinfectBody b) {
    disinfect = b.disinfect;
  }

  void _assignUnitParaAttrs(C3UnitParaBody b) {
    tempTwIn = b.tempTwIn.toDouble();
    tempTwOut = b.tempTwOut.toDouble();
    instantPower0 = b.instantPower0;
  }
}
