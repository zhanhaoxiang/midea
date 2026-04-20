/// Midea local CA device message. Mirrors midealocal/devices/ca/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int minCaGeneralBodyLength = 20;
const int caGeneralBodyLength1 = 25;
const int caGeneralBodyLength2 = 30;
const int caGeneralBodyLength3 = 31;
const int tempPosLowerValue = 1;
const int tempPosUpperValue = 29;
const int tempNegLowerValue = 49;
const int tempNegUpperValue = 54;

abstract class MessageCABase extends MessageRequest {
  MessageCABase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ca,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageCABase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class CAGeneralMessageBody extends MessageBody {
  CAGeneralMessageBody(Uint8List body) : super(body) {
    codeMode = (body[1] & 0x01) > 0;
    freezingMode = (body[1] & 0x02) > 0;
    smartMode = (body[1] & 0x04) > 0;
    energySavingMode = (body[1] & 0x08) > 0;
    holidayMode = (body[1] & 0x10) > 0;
    moisturizeMode = (body[1] & 0x20) > 0;
    preservationMode = (body[1] & 0x40) > 0;
    acmeFreezingMode = (body[1] & 0x80) > 0;

    refrigeratorSettingTemp = body[2] & 0x0F;
    freezerSettingTemp = -12 - ((body[2] & 0xF0) >> 4);

    final flexZoneTemp = body[3];
    final rightFlexZoneTemp = body[4];

    int flexTempVal;
    if (tempPosLowerValue <= flexZoneTemp &&
        flexZoneTemp <= tempPosUpperValue) {
      flexTempVal = flexZoneTemp - 19;
    } else if (tempNegLowerValue <= flexZoneTemp &&
        flexZoneTemp <= tempNegUpperValue) {
      flexTempVal = 30 - flexZoneTemp;
    } else {
      flexTempVal = 0;
    }
    flexZoneSettingTemp = flexTempVal;

    int rightFlexTempVal;
    if (tempPosLowerValue <= rightFlexZoneTemp &&
        rightFlexZoneTemp <= tempPosUpperValue) {
      rightFlexTempVal = rightFlexZoneTemp - 19;
    } else if (tempNegLowerValue <= rightFlexZoneTemp &&
        rightFlexZoneTemp <= tempNegUpperValue) {
      rightFlexTempVal = 30 - rightFlexZoneTemp;
    } else {
      rightFlexTempVal = 0;
    }
    rightFlexZoneSettingTemp = rightFlexTempVal;

    variableMode = body[5];

    refrigerationPower = (body[6] & 0x01) < 1;
    lVariablePower = (body[6] & 0x04) < 1;
    rVariablePower = (body[6] & 0x08) < 1;
    freezingPower = (body[6] & 0x10) < 1;
    crossPeakElectricityEnter = body[6] & 0x20;
    crossPeakElectricity = (body[6] & 0x40) > 0;
    allRefrigerationPower = (body[6] & 0x80) > 0;

    removeDew = body[7] & 0x01;
    humidify = body[7] & 0x02;
    unfreeze = body[7] & 0x04;
    temperatureUnit = body[7] & 0x08;
    floodLight = body[7] & 0x10;
    functionSwitch = body[7] & 0xC0;

    radarMode = body[8] & 0x01;
    milkMode = body[8] & 0x02;
    icedMode = body[8] & 0x04;
    plasmaAsepticMode = body[8] & 0x08;
    acquireIceaMode = body[8] & 0x10;
    brashIceaMode = body[8] & 0x20;
    acquireWaterMode = body[8] & 0x40;
    freezingIceMachinePower = body[8] & 0x80;

    freezingFahrenheit = body[9];
    refrigerationFahrenheit = body[10] & 0xFC;
    leachExpireDay = body[11];

    energyConsumption = (body[13] << 8) + body[12];

    freezingMotorResetStatus = (body[14] & 0x01) > 0;
    freezingMotorDeicingStatus = (body[14] & 0x02) > 0;
    freezingIceMachineWaterStatus = (body[14] & 0x04) > 0;
    freezingAllIceStatus = (body[14] & 0x08) > 0;
    humanInduction = (body[14] & 0x10) > 0;

    refrigerationDoorPower = body[15] & 0x01;
    freezingDoorPower = body[15] & 0x02;
    variableDoorPower = body[15] & 0x10;
    storageIceHomeDoorState = body[15] & 0x20;
    barDoorPower = body[15] & 0x04;
    iceMouthPower = body[15] & 0x08;

    isError = (body[16] & 0x01) > 0;
    intervalRoomHumidityLevel = body[16] & 0xFE;

    refrigeratorActualTemp = (body[17] - 100) / 2;
    freezerActualTemp = (body[18] - 100) / 2;
    flexZoneActualTemp = (body[19] - 100) / 2;
    rightFlexZoneActualTemp = (body[20] - 100) / 2;

    fastColdMinute = (body[22] << 8) + body[21];
    fastFreezeMinute = (body[24] << 8) + body[23];

    if (body.length > caGeneralBodyLength1) {
      microcrystalFresh = (body[27] & 0x01) > 0;
      dryZone = (body[27] & 0x02) > 0;
      electronicSmell = (body[27] & 0x04) > 0;
      humidity = body[27] & 0x70;
      normalTemperatureLevel = body[28];
      functionZoneLevel = body[29];
    }

    if (body.length > caGeneralBodyLength2) {
      humiditySetting = body[30] & 0x7F;
      smartHumidity = (body[30] & 0x80) > 0;
    }

    if (body.length > caGeneralBodyLength3) {
      storageLeftDoorAuto = body[31] & 0x03;
      storageRightDoorAuto = body[31] & 0x0C;
      freezerDoorAuto = body[31] & 0x30;
      freezerDoorAutoControl = (body[31] & 0x40) > 0;
      storageDoorAutoControl = (body[31] & 0x80) > 0;
    }
  }

  late bool codeMode;
  late bool freezingMode;
  late bool smartMode;
  late bool energySavingMode;
  late bool holidayMode;
  late bool moisturizeMode;
  late bool preservationMode;
  late bool acmeFreezingMode;
  late int refrigeratorSettingTemp;
  late int freezerSettingTemp;
  late int flexZoneSettingTemp;
  late int rightFlexZoneSettingTemp;
  late int variableMode;
  late bool refrigerationPower;
  late bool lVariablePower;
  late bool rVariablePower;
  late bool freezingPower;
  late int crossPeakElectricityEnter;
  late bool crossPeakElectricity;
  late bool allRefrigerationPower;
  late int removeDew;
  late int humidify;
  late int unfreeze;
  late int temperatureUnit;
  late int floodLight;
  late int functionSwitch;
  late int radarMode;
  late int milkMode;
  late int icedMode;
  late int plasmaAsepticMode;
  late int acquireIceaMode;
  late int brashIceaMode;
  late int acquireWaterMode;
  late int freezingIceMachinePower;
  late int freezingFahrenheit;
  late int refrigerationFahrenheit;
  late int leachExpireDay;
  late int energyConsumption;
  late bool freezingMotorResetStatus;
  late bool freezingMotorDeicingStatus;
  late bool freezingIceMachineWaterStatus;
  late bool freezingAllIceStatus;
  late bool humanInduction;
  late int refrigerationDoorPower;
  late int freezingDoorPower;
  late int variableDoorPower;
  late int storageIceHomeDoorState;
  late int barDoorPower;
  late int iceMouthPower;
  late bool isError;
  late int intervalRoomHumidityLevel;
  late double refrigeratorActualTemp;
  late double freezerActualTemp;
  late double flexZoneActualTemp;
  late double rightFlexZoneActualTemp;
  late int fastColdMinute;
  late int fastFreezeMinute;
  bool? microcrystalFresh;
  bool? dryZone;
  bool? electronicSmell;
  int? humidity;
  int? normalTemperatureLevel;
  int? functionZoneLevel;
  int? humiditySetting;
  bool? smartHumidity;
  int? storageLeftDoorAuto;
  int? storageRightDoorAuto;
  int? freezerDoorAuto;
  bool? freezerDoorAutoControl;
  bool? storageDoorAutoControl;
}

class CAExceptionMessageBody extends MessageBody {
  CAExceptionMessageBody(Uint8List body) : super(body) {
    refrigeratorDoorOvertime = (body[1] & 0x01) > 0;
    freezerDoorOvertime = (body[1] & 0x02) > 0;
    barDoorOvertime = (body[1] & 0x04) > 0;
    flexZoneDoorOvertime = (body[1] & 0x08) > 0;

    iceMiachineFull = body[1] & 0x10;
    refrigerationSensorError = body[2] & 0x01;
    refrigerationDeforstingSensorError = body[2] & 0x02;
    ringTemperatureSensorError = body[2] & 0x04;
    flexZoneSensorError = body[2] & 0x08;
    rightFlexZoneSensorError = body[2] & 0x10;
    freezingHighTemperature = body[2] & 0x20;
    freezingSensorError = body[2] & 0x40;
    freezingDefrostingSensorError = body[2] & 0x80;
    iceElectricalMachineryError = body[3] & 0x01;
    refrigerationDefrostingOvertime = body[3] & 0x02;
    freezingDefrostingOvertime = body[3] & 0x04;
    zeroCrossingCheckError = body[3] & 0x08;
  }

