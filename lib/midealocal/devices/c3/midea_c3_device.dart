/// Midea local C3 device. Mirrors midealocal/devices/c3/__init__.py.

import 'dart:convert';
import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
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
    DeviceAttributes.zone1Power: false,
    DeviceAttributes.zone2Power: false,
    DeviceAttributes.dhwPower: false,
    DeviceAttributes.zone1Curve: false,
    DeviceAttributes.zone2Curve: false,
    DeviceAttributes.disinfect: false,
    DeviceAttributes.fastDhw: false,
    DeviceAttributes.zoneTempType: [false, false],
    DeviceAttributes.zone1RoomTempMode: false,
    DeviceAttributes.zone2RoomTempMode: false,
    DeviceAttributes.zone1WaterTempMode: false,
    DeviceAttributes.zone2WaterTempMode: false,
    DeviceAttributes.silentMode: false,
    DeviceAttributes.silentLevel: C3SilentLevel.off.name,
    DeviceAttributes.ecoMode: false,
    DeviceAttributes.tbh: false,
    DeviceAttributes.mode: 1,
    DeviceAttributes.modeAuto: 1,
    DeviceAttributes.zoneTargetTemp: [25.0, 25.0],
    DeviceAttributes.dhwTargetTemp: 25.0,
    DeviceAttributes.roomTargetTemp: 30.0,
    DeviceAttributes.zoneHeatingTempMax: [55.0, 55.0],
    DeviceAttributes.zoneHeatingTempMin: [25.0, 25.0],
    DeviceAttributes.zoneCoolingTempMax: [25.0, 25.0],
    DeviceAttributes.zoneCoolingTempMin: [5.0, 5.0],
    DeviceAttributes.roomTempMax: 60.0,
    DeviceAttributes.roomTempMin: 34.0,
    DeviceAttributes.dhwTempMax: 60.0,
    DeviceAttributes.dhwTempMin: 20.0,
    DeviceAttributes.tankActualTemperature: null,
    DeviceAttributes.targetTemperature: [25.0, 25.0],
    DeviceAttributes.temperatureMax: [0.0, 0.0],
    DeviceAttributes.temperatureMin: [0.0, 0.0],
    DeviceAttributes.totalEnergyConsumption: null,
    DeviceAttributes.statusHeating: null,
    DeviceAttributes.statusDhw: null,
    DeviceAttributes.statusTbh: null,
    DeviceAttributes.statusIbh: null,
    DeviceAttributes.totalProducedEnergy: null,
    DeviceAttributes.outdoorTemperature: null,
    DeviceAttributes.tempTwIn: null,
    DeviceAttributes.tempTwOut: null,
    DeviceAttributes.instantPower0: null,
    DeviceAttributes.errorCode: 0,
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

    if (newStatus.containsKey(DeviceAttributes.zoneTempType)) {
      for (var zone = 0; zone < 2; zone++) {
        final zoneTempType =
            (attrs[DeviceAttributes.zoneTempType] as List)[zone];
        if (zoneTempType) {
          attrs[DeviceAttributes.targetTemperature] =
              (attrs[DeviceAttributes.zoneTargetTemp] as List)[zone];
          final modeAuto = attrs[DeviceAttributes.modeAuto] as int;
          if (modeAuto == C3DeviceMode.cool.value) {
            attrs[DeviceAttributes.temperatureMax] =
                (attrs[DeviceAttributes.zoneCoolingTempMax] as List)[zone];
            attrs[DeviceAttributes.temperatureMin] =
                (attrs[DeviceAttributes.zoneCoolingTempMin] as List)[zone];
          } else if (attrs[DeviceAttributes.mode] == C3DeviceMode.heat.value) {
            attrs[DeviceAttributes.temperatureMax] =
                (attrs[DeviceAttributes.zoneHeatingTempMax] as List)[zone];
            attrs[DeviceAttributes.temperatureMin] =
                (attrs[DeviceAttributes.zoneHeatingTempMin] as List)[zone];
          }
        } else {
          attrs[DeviceAttributes.targetTemperature] =
              attrs[DeviceAttributes.roomTargetTemp];
          attrs[DeviceAttributes.temperatureMax] =
              attrs[DeviceAttributes.roomTempMax];
          attrs[DeviceAttributes.temperatureMin] =
              attrs[DeviceAttributes.roomTempMin];
        }
        final zone1Power = attrs[DeviceAttributes.zone1Power] as bool;
        final zone2Power = attrs[DeviceAttributes.zone2Power] as bool;
        if (zone1Power) {
          if (zoneTempType) {
            attrs[DeviceAttributes.zone1WaterTempMode] = true;
            attrs[DeviceAttributes.zone1RoomTempMode] = false;
          } else {
            attrs[DeviceAttributes.zone1WaterTempMode] = false;
            attrs[DeviceAttributes.zone1RoomTempMode] = true;
          }
        } else {
          attrs[DeviceAttributes.zone1WaterTempMode] = false;
          attrs[DeviceAttributes.zone1RoomTempMode] = false;
        }
        if (zone2Power) {
          if (zoneTempType) {
            attrs[DeviceAttributes.zone2WaterTempMode] = true;
            attrs[DeviceAttributes.zone2RoomTempMode] = false;
          } else {
            attrs[DeviceAttributes.zone2WaterTempMode] = false;
            attrs[DeviceAttributes.zone2RoomTempMode] = true;
          }
        } else {
          attrs[DeviceAttributes.zone2WaterTempMode] = false;
          attrs[DeviceAttributes.zone2RoomTempMode] = false;
        }
        newStatus[DeviceAttributes.zone1WaterTempMode] =
            attrs[DeviceAttributes.zone1WaterTempMode];
        newStatus[DeviceAttributes.zone2WaterTempMode] =
            attrs[DeviceAttributes.zone2WaterTempMode];
        newStatus[DeviceAttributes.zone1RoomTempMode] =
            attrs[DeviceAttributes.zone1RoomTempMode];
        newStatus[DeviceAttributes.zone2RoomTempMode] =
            attrs[DeviceAttributes.zone2RoomTempMode];
      }
    }

    return newStatus;
  }

  bool _hasAttribute(MessageC3Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.zone1Power:
        return msg.zone1Power != null;
      case DeviceAttributes.zone2Power:
        return msg.zone2Power != null;
      case DeviceAttributes.dhwPower:
        return msg.dhwPower != null;
      case DeviceAttributes.zone1Curve:
        return msg.zone1Curve != null;
      case DeviceAttributes.zone2Curve:
        return msg.zone2Curve != null;
      case DeviceAttributes.disinfect:
        return msg.disinfect != null;
      case DeviceAttributes.fastDhw:
        return msg.fastDhw != null;
      case DeviceAttributes.tbh:
        return msg.tbh != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.modeAuto:
        return msg.modeAuto != null;
      case DeviceAttributes.zoneTargetTemp:
        return msg.zoneTargetTemp != null;
      case DeviceAttributes.dhwTargetTemp:
        return msg.dhwTargetTemp != null;
      case DeviceAttributes.roomTargetTemp:
        return msg.roomTargetTemp != null;
      case DeviceAttributes.zoneHeatingTempMax:
        return msg.zoneHeatingTempMax != null;
      case DeviceAttributes.zoneHeatingTempMin:
        return msg.zoneHeatingTempMin != null;
      case DeviceAttributes.zoneCoolingTempMax:
        return msg.zoneCoolingTempMax != null;
      case DeviceAttributes.zoneCoolingTempMin:
        return msg.zoneCoolingTempMin != null;
      case DeviceAttributes.roomTempMax:
        return msg.roomTempMax != null;
      case DeviceAttributes.roomTempMin:
        return msg.roomTempMin != null;
      case DeviceAttributes.dhwTempMax:
        return msg.dhwTempMax != null;
      case DeviceAttributes.dhwTempMin:
        return msg.dhwTempMin != null;
      case DeviceAttributes.tankActualTemperature:
        return msg.tankActualTemperature != null;
      case DeviceAttributes.errorCode:
        return msg.errorCode != null;
      case DeviceAttributes.silentMode:
        return msg.silentMode != null;
      case DeviceAttributes.silentLevel:
        return msg.silentLevel != null;
      case DeviceAttributes.ecoMode:
        return msg.ecoMode != null;
      case DeviceAttributes.statusHeating:
        return msg.statusHeating != null;
      case DeviceAttributes.statusDhw:
        return msg.statusDhw != null;
      case DeviceAttributes.statusTbh:
        return msg.statusTbh != null;
      case DeviceAttributes.statusIbh:
        return msg.statusIbh != null;
      case DeviceAttributes.totalEnergyConsumption:
        return msg.totalEnergyConsumption != null;
      case DeviceAttributes.totalProducedEnergy:
        return msg.totalProducedEnergy != null;
      case DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature != null;
      case DeviceAttributes.tempTwIn:
        return msg.tempTwIn != null;
      case DeviceAttributes.tempTwOut:
        return msg.tempTwOut != null;
      case DeviceAttributes.instantPower0:
        return msg.instantPower0 != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageC3Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.zone1Power:
        return msg.zone1Power;
      case DeviceAttributes.zone2Power:
        return msg.zone2Power;
      case DeviceAttributes.dhwPower:
        return msg.dhwPower;
      case DeviceAttributes.zone1Curve:
        return msg.zone1Curve;
      case DeviceAttributes.zone2Curve:
        return msg.zone2Curve;
      case DeviceAttributes.disinfect:
        return msg.disinfect;
      case DeviceAttributes.fastDhw:
        return msg.fastDhw;
      case DeviceAttributes.tbh:
        return msg.tbh;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.modeAuto:
        return msg.modeAuto;
      case DeviceAttributes.zoneTargetTemp:
        return msg.zoneTargetTemp;
      case DeviceAttributes.dhwTargetTemp:
        return msg.dhwTargetTemp;
      case DeviceAttributes.roomTargetTemp:
        return msg.roomTargetTemp;
      case DeviceAttributes.zoneHeatingTempMax:
        return msg.zoneHeatingTempMax;
      case DeviceAttributes.zoneHeatingTempMin:
        return msg.zoneHeatingTempMin;
      case DeviceAttributes.zoneCoolingTempMax:
        return msg.zoneCoolingTempMax;
      case DeviceAttributes.zoneCoolingTempMin:
        return msg.zoneCoolingTempMin;
      case DeviceAttributes.roomTempMax:
        return msg.roomTempMax;
      case DeviceAttributes.roomTempMin:
        return msg.roomTempMin;
      case DeviceAttributes.dhwTempMax:
        return msg.dhwTempMax;
      case DeviceAttributes.dhwTempMin:
        return msg.dhwTempMin;
      case DeviceAttributes.tankActualTemperature:
        return msg.tankActualTemperature;
      case DeviceAttributes.errorCode:
        return msg.errorCode;
      case DeviceAttributes.silentMode:
        return msg.silentMode;
      case DeviceAttributes.silentLevel:
        return msg.silentLevel;
      case DeviceAttributes.ecoMode:
        return msg.ecoMode;
      case DeviceAttributes.statusHeating:
        return msg.statusHeating;
      case DeviceAttributes.statusDhw:
        return msg.statusDhw;
      case DeviceAttributes.statusTbh:
        return msg.statusTbh;
      case DeviceAttributes.statusIbh:
        return msg.statusIbh;
      case DeviceAttributes.totalEnergyConsumption:
        return msg.totalEnergyConsumption;
      case DeviceAttributes.totalProducedEnergy:
        return msg.totalProducedEnergy;
      case DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature;
      case DeviceAttributes.tempTwIn:
        return msg.tempTwIn;
      case DeviceAttributes.tempTwOut:
        return msg.tempTwOut;
      case DeviceAttributes.instantPower0:
        return msg.instantPower0;
      default:
        return null;
    }
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.zone1Power = attrs[DeviceAttributes.zone1Power] as bool? ?? false;
    message.zone2Power = attrs[DeviceAttributes.zone2Power] as bool? ?? false;
    message.dhwPower = attrs[DeviceAttributes.dhwPower] as bool? ?? false;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 0;
    message.zoneTargetTemp = (attrs[DeviceAttributes.zoneTargetTemp] as List)
        .cast<double>();
    message.dhwTargetTemp =
        attrs[DeviceAttributes.dhwTargetTemp] as double? ?? 25.0;
    message.roomTargetTemp =
        attrs[DeviceAttributes.roomTargetTemp] as double? ?? 30.0;
    message.zone1Curve = attrs[DeviceAttributes.zone1Curve] as bool? ?? false;
    message.zone2Curve = attrs[DeviceAttributes.zone2Curve] as bool? ?? false;
    message.tbh = attrs[DeviceAttributes.tbh] as bool? ?? false;
    message.fastDhw = attrs[DeviceAttributes.fastDhw] as bool? ?? false;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    MessageRequest? message;

    if (_settableAttributes.contains(attr)) {
      message = makeMessageSet();
      switch (attr) {
        case DeviceAttributes.zone1Power:
          (message as MessageSet).zone1Power = value as bool;
          break;
        case DeviceAttributes.zone2Power:
          (message as MessageSet).zone2Power = value as bool;
          break;
        case DeviceAttributes.dhwPower:
          (message as MessageSet).dhwPower = value as bool;
          break;
        case DeviceAttributes.zone1Curve:
          (message as MessageSet).zone1Curve = value as bool;
          break;
        case DeviceAttributes.zone2Curve:
          (message as MessageSet).zone2Curve = value as bool;
          break;
        case DeviceAttributes.tbh:
          (message as MessageSet).tbh = value as bool;
          break;
        case DeviceAttributes.fastDhw:
          (message as MessageSet).fastDhw = value as bool;
          break;
        case DeviceAttributes.dhwTargetTemp:
          (message as MessageSet).dhwTargetTemp = value as double;
          break;
        case DeviceAttributes.zoneTargetTemp:
          (message as MessageSet).zoneTargetTemp = (value as List)
              .cast<double>();
          break;
      }
    } else if (attr == DeviceAttributes.ecoMode) {
      message = MessageSetECO(messageProtocolVersion);
      (message as MessageSetECO).ecoMode = value as bool;
    } else if (attr == DeviceAttributes.disinfect) {
      message = MessageSetDisinfect(messageProtocolVersion);
      (message as MessageSetDisinfect).disinfect = value as bool;
    } else if (attr == DeviceAttributes.silentMode ||
        attr == DeviceAttributes.silentLevel) {
      final silentMsg = MessageSetSilent(messageProtocolVersion);
      message = silentMsg;
      if (attr == DeviceAttributes.silentMode && value is bool) {
        silentMsg.silentMode = value;
        silentMsg.silentLevel =
            value &&
                attrs[DeviceAttributes.silentLevel] == C3SilentLevel.off.name
            ? C3SilentLevel.silent
            : C3SilentLevel.values.firstWhere(
                (e) => e.name == attrs[DeviceAttributes.silentLevel],
                orElse: () => C3SilentLevel.off,
              );
      } else if (attr == DeviceAttributes.silentLevel && value is String) {
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
    DeviceAttributes.zone1Power,
    DeviceAttributes.zone2Power,
    DeviceAttributes.dhwPower,
    DeviceAttributes.zone1Curve,
    DeviceAttributes.zone2Curve,
    DeviceAttributes.tbh,
    DeviceAttributes.fastDhw,
    DeviceAttributes.dhwTargetTemp,
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
    final zoneTempType = (attrs[DeviceAttributes.zoneTempType] as List)[zone];
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
