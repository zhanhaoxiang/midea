/// Midea local CD device. Mirrors midealocal/devices/cd/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CDSubType {
  t186(186);

  const CDSubType(this.value);
  final int value;
}

enum LuaProtocol {
  auto('auto'),
  old('old'),
  new_('new');

  const LuaProtocol(this.value);
  final String value;
}

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String maxTemperature = 'max_temperature';
  static const String minTemperature = 'min_temperature';
  static const String targetTemperature = 'target_temperature';
  static const String currentTemperature = 'current_temperature';
  static const String outdoorTemperature = 'outdoor_temperature';
  static const String condenserTemperature = 'condenser_temperature';
  static const String compressorTemperature = 'compressor_temperature';
  static const String compressorStatus = 'compressor_status';
  static const String waterLevel = 'water_level';
  static const String fahrenheit = 'fahrenheit';
  static const String heat = 'heat';
  static const String dualHeat = 'dual_heat';
  static const String elecHeat = 'elec_heat';
  static const String topElecHeat = 'top_elec_heat';
  static const String bottomElecHeat = 'bottom_elec_heat';
  static const String waterPump = 'water_pump';
  static const String fourWay = 'four_way';
  static const String backWater = 'back_water';
  static const String sterilize = 'sterilize';
  static const String disinfect = 'disinfect';
  static const String topTemperature = 'top_temperature';
  static const String bottomTemperature = 'bottom_temperature';
  static const String wind = 'wind';
  static const String smartGrid = 'smart_grid';
  static const String multiTerminal = 'multi_terminal';
  static const String muteEffect = 'mute_effect';
  static const String muteStatus = 'mute_status';
  static const String errorCode = 'error_code';
  static const String typeinfo = 'typeinfo';
  static const String vacationMode = 'vacation_mode';
  static const String vacationDays = 'vacation_days';
}

// ---------------------------------------------------------------------------
// MideaCDDevice
// ---------------------------------------------------------------------------

class MideaCDDevice extends MideaDevice {
  static const Map<int, String> _modeMap = {
    0x00: 'None',
    0x01: 'Energy-save',
    0x02: 'Standard',
    0x03: 'Dual',
    0x04: 'Smart',
    0x05: 'Vacation',
  };

  MideaCDDevice({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
    String customize = '',
  }) : _fahrenheit = false,
       _temperatureStep = _defaultTemperatureStep,
       _luaProtocol = _defaultLuaProtocol,
       super(
         deviceType: DeviceType.cd,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       ) {
    setCustomize(customize);
  }

