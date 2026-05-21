/// Midea local A1 device. Mirrors midealocal/devices/a1/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

class A1DeviceAttributes {
  static const String power = 'power';
  static const String promptTone = 'prompt_tone';
  static const String childLock = 'child_lock';
  static const String mode = 'mode';
  static const String fanSpeed = 'fan_speed';
  static const String swing = 'swing';
  static const String targetHumidity = 'target_humidity';
  static const String anion = 'anion';
  static const String tank = 'tank';
  static const String waterLevelSet = 'water_level_set';
  static const String tankFull = 'tank_full';
  static const String currentHumidity = 'current_humidity';
  static const String currentTemperature = 'current_temperature';
  static const String filterCleaningReminder = 'filter_cleaning_reminder';
}

class MideaA1Device extends MideaDevice {
  static const Map<int, String> _defaultModes = {
    1: 'Manual',
    2: 'Continuous',
    3: 'Auto',
    4: 'Clothes-Dry',
    5: 'Shoes-Dry',
  };

  static const Map<int, String> _defaultSpeeds = {
    1: 'Lowest',
    40: 'Low',
    60: 'Medium',
    80: 'High',
    102: 'Auto',
    127: 'Off',
  };

  static const List<String> _waterLevelSets = ['25', '50', '75', '100'];