  late bool refrigeratorDoorOvertime;
  late bool freezerDoorOvertime;
  late bool barDoorOvertime;
  late bool flexZoneDoorOvertime;
  late int iceMiachineFull;
  late int refrigerationSensorError;
  late int refrigerationDeforstingSensorError;
  late int ringTemperatureSensorError;
  late int flexZoneSensorError;
  late int rightFlexZoneSensorError;
  late int freezingHighTemperature;
  late int freezingSensorError;
  late int freezingDefrostingSensorError;
  late int iceElectricalMachineryError;
  late int refrigerationDefrostingOvertime;
  late int freezingDefrostingOvertime;
  late int zeroCrossingCheckError;
}

class CANotify00MessageBody extends MessageBody {
  CANotify00MessageBody(Uint8List body) : super(body) {
    refrigeratorDoor = (body[1] & 0x01) > 0;
    freezerDoor = (body[1] & 0x02) > 0;
    barDoor = (body[1] & 0x04) > 0;
    flexZoneDoor = (body[1] & 0x10) > 0;
  }

  late bool refrigeratorDoor;
  late bool freezerDoor;
  late bool barDoor;
  late bool flexZoneDoor;
}

class CANotify01MessageBody extends MessageBody {
  CANotify01MessageBody(Uint8List body) : super(body) {
    refrigeratorSettingTemp = body[37];
    freezerSettingTemp = -12 - body[38];

    final flexZoneTemp = body[39];
    final rightFlexZoneTemp = body[40];

    int flexTempVal;
    if (tempPosLowerValue <= flexZoneTemp &&
        flexZoneTemp <= tempPosUpperValue) {
      flexTempVal = flexZoneTemp - 19;
    } else if (tempNegLowerValue <= flexZoneTemp &&
        flexZoneTemp <= tempNegUpperValue) {
      flexTempVal = 30 - flexZoneTemp;
    } else {
      flexTempVal = 0;
    }
    flexZoneSettingTemp = flexTempVal;

    int rightFlexTempVal;
    if (tempPosLowerValue <= rightFlexZoneTemp &&
        rightFlexZoneTemp <= tempPosUpperValue) {
      rightFlexTempVal = rightFlexZoneTemp - 19;
    } else if (tempNegLowerValue <= rightFlexZoneTemp &&
        rightFlexZoneTemp <= tempNegUpperValue) {
      rightFlexTempVal = 30 - rightFlexZoneTemp;
    } else {
      rightFlexTempVal = 0;
    }
    rightFlexZoneSettingTemp = rightFlexTempVal;
  }

