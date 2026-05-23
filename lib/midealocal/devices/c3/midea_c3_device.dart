/// Midea local C3 device. Mirrors midealocal/devices/c3/__init__.py.

import 'dart:convert';
import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// C3DeviceAttributes
// ---------------------------------------------------------------------------

class C3DeviceAttributes {
  static const String zone1Power = 'zone1_power';
  static const String zone2Power = 'zone2_power';
  static const String dhwPower = 'dhw_power';
  static const String zone1Curve = 'zone1_curve';
  static const String zone2Curve = 'zone2_curve';
  static const String disinfect = 'disinfect';
  static const String fastDhw = 'fast_dhw';
  static const String zoneTempType = 'zone_temp_type';
  static const String zone1RoomTempMode = 'zone1_room_temp_mode';
  static const String zone2RoomTempMode = 'zone2_room_temp_mode';
  static const String zone1WaterTempMode = 'zone1_water_temp_mode';
  static const String zone2WaterTempMode = 'zone2_water_temp_mode';
  static const String mode = 'mode';
  static const String modeAuto = 'mode_auto';
  static const String zoneTargetTemp = 'zone_target_temp';
  static const String dhwTargetTemp = 'dhw_target_temp';
  static const String roomTargetTemp = 'room_target_temp';
  static const String zoneHeatingTempMax = 'zone_heating_temp_max';
  static const String zoneHeatingTempMin = 'zone_heating_temp_min';
  static const String zoneCoolingTempMax = 'zone_cooling_temp_max';
  static const String zoneCoolingTempMin = 'zone_cooling_temp_min';
  static const String tankActualTemperature = 'tank_actual_temperature';
  static const String roomTempMax = 'room_temp_max';
  static const String roomTempMin = 'room_temp_min';
  static const String dhwTempMax = 'dhw_temp_max';
  static const String dhwTempMin = 'dhw_temp_min';
  static const String targetTemperature = 'target_temperature';
  static const String temperatureMax = 'temperature_max';
  static const String temperatureMin = 'temperature_min';
  static const String statusHeating = 'status_heating';
  static const String statusDhw = 'status_dhw';
  static const String statusTbh = 'status_tbh';
  static const String statusIbh = 'status_ibh';
  static const String totalEnergyConsumption = 'total_energy_consumption';
  static const String totalProducedEnergy = 'total_produced_energy';
  static const String outdoorTemperature = 'outdoor_temperature';
  static const String tempTwIn = 'temp_tw_in';
  static const String tempTwOut = 'temp_tw_out';
  static const String instantPower0 = 'instant_power0';
  static const String silentMode = 'silent_mode';
  static const String silentLevel = 'silent_level';
  static const String ecoMode = 'eco_mode';
  static const String tbh = 'tbh';
  static const String errorCode = 'error_code';
}

// ---------------------------------------------------------------------------
// C3DeviceMode
// ---------------------------------------------------------------------------

enum C3DeviceMode {
  cool(2),
  heat(3);

  const C3DeviceMode(this.value);
  final int value;
}

// ---------------------------------------------------------------------------
// MideaC3Device
// ---------------------------------------------------------------------------

class MideaC3Device extends MideaDevice {
  static final List<String> _silentModes = [
    C3SilentLevel.off.name,
    C3SilentLevel.silent.name,
    C3SilentLevel.superSilent.name,
  ];

  MideaC3Device({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
    required String customize,
  }) : super(
         deviceType: DeviceType.c3,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _defaultTemperatureStep = 0.5;
    _temperatureStep = 0.5;
    setCustomize(customize);
  }

