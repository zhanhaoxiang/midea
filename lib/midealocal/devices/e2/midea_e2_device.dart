/// Midea local E2 device. Mirrors midealocal/devices/e2/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class E2DeviceAttributes {
  static const String power = 'power';
  static const String heating = 'heating';
  static const String keepWarm = 'keep_warm';
  static const String protection = 'protection';
  static const String currentTemperature = 'current_temperature';
  static const String targetTemperature = 'target_temperature';
  static const String wholeTankHeating = 'whole_tank_heating';
  static const String variableHeating = 'variable_heating';
  static const String heatingTimeRemaining = 'heating_time_remaining';
  static const String waterConsumption = 'water_consumption';
  static const String heatingPower = 'heating_power';
  static const String fastHotPower = 'fast_hot_power';
  static const String waterFlow = 'water_flow';
  static const String sterilization = 'sterilization';
  static const String heatWaterLevel = 'heat_water_level';
  static const String eplus = 'eplus';
  static const String fastWash = 'fast_wash';
  static const String halfHeat = 'half_heat';
  static const String summer = 'summer';
  static const String winter = 'winter';
  static const String efficient = 'efficient';
  static const String night = 'night';
  static const String screenOff = 'screen_off';
  static const String sleep = 'sleep';
  static const String cloud = 'cloud';
  static const String appointWash = 'appoint_wash';
  static const String nowWash = 'now_wash';
  static const String smartSterilize = 'smart_sterilize';
  static const String sterilizeHighTemp = 'sterilize_high_temp';
  static const String uvSterilize = 'uv_sterilize';
  static const String dischargeStatus = 'discharge_status';
  static const String topTemp = 'top_temp';
  static const String bottomHeat = 'bottom_heat';
  static const String topHeat = 'top_heat';
  static const String waterCyclic = 'water_cyclic';
  static const String waterSystem = 'water_system';
  static const String inTemperature = 'in_temperature';
  static const String dayWaterConsumption = 'day_water_consumption';
  static const String volume = 'volume';
  static const String rate = 'rate';
}

enum OldProtocol {
  auto('auto'),
  myTrue('true'),
  myFalse('false');

  const OldProtocol(this.value);
  final String value;
}

enum E2SubType {
  t82(82),
  t85(85),
  t36353(36353);

  const E2SubType(this.value);
  final int value;
}

