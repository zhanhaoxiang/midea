/// Midea local E1 device. Mirrors midealocal/devices/e1/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

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

class MideaE1Device extends MideaDevice {
  MideaE1Device({
    required String name,
    required int deviceId,
    required String ipAddress,
    required int port,
    required String token,
    required String key,
    required ProtocolVersion deviceProtocol,
    required String model,
    required int subtype,
    String? customize,
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
         deviceType: DeviceType.e1,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
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

  static const Map<int, String> _modes = {
    0x00: 'Neutral Gear',
    0x01: 'Auto Wash',
    0x02: 'Strong Wash',
    0x03: 'Standard Wash',
    0x04: 'ECO Wash',
    0x05: 'Glass Wash',
    0x06: 'Hour Wash',
    0x07: 'Fast Wash',
    0x08: 'Soak Wash',
    0x09: '90Min',
    0x0A: 'Self Clean',
    0x0B: 'Fruit Wash',
    0x0C: 'Self Define',
    0x0D: 'Germ',
    0x0E: 'Bowl Wash',
    0x0F: 'Kill Germ',
    0x10: 'Sea Food Wash',
    0x12: 'Hot Pot Wash',
    0x13: 'Quiet Night Wash',
    0x14: 'Less Wash',
    0x16: 'Oil Net Wash',
    0x19: 'Cloud Wash',
  };

  static const Map<int, String> _statusMap = {
    0x00: 'Power Off',
    0x01: 'Cancel',
    0x02: 'Delay',
    0x03: 'Running',
    0x04: 'Error',
    0x05: 'Soft Gear',
  };

  static const List<String> _progressList = [
    'Idle',
    'Pre-wash',
    'Wash',
    'Rinse',
    'Dry',
    'Complete',
  ];

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageE1Response(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DeviceAttributes.status) {
          value = _statusMap[value];
        } else if (attr == DeviceAttributes.progress) {
          if (value != null && value < _progressList.length) {
            value = _progressList[value];
          } else {
            value = null;
          }
        } else if (attr == DeviceAttributes.mode) {
          value = _modes[value];
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageE1Response msg, String attr) {
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

  dynamic _getAttribute(MessageE1Response msg, String attr) {
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
    if (value is! bool) {
      throw ValueWrongType('[e1] Expected bool');
    }
    if (attr == DeviceAttributes.power) {
      final msg = MessagePower(messageProtocolVersion);
      msg.power = value;
      buildSend(msg);
    } else if (attr == DeviceAttributes.childLock) {
      final msg = MessageLock(messageProtocolVersion);
      msg.lock = value;
      buildSend(msg);
    } else if (attr == DeviceAttributes.storage) {
      final msg = MessageStorage(messageProtocolVersion);
      msg.storage = value;
      buildSend(msg);
    }
  }
}

class MideaAppliance extends MideaE1Device {
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
    String? customize,
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