  late int refrigeratorSettingTemp;
  late int freezerSettingTemp;
  late int flexZoneSettingTemp;
  late int rightFlexZoneSettingTemp;
}

class MessageCAResponse extends MessageResponse {
  MessageCAResponse(Uint8List message) : super(message) {
    final isQueryOrSet =
        messageType == MessageType.query || messageType == MessageType.set;
    final isNotify1 = messageType == MessageType.notify1;

    if ((isQueryOrSet && bodyType == ListTypes.x00) ||
        (isNotify1 && bodyType == ListTypes.x02)) {
      if (body.length > minCaGeneralBodyLength) {
        final msgBody = CAGeneralMessageBody(body);
        setBody(msgBody);
        _assignGeneralAttrs(msgBody);
      }
    } else if ((messageType == MessageType.exception &&
            bodyType == ListTypes.x01) ||
        (messageType == MessageType.query && bodyType == ListTypes.x02)) {
      final msgBody = CAExceptionMessageBody(body);
      setBody(msgBody);
      _assignExceptionAttrs(msgBody);
    } else if (isNotify1 && bodyType == ListTypes.x00) {
      final msgBody = CANotify00MessageBody(body);
      setBody(msgBody);
      _assignNotify00Attrs(msgBody);
    } else if ((messageType == MessageType.query || isNotify1) &&
        bodyType == ListTypes.x01) {
      final msgBody = CANotify01MessageBody(body);
      setBody(msgBody);
      _assignNotify01Attrs(msgBody);
    }
  }

