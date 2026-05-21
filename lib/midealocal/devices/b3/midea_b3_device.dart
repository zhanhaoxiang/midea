/// Midea local B3 device. Mirrors midealocal/devices/b3/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String topCompartmentStatus = 'top_compartment_status';
  static const String topCompartmentMode = 'top_compartment_mode';
  static const String topCompartmentTemperature = 'top_compartment_temperature';
  static const String topCompartmentRemaining = 'top_compartment_remaining';
  static const String topCompartmentDoor = 'top_compartment_door';
  static const String topCompartmentPreheating = 'top_compartment_preheating';
  static const String topCompartmentCooling = 'top_compartment_cooling';
  static const String middleCompartmentStatus = 'middle_compartment_status';
  static const String middleCompartmentMode = 'middle_compartment_mode';
  static const String middleCompartmentTemperature =
      'middle_compartment_temperature';
  static const String middleCompartmentRemaining =
      'middle_compartment_remaining';
  static const String middleCompartmentDoor = 'middle_compartment_door';
  static const String middleCompartmentPreheating =
      'middle_compartment_preheating';
  static const String middleCompartmentCooling = 'middle_compartment_cooling';
  static const String bottomCompartmentStatus = 'bottom_compartment_status';
  static const String bottomCompartmentMode = 'bottom_compartment_mode';
  static const String bottomCompartmentTemperature =
      'bottom_compartment_temperature';
  static const String bottomCompartmentRemaining =
      'bottom_compartment_remaining';
  static const String bottomCompartmentDoor = 'bottom_compartment_door';
  static const String bottomCompartmentPreheating =
      'bottom_compartment_preheating';
  static const String bottomCompartmentCooling = 'bottom_compartment_cooling';
  static const String lock = 'lock';
}

// ---------------------------------------------------------------------------
// MideaB3Device
// ---------------------------------------------------------------------------

class MideaB3Device extends MideaDevice {
  static const Map<int, String> _statusMap = {
    0x00: 'Off',
    0x01: 'Standby',
    0x02: 'Working',
    0x03: 'Delay',
    0x04: 'Finished',
  };

