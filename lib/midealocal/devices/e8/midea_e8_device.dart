/// Midea local E8 device. Mirrors midealocal/devices/e8/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import 'message.dart';

class E8DeviceAttributes {
  static const String status = 'status';
  static const String timeRemaining = 'time_remaining';
  static const String keepWarmRemaining = 'keep_warm_remaining';
  static const String workingTime = 'working_time';
  static const String targetTemperature = 'target_temperature';
  static const String currentTemperature = 'current_temperature';
  static const String finished = 'finished';
  static const String waterShortage = 'water_shortage';
}

class MideaE8Device extends MideaDevice {
  MideaE8Device({
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
         deviceType: DeviceType.e8,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const Map<int, String> _statusMap = {
    0x00: 'Standby',
    0x01: 'Delay',
    0x02: 'Working',
    0x03: 'Paused',
    0x04: 'Keep-Warming',
    0xFF: 'Error',
  };

  static final Map<String, dynamic> _defaultAttributes = {
    E8DeviceAttributes.status: null,
    E8DeviceAttributes.timeRemaining: null,
    E8DeviceAttributes.keepWarmRemaining: null,
    E8DeviceAttributes.workingTime: null,
    E8DeviceAttributes.targetTemperature: null,
    E8DeviceAttributes.currentTemperature: null,
    E8DeviceAttributes.finished: null,
    E8DeviceAttributes.waterShortage: null,
  };

  @override
  List<MessageQuery> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageE8Response(msg);
    final newStatus = <String, dynamic>{};
    for (final attr in attrs.keys) {
      if (message.hasProperty(attr)) {
        final value = message.getProperty(attr);
        if (attr == E8DeviceAttributes.status) {
          if (_statusMap.containsKey(value)) {
            attrs[E8DeviceAttributes.status] = _statusMap[value];
          } else {
            attrs[E8DeviceAttributes.status] = null;
          }
        } else {
          attrs[attr] = value;
        }
        newStatus[attr] = attrs[attr];
      }
    }
    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}

extension MessageE8ResponseExtension on MessageE8Response {
  bool hasProperty(String attr) {
    switch (attr) {
      case E8DeviceAttributes.status:
        return status != null;
      case E8DeviceAttributes.timeRemaining:
        return timeRemaining != null;
      case E8DeviceAttributes.keepWarmRemaining:
        return keepWarmRemaining != null;
      case E8DeviceAttributes.workingTime:
        return workingTime != null;
      case E8DeviceAttributes.targetTemperature:
        return targetTemperature != null;
      case E8DeviceAttributes.currentTemperature:
        return currentTemperature != null;
      case E8DeviceAttributes.finished:
        return finished != null;
      case E8DeviceAttributes.waterShortage:
        return waterShortcut != null;
      default:
        return false;
    }
  }

  dynamic getProperty(String attr) {
    switch (attr) {
      case E8DeviceAttributes.status:
        return status;
      case E8DeviceAttributes.timeRemaining:
        return timeRemaining;
      case E8DeviceAttributes.keepWarmRemaining:
        return keepWarmRemaining;
      case E8DeviceAttributes.workingTime:
        return workingTime;
      case E8DeviceAttributes.targetTemperature:
        return targetTemperature;
      case E8DeviceAttributes.currentTemperature:
        return currentTemperature;
      case E8DeviceAttributes.finished:
        return finished;
      case E8DeviceAttributes.waterShortage:
        return waterShortcut;
      default:
        return null;
    }
  }
}