  bool? codeMode;
  bool? freezingMode;
  bool? smartMode;
  bool? energySavingMode;
  bool? holidayMode;
  bool? moisturizeMode;
  bool? preservationMode;
  bool? acmeFreezingMode;
  int? refrigeratorSettingTemp;
  int? freezerSettingTemp;
  int? flexZoneSettingTemp;
  int? rightFlexZoneSettingTemp;
  int? variableMode;
  bool? refrigerationPower;
  bool? lVariablePower;
  bool? rVariablePower;
  bool? freezingPower;
  int? crossPeakElectricityEnter;
  bool? crossPeakElectricity;
  bool? allRefrigerationPower;
  int? removeDew;
  int? humidify;
  int? unfreeze;
  int? temperatureUnit;
  int? floodLight;
  int? functionSwitch;
  int? radarMode;
  int? milkMode;
  int? icedMode;
  int? plasmaAsepticMode;
  int? acquireIceaMode;
  int? brashIceaMode;
  int? acquireWaterMode;
  int? freezingIceMachinePower;
  int? freezingFahrenheit;
  int? refrigerationFahrenheit;
  int? leachExpireDay;
  int? energyConsumption;
  bool? freezingMotorResetStatus;
  bool? freezingMotorDeicingStatus;
  bool? freezingIceMachineWaterStatus;
  bool? freezingAllIceStatus;
  bool? humanInduction;
  int? refrigerationDoorPower;
  int? freezingDoorPower;
  int? variableDoorPower;
  int? storageIceHomeDoorState;
  int? barDoorPower;
  int? iceMouthPower;
  bool? isError;
  int? intervalRoomHumidityLevel;
  double? refrigeratorActualTemp;
  double? freezerActualTemp;
  double? flexZoneActualTemp;
  double? rightFlexZoneActualTemp;
  int? fastColdMinute;
  int? fastFreezeMinute;
  bool? microcrystalFresh;
  bool? dryZone;
  bool? electronicSmell;
  int? humidity;
  int? normalTemperatureLevel;
  int? functionZoneLevel;
  int? humiditySetting;
  bool? smartHumidity;
  int? storageLeftDoorAuto;
  int? storageRightDoorAuto;
  int? freezerDoorAuto;
  bool? freezerDoorAutoControl;
  bool? storageDoorAutoControl;
  bool? refrigeratorDoorOvertime;
  bool? freezerDoorOvertime;
  bool? barDoorOvertime;
  bool? flexZoneDoorOvertime;
  int? iceMiachineFull;
  int? refrigerationSensorError;
  int? refrigerationDeforstingSensorError;
  int? ringTemperatureSensorError;
  int? flexZoneSensorError;
  int? rightFlexZoneSensorError;
  int? freezingHighTemperature;
  int? freezingSensorError;
  int? freezingDefrostingSensorError;
  int? iceElectricalMachineryError;
  int? refrigerationDefrostingOvertime;
  int? freezingDefrostingOvertime;
  int? zeroCrossingCheckError;
  bool? refrigeratorDoor;
  bool? freezerDoor;
  bool? barDoor;
  bool? flexZoneDoor;

