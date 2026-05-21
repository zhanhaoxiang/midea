/// Midea local BF device. Mirrors midealocal/devices/bf/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String door = 'door';
  static const String status = 'status';
  static const String timeRemaining = 'time_remaining';
  static const String currentTemperature = 'current_temperature';
  static const String tankEjected = 'tank_ejected';
  static const String waterChangeReminder = 'water_change_reminder';
  static const String waterShortage = 'water_shortage';
  static const String childLock = 'child_lock';
}

// ---------------------------------------------------------------------------
// MideaBFDevice
// ---------------------------------------------------------------------------

class MideaBFDevice extends MideaDevice {
  MideaBFDevice({
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
         deviceType: DeviceType.bf,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const Map<int, String> _statusMap = {
    0x01: 'PowerSave',
    0x02: 'Standby',
    0x03: 'Working',
    0x04: 'Finished',
    0x05: 'Delay',
    0x06: 'Paused',
  };

  static const Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.door: null,
    DeviceAttributes.status: null,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.currentTemperature: null,
    DeviceAttributes.tankEjected: null,
    DeviceAttributes.waterChangeReminder: null,
    DeviceAttributes.waterShortage: null,
    DeviceAttributes.childLock: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageBFResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final statusKey in attrs.keys) {
      final value = _getMessageAttribute(message, statusKey);
      if (value != null) {
        if (statusKey == DeviceAttributes.status) {
          attrs[statusKey] = _statusMap[value] ?? 'Unknown';
        } else {
          attrs[statusKey] = value;
        }
        newStatus[statusKey] = attrs[statusKey];
      }
    }
    return newStatus;
  }

  dynamic _getMessageAttribute(MessageBFResponse message, String attr) {
    switch (attr) {
      case DeviceAttributes.status:
        return message.status;
      case DeviceAttributes.timeRemaining:
        return message.timeRemaining;
      case DeviceAttributes.currentTemperature:
        return message.currentTemperature;
      case DeviceAttributes.childLock:
        return message.childLock;
      case DeviceAttributes.door:
        return message.door;
      case DeviceAttributes.tankEjected:
        return message.tankEjected;
      case DeviceAttributes.waterShortage:
        return message.waterShortage;
      case DeviceAttributes.waterChangeReminder:
        return message.waterChangeReminder;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
