/// Midea local X34 device. Mirrors midealocal/devices/x34/__init__.py.

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
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.power: false,
    DeviceAttributes.status: null,
    DeviceAttributes.mode: 0,
    DeviceAttributes.additional: 0,
    DeviceAttributes.uv: false,
    DeviceAttributes.dry: false,
    DeviceAttributes.dryStatus: false,
    DeviceAttributes.door: false,
    DeviceAttributes.rinseAid: false,
    DeviceAttributes.salt: false,
    DeviceAttributes.childLock: false,
    DeviceAttributes.storage: false,
    DeviceAttributes.storageStatus: false,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.progress: null,
    DeviceAttributes.storageRemaining: null,
    DeviceAttributes.temperature: null,
    DeviceAttributes.humidity: null,
    DeviceAttributes.waterswitch: false,
    DeviceAttributes.waterLack: false,
    DeviceAttributes.errorCode: null,
    DeviceAttributes.softwater: 0,
    DeviceAttributes.wrongOperation: null,
    DeviceAttributes.bright: 0,
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
        if (attr == DeviceAttributes.status) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _statusList.length
                ? _statusList[idx]
                : null;
          }
        } else if (attr == DeviceAttributes.progress) {
          if (value != null) {
            final idx = value as int;
            value = idx >= 0 && idx < _progressList.length
                ? _progressList[idx]
                : null;
          }
        } else if (attr == DeviceAttributes.mode) {
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
      case DeviceAttributes.power:
        return msg.power != null;
      case DeviceAttributes.status:
        return msg.status != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.additional:
        return msg.additional != null;
      case DeviceAttributes.door:
        return msg.door != null;
      case DeviceAttributes.rinseAid:
        return msg.rinseAid != null;
      case DeviceAttributes.salt:
        return msg.salt != null;
      case DeviceAttributes.childLock:
        return msg.childLock != null;
      case DeviceAttributes.uv:
        return msg.uv != null;
      case DeviceAttributes.dry:
        return msg.dry != null;
      case DeviceAttributes.dryStatus:
        return msg.dryStatus != null;
      case DeviceAttributes.storage:
        return msg.storage != null;
      case DeviceAttributes.storageStatus:
        return msg.storageStatus != null;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case DeviceAttributes.progress:
        return msg.progress != null;
      case DeviceAttributes.storageRemaining:
        return msg.storageRemaining != null;
      case DeviceAttributes.temperature:
        return msg.temperature != null;
      case DeviceAttributes.humidity:
        return msg.humidity != null;
      case DeviceAttributes.waterswitch:
        return msg.waterswitch != null;
      case DeviceAttributes.waterLack:
        return msg.waterLack != null;
      case DeviceAttributes.errorCode:
        return msg.errorCode != null;
      case DeviceAttributes.softwater:
        return msg.softwater != null;
      case DeviceAttributes.wrongOperation:
        return msg.wrongOperation != null;
      case DeviceAttributes.bright:
        return msg.bright != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(Message34Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power;
      case DeviceAttributes.status:
        return msg.status;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.additional:
        return msg.additional;
      case DeviceAttributes.door:
        return msg.door;
      case DeviceAttributes.rinseAid:
        return msg.rinseAid;
      case DeviceAttributes.salt:
        return msg.salt;
      case DeviceAttributes.childLock:
        return msg.childLock;
      case DeviceAttributes.uv:
        return msg.uv;
      case DeviceAttributes.dry:
        return msg.dry;
      case DeviceAttributes.dryStatus:
        return msg.dryStatus;
      case DeviceAttributes.storage:
        return msg.storage;
      case DeviceAttributes.storageStatus:
        return msg.storageStatus;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case DeviceAttributes.progress:
        return msg.progress;
      case DeviceAttributes.storageRemaining:
        return msg.storageRemaining;
      case DeviceAttributes.temperature:
        return msg.temperature;
      case DeviceAttributes.humidity:
        return msg.humidity;
      case DeviceAttributes.waterswitch:
        return msg.waterswitch;
      case DeviceAttributes.waterLack:
        return msg.waterLack;
      case DeviceAttributes.errorCode:
        return msg.errorCode;
      case DeviceAttributes.softwater:
        return msg.softwater;
      case DeviceAttributes.wrongOperation:
        return msg.wrongOperation;
      case DeviceAttributes.bright:
        return msg.bright;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[x34] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == DeviceAttributes.childLock) {
      if (value is! bool) {
        throw MideaLocalError('[x34] Expected bool');
      }
      final message = MessageLock(messageProtocolVersion);
      message.lock = value;
      buildSend(message);
    } else if (attr == DeviceAttributes.storage) {
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
