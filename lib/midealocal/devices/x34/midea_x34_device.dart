/// Midea local X34 device. Mirrors midealocal/devices/x34/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// X34DeviceAttributes
// ---------------------------------------------------------------------------

class X34DeviceAttributes {
  static const String power = 'power';
  static const String status = 'status';
  static const String mode = 'mode';
  static const String additional = 'additional';
  static const String door = 'door';
  static const String rinseAid = 'rinse_aid';
  static const String salt = 'salt';
  static const String childLock = 'child_lock';
  static const String uv = 'uv';
  static const String dry = 'dry';
  static const String dryStatus = 'dry_status';
  static const String storage = 'storage';
  static const String storageStatus = 'storage_status';
  static const String timeRemaining = 'time_remaining';
  static const String progress = 'progress';
  static const String storageRemaining = 'storage_remaining';
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String waterswitch = 'waterswitch';
  static const String waterLack = 'water_lack';
  static const String errorCode = 'error_code';
  static const String softwater = 'softwater';
  static const String wrongOperation = 'wrong_operation';
  static const String bright = 'bright';
}

// ---------------------------------------------------------------------------
// Midea34Device
// ---------------------------------------------------------------------------

class Midea34Device extends MideaDevice {
  static const Map<int, String> _modeMap = {
    0x00: 'Neutral Gear',
    0x01: 'Auto',
    0x02: 'Heavy',
    0x03: 'Normal',
    0x04: 'Energy Saving',
    0x05: 'Delicate',
    0x06: 'Hour',
    0x07: 'Quick',
    0x08: 'Rinse',
    0x09: '90min',
    0x0A: 'Self Clean',
    0x0B: 'Fruit Wash',
    0x0C: 'Self Define',
    0x0D: 'Germ',
    0x0E: 'Bowl Wash',
    0x0F: 'Kill Germ',
    0x10: 'Sea Food Wash',
    0x12: 'Hot Pot Wash',
    0x13: 'Quiet',
    0x14: 'Less Wash',
    0x16: 'Oil Net Wash',
    0x19: 'Cloud Wash',
  };

  static const List<String> _statusList = [
    'Off',
    'Idle',
    'Delay',
    'Running',
    'Error',
  ];

  static const List<String> _progressList = [
    'Idle',
    'Pre-wash',
    'Wash',
    'Rinse',
    'Dry',
    'Complete',
  ];