  MideaA1Device({
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
         deviceType: DeviceType.a1,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _speeds = _defaultSpeeds;
    _modes = _defaultModes;
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  Map<int, String> _speeds = {};
  Map<int, String> _modes = {};

  List<String> get modes => _modes.values.toList();

  List<String> get fanSpeeds => _speeds.values.toList();

  List<String> get waterLevelSets => _waterLevelSets;

  static final Map<String, dynamic> _defaultAttributes = {
    A1DeviceAttributes.power: false,
    A1DeviceAttributes.promptTone: true,
    A1DeviceAttributes.childLock: false,
    A1DeviceAttributes.mode: null,
    A1DeviceAttributes.fanSpeed: 'Medium',
    A1DeviceAttributes.swing: false,
    A1DeviceAttributes.targetHumidity: 35,
    A1DeviceAttributes.anion: false,
    A1DeviceAttributes.tank: 0,
    A1DeviceAttributes.waterLevelSet: 50,
    A1DeviceAttributes.tankFull: null,
    A1DeviceAttributes.currentHumidity: null,
    A1DeviceAttributes.currentTemperature: null,
    A1DeviceAttributes.filterCleaningReminder: false,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageA1Response(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == A1DeviceAttributes.mode) {
          value = _modes[value] ?? value;
        } else if (attr == A1DeviceAttributes.fanSpeed) {
          value = _speeds[value] ?? value;
        } else if (attr == A1DeviceAttributes.waterLevelSet) {
          value = value != null ? value.toString() : null;
        }
        if (attr == A1DeviceAttributes.tankFull) {
          final tank = attrs[A1DeviceAttributes.tank] as int? ?? 0;
          final waterLevel =
              int.tryParse(attrs[A1DeviceAttributes.waterLevelSet].toString()) ??
              50;
          final tankFullCalculated = tank > 0 ? tank >= waterLevel : false;
          if (value == null || value != tankFullCalculated) {
            value = tankFullCalculated;
          }
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageA1Response msg, String attr) {
    switch (attr) {
      case A1DeviceAttributes.power:
        return msg.power != null;
      case A1DeviceAttributes.promptTone:
        return msg.promptTone != null;
      case A1DeviceAttributes.childLock:
        return msg.childLock != null;
      case A1DeviceAttributes.mode:
        return msg.mode != null;
      case A1DeviceAttributes.fanSpeed:
        return msg.fanSpeed != null;
      case A1DeviceAttributes.swing:
        return msg.swing != null;
      case A1DeviceAttributes.targetHumidity:
        return msg.targetHumidity != null;
      case A1DeviceAttributes.anion:
        return msg.anion != null;
      case A1DeviceAttributes.tank:
        return msg.tank != null;
      case A1DeviceAttributes.waterLevelSet:
        return msg.waterLevelSet != null;
      case A1DeviceAttributes.tankFull:
        return msg.tank != null;
      case A1DeviceAttributes.currentHumidity:
        return msg.currentHumidity != null;
      case A1DeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case A1DeviceAttributes.filterCleaningReminder:
        return msg.filterCleaningReminder != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageA1Response msg, String attr) {
    switch (attr) {
      case A1DeviceAttributes.power:
        return msg.power;
      case A1DeviceAttributes.promptTone:
        return msg.promptTone;
      case A1DeviceAttributes.childLock:
        return msg.childLock;
      case A1DeviceAttributes.mode:
        return msg.mode;
      case A1DeviceAttributes.fanSpeed:
        return msg.fanSpeed;
      case A1DeviceAttributes.swing:
        return msg.swing;
      case A1DeviceAttributes.targetHumidity:
        return msg.targetHumidity;
      case A1DeviceAttributes.anion:
        return msg.anion;
      case A1DeviceAttributes.tank:
        return msg.tank;
      case A1DeviceAttributes.waterLevelSet:
        return msg.waterLevelSet;
      case A1DeviceAttributes.tankFull:
        return msg.tank;
      case A1DeviceAttributes.currentHumidity:
        return msg.currentHumidity;
      case A1DeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case A1DeviceAttributes.filterCleaningReminder:
        return msg.filterCleaningReminder;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == A1DeviceAttributes.promptTone) {
      if (value is! bool) {
        throw MideaLocalError('[a1] Expected bool');
      }
      attrs[A1DeviceAttributes.promptTone] = value;
      updateAll({A1DeviceAttributes.promptTone: value});
      return;
    }

    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[A1DeviceAttributes.power] as bool? ?? false;
    message.promptTone = attrs[A1DeviceAttributes.promptTone] as bool? ?? true;
    message.childLock = attrs[A1DeviceAttributes.childLock] as bool? ?? false;

    final mode = attrs[A1DeviceAttributes.mode];
    if (mode != null && _modes.containsValue(mode.toString())) {
      for (final entry in _modes.entries) {
        if (entry.value == mode) {
          message.mode = entry.key;
          break;
        }
      }
    } else {
      message.mode = 1;
    }

    final fanSpeed = attrs[A1DeviceAttributes.fanSpeed];
    if (fanSpeed != null && _speeds.containsValue(fanSpeed.toString())) {
      for (final entry in _speeds.entries) {
        if (entry.value == fanSpeed) {
          message.fanSpeed = entry.key;
          break;
        }
      }
    } else {
      message.fanSpeed = 40;
    }

    message.targetHumidity =
        attrs[A1DeviceAttributes.targetHumidity] as int? ?? 35;
    message.swing = attrs[A1DeviceAttributes.swing] as bool? ?? false;
    message.anion = attrs[A1DeviceAttributes.anion] as bool? ?? false;

    final waterLevelStr = attrs[A1DeviceAttributes.waterLevelSet]?.toString();
    if (waterLevelStr != null && _waterLevelSets.contains(waterLevelStr)) {
      message.waterLevelSet = int.tryParse(waterLevelStr) ?? 50;
    } else {
      message.waterLevelSet = 50;
    }

    if (attr == A1DeviceAttributes.mode && value != null) {
      if (_modes.containsValue(value.toString())) {
        for (final entry in _modes.entries) {
          if (entry.value == value) {
            message.mode = entry.key;
            break;
          }
        }
      }
    } else if (attr == A1DeviceAttributes.fanSpeed && value != null) {
      if (_speeds.containsValue(value.toString())) {
        for (final entry in _speeds.entries) {
          if (entry.value == value) {
            message.fanSpeed = entry.key;
            break;
          }
        }
      }
    } else if (attr == A1DeviceAttributes.waterLevelSet && value != null) {
      if (_waterLevelSets.contains(value.toString())) {
        message.waterLevelSet = int.tryParse(value.toString()) ?? 50;
      }
    } else {
      switch (attr) {
        case A1DeviceAttributes.power:
          if (value is bool) message.power = value;
          break;
        case A1DeviceAttributes.promptTone:
          if (value is bool) message.promptTone = value;
          break;
        case A1DeviceAttributes.childLock:
          if (value is bool) message.childLock = value;
          break;
        case A1DeviceAttributes.targetHumidity:
          if (value is int) message.targetHumidity = value;
          break;
        case A1DeviceAttributes.swing:
          if (value is bool) message.swing = value;
          break;
        case A1DeviceAttributes.anion:
          if (value is bool) message.anion = value;
          break;
      }
    }

    buildSend(message);
  }

  void setCustomize(String customize) {
    _speeds = Map<int, String>.from(_defaultSpeeds);
    _modes = Map<int, String>.from(_defaultModes);

    if (customize.isEmpty) return;

    try {
      final params = json.decode(customize) as Map<String, dynamic>;
      if (params.isEmpty) return;

      if (params.containsKey('speeds')) {
        final speedsData = params['speeds'] as Map<String, dynamic>;
        _speeds = {};
        for (final entry in speedsData.entries) {
          _speeds[int.parse(entry.key)] = entry.value.toString();
        }
        final sortedKeys = _speeds.keys.toList()..sort();
        final sortedSpeeds = <int, String>{};
        for (final k in sortedKeys) {
          sortedSpeeds[k] = _speeds[k]!;
        }
        _speeds = sortedSpeeds;
      }

      if (params.containsKey('modes')) {
        final modesData = params['modes'] as Map<String, dynamic>;
        _modes = {};
        for (final entry in modesData.entries) {
          _modes[int.parse(entry.key)] = entry.value.toString();
        }
        final sortedKeys = _modes.keys.toList()..sort();
        final sortedModes = <int, String>{};
        for (final k in sortedKeys) {
          sortedModes[k] = _modes[k]!;
        }
        _modes = sortedModes;
      }
    } catch (_) {}
  }
}
