import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String power = 'power';
  static const String childLock = 'child_lock';
  static const String mode = 'mode';
  static const String fanSpeed = 'fan_speed';
  static const String oscillate = 'oscillate';
  static const String oscillationAngle = 'oscillation_angle';
  static const String tiltingAngle = 'tilting_angle';
  static const String oscillationMode = 'oscillation_mode';
}

class MideaFADevice extends MideaDevice {
  static const List<String> oscillationAngles = [
    'Off',
    '30',
    '60',
    '90',
    '120',
    '180',
    '360',
  ];
  static const List<String> tiltingAngles = [
    'Off',
    '30',
    '60',
    '90',
    '120',
    '180',
    '360',
    '+60',
    '-60',
    '40',
  ];
  static const List<String> oscillationModes = [
    'Off',
    'Oscillation',
    'Tilting',
    'Curve-W',
    'Curve-8',
    'Reserved',
    'Both',
  ];
  static const List<String> modes = [
    'Normal',
    'Natural',
    'Sleep',
    'Comfort',
    'Silent',
    'Baby',
    'Induction',
    'Circulation',
    'Strong',
    'Soft',
    'Customize',
    'Warm',
    'Smart',
  ];

  int _speedCount = 3;

  MideaFADevice({
    required String name,
    required int deviceId,
    required String ipAddress,
    required int port,
    required String token,
    required String key,
    required ProtocolVersion deviceProtocol,
    required String model,
    required int subtype,
    required String customize,
  }) : super(
         name: name,
         deviceId: deviceId,
         deviceType: DeviceType.fa,
         ipAddress: ipAddress,
         port: port,
         token: token,
         key: key,
         deviceProtocol: deviceProtocol,
         model: model,
         subtype: subtype,
         attributes: {
           DeviceAttributes.power: false,
           DeviceAttributes.childLock: false,
           DeviceAttributes.mode: 0,
           DeviceAttributes.fanSpeed: 0,
           DeviceAttributes.oscillate: false,
           DeviceAttributes.oscillationAngle: null,
           DeviceAttributes.tiltingAngle: null,
           DeviceAttributes.oscillationMode: null,
         },
       ) {
    setCustomize(customize);
  }

  int get speedCount => _speedCount;

  List<String> get oscillationAnglesList => oscillationAngles;

  List<String> get tiltingAnglesList => tiltingAngles;

  List<String> get oscillationModesList => oscillationModes;