  static final Map<String, dynamic> _defaultAttributes = {
    C3DeviceAttributes.zone1Power: false,
    C3DeviceAttributes.zone2Power: false,
    C3DeviceAttributes.dhwPower: false,
    C3DeviceAttributes.zone1Curve: false,
    C3DeviceAttributes.zone2Curve: false,
    C3DeviceAttributes.disinfect: false,
    C3DeviceAttributes.fastDhw: false,
    C3DeviceAttributes.zoneTempType: [false, false],
    C3DeviceAttributes.zone1RoomTempMode: false,
    C3DeviceAttributes.zone2RoomTempMode: false,
    C3DeviceAttributes.zone1WaterTempMode: false,
    C3DeviceAttributes.zone2WaterTempMode: false,
    C3DeviceAttributes.silentMode: false,
    C3DeviceAttributes.silentLevel: C3SilentLevel.off.name,
    C3DeviceAttributes.ecoMode: false,
    C3DeviceAttributes.tbh: false,
    C3DeviceAttributes.mode: 1,
    C3DeviceAttributes.modeAuto: 1,
    C3DeviceAttributes.zoneTargetTemp: [25.0, 25.0],
    C3DeviceAttributes.dhwTargetTemp: 25.0,
    C3DeviceAttributes.roomTargetTemp: 30.0,
    C3DeviceAttributes.zoneHeatingTempMax: [55.0, 55.0],
    C3DeviceAttributes.zoneHeatingTempMin: [25.0, 25.0],
    C3DeviceAttributes.zoneCoolingTempMax: [25.0, 25.0],
    C3DeviceAttributes.zoneCoolingTempMin: [5.0, 5.0],
    C3DeviceAttributes.roomTempMax: 60.0,
    C3DeviceAttributes.roomTempMin: 34.0,
    C3DeviceAttributes.dhwTempMax: 60.0,
    C3DeviceAttributes.dhwTempMin: 20.0,
    C3DeviceAttributes.tankActualTemperature: null,
    C3DeviceAttributes.targetTemperature: [25.0, 25.0],
    C3DeviceAttributes.temperatureMax: [0.0, 0.0],
    C3DeviceAttributes.temperatureMin: [0.0, 0.0],
    C3DeviceAttributes.totalEnergyConsumption: null,
    C3DeviceAttributes.statusHeating: null,
    C3DeviceAttributes.statusDhw: null,
    C3DeviceAttributes.statusTbh: null,
    C3DeviceAttributes.statusIbh: null,
    C3DeviceAttributes.totalProducedEnergy: null,
    C3DeviceAttributes.outdoorTemperature: null,
    C3DeviceAttributes.tempTwIn: null,
    C3DeviceAttributes.tempTwOut: null,
    C3DeviceAttributes.instantPower0: null,
    C3DeviceAttributes.errorCode: 0,
  };

  double _defaultTemperatureStep = 0.5;
  double _temperatureStep = 0.5;

  double? get temperatureStep => _temperatureStep;

  List<String> get silentModes => _silentModes;

  @override
  List<MessageRequest> buildQuery() {
    return [
      MessageQueryBasic(messageProtocolVersion),
      MessageQueryDisinfect(messageProtocolVersion),
      MessageQuerySilence(messageProtocolVersion),
      MessageQueryECO(messageProtocolVersion),
      MessageQueryUnitPara(messageProtocolVersion),
    ];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageC3Response(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      if (_hasAttribute(message, status)) {
        final value = _getAttribute(message, status);
        attrs[status] = value;
        newStatus[status] = value;
      }
    }

    if (newStatus.containsKey(C3DeviceAttributes.zoneTempType)) {
      for (var zone = 0; zone < 2; zone++) {
        final zoneTempType =
            (attrs[C3DeviceAttributes.zoneTempType] as List)[zone];
        if (zoneTempType) {
          attrs[C3DeviceAttributes.targetTemperature] =
              (attrs[C3DeviceAttributes.zoneTargetTemp] as List)[zone];
          final modeAuto = attrs[C3DeviceAttributes.modeAuto] as int;
          if (modeAuto == C3DeviceMode.cool.value) {
            attrs[C3DeviceAttributes.temperatureMax] =
                (attrs[C3DeviceAttributes.zoneCoolingTempMax] as List)[zone];
            attrs[C3DeviceAttributes.temperatureMin] =
                (attrs[C3DeviceAttributes.zoneCoolingTempMin] as List)[zone];
          } else if (attrs[C3DeviceAttributes.mode] == C3DeviceMode.heat.value) {
            attrs[C3DeviceAttributes.temperatureMax] =
                (attrs[C3DeviceAttributes.zoneHeatingTempMax] as List)[zone];
            attrs[C3DeviceAttributes.temperatureMin] =
                (attrs[C3DeviceAttributes.zoneHeatingTempMin] as List)[zone];
          }
        } else {
          attrs[C3DeviceAttributes.targetTemperature] =
              attrs[C3DeviceAttributes.roomTargetTemp];
          attrs[C3DeviceAttributes.temperatureMax] =
              attrs[C3DeviceAttributes.roomTempMax];
          attrs[C3DeviceAttributes.temperatureMin] =
              attrs[C3DeviceAttributes.roomTempMin];
        }
        final zone1Power = attrs[C3DeviceAttributes.zone1Power] as bool;
        final zone2Power = attrs[C3DeviceAttributes.zone2Power] as bool;
        if (zone1Power) {
          if (zoneTempType) {
            attrs[C3DeviceAttributes.zone1WaterTempMode] = true;
            attrs[C3DeviceAttributes.zone1RoomTempMode] = false;
          } else {
            attrs[C3DeviceAttributes.zone1WaterTempMode] = false;
            attrs[C3DeviceAttributes.zone1RoomTempMode] = true;
          }
        } else {
          attrs[C3DeviceAttributes.zone1WaterTempMode] = false;
          attrs[C3DeviceAttributes.zone1RoomTempMode] = false;
        }
        if (zone2Power) {
          if (zoneTempType) {
            attrs[C3DeviceAttributes.zone2WaterTempMode] = true;
            attrs[C3DeviceAttributes.zone2RoomTempMode] = false;
          } else {
            attrs[C3DeviceAttributes.zone2WaterTempMode] = false;
            attrs[C3DeviceAttributes.zone2RoomTempMode] = true;
          }
        } else {
          attrs[C3DeviceAttributes.zone2WaterTempMode] = false;
          attrs[C3DeviceAttributes.zone2RoomTempMode] = false;
        }
        newStatus[C3DeviceAttributes.zone1WaterTempMode] =
            attrs[C3DeviceAttributes.zone1WaterTempMode];
        newStatus[C3DeviceAttributes.zone2WaterTempMode] =
            attrs[C3DeviceAttributes.zone2WaterTempMode];
        newStatus[C3DeviceAttributes.zone1RoomTempMode] =
            attrs[C3DeviceAttributes.zone1RoomTempMode];
        newStatus[C3DeviceAttributes.zone2RoomTempMode] =
            attrs[C3DeviceAttributes.zone2RoomTempMode];
      }
    }

    return newStatus;
  }

