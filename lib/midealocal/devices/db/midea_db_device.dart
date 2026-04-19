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
          deviceType: DeviceType.db,
          ipAddress: ipAddress,
          port: port,
          token: token,
          key: key,
          deviceProtocol: deviceProtocol,
          model: model,
          subtype: subtype,
          attributes: {
            DeviceAttributes.power: false,
            DeviceAttributes.start: false,
            DeviceAttributes.status: null,
            DeviceAttributes.mode: null,
            DeviceAttributes.program: null,
            DeviceAttributes.waterLevel: null,
            DeviceAttributes.temperature: null,
            DeviceAttributes.dehydrationSpeed: null,
            DeviceAttributes.washTime: null,
            DeviceAttributes.dehydrationTime: null,
            DeviceAttributes.detergent: null,
            DeviceAttributes.softener: null,
            DeviceAttributes.washingData: Uint8List(0),
            DeviceAttributes.progress: null,
            DeviceAttributes.stains: null,
            DeviceAttributes.timeRemaining: null,
            DeviceAttributes.washTimeValue: null,
            DeviceAttributes.dehydrationTimeValue: null,
            DeviceAttributes.dirtyDegree: null,
          },
        );

  @override
  List<MessageRequest> buildQuery() =>
      [MessageQuery(messageProtocolVersion)];

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageDBResponse(msg);
    final newStatus = <String, dynamic>{};

    void setAttr(String attr, dynamic raw) {
      attrs[attr] = raw;
      newStatus[attr] = raw;
    }

    if (message.power != null) {
      setAttr(DeviceAttributes.power, message.power);
    }
    if (message.start != null) {
      setAttr(DeviceAttributes.start, message.start);
    }
    if (message.washingData != null) {
      setAttr(DeviceAttributes.washingData, message.washingData);
    }
    if (message.status != null) {
      setAttr(
          DeviceAttributes.status, _statusMap[message.status] ?? message.status);
    }
    if (message.mode != null) {
      setAttr(DeviceAttributes.mode, _modeMap[message.mode] ?? message.mode);
    }
    if (message.program != null) {
      setAttr(
          DeviceAttributes.program,
          _programMap[message.program] ?? message.program);
    }
    if (message.waterLevel != null) {
      setAttr(DeviceAttributes.waterLevel,
          _waterLevelMap[message.waterLevel] ?? message.waterLevel);
    }
    if (message.temperature != null) {
      setAttr(DeviceAttributes.temperature,
          _temperatureMap[message.temperature] ?? message.temperature);
    }
    if (message.dehydrationSpeed != null) {
      setAttr(DeviceAttributes.dehydrationSpeed,
          _dehydrationSpeedMap[message.dehydrationSpeed] ?? message.dehydrationSpeed);
    }
    if (message.washTime != null) {
      setAttr(DeviceAttributes.washTime, message.washTime);
    }
    if (message.dehydrationTime != null) {
      setAttr(DeviceAttributes.dehydrationTime, message.dehydrationTime);
    }
    if (message.detergent != null) {
      setAttr(DeviceAttributes.detergent, message.detergent);
    }
    if (message.softener != null) {
      setAttr(DeviceAttributes.softener, message.softener);
    }
    if (message.progress != null) {
      final idx = message.progress!;
      setAttr(DeviceAttributes.progress,
          idx < _progressList.length ? _progressList[idx] : 'Unknown');
    }
    if (message.stains != null) {
      setAttr(DeviceAttributes.stains, message.stains);
    }
    if (message.washTimeValue != null) {
      setAttr(DeviceAttributes.washTimeValue, message.washTimeValue);
    }
    if (message.dehydrationTimeValue != null) {
      setAttr(DeviceAttributes.dehydrationTimeValue, message.dehydrationTimeValue);
    }
    if (message.dirtyDegree != null) {
      setAttr(DeviceAttributes.dirtyDegree, message.dirtyDegree);
    }
    if (message.timeRemaining != null) {
      setAttr(DeviceAttributes.timeRemaining, message.timeRemaining);
    }

    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (value is! bool) throw ValueWrongType('[db] Expected bool');
    if (attr == DeviceAttributes.power) {
      final cmd = MessagePower(messageProtocolVersion);
      cmd.power = value;
      buildSend(cmd);
    } else if (attr == DeviceAttributes.start) {
      final cmd = MessageStart(messageProtocolVersion);
      cmd.start = value;
      cmd.washingData = (attrs[DeviceAttributes.washingData] as Uint8List?) ?? Uint8List(0);
      buildSend(cmd);
    }
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance (alias, mirrors Python class)
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaDBDevice {
  MideaAppliance({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required super.deviceProtocol,
    required super.model,
    required super.subtype,
  });
}
