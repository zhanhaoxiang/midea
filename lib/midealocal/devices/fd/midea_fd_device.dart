/// Midea local FD device. Mirrors midealocal/devices/fd/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

const int maxSubtypeOldSpeeds = 5;

class FdDeviceAttributes {
  static const String power = 'power';
  static const String fanSpeed = 'fan_speed';
  static const String promptTone = 'prompt_tone';
  static const String targetHumidity = 'target_humidity';
  static const String currentHumidity = 'current_humidity';
  static const String currentTemperature = 'current_temperature';
  static const String tank = 'tank';
  static const String mode = 'mode';
  static const String screenDisplay = 'screen_display';
  static const String disinfect = 'disinfect';
}

class MideaFDDevice extends MideaDevice {
  MideaFDDevice({
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
         deviceType: DeviceType.fd,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    if (subtype > maxSubtypeOldSpeeds) {
      _speeds = _speedsNew;
    } else {
      _speeds = _speedsOld;
    }
  }

  static const List<String> _modes = [
    'Manual',
    'Auto',
    'Continuous',
    'Living-Room',
    'Bed-Room',
    'Kitchen',
    'Sleep',
  ];

  static const Map<int, String> _speedsOld = {
    1: 'Lowest',
    40: 'Low',
    60: 'Medium',
    80: 'High',
    102: 'Auto',
    127: 'Off',
  };

  static const Map<int, String> _speedsNew = {
    1: 'Lowest',
    39: 'Low',
    59: 'Medium',
    80: 'High',
    101: 'Auto',
    127: 'Off',
  };

  static const Map<int, String> _screenDisplays = {
    0: 'Bright',
    6: 'Dim',
    7: 'Off',
  };

  static const List<String> _detectModes = ['Off', 'PM 2.5', 'Methanal'];

  static final Map<String, dynamic> _defaultAttributes = {
    FdDeviceAttributes.power: false,
    FdDeviceAttributes.fanSpeed: null,
    FdDeviceAttributes.promptTone: true,
    FdDeviceAttributes.targetHumidity: 60,
    FdDeviceAttributes.currentHumidity: null,
    FdDeviceAttributes.currentTemperature: null,
    FdDeviceAttributes.tank: 0,
    FdDeviceAttributes.mode: null,
    FdDeviceAttributes.screenDisplay: null,
    FdDeviceAttributes.disinfect: null,
  };

  late Map<int, String> _speeds;

  List<String> get modes => _modes;

  List<String> get fanSpeeds => _speeds.values.toList();

  List<String> get screenDisplays => _screenDisplays.values.toList();

  List<String> get detectModes => _detectModes;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageFDResponse(msg);
    final newStatus = <String, dynamic>{};
    for (final status in attrs.keys) {
      if (status == FdDeviceAttributes.mode) {
        final value = message.mode;
        if (value != null && value <= _modes.length) {
          attrs[status] = _modes[value - 1];
        } else {
          attrs[status] = null;
        }
      } else if (status == FdDeviceAttributes.fanSpeed) {
        final value = message.fanSpeed;
        if (value != null && _speeds.containsKey(value)) {
          attrs[status] = _speeds[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == FdDeviceAttributes.screenDisplay) {
        final value = message.screenDisplay;
        if (value != null && _screenDisplays.containsKey(value)) {
          attrs[status] = _screenDisplays[value];
        } else {
          attrs[status] = null;
        }
      } else {
        final value = _getMessageValue(message, status);
        attrs[status] = value;
      }
      newStatus[status] = attrs[status];
    }
    return newStatus;
  }

  dynamic _getMessageValue(MessageFDResponse message, String status) {
    switch (status) {
      case FdDeviceAttributes.power:
        return message.power;
      case FdDeviceAttributes.fanSpeed:
        return message.fanSpeed;
      case FdDeviceAttributes.promptTone:
        return true;
      case FdDeviceAttributes.targetHumidity:
        return message.targetHumidity;
      case FdDeviceAttributes.currentHumidity:
        return message.currentHumidity;
      case FdDeviceAttributes.currentTemperature:
        return message.currentTemperature;
      case FdDeviceAttributes.tank:
        return message.tank;
      case FdDeviceAttributes.mode:
        return message.mode;
      case FdDeviceAttributes.screenDisplay:
        return message.screenDisplay;
      case FdDeviceAttributes.disinfect:
        return message.disinfect;
      default:
        return null;
    }
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    final power = attrs[FdDeviceAttributes.power];
    if (power != null) message.power = power as bool;
    final promptTone = attrs[FdDeviceAttributes.promptTone];
    if (promptTone != null) message.promptTone = promptTone as bool;
    final screenDisplayAttr = attrs[FdDeviceAttributes.screenDisplay];
    if (screenDisplayAttr != null &&
        _screenDisplays.containsValue(screenDisplayAttr as String)) {
      message.screenDisplay = _screenDisplays.keys.firstWhere(
        (k) => _screenDisplays[k] == screenDisplayAttr,
      );
    }
    final disinfect = attrs[FdDeviceAttributes.disinfect];
    if (disinfect != null) message.disinfect = disinfect as bool?;
    final mode = attrs[FdDeviceAttributes.mode];
    if (mode != null && _modes.contains(mode)) {
      message.mode = _modes.indexOf(mode as String) + 1;
    } else {
      message.mode = 1;
    }
    final fanSpeed = attrs[FdDeviceAttributes.fanSpeed];
    if (fanSpeed != null && _speeds.containsValue(fanSpeed as String)) {
      message.fanSpeed = _speeds.keys.firstWhere((k) => _speeds[k] == fanSpeed);
    } else {
      message.fanSpeed = 40;
    }
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == FdDeviceAttributes.promptTone) {
      attrs[FdDeviceAttributes.promptTone] = value;
      updateAll({FdDeviceAttributes.promptTone: value});
    } else {
      final message = makeMessageSet();
      if (attr == FdDeviceAttributes.mode) {
        if (_modes.contains(value)) {
          message.mode = _modes.indexOf(value as String) + 1;
        }
      } else if (attr == FdDeviceAttributes.fanSpeed) {
        if (_speeds.containsValue(value)) {
          message.fanSpeed = _speeds.keys.firstWhere(
            (k) => _speeds[k] == value,
          );
        }
      } else if (attr == FdDeviceAttributes.screenDisplay) {
        if (_screenDisplays.containsValue(value)) {
          message.screenDisplay = _screenDisplays.keys.firstWhere(
            (k) => _screenDisplays[k] == value,
          );
        } else if (value == false || value == 0) {
          message.screenDisplay = 7;
        }
      }
      buildSend(message);
    }
  }
}