  static const double _defaultTemperatureStep = 1.0;
  static const LuaProtocol _defaultLuaProtocol = LuaProtocol.auto;

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.power: false,
    DeviceAttributes.mode: null,
    DeviceAttributes.maxTemperature: 65.0,
    DeviceAttributes.minTemperature: 35.0,
    DeviceAttributes.targetTemperature: 40.0,
    DeviceAttributes.currentTemperature: null,
    DeviceAttributes.outdoorTemperature: null,
    DeviceAttributes.condenserTemperature: null,
    DeviceAttributes.compressorTemperature: null,
    DeviceAttributes.compressorStatus: null,
    DeviceAttributes.waterLevel: null,
    DeviceAttributes.fahrenheit: false,
    DeviceAttributes.heat: null,
    DeviceAttributes.dualHeat: null,
    DeviceAttributes.elecHeat: null,
    DeviceAttributes.topElecHeat: null,
    DeviceAttributes.bottomElecHeat: null,
    DeviceAttributes.waterPump: null,
    DeviceAttributes.fourWay: null,
    DeviceAttributes.backWater: null,
    DeviceAttributes.sterilize: null,
    DeviceAttributes.disinfect: null,
    DeviceAttributes.topTemperature: null,
    DeviceAttributes.bottomTemperature: null,
    DeviceAttributes.wind: null,
    DeviceAttributes.smartGrid: null,
    DeviceAttributes.multiTerminal: null,
    DeviceAttributes.muteEffect: null,
    DeviceAttributes.muteStatus: null,
    DeviceAttributes.errorCode: null,
    DeviceAttributes.typeinfo: null,
    DeviceAttributes.vacationMode: false,
    DeviceAttributes.vacationDays: 0,
  };

  Map<String, dynamic> _fields = {};
  double? _temperatureStep;
  LuaProtocol _luaProtocol;
  bool _fahrenheit;

  double? _valueToTemperature(
    double value,
    bool forceFahrenheit,
    bool forceOld,
  ) {
    if (_fahrenheit || forceFahrenheit) {
      return _fahrenheitToCelsius(value, forceFahrenheit ? true : null);
    }
    if (_luaProtocol == LuaProtocol.old || forceOld) {
      return ((value - 30.0) / 2).roundToDouble();
    }
    return value;
  }

  double _temperatureToValue(double value) {
    if (_fahrenheit) {
      return _celsiusToFahrenheit(value);
    }
    if (_luaProtocol == LuaProtocol.old) {
      return (value * 2 + 30.0).roundToDouble();
    }
    return value;
  }

  double _celsiusToFahrenheit(double celsius) => celsius * 9.0 / 5.0 + 32;

  double _fahrenheitToCelsius(double fahrenheit, bool? isFahrenheit) {
    final shouldConvert = isFahrenheit ?? _fahrenheit;
    if (shouldConvert) {
      return (fahrenheit - 32) * 5.0 / 9.0;
    }
    return fahrenheit;
  }

  LuaProtocol _normalizeLuaProtocol(dynamic value) {
    if (value is String) {
      var returnValue = LuaProtocol.values.firstWhere(
        (e) => e.value == value,
        orElse: () => LuaProtocol.auto,
      );
      if (returnValue == LuaProtocol.auto) {
        final checkDevice =
            subtype == CDSubType.t186.value ||
            model == 'RSJRAC01' ||
            model == 'RSJRAC06' ||
            model == 'RSJRAC07';
        returnValue = checkDevice ? LuaProtocol.new_ : LuaProtocol.old;
      }
      return returnValue;
    } else if (value is bool || value is int) {
      return (value as bool) ? LuaProtocol.new_ : LuaProtocol.old;
    }
    return LuaProtocol.auto;
  }

  double? get temperatureStep => _temperatureStep;

  List<String> get presetModes => _modeMap.values.toList();

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageCDResponse(msg);
    final newStatus = <String, dynamic>{};

    _fields = message.fields ?? {};

    if (message.fahrenheit != null) {
      _fahrenheit = message.fahrenheit!;
    }

    for (final attr in attrs.keys) {
      final attrStr = attr as String;
      final hasAttr = _hasAttribute(message, attrStr);
      if (!hasAttr) continue;

      var rawValue = _getAttribute(message, attrStr);
      if (attr == DeviceAttributes.mode) {
        attrs[attr] = _modeMap[rawValue] ?? rawValue;
        newStatus[attrStr] = attrs[attr];
        continue;
      }

      if (_isTemperatureAttribute(attr)) {
        final isOutdoorTemp = attr == DeviceAttributes.outdoorTemperature;
        final isCurrentTemp = attr == DeviceAttributes.currentTemperature;
        var parsed = _valueToTemperature(
          rawValue,
          _forceFahrenheit(attr, isOutdoorTemp),
          _forceOld(attr, isCurrentTemp),
        );

        if (_isDefensiveTempAttribute(attr)) {
          double? pv;
          try {
            pv = parsed?.toDouble();
          } catch (_) {
            pv = null;
          }
          if (pv == null || pv <= 0) {
            final existing = attrs[attr];
            if (existing is num && existing > 0) {
              newStatus[attrStr] = existing;
              continue;
            }
          }
        }

        attrs[attr] = parsed;
        newStatus[attrStr] = parsed;
        continue;
      }

      attrs[attr] = rawValue;
      newStatus[attrStr] = rawValue;
    }

    return newStatus;
  }

  bool _isTemperatureAttribute(String attr) {
    return attr == DeviceAttributes.maxTemperature ||
        attr == DeviceAttributes.minTemperature ||
        attr == DeviceAttributes.targetTemperature ||
        attr == DeviceAttributes.currentTemperature ||
        attr == DeviceAttributes.outdoorTemperature ||
        attr == DeviceAttributes.condenserTemperature ||
        attr == DeviceAttributes.compressorTemperature;
  }

  bool _isDefensiveTempAttribute(String attr) {
    return attr == DeviceAttributes.maxTemperature ||
        attr == DeviceAttributes.minTemperature ||
        attr == DeviceAttributes.targetTemperature ||
        attr == DeviceAttributes.currentTemperature;
  }

  bool _forceFahrenheit(String attr, bool isOutdoorTemp) {
    return (model == 'RSJRAC06' || model == 'RSJRAC07') && isOutdoorTemp;
  }

  bool _forceOld(String attr, bool isCurrentTemp) {
    return (model == 'RSJRAC06' || model == 'RSJRAC07') && isCurrentTemp;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.mode ||
        attr == DeviceAttributes.power ||
        attr == DeviceAttributes.targetTemperature ||
        attr == DeviceAttributes.vacationMode) {
      final message = MessageSet(messageProtocolVersion);
      message.fields = Map<String, dynamic>.from(_fields);
      message.useOldProtocol = _luaProtocol == LuaProtocol.old;

      final currentPower = attrs[DeviceAttributes.power] ?? false;
      final currentTemp = attrs[DeviceAttributes.targetTemperature];
      final currentMode = attrs[DeviceAttributes.mode];

      message.power = (currentPower as bool?) ?? false;

      if (currentTemp is num && currentTemp > 0) {
        message.targetTemperature = currentTemp.toDouble();
      } else {
        final minTemp = attrs[DeviceAttributes.minTemperature] ?? 35.0;
        message.targetTemperature = (minTemp as num?)?.toDouble() ?? 40.0;
      }

      if (currentMode == null || currentMode == 'None') {
        message.mode = 0x00;
      } else {
        message.mode =
            _getDictKeyBy_value(_modeMap, currentMode.toString()) ?? 0x00;
      }

      if (attr == DeviceAttributes.mode) {
        final modeKey = _getDictKeyBy_value(_modeMap, value.toString());
        if (modeKey == null) {
          return;
        }
        message.mode = modeKey;
      } else if (attr == DeviceAttributes.power) {
        message.power = value as bool;
      } else if (attr == DeviceAttributes.targetTemperature) {
        message.targetTemperature = (value as num).toDouble();
      } else if (attr == DeviceAttributes.vacationMode) {
        if (value) {
          message.mode = 0x05;
        } else if (currentMode == null || currentMode == 'None') {
          message.mode = 0x00;
        } else {
          message.mode =
              _getDictKeyBy_value(_modeMap, currentMode.toString()) ?? 0x00;
        }
      }

      _fields = Map<String, dynamic>.from(message.fields);
      buildSend(message);
    }
  }

  int? _getDictKeyBy_value(Map<int, String> dict, String value) {
    for (final entry in dict.entries) {
      if (entry.value == value) return entry.key;
    }
    return null;
  }

  void setCustomize(String customize) {
    _temperatureStep = _defaultTemperatureStep;
    _luaProtocol = _defaultLuaProtocol;

    if (customize.isEmpty) return;

    try {
      final params = json.decode(customize) as Map<String, dynamic>;
      if (params.containsKey('temperature_step')) {
        _temperatureStep = (params['temperature_step'] as num).toDouble();
      }
      if (params.containsKey('lua_protocol')) {
        _luaProtocol = _normalizeLuaProtocol(params['lua_protocol']);
      }
    } catch (_) {}

    updateAll({
      'temperature_step': _temperatureStep,
      'lua_protocol': _luaProtocol,
    });
  }

  bool _hasAttribute(MessageCDResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.maxTemperature:
        return msg.maxTemperature != null;
      case DeviceAttributes.minTemperature:
        return msg.minTemperature != null;
      case DeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature != null;
      case DeviceAttributes.condenserTemperature:
        return msg.condenserTemperature != null;
      case DeviceAttributes.compressorTemperature:
        return msg.compressorTemperature != null;
      case DeviceAttributes.compressorStatus:
        return msg.compressorStatus != null;
      case DeviceAttributes.waterLevel:
        return msg.waterLevel != null;
      case DeviceAttributes.fahrenheit:
        return msg.fahrenheit != null;
      case DeviceAttributes.heat:
        return msg.heat != null;
      case DeviceAttributes.dualHeat:
        return msg.dualHeat != null;
      case DeviceAttributes.elecHeat:
        return msg.elecHeat != null;
      case DeviceAttributes.topElecHeat:
        return msg.topElecHeat != null;
      case DeviceAttributes.bottomElecHeat:
        return msg.bottomElecHeat != null;
      case DeviceAttributes.waterPump:
        return msg.waterPump != null;
      case DeviceAttributes.fourWay:
        return msg.fourWay != null;
      case DeviceAttributes.backWater:
        return msg.backWater != null;
      case DeviceAttributes.sterilize:
        return msg.sterilize != null;
      case DeviceAttributes.disinfect:
        return msg.disinfect != null;
      case DeviceAttributes.topTemperature:
        return msg.topTemperature != null;
      case DeviceAttributes.bottomTemperature:
        return msg.bottomTemperature != null;
      case DeviceAttributes.wind:
        return msg.wind != null;
      case DeviceAttributes.smartGrid:
        return msg.smartGrid != null;
      case DeviceAttributes.multiTerminal:
        return msg.multiTerminal != null;
      case DeviceAttributes.muteEffect:
        return msg.muteEffect != null;
      case DeviceAttributes.muteStatus:
        return msg.muteStatus != null;
      case DeviceAttributes.errorCode:
        return msg.errorCode != null;
      case DeviceAttributes.typeinfo:
        return msg.typeinfo != null;
      case DeviceAttributes.vacationMode:
        return msg.vacationMode != null;
      case DeviceAttributes.vacationDays:
        return msg.vacationDays != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCDResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.maxTemperature:
        return msg.maxTemperature;
      case DeviceAttributes.minTemperature:
        return msg.minTemperature;
      case DeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case DeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature;
      case DeviceAttributes.condenserTemperature:
        return msg.condenserTemperature;
      case DeviceAttributes.compressorTemperature:
        return msg.compressorTemperature;
      case DeviceAttributes.compressorStatus:
        return msg.compressorStatus;
      case DeviceAttributes.waterLevel:
        return msg.waterLevel;
      case DeviceAttributes.fahrenheit:
        return msg.fahrenheit;
      case DeviceAttributes.heat:
        return msg.heat;
      case DeviceAttributes.dualHeat:
        return msg.dualHeat;
      case DeviceAttributes.elecHeat:
        return msg.elecHeat;
      case DeviceAttributes.topElecHeat:
        return msg.topElecHeat;
      case DeviceAttributes.bottomElecHeat:
        return msg.bottomElecHeat;
      case DeviceAttributes.waterPump:
        return msg.waterPump;
      case DeviceAttributes.fourWay:
        return msg.fourWay;
      case DeviceAttributes.backWater:
        return msg.backWater;
      case DeviceAttributes.sterilize:
        return msg.sterilize;
      case DeviceAttributes.disinfect:
        return msg.disinfect;
      case DeviceAttributes.topTemperature:
        return msg.topTemperature;
      case DeviceAttributes.bottomTemperature:
        return msg.bottomTemperature;
      case DeviceAttributes.wind:
        return msg.wind;
      case DeviceAttributes.smartGrid:
        return msg.smartGrid;
      case DeviceAttributes.multiTerminal:
        return msg.multiTerminal;
      case DeviceAttributes.muteEffect:
        return msg.muteEffect;
      case DeviceAttributes.muteStatus:
        return msg.muteStatus;
      case DeviceAttributes.errorCode:
        return msg.errorCode;
      case DeviceAttributes.typeinfo:
        return msg.typeinfo;
      case DeviceAttributes.vacationMode:
        return msg.vacationMode;
      case DeviceAttributes.vacationDays:
        return msg.vacationDays;
      default:
        return null;
    }
  }
}
