/// Midea local A1 device. Mirrors midealocal/devices/a1/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
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
         attributes: _defaultAttributes,
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
    DeviceAttributes.power: false,
    DeviceAttributes.promptTone: true,
    DeviceAttributes.childLock: false,
    DeviceAttributes.mode: null,
    DeviceAttributes.fanSpeed: 'Medium',
    DeviceAttributes.swing: false,
    DeviceAttributes.targetHumidity: 35,
    DeviceAttributes.anion: false,
    DeviceAttributes.tank: 0,
    DeviceAttributes.waterLevelSet: 50,
    DeviceAttributes.tankFull: null,
    DeviceAttributes.currentHumidity: null,
    DeviceAttributes.currentTemperature: null,
    DeviceAttributes.filterCleaningReminder: false,
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
        if (attr == DeviceAttributes.mode) {
          value = _modes[value] ?? value;
        } else if (attr == DeviceAttributes.fanSpeed) {
          value = _speeds[value] ?? value;
        } else if (attr == DeviceAttributes.waterLevelSet) {
          value = value != null ? value.toString() : null;
        }
        if (attr == DeviceAttributes.tankFull) {
          final tank = attrs[DeviceAttributes.tank] as int? ?? 0;
          final waterLevel =
              int.tryParse(attrs[DeviceAttributes.waterLevelSet].toString()) ??
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
      case DeviceAttributes.power:
        return msg.power != null;
      case DeviceAttributes.promptTone:
        return msg.promptTone != null;
      case DeviceAttributes.childLock:
        return msg.childLock != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.fanSpeed:
        return msg.fanSpeed != null;
      case DeviceAttributes.swing:
        return msg.swing != null;
      case DeviceAttributes.targetHumidity:
        return msg.targetHumidity != null;
      case DeviceAttributes.anion:
        return msg.anion != null;
      case DeviceAttributes.tank:
        return msg.tank != null;
      case DeviceAttributes.waterLevelSet:
        return msg.waterLevelSet != null;
      case DeviceAttributes.tankFull:
        return msg.tank != null;
      case DeviceAttributes.currentHumidity:
        return msg.currentHumidity != null;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case DeviceAttributes.filterCleaningReminder:
        return msg.filterCleaningReminder != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageA1Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power;
      case DeviceAttributes.promptTone:
        return msg.promptTone;
      case DeviceAttributes.childLock:
        return msg.childLock;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.fanSpeed:
        return msg.fanSpeed;
      case DeviceAttributes.swing:
        return msg.swing;
      case DeviceAttributes.targetHumidity:
        return msg.targetHumidity;
      case DeviceAttributes.anion:
        return msg.anion;
      case DeviceAttributes.tank:
        return msg.tank;
      case DeviceAttributes.waterLevelSet:
        return msg.waterLevelSet;
      case DeviceAttributes.tankFull:
        return msg.tank;
      case DeviceAttributes.currentHumidity:
        return msg.currentHumidity;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case DeviceAttributes.filterCleaningReminder:
        return msg.filterCleaningReminder;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.promptTone) {
      if (value is! bool) {
        throw MideaLocalError('[a1] Expected bool');
      }
      attrs[DeviceAttributes.promptTone] = value;
      updateAll({DeviceAttributes.promptTone: value});
      return;
    }

    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[DeviceAttributes.power] as bool? ?? false;
    message.promptTone = attrs[DeviceAttributes.promptTone] as bool? ?? true;
    message.childLock = attrs[DeviceAttributes.childLock] as bool? ?? false;

    final mode = attrs[DeviceAttributes.mode];
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

    final fanSpeed = attrs[DeviceAttributes.fanSpeed];
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
        attrs[DeviceAttributes.targetHumidity] as int? ?? 35;
    message.swing = attrs[DeviceAttributes.swing] as bool? ?? false;
    message.anion = attrs[DeviceAttributes.anion] as bool? ?? false;

    final waterLevelStr = attrs[DeviceAttributes.waterLevelSet]?.toString();
    if (waterLevelStr != null && _waterLevelSets.contains(waterLevelStr)) {
      message.waterLevelSet = int.tryParse(waterLevelStr) ?? 50;
    } else {
      message.waterLevelSet = 50;
    }

    if (attr == DeviceAttributes.mode && value != null) {
      if (_modes.containsValue(value.toString())) {
        for (final entry in _modes.entries) {
          if (entry.value == value) {
            message.mode = entry.key;
            break;
          }
        }
      }
    } else if (attr == DeviceAttributes.fanSpeed && value != null) {
      if (_speeds.containsValue(value.toString())) {
        for (final entry in _speeds.entries) {
          if (entry.value == value) {
            message.fanSpeed = entry.key;
            break;
          }
        }
      }
    } else if (attr == DeviceAttributes.waterLevelSet && value != null) {
      if (_waterLevelSets.contains(value.toString())) {
        message.waterLevelSet = int.tryParse(value.toString()) ?? 50;
      }
    } else {
      switch (attr) {
        case DeviceAttributes.power:
          if (value is bool) message.power = value;
          break;
        case DeviceAttributes.promptTone:
          if (value is bool) message.promptTone = value;
          break;
        case DeviceAttributes.childLock:
          if (value is bool) message.childLock = value;
          break;
        case DeviceAttributes.targetHumidity:
          if (value is int) message.targetHumidity = value;
          break;
        case DeviceAttributes.swing:
          if (value is bool) message.swing = value;
          break;
        case DeviceAttributes.anion:
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