  List<String> get presetModesList => modes;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageFAResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      final value = _getAttribute(message, status);
      if (status == DeviceAttributes.oscillationAngle) {
        if (value < oscillationAngles.length) {
          attrs[status] = oscillationAngles[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == DeviceAttributes.tiltingAngle) {
        if (value < tiltingAngles.length) {
          attrs[status] = tiltingAngles[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == DeviceAttributes.oscillationMode) {
        if (value < oscillationModes.length) {
          attrs[status] = oscillationModes[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == DeviceAttributes.mode) {
        if (value < modes.length) {
          attrs[status] = modes[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == DeviceAttributes.power) {
        attrs[status] = value;
        if (!value) {
          attrs[DeviceAttributes.fanSpeed] = 0;
        }
      } else if (status == DeviceAttributes.fanSpeed &&
          !(attrs[DeviceAttributes.power] as bool)) {
        attrs[status] = 0;
      } else {
        attrs[status] = value;
      }
      newStatus[status] = attrs[status];
    }
    return newStatus;
  }

  dynamic _getAttribute(MessageFAResponse message, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return message.power;
      case DeviceAttributes.childLock:
        return message.childLock;
      case DeviceAttributes.mode:
        return message.mode;
      case DeviceAttributes.fanSpeed:
        return message.fanSpeed;
      case DeviceAttributes.oscillate:
        return message.oscillate;
      case DeviceAttributes.oscillationAngle:
        return message.oscillationAngle;
      case DeviceAttributes.oscillationMode:
        return message.oscillationMode;
      case DeviceAttributes.tiltingAngle:
        return message.tiltingAngle;
      default:
        return null;
    }
  }

  void _setOscillationMode(MessageSet message, String value) {
    if (value == 'Off' || value.isEmpty) {
      message.oscillate = false;
    } else {
      message.oscillate = true;
      message.oscillationMode = oscillationModes.indexOf(value);
      if (value == 'Oscillation') {
        if (attrs[DeviceAttributes.oscillationAngle] == 'Off') {
          message.oscillationAngle = 3;
        } else {
          message.oscillationAngle = oscillationAngles.indexOf(
            attrs[DeviceAttributes.oscillationAngle] as String,
          );
        }
      } else if (value == 'Tilting') {
        if (attrs[DeviceAttributes.tiltingAngle] == 'Off') {
          message.tiltingAngle = 3;
        } else {
          message.tiltingAngle = tiltingAngles.indexOf(
            attrs[DeviceAttributes.tiltingAngle] as String,
          );
        }
      } else {
        if (attrs[DeviceAttributes.oscillationAngle] == 'Off') {
          message.oscillationAngle = 3;
        } else {
          message.oscillationAngle = oscillationAngles.indexOf(
            attrs[DeviceAttributes.oscillationAngle] as String,
          );
        }
        if (attrs[DeviceAttributes.tiltingAngle] == 'Off') {
          message.tiltingAngle = 3;
        } else {
          message.tiltingAngle = tiltingAngles.indexOf(
            attrs[DeviceAttributes.tiltingAngle] as String,
          );
        }
      }
    }
  }

  void _setOscillationAngle(MessageSet message, String value) {
    if (value == 'Off' || value.isEmpty) {
      if (attrs[DeviceAttributes.tiltingAngle] == 'Off') {
        message.oscillate = false;
      } else {
        message.oscillate = true;
        message.oscillationMode = 2;
        message.tiltingAngle = tiltingAngles.indexOf(
          attrs[DeviceAttributes.tiltingAngle] as String,
        );
      }
    } else {
      message.oscillationAngle = oscillationAngles.indexOf(value);
      message.oscillate = true;
      if (attrs[DeviceAttributes.tiltingAngle] == 'Off') {
        message.oscillationMode = 1;
      } else if (attrs[DeviceAttributes.oscillationMode] == 'Tilting') {
        message.oscillationMode = 6;
        message.tiltingAngle = tiltingAngles.indexOf(
          attrs[DeviceAttributes.tiltingAngle] as String,
        );
      }
    }
  }

  void _setTiltingAngle(MessageSet message, String value) {
    if (value == 'Off' || value.isEmpty) {
      if (attrs[DeviceAttributes.oscillationAngle] == 'Off') {
        message.oscillate = false;
      } else {
        message.oscillate = true;
        message.oscillationMode = 1;
        message.oscillationAngle = oscillationAngles.indexOf(
          attrs[DeviceAttributes.oscillationAngle] as String,
        );
      }
    } else {
      message.tiltingAngle = tiltingAngles.indexOf(value);
      message.oscillate = true;
      if (attrs[DeviceAttributes.oscillationAngle] == 'Off') {
        message.oscillationMode = 2;
      } else if (attrs[DeviceAttributes.oscillationMode] == 'Oscillation') {
        message.oscillationMode = 6;
        message.oscillationAngle = oscillationAngles.indexOf(
          attrs[DeviceAttributes.oscillationAngle] as String,
        );
      }
    }
  }

  MessageSet? setOscillation(String attr, dynamic value) {
    MessageSet? message;
    if (attrs[attr] != value) {
      if (attr == DeviceAttributes.oscillate) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        message.oscillate = value as bool;
        if (value) {
          message.oscillationAngle = 3;
          message.oscillationMode = 1;
        }
      } else if (attr == DeviceAttributes.oscillationMode &&
          (oscillationModes.contains(value) || value.toString().isEmpty)) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        _setOscillationMode(message, value.toString());
      } else if (attr == DeviceAttributes.oscillationAngle &&
          (oscillationAngles.contains(value) || value.toString().isEmpty)) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        _setOscillationAngle(message, value.toString());
      } else if (attr == DeviceAttributes.tiltingAngle &&
          (tiltingAngles.contains(value) || value.toString().isEmpty)) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        _setTiltingAngle(message, value.toString());
      }
    }
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    MessageSet? message;
    if ([
      DeviceAttributes.oscillate,
      DeviceAttributes.oscillationMode,
      DeviceAttributes.oscillationAngle,
      DeviceAttributes.tiltingAngle,
    ].contains(attr)) {
      message = setOscillation(attr, value);
    } else if (attr == DeviceAttributes.fanSpeed &&
        value > 0 &&
        !(attrs[DeviceAttributes.power] as bool)) {
      message = MessageSet(
        protocolVersion: messageProtocolVersion,
        subtype: subtype,
      );
      message.fanSpeed = value as int;
      message.power = true;
    } else if (attr == DeviceAttributes.mode) {
      final modeVal = modes.indexOf(value.toString());
      if (modeVal >= 0) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        message.mode = modeVal;
      }
    } else if (!(attr == DeviceAttributes.fanSpeed && value == 0)) {
      message = MessageSet(
        protocolVersion: messageProtocolVersion,
        subtype: subtype,
      );
      _setAttr(message, attr, value);
    }
    if (message != null) {
      buildSend(message);
    }
  }

  void _setAttr(MessageSet message, String attr, dynamic value) {
    switch (attr) {
      case DeviceAttributes.power:
        message.power = value as bool;
        break;
      case DeviceAttributes.childLock:
        message.lock = value as bool;
        break;
      case DeviceAttributes.fanSpeed:
        message.fanSpeed = value as int;
        break;
      default:
        break;
    }
  }

  void turnOn({int? fanSpeed, String? mode}) {
    final message = MessageSet(
      protocolVersion: messageProtocolVersion,
      subtype: subtype,
    );
    message.power = true;
    if (fanSpeed != null) {
      message.fanSpeed = fanSpeed;
    }
    if (mode != null) {
      final modeIndex = modes.indexOf(mode);
      if (modeIndex >= 0) {
        message.mode = modeIndex;
      }
    }
    buildSend(message);
  }

  void setCustomize(String customize) {
    _speedCount = 3;
    if (customize.isNotEmpty) {
      try {
        final params = jsonDecode(customize) as Map<String, dynamic>;
        if (params.containsKey('speed_count')) {
          _speedCount = params['speed_count'] as int;
        }
      } catch (_) {}
    }
    updateAll({'speed_count': _speedCount});
  }
}

class MideaAppliance extends MideaFADevice {
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
    required String customize,
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
