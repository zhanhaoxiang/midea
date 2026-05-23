/// Midea local FC device. Mirrors midealocal/devices/fc/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

const int standbyDetectLength = 2;

class FcDeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String fanSpeed = 'fan_speed';
  static const String anion = 'anion';
  static const String screenDisplay = 'screen_display';
  static const String detectMode = 'detect_mode';
  static const String pm25 = 'pm25';
  static const String tvoc = 'tvoc';
  static const String hcho = 'hcho';
  static const String childLock = 'child_lock';
  static const String promptTone = 'prompt_tone';
  static const String filter1Life = 'filter1_life';
  static const String filter2Life = 'filter2_life';
  static const String standby = 'standby';
}

class MideaFCDevice extends MideaDevice {
  MideaFCDevice({
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
         deviceType: DeviceType.fc,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _standbyDetect = List<int>.from(_standbyDetectDefault);
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const Map<int, String> _modes = {
    0x00: 'Standby',
    0x10: 'Auto',
    0x20: 'Manual',
    0x30: 'Sleep',
    0x40: 'Fast',
    0x50: 'Smoke',
  };

  static const Map<int, String> _speeds = {
    1: 'Auto',
    4: 'Standby',
    39: 'Low',
    59: 'Medium',
    80: 'High',
  };

  static const Map<int, String> _screenDisplays = {
    0: 'Bright',
    6: 'Dim',
    7: 'Off',
  };

  static const List<String> _detectModes = ['Off', 'PM 2.5', 'Methanal'];

  static final Map<String, dynamic> _defaultAttributes = {
    FcDeviceAttributes.power: false,
    FcDeviceAttributes.mode: null,
    FcDeviceAttributes.fanSpeed: null,
    FcDeviceAttributes.anion: false,
    FcDeviceAttributes.standby: false,
    FcDeviceAttributes.screenDisplay: null,
    FcDeviceAttributes.detectMode: null,
    FcDeviceAttributes.pm25: null,
    FcDeviceAttributes.tvoc: null,
    FcDeviceAttributes.hcho: null,
    FcDeviceAttributes.childLock: false,
    FcDeviceAttributes.promptTone: true,
    FcDeviceAttributes.filter1Life: null,
    FcDeviceAttributes.filter2Life: null,
  };

  static const List<int> _standbyDetectDefault = [40, 20];

  List<int> _standbyDetect = List<int>.from(_standbyDetectDefault);

  List<String> get modes => _modes.values.toList();

  List<String> get fanSpeeds => _speeds.values.toList();

  List<String> get screenDisplays => _screenDisplays.values.toList();

  List<String> get detectModes => _detectModes;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageFCResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      if (message.hasAttribute(status)) {
        var value = message.getAttribute(status);
        if (status == FcDeviceAttributes.mode) {
          if (value != null && _modes.containsKey(value)) {
            attrs[status] = _modes[value];
          } else {
            attrs[status] = null;
          }
        } else if (status == FcDeviceAttributes.fanSpeed) {
          if (value != null && _speeds.containsKey(value)) {
            attrs[status] = _speeds[value];
          } else {
            attrs[status] = null;
          }
        } else if (status == FcDeviceAttributes.screenDisplay) {
          if (value != null && _screenDisplays.containsKey(value)) {
            attrs[status] = _screenDisplays[value];
          } else {
            attrs[status] = null;
          }
        } else if (status == FcDeviceAttributes.detectMode) {
          if (value != null && value is int && value < _detectModes.length) {
            attrs[status] = _detectModes[value];
          } else {
            attrs[status] = null;
          }
        } else {
          attrs[status] = value;
        }
        newStatus[status] = attrs[status];
      }
    }
    return newStatus;
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[FcDeviceAttributes.power] as bool? ?? false;
    message.childLock = attrs[FcDeviceAttributes.childLock] as bool? ?? false;
    message.promptTone = attrs[FcDeviceAttributes.promptTone] as bool? ?? true;
    message.anion = attrs[FcDeviceAttributes.anion] as bool? ?? false;
    message.standby = attrs[FcDeviceAttributes.standby] as bool? ?? false;
    message.screenDisplay = _getScreenDisplayValue();
    message.detectMode = _getDetectModeValue();
    message.mode = _getModeValue();
    message.fanSpeed = _getFanSpeedValue();
    message.standbyDetect = _standbyDetect;
    return message;
  }