class MideaE2Device extends MideaDevice {
  MideaE2Device({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
    String? customize,
  }) : super(
         deviceType: DeviceType.e2,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _oldProtocol = _defaultOldProtocol;
    _temperatureStep = _defaultTemperatureStep;
    _precisionHalves = _defaultPrecisionHalves;
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const OldProtocol _defaultOldProtocol = OldProtocol.auto;
  static const double _defaultTemperatureStep = 1.0;
  static const bool _defaultPrecisionHalves = false;

  OldProtocol _oldProtocol = _defaultOldProtocol;
  double? _temperatureStep = _defaultTemperatureStep;
  bool? _precisionHalves = _defaultPrecisionHalves;

  bool? get precisionHalves => _precisionHalves;

  double? get temperatureStep => _temperatureStep;

  static final Map<String, dynamic> _defaultAttributes = {
    E2DeviceAttributes.power: false,
    E2DeviceAttributes.heating: false,
    E2DeviceAttributes.keepWarm: false,
    E2DeviceAttributes.protection: false,
    E2DeviceAttributes.currentTemperature: null,
    E2DeviceAttributes.targetTemperature: 40.0,
    E2DeviceAttributes.wholeTankHeating: false,
    E2DeviceAttributes.variableHeating: false,
    E2DeviceAttributes.heatingTimeRemaining: 0,
    E2DeviceAttributes.waterConsumption: null,
    E2DeviceAttributes.heatingPower: null,
    E2DeviceAttributes.fastHotPower: null,
    E2DeviceAttributes.waterFlow: null,
    E2DeviceAttributes.sterilization: null,
    E2DeviceAttributes.heatWaterLevel: null,
    E2DeviceAttributes.eplus: null,
    E2DeviceAttributes.fastWash: null,
    E2DeviceAttributes.halfHeat: null,
    E2DeviceAttributes.summer: null,
    E2DeviceAttributes.winter: null,
    E2DeviceAttributes.efficient: null,
    E2DeviceAttributes.night: null,
    E2DeviceAttributes.screenOff: null,
    E2DeviceAttributes.sleep: null,
    E2DeviceAttributes.cloud: null,
    E2DeviceAttributes.appointWash: null,
    E2DeviceAttributes.nowWash: null,
    E2DeviceAttributes.smartSterilize: null,
    E2DeviceAttributes.sterilizeHighTemp: null,
    E2DeviceAttributes.uvSterilize: null,
    E2DeviceAttributes.dischargeStatus: null,
    E2DeviceAttributes.topTemp: null,
    E2DeviceAttributes.bottomHeat: null,
    E2DeviceAttributes.topHeat: null,
    E2DeviceAttributes.waterCyclic: null,
    E2DeviceAttributes.waterSystem: null,
    E2DeviceAttributes.inTemperature: null,
    E2DeviceAttributes.dayWaterConsumption: null,
    E2DeviceAttributes.volume: null,
    E2DeviceAttributes.rate: null,
  };

  OldProtocol _normalizeOldProtocol(dynamic value) {
    if (value is String) {
      var returnValue = OldProtocol.values.firstWhere(
        (e) => e.value == value,
        orElse: () => OldProtocol.auto,
      );
      if (returnValue == OldProtocol.auto) {
        final result =
            subtype <= E2SubType.t82.value ||
            subtype == E2SubType.t85.value ||
            subtype == E2SubType.t36353.value;
        returnValue = result ? OldProtocol.myTrue : OldProtocol.myFalse;
      }
      return returnValue;
    }
    return value ? OldProtocol.myTrue : OldProtocol.myFalse;
  }

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageE2Response(msg);
    final newStatus = <String, dynamic>{};
    for (final status in attrs.keys) {
      if (message.hasAttribute(status)) {
        final value = message.getAttribute(status);
        attrs[status] = value;
        newStatus[status] = value;
      }
    }
    return newStatus;
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.protection = attrs[E2DeviceAttributes.protection] as bool? ?? false;
    message.wholeTankHeating =
        attrs[E2DeviceAttributes.wholeTankHeating] as bool? ?? false;
    message.targetTemperature =
        (attrs[E2DeviceAttributes.targetTemperature] as num?)?.toDouble() ?? 40.0;
    message.variableHeating =
        attrs[E2DeviceAttributes.variableHeating] as bool? ?? false;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final readOnlyAttrs = <String>[
      E2DeviceAttributes.heating,
      E2DeviceAttributes.keepWarm,
      E2DeviceAttributes.currentTemperature,
    ];
    if (readOnlyAttrs.contains(attr)) {
      return;
    }

    final oldProtocol = _normalizeOldProtocol(_oldProtocol);
    if (attr == E2DeviceAttributes.targetTemperature) {
      value = _precisionHalves == true ? value : (value as num) * 2;
    }

    if (attr == E2DeviceAttributes.power) {
      final message = MessagePower(messageProtocolVersion);
      message.power = value as bool;
      buildSend(message);
      return;
    }

    if (oldProtocol == OldProtocol.myTrue) {
      final message = makeMessageSet();
      if (attr == E2DeviceAttributes.targetTemperature) {
        message.targetTemperature = (value as num).toDouble();
      } else if (attr == E2DeviceAttributes.wholeTankHeating) {
        message.wholeTankHeating = value as bool;
      } else if (attr == E2DeviceAttributes.variableHeating) {
        message.variableHeating = value as bool;
      } else if (attr == E2DeviceAttributes.protection) {
        message.protection = value as bool;
      }
      buildSend(message);
    } else {
      final message = MessageNewProtocolSet(messageProtocolVersion);
      if (attr == E2DeviceAttributes.targetTemperature) {
        message.targetTemperature = (value as num).toDouble();
      } else if (attr == E2DeviceAttributes.wholeTankHeating) {
        message.wholeTankHeating = value as bool;
      } else if (attr == E2DeviceAttributes.variableHeating) {
        message.variableHeating = value as bool;
      } else if (attr == E2DeviceAttributes.sterilization) {
        message.sterilization = value as bool;
      } else if (attr == E2DeviceAttributes.protection) {
        message.protect = value as bool;
      } else if (attr == E2DeviceAttributes.sleep) {
        message.sleep = value as bool;
      } else if (attr == E2DeviceAttributes.screenOff) {
        message.screenOff = value as bool;
      } else if (attr == E2DeviceAttributes.smartSterilize) {
        message.smartSterilize = value as bool;
      } else if (attr == E2DeviceAttributes.uvSterilize) {
        message.uvSterilize = value as bool;
      }
      buildSend(message);
    }
  }

  void setCustomize(String customize) {
    _oldProtocol = _defaultOldProtocol;
    _temperatureStep = _defaultTemperatureStep;
    _precisionHalves = _defaultPrecisionHalves;
    if (customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>?;
        if (params != null) {
          if (params.containsKey('old_protocol')) {
            _oldProtocol = _normalizeOldProtocol(params['old_protocol']);
          }
          if (params.containsKey('temperature_step')) {
            _temperatureStep = (params['temperature_step'] as num?)?.toDouble();
          }
          if (params.containsKey('precision_halves')) {
            _precisionHalves = params['precision_halves'] as bool?;
          }
        }
      } catch (_) {}
    }
    updateAll({
      'temperature_step': _temperatureStep,
      'old_protocol': _oldProtocol,
      'precision_halves': _precisionHalves,
    });
  }
}

class MideaAppliance extends MideaE2Device {
  MideaAppliance({
    required String name,
    required int deviceId,
    required String ipAddress,
    required int port,
    required String token,
    required String key,
    required ProtocolVersion deviceProtocol,
    required String model,
    required int subtype,
    String? customize,
  }) : super(
         name: name,
         deviceId: deviceId,
         ipAddress: ipAddress,
         port: port,
         token: token,
         key: key,
         deviceProtocol: deviceProtocol,
         model: model,
         subtype: subtype,
         customize: customize,
       );
}
