import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class FaDeviceAttributes {
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
           FaDeviceAttributes.power: false,
           FaDeviceAttributes.childLock: false,
           FaDeviceAttributes.mode: 0,
           FaDeviceAttributes.fanSpeed: 0,
           FaDeviceAttributes.oscillate: false,
           FaDeviceAttributes.oscillationAngle: null,
           FaDeviceAttributes.tiltingAngle: null,
           FaDeviceAttributes.oscillationMode: null,
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
      if (status == FaDeviceAttributes.oscillationAngle) {
        if (value < oscillationAngles.length) {
          attrs[status] = oscillationAngles[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == FaDeviceAttributes.tiltingAngle) {
        if (value < tiltingAngles.length) {
          attrs[status] = tiltingAngles[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == FaDeviceAttributes.oscillationMode) {
        if (value < oscillationModes.length) {
          attrs[status] = oscillationModes[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == FaDeviceAttributes.mode) {
        if (value < modes.length) {
          attrs[status] = modes[value];
        } else {
          attrs[status] = null;
        }
      } else if (status == FaDeviceAttributes.power) {
        attrs[status] = value;
        if (!value) {
          attrs[FaDeviceAttributes.fanSpeed] = 0;
        }
      } else if (status == FaDeviceAttributes.fanSpeed &&
          !(attrs[FaDeviceAttributes.power] as bool)) {
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
      case FaDeviceAttributes.power:
        return message.power;
      case FaDeviceAttributes.childLock:
        return message.childLock;
      case FaDeviceAttributes.mode:
        return message.mode;
      case FaDeviceAttributes.fanSpeed:
        return message.fanSpeed;
      case FaDeviceAttributes.oscillate:
        return message.oscillate;
      case FaDeviceAttributes.oscillationAngle:
        return message.oscillationAngle;
      case FaDeviceAttributes.oscillationMode:
        return message.oscillationMode;
      case FaDeviceAttributes.tiltingAngle:
        return message.tiltingAngle;
      default:
        return null;
    }
  }

  void _setOscillationMode(MessageSet message, String value) {
    if (value == 'Off' || value.isEmpty) {
      message.oscillate = false;
    } else {
      final oscillationAngle =
          attrs[FaDeviceAttributes.oscillationAngle] as String?;
      final tiltingAngle = attrs[FaDeviceAttributes.tiltingAngle] as String?;
      message.oscillate = true;
      message.oscillationMode = oscillationModes.indexOf(value);
      if (value == 'Oscillation') {
        if (oscillationAngle == null || oscillationAngle == 'Off') {
          message.oscillationAngle = 3;
        } else {
          message.oscillationAngle = oscillationAngles.indexOf(oscillationAngle);
        }
      } else if (value == 'Tilting') {
        if (tiltingAngle == null || tiltingAngle == 'Off') {
          message.tiltingAngle = 3;
        } else {
          message.tiltingAngle = tiltingAngles.indexOf(tiltingAngle);
        }
      } else {
        if (oscillationAngle == null || oscillationAngle == 'Off') {
          message.oscillationAngle = 3;
        } else {
          message.oscillationAngle = oscillationAngles.indexOf(oscillationAngle);
        }
        if (tiltingAngle == null || tiltingAngle == 'Off') {
          message.tiltingAngle = 3;
        } else {
          message.tiltingAngle = tiltingAngles.indexOf(tiltingAngle);
        }
      }
    }
  }

  void _setOscillationAngle(MessageSet message, String value) {
    final tiltingAngle = attrs[FaDeviceAttributes.tiltingAngle] as String?;
    if (value == 'Off' || value.isEmpty) {
      if (tiltingAngle == null || tiltingAngle == 'Off') {
        message.oscillate = false;
      } else {
        message.oscillate = true;
        message.oscillationMode = 2;
        message.tiltingAngle = tiltingAngles.indexOf(tiltingAngle);
      }
    } else {
      message.oscillationAngle = oscillationAngles.indexOf(value);
      message.oscillate = true;
      if (tiltingAngle == null || tiltingAngle == 'Off') {
        message.oscillationMode = 1;
      } else if (attrs[FaDeviceAttributes.oscillationMode] == 'Tilting') {
        message.oscillationMode = 6;
        message.tiltingAngle = tiltingAngles.indexOf(tiltingAngle);
      }
    }
  }

  void _setTiltingAngle(MessageSet message, String value) {
    final oscillationAngle =
        attrs[FaDeviceAttributes.oscillationAngle] as String?;
    if (value == 'Off' || value.isEmpty) {
      if (oscillationAngle == null || oscillationAngle == 'Off') {
        message.oscillate = false;
      } else {
        message.oscillate = true;
        message.oscillationMode = 1;
        message.oscillationAngle = oscillationAngles.indexOf(oscillationAngle);
      }
    } else {
      message.tiltingAngle = tiltingAngles.indexOf(value);
      message.oscillate = true;
      if (oscillationAngle == null || oscillationAngle == 'Off') {
        message.oscillationMode = 2;
      } else if (attrs[FaDeviceAttributes.oscillationMode] == 'Oscillation') {
        message.oscillationMode = 6;
        message.oscillationAngle = oscillationAngles.indexOf(oscillationAngle);
      }
    }
  }

  MessageSet? setOscillation(String attr, dynamic value) {
    MessageSet? message;
    if (attrs[attr] != value) {
      if (attr == FaDeviceAttributes.oscillate) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        message.oscillate = value as bool;
        if (value) {
          message.oscillationAngle = 3;
          message.oscillationMode = 1;
        }
      } else if (attr == FaDeviceAttributes.oscillationMode &&
          (oscillationModes.contains(value) || value.toString().isEmpty)) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        _setOscillationMode(message, value.toString());
      } else if (attr == FaDeviceAttributes.oscillationAngle &&
          (oscillationAngles.contains(value) || value.toString().isEmpty)) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        _setOscillationAngle(message, value.toString());
      } else if (attr == FaDeviceAttributes.tiltingAngle &&
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
      FaDeviceAttributes.oscillate,
      FaDeviceAttributes.oscillationMode,
      FaDeviceAttributes.oscillationAngle,
      FaDeviceAttributes.tiltingAngle,
    ].contains(attr)) {
      message = setOscillation(attr, value);
    } else if (attr == FaDeviceAttributes.fanSpeed &&
        value > 0 &&
        !(attrs[FaDeviceAttributes.power] as bool)) {
      message = MessageSet(
        protocolVersion: messageProtocolVersion,
        subtype: subtype,
      );
      message.fanSpeed = value as int;
      message.power = true;
    } else if (attr == FaDeviceAttributes.mode) {
      final modeVal = modes.indexOf(value.toString());
      if (modeVal >= 0) {
        message = MessageSet(
          protocolVersion: messageProtocolVersion,
          subtype: subtype,
        );
        message.mode = modeVal;
      }
    } else if (!(attr == FaDeviceAttributes.fanSpeed && value == 0)) {
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
      case FaDeviceAttributes.power:
        message.power = value as bool;
        break;
      case FaDeviceAttributes.childLock:
        message.lock = value as bool;
        break;
      case FaDeviceAttributes.fanSpeed:
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
