/// Midea local DA device. Mirrors midealocal/devices/da/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DaDeviceAttributes
// ---------------------------------------------------------------------------

class DaDeviceAttributes {
  static const String power = 'power';
  static const String start = 'start';
  static const String washingData = 'washing_data';
  static const String program = 'program';
  static const String progress = 'progress';
  static const String timeRemaining = 'time_remaining';
  static const String washTime = 'wash_time';
  static const String soakTime = 'soak_time';
  static const String dehydrationTime = 'dehydration_time';
  static const String dehydrationSpeed = 'dehydration_speed';
  static const String errorCode = 'error_code';
  static const String rinseCount = 'rinse_count';
  static const String rinseLevel = 'rinse_level';
  static const String washLevel = 'wash_level';
  static const String washStrength = 'wash_strength';
  static const String softener = 'softener';
  static const String detergent = 'detergent';
}

// ---------------------------------------------------------------------------
// MideaDADevice
// ---------------------------------------------------------------------------

class MideaDADevice extends MideaDevice {
  static const int _minTemp = 15;

  static const List<String> _progressList = [
    'Idle',
    'Spin',
    'Rinse',
    'Wash',
    'Weight',
    'Unknown',
    'Dry',
    'Soak',
  ];

  static const List<String> _programList = [
    'Standard',
    'Fast',
    'Blanket',
    'Wool',
    'embathe',
    'Memory',
    'Child',
    'Down Jacket',
    'Stir',
    'Mute',
    'Bucket Self Clean',
    'Air Dry',
  ];

  static const List<String> _speedList = ['-', 'Low', 'Medium', 'High'];

  static const List<String> _strengthList = ['-', 'Week', 'Medium', 'Strong'];

  static const List<String> _detergentList = [
    'No',
    'Less',
    'Medium',
    'More',
    '4',
    '5',
    '6',
    '7',
    '8',
    'Insufficient',
  ];

  static const List<String> _softenerList = [
    'No',
    'Intelligent',
    'Programed',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    'Insufficient',
  ];

  MideaDADevice({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
  }) : super(
         deviceType: DeviceType.da,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DaDeviceAttributes.power: false,
    DaDeviceAttributes.start: false,
    DaDeviceAttributes.errorCode: null,
    DaDeviceAttributes.washingData: Uint8List(0),
    DaDeviceAttributes.program: null,
    DaDeviceAttributes.progress: 'Unknown',
    DaDeviceAttributes.timeRemaining: null,
    DaDeviceAttributes.washTime: null,
    DaDeviceAttributes.soakTime: null,
    DaDeviceAttributes.dehydrationTime: null,
    DaDeviceAttributes.dehydrationSpeed: null,
    DaDeviceAttributes.rinseCount: null,
    DaDeviceAttributes.rinseLevel: null,
    DaDeviceAttributes.washLevel: null,
    DaDeviceAttributes.washStrength: null,
    DaDeviceAttributes.softener: null,
    DaDeviceAttributes.detergent: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageDAResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DaDeviceAttributes.progress) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _progressList.length
                ? _progressList[idx]
                : _progressList[5];
          }
        } else if (attr == DaDeviceAttributes.program) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _programList.length
                ? _programList[idx]
                : null;
          }
        } else if (attr == DaDeviceAttributes.rinseLevel) {
          if (value != null) {
            final idx = value as int;
            value = idx == _minTemp ? '-' : idx;
          }
        } else if (attr == DaDeviceAttributes.dehydrationSpeed) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _speedList.length
                ? _speedList[idx]
                : null;
          }
        } else if (attr == DaDeviceAttributes.detergent) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _detergentList.length
                ? _detergentList[idx]
                : null;
          }
        } else if (attr == DaDeviceAttributes.softener) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _softenerList.length
                ? _softenerList[idx]
                : null;
          }
        } else if (attr == DaDeviceAttributes.washStrength) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _strengthList.length
                ? _strengthList[idx]
                : null;
          }
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageDAResponse msg, String attr) {
    switch (attr) {
      case DaDeviceAttributes.power:
        return msg.power != null;
      case DaDeviceAttributes.start:
        return msg.start != null;
      case DaDeviceAttributes.errorCode:
        return msg.errorCode != null;
      case DaDeviceAttributes.washingData:
        return msg.washingData != null;
      case DaDeviceAttributes.program:
        return msg.program != null;
      case DaDeviceAttributes.progress:
        return msg.progress != null;
      case DaDeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case DaDeviceAttributes.washTime:
        return msg.washTime != null;
      case DaDeviceAttributes.soakTime:
        return msg.soakTime != null;
      case DaDeviceAttributes.dehydrationTime:
        return msg.dehydrationTime != null;
      case DaDeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed != null;
      case DaDeviceAttributes.rinseCount:
        return msg.rinseCount != null;
      case DaDeviceAttributes.rinseLevel:
        return msg.rinseLevel != null;
      case DaDeviceAttributes.washLevel:
        return msg.washLevel != null;
      case DaDeviceAttributes.washStrength:
        return msg.washStrength != null;
      case DaDeviceAttributes.softener:
        return msg.softener != null;
      case DaDeviceAttributes.detergent:
        return msg.detergent != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageDAResponse msg, String attr) {
    switch (attr) {
      case DaDeviceAttributes.power:
        return msg.power;
      case DaDeviceAttributes.start:
        return msg.start;
      case DaDeviceAttributes.errorCode:
        return msg.errorCode;
      case DaDeviceAttributes.washingData:
        return msg.washingData;
      case DaDeviceAttributes.program:
        return msg.program;
      case DaDeviceAttributes.progress:
        return msg.progress;
      case DaDeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case DaDeviceAttributes.washTime:
        return msg.washTime;
      case DaDeviceAttributes.soakTime:
        return msg.soakTime;
      case DaDeviceAttributes.dehydrationTime:
        return msg.dehydrationTime;
      case DaDeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed;
      case DaDeviceAttributes.rinseCount:
        return msg.rinseCount;
      case DaDeviceAttributes.rinseLevel:
        return msg.rinseLevel;
      case DaDeviceAttributes.washLevel:
        return msg.washLevel;
      case DaDeviceAttributes.washStrength:
        return msg.washStrength;
      case DaDeviceAttributes.softener:
        return msg.softener;
      case DaDeviceAttributes.detergent:
        return msg.detergent;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DaDeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[da] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == DaDeviceAttributes.start) {
      if (value is! bool) {
        throw MideaLocalError('[da] Expected bool');
      }
      final message = MessageStart(messageProtocolVersion);
      message.start = value;
      message.washingData =
          attrs[DaDeviceAttributes.washingData] as Uint8List? ?? Uint8List(0);
      buildSend(message);
    }
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaDADevice {
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
       );
}
