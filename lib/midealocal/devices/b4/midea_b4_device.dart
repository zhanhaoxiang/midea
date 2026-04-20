/// Midea local B4 device. Mirrors midealocal/devices/b4/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String door = 'door';
  static const String status = 'status';
  static const String timeRemaining = 'time_remaining';
  static const String currentTemperature = 'current_temperature';
  static const String tankEjected = 'tank_ejected';
  static const String waterChangeReminder = 'water_change_reminder';
  static const String waterShortage = 'water_shortage';
}

class MideaB4Device extends MideaDevice {
  MideaB4Device({
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
         deviceType: DeviceType.b4,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       );

  static const Map<int, String> _statusMap = {
    0x01: 'Standby',
    0x02: 'Idle',
    0x03: 'Working',
    0x04: 'Finished',
    0x05: 'Delay',
    0x06: 'Paused',
  };

  static const Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.door: false,
    DeviceAttributes.status: null,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.currentTemperature: null,
    DeviceAttributes.tankEjected: false,
    DeviceAttributes.waterChangeReminder: false,
    DeviceAttributes.waterShortage: false,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB4Response(msg);
    final newStatus = <String, dynamic>{};

    for (final statusKey in attrs.keys) {
      if (message.hasAttribute(statusKey)) {
        final value = message.getAttribute(statusKey);
        if (statusKey == DeviceAttributes.status) {
          final statusValue = _statusMap[value];
          attrs[DeviceAttributes.status] = statusValue;
          newStatus[DeviceAttributes.status] = attrs[DeviceAttributes.status];
        } else {
          attrs[statusKey] = value;
          newStatus[statusKey] = value;
        }
      }
    }

    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}

class MideaAppliance extends MideaB4Device {
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