  void _assignGeneralAttrs(CAGeneralMessageBody b) {
    codeMode = b.codeMode;
    freezingMode = b.freezingMode;
    smartMode = b.smartMode;
    energySavingMode = b.energySavingMode;
    holidayMode = b.holidayMode;
    moisturizeMode = b.moisturizeMode;
    preservationMode = b.preservationMode;
    acmeFreezingMode = b.acmeFreezingMode;
    refrigeratorSettingTemp = b.refrigeratorSettingTemp;
    freezerSettingTemp = b.freezerSettingTemp;
    flexZoneSettingTemp = b.flexZoneSettingTemp;
    rightFlexZoneSettingTemp = b.rightFlexZoneSettingTemp;
    variableMode = b.variableMode;
    refrigerationPower = b.refrigerationPower;
    lVariablePower = b.lVariablePower;
    rVariablePower = b.rVariablePower;
    freezingPower = b.freezingPower;
    crossPeakElectricityEnter = b.crossPeakElectricityEnter;
    crossPeakElectricity = b.crossPeakElectricity;
    allRefrigerationPower = b.allRefrigerationPower;
    removeDew = b.removeDew;
    humidify = b.humidify;
    unfreeze = b.unfreeze;
    temperatureUnit = b.temperatureUnit;
    floodLight = b.floodLight;
    functionSwitch = b.functionSwitch;
    radarMode = b.radarMode;
    milkMode = b.milkMode;
    icedMode = b.icedMode;
    plasmaAsepticMode = b.plasmaAsepticMode;
    acquireIceaMode = b.acquireIceaMode;
    brashIceaMode = b.brashIceaMode;
    acquireWaterMode = b.acquireWaterMode;
    freezingIceMachinePower = b.freezingIceMachinePower;
    freezingFahrenheit = b.freezingFahrenheit;
    refrigerationFahrenheit = b.refrigerationFahrenheit;
    leachExpireDay = b.leachExpireDay;
    energyConsumption = b.energyConsumption;
    freezingMotorResetStatus = b.freezingMotorResetStatus;
    freezingMotorDeicingStatus = b.freezingMotorDeicingStatus;
    freezingIceMachineWaterStatus = b.freezingIceMachineWaterStatus;
    freezingAllIceStatus = b.freezingAllIceStatus;
    humanInduction = b.humanInduction;
    refrigerationDoorPower = b.refrigerationDoorPower;
    freezingDoorPower = b.freezingDoorPower;
    variableDoorPower = b.variableDoorPower;
    storageIceHomeDoorState = b.storageIceHomeDoorState;
    barDoorPower = b.barDoorPower;
    iceMouthPower = b.iceMouthPower;
    isError = b.isError;
    intervalRoomHumidityLevel = b.intervalRoomHumidityLevel;
    refrigeratorActualTemp = b.refrigeratorActualTemp;
    freezerActualTemp = b.freezerActualTemp;
    flexZoneActualTemp = b.flexZoneActualTemp;
    rightFlexZoneActualTemp = b.rightFlexZoneActualTemp;
    fastColdMinute = b.fastColdMinute;
    fastFreezeMinute = b.fastFreezeMinute;
    microcrystalFresh = b.microcrystalFresh;
    dryZone = b.dryZone;
    electronicSmell = b.electronicSmell;
    humidity = b.humidity;
    normalTemperatureLevel = b.normalTemperatureLevel;
    functionZoneLevel = b.functionZoneLevel;
    humiditySetting = b.humiditySetting;
    smartHumidity = b.smartHumidity;
    storageLeftDoorAuto = b.storageLeftDoorAuto;
    storageRightDoorAuto = b.storageRightDoorAuto;
    freezerDoorAuto = b.freezerDoorAuto;
    freezerDoorAutoControl = b.freezerDoorAutoControl;
    storageDoorAutoControl = b.storageDoorAutoControl;
  }

  void _assignExceptionAttrs(CAExceptionMessageBody b) {
    refrigeratorDoorOvertime = b.refrigeratorDoorOvertime;
    freezerDoorOvertime = b.freezerDoorOvertime;
    barDoorOvertime = b.barDoorOvertime;
    flexZoneDoorOvertime = b.flexZoneDoorOvertime;
    iceMiachineFull = b.iceMiachineFull;
    refrigerationSensorError = b.refrigerationSensorError;
    refrigerationDeforstingSensorError = b.refrigerationDeforstingSensorError;
    ringTemperatureSensorError = b.ringTemperatureSensorError;
    flexZoneSensorError = b.flexZoneSensorError;
    rightFlexZoneSensorError = b.rightFlexZoneSensorError;
    freezingHighTemperature = b.freezingHighTemperature;
    freezingSensorError = b.freezingSensorError;
    freezingDefrostingSensorError = b.freezingDefrostingSensorError;
    iceElectricalMachineryError = b.iceElectricalMachineryError;
    refrigerationDefrostingOvertime = b.refrigerationDefrostingOvertime;
    freezingDefrostingOvertime = b.freezingDefrostingOvertime;
    zeroCrossingCheckError = b.zeroCrossingCheckError;
  }

  void _assignNotify00Attrs(CANotify00MessageBody b) {
    refrigeratorDoor = b.refrigeratorDoor;
    freezerDoor = b.freezerDoor;
    barDoor = b.barDoor;
    flexZoneDoor = b.flexZoneDoor;
  }

  void _assignNotify01Attrs(CANotify01MessageBody b) {
    refrigeratorSettingTemp = b.refrigeratorSettingTemp;
    freezerSettingTemp = b.freezerSettingTemp;
    flexZoneSettingTemp = b.flexZoneSettingTemp;
    rightFlexZoneSettingTemp = b.rightFlexZoneSettingTemp;
  }
}