  int _getScreenDisplayValue() {
    final display = attrs[FcDeviceAttributes.screenDisplay];
    if (display == null) return 0;
    for (final entry in _screenDisplays.entries) {
      if (entry.value == display) return entry.key;
    }
    return 0;
  }

  int _getDetectModeValue() {
    final modeVal = attrs[FcDeviceAttributes.detectMode];
    if (modeVal == null) return 0;
    return _detectModes.indexOf(modeVal as String);
  }

  int _getModeValue() {
    final modeVal = attrs[FcDeviceAttributes.mode];
    if (modeVal == null) return 0x10;
    for (final entry in _modes.entries) {
      if (entry.value == modeVal) return entry.key;
    }
    return 0x10;
  }

  int _getFanSpeedValue() {
    final speedVal = attrs[FcDeviceAttributes.fanSpeed];
    if (speedVal == null) return 39;
    for (final entry in _speeds.entries) {
      if (entry.value == speedVal) return entry.key;
    }
    return 39;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == FcDeviceAttributes.promptTone) {
      attrs[FcDeviceAttributes.promptTone] = value;
      updateAll({FcDeviceAttributes.promptTone: value});
      return;
    }

    final message = makeMessageSet();

    if (attr == FcDeviceAttributes.mode) {
      if (value != null) {
        message.mode = _getModeFromValue(value);
      }
    } else if (attr == FcDeviceAttributes.fanSpeed) {
      if (value != null) {
        message.fanSpeed = _getSpeedFromValue(value);
      }
    } else if (attr == FcDeviceAttributes.screenDisplay) {
      if (value != null) {
        message.screenDisplay = _getScreenDisplayKey(value);
      } else {
        message.screenDisplay = 7;
      }
    } else if (attr == FcDeviceAttributes.detectMode) {
      if (value != null) {
        message.detectMode = _detectModes.indexOf(value as String);
      } else {
        message.detectMode = 0;
      }
    } else {
      if (attr == FcDeviceAttributes.power) {
        message.power = value as bool? ?? false;
      } else if (attr == FcDeviceAttributes.childLock) {
        message.childLock = value as bool? ?? false;
      } else if (attr == FcDeviceAttributes.anion) {
        message.anion = value as bool? ?? false;
      } else if (attr == FcDeviceAttributes.standby) {
        message.standby = value as bool? ?? false;
      }
    }
    buildSend(message);
  }

  int _getModeFromValue(dynamic value) {
    final val = value.toString();
    for (final entry in _modes.entries) {
      if (entry.value == val) return entry.key;
    }
    return 0x10;
  }

  int _getSpeedFromValue(dynamic value) {
    final val = value.toString();
    for (final entry in _speeds.entries) {
      if (entry.value == val) return entry.key;
    }
    return 39;
  }

  int _getScreenDisplayKey(dynamic value) {
    final val = value.toString();
    for (final entry in _screenDisplays.entries) {
      if (entry.value == val) return entry.key;
    }
    return 0;
  }

  void setCustomize(String customize) {
    _standbyDetect = List<int>.from(_standbyDetectDefault);
    if (customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>?;
        if (params != null && params.containsKey('standby_detect')) {
          final settings = params['standby_detect'] as List<dynamic>?;
          if (settings != null &&
              settings.length == standbyDetectLength &&
              (settings[0] as int) > (settings[1] as int)) {
            _standbyDetect = settings.cast<int>();
          }
        }
      } catch (_) {}
      updateAll({'standby_detect': _standbyDetect});
    }
  }
}

typedef MideaAppliance = MideaFCDevice;
