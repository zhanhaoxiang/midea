/// Midea local B3 device. Mirrors midealocal/devices/b3/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// B3DeviceAttributes
// ---------------------------------------------------------------------------

class B3DeviceAttributes {
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
    B3DeviceAttributes.topCompartmentStatus: null,
    B3DeviceAttributes.topCompartmentMode: null,
    B3DeviceAttributes.topCompartmentTemperature: null,
    B3DeviceAttributes.topCompartmentRemaining: null,
    B3DeviceAttributes.topCompartmentDoor: false,
    B3DeviceAttributes.topCompartmentPreheating: false,
    B3DeviceAttributes.topCompartmentCooling: false,
    B3DeviceAttributes.middleCompartmentStatus: null,
    B3DeviceAttributes.middleCompartmentMode: null,
    B3DeviceAttributes.middleCompartmentTemperature: null,
    B3DeviceAttributes.middleCompartmentRemaining: null,
    B3DeviceAttributes.middleCompartmentDoor: false,
    B3DeviceAttributes.middleCompartmentPreheating: false,
    B3DeviceAttributes.middleCompartmentCooling: false,
    B3DeviceAttributes.bottomCompartmentStatus: null,
    B3DeviceAttributes.bottomCompartmentMode: null,
    B3DeviceAttributes.bottomCompartmentTemperature: null,
    B3DeviceAttributes.bottomCompartmentRemaining: null,
    B3DeviceAttributes.bottomCompartmentDoor: false,
    B3DeviceAttributes.bottomCompartmentPreheating: false,
    B3DeviceAttributes.bottomCompartmentCooling: false,
    B3DeviceAttributes.lock: false,
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
        if (attr == B3DeviceAttributes.topCompartmentStatus ||
            attr == B3DeviceAttributes.middleCompartmentStatus ||
            attr == B3DeviceAttributes.bottomCompartmentStatus) {
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
      case B3DeviceAttributes.topCompartmentStatus:
        return msg.topCompartmentStatus != null;
      case B3DeviceAttributes.topCompartmentMode:
        return msg.topCompartmentMode != null;
      case B3DeviceAttributes.topCompartmentTemperature:
        return msg.topCompartmentTemperature != null;
      case B3DeviceAttributes.topCompartmentRemaining:
        return msg.topCompartmentRemaining != null;
      case B3DeviceAttributes.topCompartmentDoor:
        return msg.topCompartmentDoor != null;
      case B3DeviceAttributes.topCompartmentPreheating:
        return msg.topCompartmentPreheating != null;
      case B3DeviceAttributes.topCompartmentCooling:
        return msg.topCompartmentCooling != null;
      case B3DeviceAttributes.middleCompartmentStatus:
        return msg.middleCompartmentStatus != null;
      case B3DeviceAttributes.middleCompartmentMode:
        return msg.middleCompartmentMode != null;
      case B3DeviceAttributes.middleCompartmentTemperature:
        return msg.middleCompartmentTemperature != null;
      case B3DeviceAttributes.middleCompartmentRemaining:
        return msg.middleCompartmentRemaining != null;
      case B3DeviceAttributes.middleCompartmentDoor:
        return msg.middleCompartmentDoor != null;
      case B3DeviceAttributes.middleCompartmentPreheating:
        return msg.middleCompartmentPreheating != null;
      case B3DeviceAttributes.middleCompartmentCooling:
        return msg.middleCompartmentCooling != null;
      case B3DeviceAttributes.bottomCompartmentStatus:
        return msg.bottomCompartmentStatus != null;
      case B3DeviceAttributes.bottomCompartmentMode:
        return msg.bottomCompartmentMode != null;
      case B3DeviceAttributes.bottomCompartmentTemperature:
        return msg.bottomCompartmentTemperature != null;
      case B3DeviceAttributes.bottomCompartmentRemaining:
        return msg.bottomCompartmentRemaining != null;
      case B3DeviceAttributes.bottomCompartmentDoor:
        return msg.bottomCompartmentDoor != null;
      case B3DeviceAttributes.bottomCompartmentPreheating:
        return msg.bottomCompartmentPreheating != null;
      case B3DeviceAttributes.bottomCompartmentCooling:
        return msg.bottomCompartmentCooling != null;
      case B3DeviceAttributes.lock:
        return msg.lock != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageB3Response msg, String attr) {
    switch (attr) {
      case B3DeviceAttributes.topCompartmentStatus:
        return msg.topCompartmentStatus;
      case B3DeviceAttributes.topCompartmentMode:
        return msg.topCompartmentMode;
      case B3DeviceAttributes.topCompartmentTemperature:
        return msg.topCompartmentTemperature;
      case B3DeviceAttributes.topCompartmentRemaining:
        return msg.topCompartmentRemaining;
      case B3DeviceAttributes.topCompartmentDoor:
        return msg.topCompartmentDoor;
      case B3DeviceAttributes.topCompartmentPreheating:
        return msg.topCompartmentPreheating;
      case B3DeviceAttributes.topCompartmentCooling:
        return msg.topCompartmentCooling;
      case B3DeviceAttributes.middleCompartmentStatus:
        return msg.middleCompartmentStatus;
      case B3DeviceAttributes.middleCompartmentMode:
        return msg.middleCompartmentMode;
      case B3DeviceAttributes.middleCompartmentTemperature:
        return msg.middleCompartmentTemperature;
      case B3DeviceAttributes.middleCompartmentRemaining:
        return msg.middleCompartmentRemaining;
      case B3DeviceAttributes.middleCompartmentDoor:
        return msg.middleCompartmentDoor;
      case B3DeviceAttributes.middleCompartmentPreheating:
        return msg.middleCompartmentPreheating;
      case B3DeviceAttributes.middleCompartmentCooling:
        return msg.middleCompartmentCooling;
      case B3DeviceAttributes.bottomCompartmentStatus:
        return msg.bottomCompartmentStatus;
      case B3DeviceAttributes.bottomCompartmentMode:
        return msg.bottomCompartmentMode;
      case B3DeviceAttributes.bottomCompartmentTemperature:
        return msg.bottomCompartmentTemperature;
      case B3DeviceAttributes.bottomCompartmentRemaining:
        return msg.bottomCompartmentRemaining;
      case B3DeviceAttributes.bottomCompartmentDoor:
        return msg.bottomCompartmentDoor;
      case B3DeviceAttributes.bottomCompartmentPreheating:
        return msg.bottomCompartmentPreheating;
      case B3DeviceAttributes.bottomCompartmentCooling:
        return msg.bottomCompartmentCooling;
      case B3DeviceAttributes.lock:
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