  MideaB3Device({
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
         deviceType: DeviceType.b3,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.topCompartmentStatus: null,
    DeviceAttributes.topCompartmentMode: null,
    DeviceAttributes.topCompartmentTemperature: null,
    DeviceAttributes.topCompartmentRemaining: null,
    DeviceAttributes.topCompartmentDoor: false,
    DeviceAttributes.topCompartmentPreheating: false,
    DeviceAttributes.topCompartmentCooling: false,
    DeviceAttributes.middleCompartmentStatus: null,
    DeviceAttributes.middleCompartmentMode: null,
    DeviceAttributes.middleCompartmentTemperature: null,
    DeviceAttributes.middleCompartmentRemaining: null,
    DeviceAttributes.middleCompartmentDoor: false,
    DeviceAttributes.middleCompartmentPreheating: false,
    DeviceAttributes.middleCompartmentCooling: false,
    DeviceAttributes.bottomCompartmentStatus: null,
    DeviceAttributes.bottomCompartmentMode: null,
    DeviceAttributes.bottomCompartmentTemperature: null,
    DeviceAttributes.bottomCompartmentRemaining: null,
    DeviceAttributes.bottomCompartmentDoor: false,
    DeviceAttributes.bottomCompartmentPreheating: false,
    DeviceAttributes.bottomCompartmentCooling: false,
    DeviceAttributes.lock: false,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB3Response(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DeviceAttributes.topCompartmentStatus ||
            attr == DeviceAttributes.middleCompartmentStatus ||
            attr == DeviceAttributes.bottomCompartmentStatus) {
          if (value != null) {
            value = _statusMap[value] ?? null;
          }
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageB3Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.topCompartmentStatus:
        return msg.topCompartmentStatus != null;
      case DeviceAttributes.topCompartmentMode:
        return msg.topCompartmentMode != null;
      case DeviceAttributes.topCompartmentTemperature:
        return msg.topCompartmentTemperature != null;
      case DeviceAttributes.topCompartmentRemaining:
        return msg.topCompartmentRemaining != null;
      case DeviceAttributes.topCompartmentDoor:
        return msg.topCompartmentDoor != null;
      case DeviceAttributes.topCompartmentPreheating:
        return msg.topCompartmentPreheating != null;
      case DeviceAttributes.topCompartmentCooling:
        return msg.topCompartmentCooling != null;
      case DeviceAttributes.middleCompartmentStatus:
        return msg.middleCompartmentStatus != null;
      case DeviceAttributes.middleCompartmentMode:
        return msg.middleCompartmentMode != null;
      case DeviceAttributes.middleCompartmentTemperature:
        return msg.middleCompartmentTemperature != null;
      case DeviceAttributes.middleCompartmentRemaining:
        return msg.middleCompartmentRemaining != null;
      case DeviceAttributes.middleCompartmentDoor:
        return msg.middleCompartmentDoor != null;
      case DeviceAttributes.middleCompartmentPreheating:
        return msg.middleCompartmentPreheating != null;
      case DeviceAttributes.middleCompartmentCooling:
        return msg.middleCompartmentCooling != null;
      case DeviceAttributes.bottomCompartmentStatus:
        return msg.bottomCompartmentStatus != null;
      case DeviceAttributes.bottomCompartmentMode:
        return msg.bottomCompartmentMode != null;
      case DeviceAttributes.bottomCompartmentTemperature:
        return msg.bottomCompartmentTemperature != null;
      case DeviceAttributes.bottomCompartmentRemaining:
        return msg.bottomCompartmentRemaining != null;
      case DeviceAttributes.bottomCompartmentDoor:
        return msg.bottomCompartmentDoor != null;
      case DeviceAttributes.bottomCompartmentPreheating:
        return msg.bottomCompartmentPreheating != null;
      case DeviceAttributes.bottomCompartmentCooling:
        return msg.bottomCompartmentCooling != null;
      case DeviceAttributes.lock:
        return msg.lock != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageB3Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.topCompartmentStatus:
        return msg.topCompartmentStatus;
      case DeviceAttributes.topCompartmentMode:
        return msg.topCompartmentMode;
      case DeviceAttributes.topCompartmentTemperature:
        return msg.topCompartmentTemperature;
      case DeviceAttributes.topCompartmentRemaining:
        return msg.topCompartmentRemaining;
      case DeviceAttributes.topCompartmentDoor:
        return msg.topCompartmentDoor;
      case DeviceAttributes.topCompartmentPreheating:
        return msg.topCompartmentPreheating;
      case DeviceAttributes.topCompartmentCooling:
        return msg.topCompartmentCooling;
      case DeviceAttributes.middleCompartmentStatus:
        return msg.middleCompartmentStatus;
      case DeviceAttributes.middleCompartmentMode:
        return msg.middleCompartmentMode;
      case DeviceAttributes.middleCompartmentTemperature:
        return msg.middleCompartmentTemperature;
      case DeviceAttributes.middleCompartmentRemaining:
        return msg.middleCompartmentRemaining;
      case DeviceAttributes.middleCompartmentDoor:
        return msg.middleCompartmentDoor;
      case DeviceAttributes.middleCompartmentPreheating:
        return msg.middleCompartmentPreheating;
      case DeviceAttributes.middleCompartmentCooling:
        return msg.middleCompartmentCooling;
      case DeviceAttributes.bottomCompartmentStatus:
        return msg.bottomCompartmentStatus;
      case DeviceAttributes.bottomCompartmentMode:
        return msg.bottomCompartmentMode;
      case DeviceAttributes.bottomCompartmentTemperature:
        return msg.bottomCompartmentTemperature;
      case DeviceAttributes.bottomCompartmentRemaining:
        return msg.bottomCompartmentRemaining;
      case DeviceAttributes.bottomCompartmentDoor:
        return msg.bottomCompartmentDoor;
      case DeviceAttributes.bottomCompartmentPreheating:
        return msg.bottomCompartmentPreheating;
      case DeviceAttributes.bottomCompartmentCooling:
        return msg.bottomCompartmentCooling;
      case DeviceAttributes.lock:
        return msg.lock;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}

// ---------------------------------------------------------------------------
// MideaAppliance (alias)
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaB3Device {
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
