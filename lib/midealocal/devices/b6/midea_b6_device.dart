/// Midea local B6 device. Mirrors midealocal/devices/b6/__init__.py.

import 'dart:convert';
import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import 'message.dart';

class B6DeviceAttributes {
  static const String power = 'power';
  static const String light = 'light';
  static const String mode = 'mode';
  static const String fanLevel = 'fan_level';
  static const String fanSpeed = 'fan_speed';
  static const String oilCupFull = 'oilcup_full';
  static const String cleaningReminder = 'cleaning_reminder';
}

class MideaB6Device extends MideaDevice {
  MideaB6Device({
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
         deviceType: DeviceType.b6,
         deviceProtocol: deviceProtocol,
         attributes: {
           B6DeviceAttributes.power: false,
           B6DeviceAttributes.light: null,
           B6DeviceAttributes.mode: null,
           B6DeviceAttributes.fanLevel: 0,
           B6DeviceAttributes.fanSpeed: 0,
           B6DeviceAttributes.oilCupFull: false,
           B6DeviceAttributes.cleaningReminder: false,
         },
       ) {
    _defaultPowerSpeed = 2;
    _powerSpeed = _defaultPowerSpeed;
    _speeds = Map<int, String>.from(_defaultSpeeds);
    setCustomize(customize ?? '');
  }

  static final Map<int, String> _defaultSpeeds = {
    0: 'Off',
    1: 'Level 1',
    2: 'Level 2',
  };
  int _defaultPowerSpeed = 2;
  int _powerSpeed = 2;
  Map<int, String> _speeds = {};

  int get speedCount => _speeds.length - 1;

  List<String> get presetModes => _speeds.values.toList();

  @override
  List<MessageQuery> buildQuery() {
    return [MessageQuery(this.messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB6Response(msg);
    this.messageProtocolVersion = message.protocolVersion;
    final newStatus = <String, dynamic>{};
    for (final status in attrs.keys) {
      if (hasAttr(message, status)) {
        final value = getAttr(message, status);
        if (status == B6DeviceAttributes.fanLevel) {
          if (_speeds.containsKey(value)) {
            attrs[B6DeviceAttributes.mode] = _speeds[value];
            attrs[B6DeviceAttributes.fanSpeed] = _speeds.keys.toList().indexOf(
              value,
            );
          } else {
            attrs[B6DeviceAttributes.mode] = null;
            attrs[B6DeviceAttributes.fanSpeed] = 0;
          }
          newStatus[B6DeviceAttributes.mode] = attrs[B6DeviceAttributes.mode];
          newStatus[B6DeviceAttributes.fanSpeed] =
              attrs[B6DeviceAttributes.fanSpeed];
        }
        attrs[status] = value;
        newStatus[status] = attrs[status];
      }
    }
    return newStatus;
  }

  bool hasAttr(MessageB6Response msg, String attr) {
    switch (attr) {
      case B6DeviceAttributes.power:
        return msg.power != null;
      case B6DeviceAttributes.light:
        return msg.light != null;
      case B6DeviceAttributes.fanLevel:
        return msg.fanLevel != null;
      case B6DeviceAttributes.oilCupFull:
        return msg.oilCupFull != null;
      case B6DeviceAttributes.cleaningReminder:
        return msg.cleaningReminder != null;
      default:
        return false;
    }
  }

  dynamic getAttr(MessageB6Response msg, String attr) {
    switch (attr) {
      case B6DeviceAttributes.power:
        return msg.power;
      case B6DeviceAttributes.light:
        return msg.light;
      case B6DeviceAttributes.fanLevel:
        return msg.fanLevel;
      case B6DeviceAttributes.oilCupFull:
        return msg.oilCupFull;
      case B6DeviceAttributes.cleaningReminder:
        return msg.cleaningReminder;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    MessageSet? message;
    if (attr == B6DeviceAttributes.fanSpeed) {
      if (value < _speeds.length) {
        message = MessageSet(this.messageProtocolVersion);
        message.fanLevel = _speeds.keys.toList()[value];
      }
    } else if (attr == B6DeviceAttributes.mode) {
      if (_speeds.containsValue(value)) {
        message = MessageSet(this.messageProtocolVersion);
        message.fanLevel = _speeds.keys
            .toList()[_speeds.values.toList().indexOf(value)];
      } else if (!value) {
        message = MessageSet(this.messageProtocolVersion);
        message.power = false;
      }
    } else if (attr == B6DeviceAttributes.power) {
      message = MessageSet(this.messageProtocolVersion);
      message.power = value;
      message.fanLevel = _powerSpeed;
    } else if (attr == B6DeviceAttributes.light) {
      message = MessageSet(this.messageProtocolVersion);
      message.light = value;
    }
    if (message != null) {
      buildSend(message);
    }
  }

  void turnOn({int? fanSpeed, String? mode}) {
    final message = MessageSet(this.messageProtocolVersion);
    message.power = true;
    if (fanSpeed != null && fanSpeed < _speeds.length) {
      message.fanLevel = _speeds.keys.toList()[fanSpeed];
    } else {
      message.fanLevel = _powerSpeed;
    }
    if (mode != null && _speeds.containsValue(mode)) {
      message.fanLevel = _speeds.keys
          .toList()[_speeds.values.toList().indexOf(mode)];
    }
    buildSend(message);
  }

  void setCustomize(String customize) {
    _speeds = Map<int, String>.from(_defaultSpeeds);
    _powerSpeed = _defaultPowerSpeed;
    if (customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>;
        if (params.isNotEmpty) {
          if (params.containsKey('default_speed')) {
            _powerSpeed = params['default_speed'] as int;
          }
          if (params.containsKey('speeds')) {
            _speeds = {};
            final speedsRaw = params['speeds'] as Map<String, dynamic>;
            for (final entry in speedsRaw.entries) {
              _speeds[int.parse(entry.key)] = entry.value as String;
            }
            final keys = _speeds.keys.toList()..sort();
            _speeds = {for (var k in keys) k: _speeds[k]!};
          }
          updateAll({'speeds': _speeds, 'default_speed': _powerSpeed});
        }
      } catch (e) {
        // ignore errors
      }
    }
  }
}
