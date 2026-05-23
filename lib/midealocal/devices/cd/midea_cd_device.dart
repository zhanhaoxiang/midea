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
// CdDeviceAttributes
// ---------------------------------------------------------------------------

class CdDeviceAttributes {
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
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    setCustomize(customize);
  }

  static const double _defaultTemperatureStep = 1.0;
  static const LuaProtocol _defaultLuaProtocol = LuaProtocol.auto;

  static final Map<String, dynamic> _defaultAttributes = {
    CdDeviceAttributes.power: false,
    CdDeviceAttributes.mode: null,
    CdDeviceAttributes.maxTemperature: 65.0,
    CdDeviceAttributes.minTemperature: 35.0,
    CdDeviceAttributes.targetTemperature: 40.0,
    CdDeviceAttributes.currentTemperature: null,
    CdDeviceAttributes.outdoorTemperature: null,
    CdDeviceAttributes.condenserTemperature: null,
    CdDeviceAttributes.compressorTemperature: null,
    CdDeviceAttributes.compressorStatus: null,
    CdDeviceAttributes.waterLevel: null,
    CdDeviceAttributes.fahrenheit: false,
    CdDeviceAttributes.heat: null,
    CdDeviceAttributes.dualHeat: null,
    CdDeviceAttributes.elecHeat: null,
    CdDeviceAttributes.topElecHeat: null,
    CdDeviceAttributes.bottomElecHeat: null,
    CdDeviceAttributes.waterPump: null,
    CdDeviceAttributes.fourWay: null,
    CdDeviceAttributes.backWater: null,
    CdDeviceAttributes.sterilize: null,
    CdDeviceAttributes.disinfect: null,
    CdDeviceAttributes.topTemperature: null,
    CdDeviceAttributes.bottomTemperature: null,
    CdDeviceAttributes.wind: null,
    CdDeviceAttributes.smartGrid: null,
    CdDeviceAttributes.multiTerminal: null,
    CdDeviceAttributes.muteEffect: null,
    CdDeviceAttributes.muteStatus: null,
    CdDeviceAttributes.errorCode: null,
    CdDeviceAttributes.typeinfo: null,
    CdDeviceAttributes.vacationMode: false,
    CdDeviceAttributes.vacationDays: 0,
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
      final attrStr = attr;
      final hasAttr = _hasAttribute(message, attrStr);
      if (!hasAttr) continue;

      var rawValue = _getAttribute(message, attrStr);
      if (attr == CdDeviceAttributes.mode) {
        attrs[attr] = _modeMap[rawValue] ?? rawValue;
        newStatus[attrStr] = attrs[attr];
        continue;
      }

      if (_isTemperatureAttribute(attr)) {
        final isOutdoorTemp = attr == CdDeviceAttributes.outdoorTemperature;
        final isCurrentTemp = attr == CdDeviceAttributes.currentTemperature;
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
    return attr == CdDeviceAttributes.maxTemperature ||
        attr == CdDeviceAttributes.minTemperature ||
        attr == CdDeviceAttributes.targetTemperature ||
        attr == CdDeviceAttributes.currentTemperature ||
        attr == CdDeviceAttributes.outdoorTemperature ||
        attr == CdDeviceAttributes.condenserTemperature ||
        attr == CdDeviceAttributes.compressorTemperature;
  }

  bool _isDefensiveTempAttribute(String attr) {
    return attr == CdDeviceAttributes.maxTemperature ||
        attr == CdDeviceAttributes.minTemperature ||
        attr == CdDeviceAttributes.targetTemperature ||
        attr == CdDeviceAttributes.currentTemperature;
  }

  bool _forceFahrenheit(String attr, bool isOutdoorTemp) {
    return (model == 'RSJRAC06' || model == 'RSJRAC07') && isOutdoorTemp;
  }

  bool _forceOld(String attr, bool isCurrentTemp) {
    return (model == 'RSJRAC06' || model == 'RSJRAC07') && isCurrentTemp;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == CdDeviceAttributes.mode ||
        attr == CdDeviceAttributes.power ||
        attr == CdDeviceAttributes.targetTemperature ||
        attr == CdDeviceAttributes.vacationMode) {
      final message = MessageSet(messageProtocolVersion);
      message.fields = Map<String, dynamic>.from(_fields);
      message.useOldProtocol = _luaProtocol == LuaProtocol.old;

      final currentPower = attrs[CdDeviceAttributes.power] ?? false;
      final currentTemp = attrs[CdDeviceAttributes.targetTemperature];
      final currentMode = attrs[CdDeviceAttributes.mode];

      message.power = (currentPower as bool?) ?? false;

      if (currentTemp is num && currentTemp > 0) {
        message.targetTemperature = currentTemp.toDouble();
      } else {
        final minTemp = attrs[CdDeviceAttributes.minTemperature] ?? 35.0;
        message.targetTemperature = (minTemp as num?)?.toDouble() ?? 40.0;
      }

      if (currentMode == null || currentMode == 'None') {
        message.mode = 0x00;
      } else {
        message.mode =
            _getDictKeyBy_value(_modeMap, currentMode.toString()) ?? 0x00;
      }

      if (attr == CdDeviceAttributes.mode) {
        final modeKey = _getDictKeyBy_value(_modeMap, value.toString());
        if (modeKey == null) {
          return;
        }
        message.mode = modeKey;
      } else if (attr == CdDeviceAttributes.power) {
        message.power = value as bool;
      } else if (attr == CdDeviceAttributes.targetTemperature) {
        message.targetTemperature = (value as num).toDouble();
      } else if (attr == CdDeviceAttributes.vacationMode) {
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
      case CdDeviceAttributes.power:
        return msg.power != null;
      case CdDeviceAttributes.mode:
        return msg.mode != null;
      case CdDeviceAttributes.maxTemperature:
        return msg.maxTemperature != null;
      case CdDeviceAttributes.minTemperature:
        return msg.minTemperature != null;
      case CdDeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      case CdDeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case CdDeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature != null;
      case CdDeviceAttributes.condenserTemperature:
        return msg.condenserTemperature != null;
      case CdDeviceAttributes.compressorTemperature:
        return msg.compressorTemperature != null;
      case CdDeviceAttributes.compressorStatus:
        return msg.compressorStatus != null;
      case CdDeviceAttributes.waterLevel:
        return msg.waterLevel != null;
      case CdDeviceAttributes.fahrenheit:
        return msg.fahrenheit != null;
      case CdDeviceAttributes.heat:
        return msg.heat != null;
      case CdDeviceAttributes.dualHeat:
        return msg.dualHeat != null;
      case CdDeviceAttributes.elecHeat:
        return msg.elecHeat != null;
      case CdDeviceAttributes.topElecHeat:
        return msg.topElecHeat != null;
      case CdDeviceAttributes.bottomElecHeat:
        return msg.bottomElecHeat != null;
      case CdDeviceAttributes.waterPump:
        return msg.waterPump != null;
      case CdDeviceAttributes.fourWay:
        return msg.fourWay != null;
      case CdDeviceAttributes.backWater:
        return msg.backWater != null;
      case CdDeviceAttributes.sterilize:
        return msg.sterilize != null;
      case CdDeviceAttributes.disinfect:
        return msg.disinfect != null;
      case CdDeviceAttributes.topTemperature:
        return msg.topTemperature != null;
      case CdDeviceAttributes.bottomTemperature:
        return msg.bottomTemperature != null;
      case CdDeviceAttributes.wind:
        return msg.wind != null;
      case CdDeviceAttributes.smartGrid:
        return msg.smartGrid != null;
      case CdDeviceAttributes.multiTerminal:
        return msg.multiTerminal != null;
      case CdDeviceAttributes.muteEffect:
        return msg.muteEffect != null;
      case CdDeviceAttributes.muteStatus:
        return msg.muteStatus != null;
      case CdDeviceAttributes.errorCode:
        return msg.errorCode != null;
      case CdDeviceAttributes.typeinfo:
        return msg.typeinfo != null;
      case CdDeviceAttributes.vacationMode:
        return msg.vacationMode != null;
      case CdDeviceAttributes.vacationDays:
        return msg.vacationDays != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCDResponse msg, String attr) {
    switch (attr) {
      case CdDeviceAttributes.power:
        return msg.power;
      case CdDeviceAttributes.mode:
        return msg.mode;
      case CdDeviceAttributes.maxTemperature:
        return msg.maxTemperature;
      case CdDeviceAttributes.minTemperature:
        return msg.minTemperature;
      case CdDeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      case CdDeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case CdDeviceAttributes.outdoorTemperature:
        return msg.outdoorTemperature;
      case CdDeviceAttributes.condenserTemperature:
        return msg.condenserTemperature;
      case CdDeviceAttributes.compressorTemperature:
        return msg.compressorTemperature;
      case CdDeviceAttributes.compressorStatus:
        return msg.compressorStatus;
      case CdDeviceAttributes.waterLevel:
        return msg.waterLevel;
      case CdDeviceAttributes.fahrenheit:
        return msg.fahrenheit;
      case CdDeviceAttributes.heat:
        return msg.heat;
      case CdDeviceAttributes.dualHeat:
        return msg.dualHeat;
      case CdDeviceAttributes.elecHeat:
        return msg.elecHeat;
      case CdDeviceAttributes.topElecHeat:
        return msg.topElecHeat;
      case CdDeviceAttributes.bottomElecHeat:
        return msg.bottomElecHeat;
      case CdDeviceAttributes.waterPump:
        return msg.waterPump;
      case CdDeviceAttributes.fourWay:
        return msg.fourWay;
      case CdDeviceAttributes.backWater:
        return msg.backWater;
      case CdDeviceAttributes.sterilize:
        return msg.sterilize;
      case CdDeviceAttributes.disinfect:
        return msg.disinfect;
      case CdDeviceAttributes.topTemperature:
        return msg.topTemperature;
      case CdDeviceAttributes.bottomTemperature:
        return msg.bottomTemperature;
      case CdDeviceAttributes.wind:
        return msg.wind;
      case CdDeviceAttributes.smartGrid:
        return msg.smartGrid;
      case CdDeviceAttributes.multiTerminal:
        return msg.multiTerminal;
      case CdDeviceAttributes.muteEffect:
        return msg.muteEffect;
      case CdDeviceAttributes.muteStatus:
        return msg.muteStatus;
      case CdDeviceAttributes.errorCode:
        return msg.errorCode;
      case CdDeviceAttributes.typeinfo:
        return msg.typeinfo;
      case CdDeviceAttributes.vacationMode:
        return msg.vacationMode;
      case CdDeviceAttributes.vacationDays:
        return msg.vacationDays;
      default:
        return null;
    }
  }
}
