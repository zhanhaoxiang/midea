/// Midea local DB device. Mirrors midealocal/devices/db/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DbDeviceAttributes
// ---------------------------------------------------------------------------

class DbDeviceAttributes {
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
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DbDeviceAttributes.power: false,
    DbDeviceAttributes.start: false,
    DbDeviceAttributes.status: null,
    DbDeviceAttributes.mode: null,
    DbDeviceAttributes.program: null,
    DbDeviceAttributes.waterLevel: null,
    DbDeviceAttributes.temperature: null,
    DbDeviceAttributes.dehydrationSpeed: null,
    DbDeviceAttributes.washTime: null,
    DbDeviceAttributes.washTimeValue: null,
    DbDeviceAttributes.dehydrationTime: null,
    DbDeviceAttributes.dehydrationTimeValue: null,
    DbDeviceAttributes.detergent: null,
    DbDeviceAttributes.softener: null,
    DbDeviceAttributes.washingData: Uint8List(0),
    DbDeviceAttributes.progress: null,
    DbDeviceAttributes.stains: null,
    DbDeviceAttributes.timeRemaining: null,
    DbDeviceAttributes.dirtyDegree: null,
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
        if (attr == DbDeviceAttributes.mode) {
          value = _modeMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.status) {
          value = _statusMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.dehydrationSpeed) {
          value = _dehydrationSpeedMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.waterLevel) {
          value = _waterLevelMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.program) {
          value = _programMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.temperature) {
          value = _temperatureMap[value] ?? value;
        } else if (attr == DbDeviceAttributes.progress && value != null) {
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
      case DbDeviceAttributes.power:
        return msg.power != null;
      case DbDeviceAttributes.start:
        return msg.start != null;
      case DbDeviceAttributes.status:
        return msg.status != null;
      case DbDeviceAttributes.mode:
        return msg.mode != null;
      case DbDeviceAttributes.program:
        return msg.program != null;
      case DbDeviceAttributes.waterLevel:
        return msg.waterLevel != null;
      case DbDeviceAttributes.temperature:
        return msg.temperature != null;
      case DbDeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed != null;
      case DbDeviceAttributes.washTime:
        return msg.washTime != null;
      case DbDeviceAttributes.dehydrationTime:
        return msg.dehydrationTime != null;
      case DbDeviceAttributes.detergent:
        return msg.detergent != null;
      case DbDeviceAttributes.softener:
        return msg.softener != null;
      case DbDeviceAttributes.washingData:
        return msg.washingData != null;
      case DbDeviceAttributes.progress:
        return msg.progress != null;
      case DbDeviceAttributes.stains:
        return msg.stains != null;
      case DbDeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case DbDeviceAttributes.washTimeValue:
        return msg.washTimeValue != null;
      case DbDeviceAttributes.dehydrationTimeValue:
        return msg.dehydrationTimeValue != null;
      case DbDeviceAttributes.dirtyDegree:
        return msg.dirtyDegree != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageDBResponse msg, String attr) {
    switch (attr) {
      case DbDeviceAttributes.power:
        return msg.power;
      case DbDeviceAttributes.start:
        return msg.start;
      case DbDeviceAttributes.status:
        return msg.status;
      case DbDeviceAttributes.mode:
        return msg.mode;
      case DbDeviceAttributes.program:
        return msg.program;
      case DbDeviceAttributes.waterLevel:
        return msg.waterLevel;
      case DbDeviceAttributes.temperature:
        return msg.temperature;
      case DbDeviceAttributes.dehydrationSpeed:
        return msg.dehydrationSpeed;
      case DbDeviceAttributes.washTime:
        return msg.washTime;
      case DbDeviceAttributes.dehydrationTime:
        return msg.dehydrationTime;
      case DbDeviceAttributes.detergent:
        return msg.detergent;
      case DbDeviceAttributes.softener:
        return msg.softener;
      case DbDeviceAttributes.washingData:
        return msg.washingData;
      case DbDeviceAttributes.progress:
        return msg.progress;
      case DbDeviceAttributes.stains:
        return msg.stains;
      case DbDeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case DbDeviceAttributes.washTimeValue:
        return msg.washTimeValue;
      case DbDeviceAttributes.dehydrationTimeValue:
        return msg.dehydrationTimeValue;
      case DbDeviceAttributes.dirtyDegree:
        return msg.dirtyDegree;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DbDeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[db] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == DbDeviceAttributes.start) {
      if (value is! bool) {
        throw MideaLocalError('[db] Expected bool');
      }
      final message = MessageStart(messageProtocolVersion);
      message.start = value;
      message.washingData =
          attrs[DbDeviceAttributes.washingData] as Uint8List? ?? Uint8List(0);
      buildSend(message);
    }
  }
}
