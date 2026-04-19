/// Midea local DB device. Mirrors midealocal/devices/db/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String power = 'power';
  static const String start = 'start';
  static const String status = 'status';
  static const String mode = 'mode';
  static const String program = 'program';
  static const String waterLevel = 'water_level';
  static const String temperature = 'temperature';
  static const String dehydrationSpeed = 'dehydration_speed';
  static const String washTime = 'wash_time';
  static const String washTimeValue = 'wash_time_value';
  static const String dehydrationTime = 'dehydration_time';
  static const String dehydrationTimeValue = 'dehydration_time_value';
  static const String detergent = 'detergent';
  static const String softener = 'softener';
  static const String washingData = 'washing_data';
  static const String progress = 'progress';
  static const String timeRemaining = 'time_remaining';
  static const String stains = 'stains';
  static const String dirtyDegree = 'dirty_degree';
}

// ---------------------------------------------------------------------------
// MideaDBDevice
// ---------------------------------------------------------------------------

class MideaDBDevice extends MideaDevice {
  static const Map<int, String> _statusMap = {
    0: 'idle',
    1: 'standby',
    2: 'start',
    3: 'pause',
    4: 'end',
    5: 'fault',
    6: 'delay',
  };

  static const Map<int, String> _modeMap = {
    0: 'normal',
    1: 'factory_test',
    2: 'service',
    3: 'normal_continus',
  };

  static const Map<int, String> _dehydrationSpeedMap = {
    0x00: '0',
    0x01: '400',
    0x02: '600',
    0x03: '800',
    0x04: '1000',
    0x05: '1200',
    0x06: '1400',
    0x07: '1600',
    0x08: '1300',
    0xFF: 'default',
  };

  static const Map<int, String> _waterLevelMap = {
    0x01: 'Low',
    0x02: 'Mid',
    0x03: 'High',
    0x04: '4',
    0x05: 'Auto',
    0xFF: 'default',
  };

  static const Map<int, String> _programMap = {
    0x00: 'cotton',
    0x01: 'eco',
    0x02: 'fast_wash',
    0x03: 'mixed_wash',
    0x04: 'fiber',
    0x05: 'wool',
    0x06: 'enzyme',
    0x07: 'ssp',
    0x08: 'sport_clothes',
    0x09: 'single_dehytration',
    0x0A: 'rinsing_dehydration',
    0x0B: 'big',
    0x0C: 'baby_clothes',
    0x0D: 'outdoor',
    0x0E: 'air_wash',
    0x0F: 'down_jacket',
    0x10: 'color',
    0x11: 'intelligent',
    0x12: 'quick_wash',
    0x13: 'kids',
    0x14: 'water_cotton',
    0x15: 'single_drying',
    0x17: 'fast_wash_30',
    0x18: 'fast_wash_60',
    0xFF: 'default',
  };

  static const Map<int, String> _temperatureMap = {
    0x01: '0',
    0x02: '20',
    0x03: '30',
    0x04: '40',
    0x05: '60',
    0x06: '95',
    0x07: '70',
    0xFF: 'default',
  };

  static const List<String> _progressList = [
    'Idle',
    'Spin',
    'Rinse',
    'Wash',
    'Pre-wash',
    'Dry',
    'Weight',
    'Hi-speed Spin',
    'Unknown',
  ];

  MideaDBDevice({
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
         deviceType: DeviceType.db,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.power: false,
    DeviceAttributes.start: false,
    DeviceAttributes.status: null,
    DeviceAttributes.mode: null,
    DeviceAttributes.program: null,
    DeviceAttributes.waterLevel: null,
    DeviceAttributes.temperature: null,
    DeviceAttributes.dehydrationSpeed: null,
    DeviceAttributes.washTime: null,
    DeviceAttributes.washTimeValue: null,
    DeviceAttributes.dehydrationTime: null,
    DeviceAttributes.dehydrationTimeValue: null,
    DeviceAttributes.detergent: null,
    DeviceAttributes.softener: null,
    DeviceAttributes.washingData: Uint8List(0),
    DeviceAttributes.progress: null,
    DeviceAttributes.stains: null,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.dirtyDegree: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageDBResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DeviceAttributes.mode) {
          value = _modeMap[value] ?? value;
        } else if (attr == DeviceAttributes.status) {
          value = _statusMap[value] ?? value;
        } else if (attr == DeviceAttributes.dehydrationSpeed) {
          value = _dehydrationSpeedMap[value] ?? value;
        } else if (attr == DeviceAttributes.waterLevel) {
          value = _waterLevelMap[value] ?? value;
        } else if (attr == DeviceAttributes.program) {
          value = _programMap[value] ?? value;
        } else if (attr == DeviceAttributes.temperature) {
          value = _temperatureMap[value] ?? value;
        } else if (attr == DeviceAttributes.progress && value != null) {
          final idx = value as int;
          value = idx >= 0 && idx < _progressList.length
              ? _progressList[idx]
              : _progressList.last;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageDBResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power != null;
      case DeviceAttributes.start:
        return msg.start != null;
      case DeviceAttributes.status:
        return msg.status != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.program:
        return msg.program != null;
      case DeviceAttributes.waterLevel:
        return msg.waterLevel != null;
      case DeviceAttributes.temperature:
        return msg.temperature != null;
      case DeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed != null;
      case DeviceAttributes.washTime:
        return msg.washTime != null;
      case DeviceAttributes.dehydrationTime:
        return msg.dehydrationTime != null;
      case DeviceAttributes.detergent:
        return msg.detergent != null;
      case DeviceAttributes.softener:
        return msg.softener != null;
      case DeviceAttributes.washingData:
        return msg.washingData != null;
      case DeviceAttributes.progress:
        return msg.progress != null;
      case DeviceAttributes.stains:
        return msg.stains != null;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case DeviceAttributes.washTimeValue:
        return msg.washTimeValue != null;
      case DeviceAttributes.dehydrationTimeValue:
        return msg.dehydrationTimeValue != null;
      case DeviceAttributes.dirtyDegree:
        return msg.dirtyDegree != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageDBResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power;
      case DeviceAttributes.start:
        return msg.start;
      case DeviceAttributes.status:
        return msg.status;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.program:
        return msg.program;
      case DeviceAttributes.waterLevel:
        return msg.waterLevel;
      case DeviceAttributes.temperature:
        return msg.temperature;
      case DeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed;
      case DeviceAttributes.washTime:
        return msg.washTime;
      case DeviceAttributes.dehydrationTime:
        return msg.dehydrationTime;
      case DeviceAttributes.detergent:
        return msg.detergent;
      case DeviceAttributes.softener:
        return msg.softener;
      case DeviceAttributes.washingData:
        return msg.washingData;
      case DeviceAttributes.progress:
        return msg.progress;
      case DeviceAttributes.stains:
        return msg.stains;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case DeviceAttributes.washTimeValue:
        return msg.washTimeValue;
      case DeviceAttributes.dehydrationTimeValue:
        return msg.dehydrationTimeValue;
      case DeviceAttributes.dirtyDegree:
        return msg.dirtyDegree;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[db] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == DeviceAttributes.start) {
      if (value is! bool) {
        throw MideaLocalError('[db] Expected bool');
      }
      final message = MessageStart(messageProtocolVersion);
      message.start = value;
      message.washingData =
          attrs[DeviceAttributes.washingData] as Uint8List? ?? Uint8List(0);
      buildSend(message);
    }
  }
}