  Midea34Device({
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
         deviceType: DeviceType.x34,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    X34DeviceAttributes.power: false,
    X34DeviceAttributes.status: null,
    X34DeviceAttributes.mode: 0,
    X34DeviceAttributes.additional: 0,
    X34DeviceAttributes.uv: false,
    X34DeviceAttributes.dry: false,
    X34DeviceAttributes.dryStatus: false,
    X34DeviceAttributes.door: false,
    X34DeviceAttributes.rinseAid: false,
    X34DeviceAttributes.salt: false,
    X34DeviceAttributes.childLock: false,
    X34DeviceAttributes.storage: false,
    X34DeviceAttributes.storageStatus: false,
    X34DeviceAttributes.timeRemaining: null,
    X34DeviceAttributes.progress: null,
    X34DeviceAttributes.storageRemaining: null,
    X34DeviceAttributes.temperature: null,
    X34DeviceAttributes.humidity: null,
    X34DeviceAttributes.waterswitch: false,
    X34DeviceAttributes.waterLack: false,
    X34DeviceAttributes.errorCode: null,
    X34DeviceAttributes.softwater: 0,
    X34DeviceAttributes.wrongOperation: null,
    X34DeviceAttributes.bright: 0,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = Message34Response(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == X34DeviceAttributes.status) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _statusList.length
                ? _statusList[idx]
                : null;
          }
        } else if (attr == X34DeviceAttributes.progress) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _progressList.length
                ? _progressList[idx]
                : null;
          }
        } else if (attr == X34DeviceAttributes.mode) {
          value = _modeMap[value] ?? value;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(Message34Response msg, String attr) {
    switch (attr) {
      case X34DeviceAttributes.power:
        return msg.power != null;
      case X34DeviceAttributes.status:
        return msg.status != null;
      case X34DeviceAttributes.mode:
        return msg.mode != null;
      case X34DeviceAttributes.additional:
        return msg.additional != null;
      case X34DeviceAttributes.door:
        return msg.door != null;
      case X34DeviceAttributes.rinseAid:
        return msg.rinseAid != null;
      case X34DeviceAttributes.salt:
        return msg.salt != null;
      case X34DeviceAttributes.childLock:
        return msg.childLock != null;
      case X34DeviceAttributes.uv:
        return msg.uv != null;
      case X34DeviceAttributes.dry:
        return msg.dry != null;
      case X34DeviceAttributes.dryStatus:
        return msg.dryStatus != null;
      case X34DeviceAttributes.storage:
        return msg.storage != null;
      case X34DeviceAttributes.storageStatus:
        return msg.storageStatus != null;
      case X34DeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case X34DeviceAttributes.progress:
        return msg.progress != null;
      case X34DeviceAttributes.storageRemaining:
        return msg.storageRemaining != null;
      case X34DeviceAttributes.temperature:
        return msg.temperature != null;
      case X34DeviceAttributes.humidity:
        return msg.humidity != null;
      case X34DeviceAttributes.waterswitch:
        return msg.waterswitch != null;
      case X34DeviceAttributes.waterLack:
        return msg.waterLack != null;
      case X34DeviceAttributes.errorCode:
        return msg.errorCode != null;
      case X34DeviceAttributes.softwater:
        return msg.softwater != null;
      case X34DeviceAttributes.wrongOperation:
        return msg.wrongOperation != null;
      case X34DeviceAttributes.bright:
        return msg.bright != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(Message34Response msg, String attr) {
    switch (attr) {
      case X34DeviceAttributes.power:
        return msg.power;
      case X34DeviceAttributes.status:
        return msg.status;
      case X34DeviceAttributes.mode:
        return msg.mode;
      case X34DeviceAttributes.additional:
        return msg.additional;
      case X34DeviceAttributes.door:
        return msg.door;
      case X34DeviceAttributes.rinseAid:
        return msg.rinseAid;
      case X34DeviceAttributes.salt:
        return msg.salt;
      case X34DeviceAttributes.childLock:
        return msg.childLock;
      case X34DeviceAttributes.uv:
        return msg.uv;
      case X34DeviceAttributes.dry:
        return msg.dry;
      case X34DeviceAttributes.dryStatus:
        return msg.dryStatus;
      case X34DeviceAttributes.storage:
        return msg.storage;
      case X34DeviceAttributes.storageStatus:
        return msg.storageStatus;
      case X34DeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case X34DeviceAttributes.progress:
        return msg.progress;
      case X34DeviceAttributes.storageRemaining:
        return msg.storageRemaining;
      case X34DeviceAttributes.temperature:
        return msg.temperature;
      case X34DeviceAttributes.humidity:
        return msg.humidity;
      case X34DeviceAttributes.waterswitch:
        return msg.waterswitch;
      case X34DeviceAttributes.waterLack:
        return msg.waterLack;
      case X34DeviceAttributes.errorCode:
        return msg.errorCode;
      case X34DeviceAttributes.softwater:
        return msg.softwater;
      case X34DeviceAttributes.wrongOperation:
        return msg.wrongOperation;
      case X34DeviceAttributes.bright:
        return msg.bright;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == X34DeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[x34] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == X34DeviceAttributes.childLock) {
      if (value is! bool) {
        throw MideaLocalError('[x34] Expected bool');
      }
      final message = MessageLock(messageProtocolVersion);
      message.lock = value;
      buildSend(message);
    } else if (attr == X34DeviceAttributes.storage) {
      if (value is! bool) {
        throw MideaLocalError('[x34] Expected bool');
      }
      final message = MessageStorage(messageProtocolVersion);
      message.storage = value;
      buildSend(message);
    }
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends Midea34Device {
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