  bool _hasAttribute(MessageC3Response msg, String attr) {
    switch (attr) {
      case C3DeviceAttributes.zone1Power:
        return msg.zone1Power != null;
      case C3DeviceAttributes.zone2Power:
        return msg.zone2Power != null;
      case C3DeviceAttributes.dhwPower:
        return msg.dhwPower != null;
      case C3DeviceAttributes.zone1Curve:
        return msg.zone1Curve != null;
      case C3DeviceAttributes.zone2Curve:
        return msg.zone2Curve != null;
      case C3DeviceAttributes.disinfect:
        return msg.disinfect != null;
      case C3DeviceAttributes.fastDhw:
        return msg.fastDhw != null;
      case C3DeviceAttributes.tbh:
        return msg.tbh != null;
      case C3DeviceAttributes.mode:
        return msg.mode != null;
      case C3DeviceAttributes.modeAuto:
        return msg.modeAuto != null;
      case C3DeviceAttributes.zoneTargetTemp:
        return msg.zoneTargetTemp != null;
      case C3DeviceAttributes.dhwTargetTemp:
        return msg.dhwTargetTemp != null;
      case C3DeviceAttributes.roomTargetTemp:
        return msg.roomTargetTemp != null;
      case C3DeviceAttributes.zoneHeatingTempMax:
        return msg.zoneHeatingTempMax != null;
      case C3DeviceAttributes.zoneHeatingTempMin:
        return msg.zoneHeatingTempMin != null;
      case C3DeviceAttributes.zoneCoolingTempMax:
        return msg.zoneCoolingTempMax != null;
      case C3DeviceAttributes.zoneCoolingTempMin:
        return msg.zoneCoolingTempMin != null;
      case C3DeviceAttributes.roomTempMax:
        return msg.roomTempMax != null;
      case C3DeviceAttributes.roomTempMin:
        return msg.roomTempMin != null;
      case C3DeviceAttributes.dhwTempMax:
        return msg.dhwTempMax != null;
      case C3DeviceAttributes.dhwTempMin:
        return msg.dhwTempMin != null;
      case C3DeviceAttributes.tankActualTemperature:
        return msg.tankActualTemperature != null;
      case C3DeviceAttributes.errorCode:
        return msg.errorCode != null;
      case C3DeviceAttributes.silentMode:
        return msg.silentMode != null;
      case C3DeviceAttributes.silentLevel:
        return msg.silentLevel != null;
      case C3DeviceAttributes.ecoMode:
        return msg.ecoMode != null;
      case C3DeviceAttributes.statusHeating:
        return msg.statusHeating != null;
      case C3DeviceAttributes.statusDhw:
        return msg.statusDhw != null;
      case C3DeviceAttributes.statusTbh:
        return msg.statusTbh != null;
      case C3DeviceAttributes.statusIbh:
        return msg.statusIbh != null;
      case C3DeviceAttributes.totalEnergyConsumption:
        return msg.totalEnergyConsumption != null;
      case C3DeviceAttributes.totalProducedEnergy:
        return msg.totalProducedEnergy != null;
      case C3DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature != null;
      case C3DeviceAttributes.tempTwIn:
        return msg.tempTwIn != null;
      case C3DeviceAttributes.tempTwOut:
        return msg.tempTwOut != null;
      case C3DeviceAttributes.instantPower0:
        return msg.instantPower0 != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageC3Response msg, String attr) {
    switch (attr) {
      case C3DeviceAttributes.zone1Power:
        return msg.zone1Power;
      case C3DeviceAttributes.zone2Power:
        return msg.zone2Power;
      case C3DeviceAttributes.dhwPower:
        return msg.dhwPower;
      case C3DeviceAttributes.zone1Curve:
        return msg.zone1Curve;
      case C3DeviceAttributes.zone2Curve:
        return msg.zone2Curve;
      case C3DeviceAttributes.disinfect:
        return msg.disinfect;
      case C3DeviceAttributes.fastDhw:
        return msg.fastDhw;
      case C3DeviceAttributes.tbh:
        return msg.tbh;
      case C3DeviceAttributes.mode:
        return msg.mode;
      case C3DeviceAttributes.modeAuto:
        return msg.modeAuto;
      case C3DeviceAttributes.zoneTargetTemp:
        return msg.zoneTargetTemp;
      case C3DeviceAttributes.dhwTargetTemp:
        return msg.dhwTargetTemp;
      case C3DeviceAttributes.roomTargetTemp:
        return msg.roomTargetTemp;
      case C3DeviceAttributes.zoneHeatingTempMax:
        return msg.zoneHeatingTempMax;
      case C3DeviceAttributes.zoneHeatingTempMin:
        return msg.zoneHeatingTempMin;
      case C3DeviceAttributes.zoneCoolingTempMax:
        return msg.zoneCoolingTempMax;
      case C3DeviceAttributes.zoneCoolingTempMin:
        return msg.zoneCoolingTempMin;
      case C3DeviceAttributes.roomTempMax:
        return msg.roomTempMax;
      case C3DeviceAttributes.roomTempMin:
        return msg.roomTempMin;
      case C3DeviceAttributes.dhwTempMax:
        return msg.dhwTempMax;
      case C3DeviceAttributes.dhwTempMin:
        return msg.dhwTempMin;
      case C3DeviceAttributes.tankActualTemperature:
        return msg.tankActualTemperature;
      case C3DeviceAttributes.errorCode:
        return msg.errorCode;
      case C3DeviceAttributes.silentMode:
        return msg.silentMode;
      case C3DeviceAttributes.silentLevel:
        return msg.silentLevel;
      case C3DeviceAttributes.ecoMode:
        return msg.ecoMode;
      case C3DeviceAttributes.statusHeating:
        return msg.statusHeating;
      case C3DeviceAttributes.statusDhw:
        return msg.statusDhw;
      case C3DeviceAttributes.statusTbh:
        return msg.statusTbh;
      case C3DeviceAttributes.statusIbh:
        return msg.statusIbh;
      case C3DeviceAttributes.totalEnergyConsumption:
        return msg.totalEnergyConsumption;
      case C3DeviceAttributes.totalProducedEnergy:
        return msg.totalProducedEnergy;
      case C3DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature;
      case C3DeviceAttributes.tempTwIn:
        return msg.tempTwIn;
      case C3DeviceAttributes.tempTwOut:
        return msg.tempTwOut;
      case C3DeviceAttributes.instantPower0:
        return msg.instantPower0;
      default:
        return null;
    }
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.zone1Power = attrs[C3DeviceAttributes.zone1Power] as bool? ?? false;
    message.zone2Power = attrs[C3DeviceAttributes.zone2Power] as bool? ?? false;
    message.dhwPower = attrs[C3DeviceAttributes.dhwPower] as bool? ?? false;
    message.mode = attrs[C3DeviceAttributes.mode] as int? ?? 0;
    message.zoneTargetTemp = (attrs[C3DeviceAttributes.zoneTargetTemp] as List)
        .cast<double>();
    message.dhwTargetTemp =
        attrs[C3DeviceAttributes.dhwTargetTemp] as double? ?? 25.0;
    message.roomTargetTemp =
        attrs[C3DeviceAttributes.roomTargetTemp] as double? ?? 30.0;
    message.zone1Curve = attrs[C3DeviceAttributes.zone1Curve] as bool? ?? false;
    message.zone2Curve = attrs[C3DeviceAttributes.zone2Curve] as bool? ?? false;
    message.tbh = attrs[C3DeviceAttributes.tbh] as bool? ?? false;
    message.fastDhw = attrs[C3DeviceAttributes.fastDhw] as bool? ?? false;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    MessageRequest? message;

    if (_settableAttributes.contains(attr)) {
      message = makeMessageSet();
      switch (attr) {
        case C3DeviceAttributes.zone1Power:
          (message as MessageSet).zone1Power = value as bool;
          break;
        case C3DeviceAttributes.zone2Power:
          (message as MessageSet).zone2Power = value as bool;
          break;
        case C3DeviceAttributes.dhwPower:
          (message as MessageSet).dhwPower = value as bool;
          break;
        case C3DeviceAttributes.zone1Curve:
          (message as MessageSet).zone1Curve = value as bool;
          break;
        case C3DeviceAttributes.zone2Curve:
          (message as MessageSet).zone2Curve = value as bool;
          break;
        case C3DeviceAttributes.tbh:
          (message as MessageSet).tbh = value as bool;
          break;
        case C3DeviceAttributes.fastDhw:
          (message as MessageSet).fastDhw = value as bool;
          break;
        case C3DeviceAttributes.dhwTargetTemp:
          (message as MessageSet).dhwTargetTemp = value as double;
          break;
        case C3DeviceAttributes.zoneTargetTemp:
          (message as MessageSet).zoneTargetTemp = (value as List)
              .cast<double>();
          break;
      }
    } else if (attr == C3DeviceAttributes.ecoMode) {
      message = MessageSetECO(messageProtocolVersion);
      (message as MessageSetECO).ecoMode = value as bool;
    } else if (attr == C3DeviceAttributes.disinfect) {
      message = MessageSetDisinfect(messageProtocolVersion);
      (message as MessageSetDisinfect).disinfect = value as bool;
    } else if (attr == C3DeviceAttributes.silentMode ||
        attr == C3DeviceAttributes.silentLevel) {
      final silentMsg = MessageSetSilent(messageProtocolVersion);
      message = silentMsg;
      if (attr == C3DeviceAttributes.silentMode && value is bool) {
        silentMsg.silentMode = value;
        silentMsg.silentLevel =
            value &&
                attrs[C3DeviceAttributes.silentLevel] == C3SilentLevel.off.name
            ? C3SilentLevel.silent
            : C3SilentLevel.values.firstWhere(
                (e) => e.name == attrs[C3DeviceAttributes.silentLevel],
                orElse: () => C3SilentLevel.off,
              );
      } else if (attr == C3DeviceAttributes.silentLevel && value is String) {
        silentMsg.silentLevel = C3SilentLevel.values.firstWhere(
          (e) => e.name == value,
          orElse: () => C3SilentLevel.off,
        );
        silentMsg.silentMode = value != C3SilentLevel.off.name;
      }
    }

    if (message != null) {
      buildSend(message);
    }
  }

  static const _settableAttributes = {
    C3DeviceAttributes.zone1Power,
    C3DeviceAttributes.zone2Power,
    C3DeviceAttributes.dhwPower,
    C3DeviceAttributes.zone1Curve,
    C3DeviceAttributes.zone2Curve,
    C3DeviceAttributes.tbh,
    C3DeviceAttributes.fastDhw,
    C3DeviceAttributes.dhwTargetTemp,
  };

  void setMode(int zone, int mode) {
    final message = makeMessageSet();
    if (zone == 0) {
      message.zone1Power = true;
    } else {
      message.zone2Power = true;
    }
    message.mode = mode;
    buildSend(message);
  }

  void setTargetTemperature({
    required double targetTemperature,
    int? mode,
    required int zone,
  }) {
    if (zone < 0 || zone > 1) {
      throw MideaLocalError('[C3] Parameter `zone` must be 0 or 1');
    }

    final message = makeMessageSet();
    final zoneTempType = (attrs[C3DeviceAttributes.zoneTempType] as List)[zone];
    if (zoneTempType) {
      message.zoneTargetTemp[zone] = targetTemperature;
    } else {
      message.roomTargetTemp = targetTemperature;
    }
    if (mode != null) {
      if (zone == 0) {
        message.zone1Power = true;
      } else {
        message.zone2Power = true;
      }
      message.mode = mode;
    }
    buildSend(message);
  }

  void setCustomize(String customize) {
    _temperatureStep = _defaultTemperatureStep;
    if (customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>;
        if (params.containsKey('temperature_step')) {
          final tempStep = params['temperature_step'];
          if (tempStep is num) {
            _temperatureStep = tempStep.toDouble();
          }
        }
      } catch (e) {
        // ignore
      }
    }
    updateAll({'temperature_step': _temperatureStep});
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaC3Device {
  MideaAppliance({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
    required String customize,
  }) : super(deviceProtocol: deviceProtocol, customize: customize);
}
