/// Midea local ED device. Mirrors midealocal/devices/ed/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// EdDeviceAttributes
// ---------------------------------------------------------------------------

class EdDeviceAttributes {
  static const String power = 'power';
  static const String waterConsumption = 'water_consumption';
  static const String inTds = 'in_tds';
  static const String outTds = 'out_tds';
  static const String filter1 = 'filter1';
  static const String filter2 = 'filter2';
  static const String filter3 = 'filter3';
  static const String life1 = 'life1';
  static const String life2 = 'life2';
  static const String life3 = 'life3';
  static const String childLock = 'child_lock';
}

// ---------------------------------------------------------------------------
// MideaEDDevice
// ---------------------------------------------------------------------------

class MideaEDDevice extends MideaDevice {
  static final List<int> _subtypeQuery04 = [
    309,
    310,
    311,
    313,
    314,
    315,
    317,
    330,
  ];
  static final List<int> _subtypeQuery05 = [316, 318, 319, 320];
  static final List<int> _subtypeQuery06 = [290, 331, 332, 340];
  static final List<int> _subtypeQuery07 = [288, 307, 329, 349];
  static final List<int> _subtypeQuery01 = [775];

  MideaEDDevice({
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
         deviceType: DeviceType.ed,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    EdDeviceAttributes.power: false,
    EdDeviceAttributes.waterConsumption: null,
    EdDeviceAttributes.inTds: null,
    EdDeviceAttributes.outTds: null,
    EdDeviceAttributes.filter1: null,
    EdDeviceAttributes.filter2: null,
    EdDeviceAttributes.filter3: null,
    EdDeviceAttributes.life1: null,
    EdDeviceAttributes.life2: null,
    EdDeviceAttributes.life3: null,
    EdDeviceAttributes.childLock: false,
  };

  int _deviceClass = 0x00;

  bool _useNewSet() => true;

  @override
  List<MessageRequest> buildQuery() {
    final st = subtype;
    if (_subtypeQuery04.contains(st)) {
      return [MessageQuery04(messageProtocolVersion)];
    }
    if (_subtypeQuery05.contains(st)) {
      return [MessageQuery05(messageProtocolVersion)];
    }
    if (_subtypeQuery06.contains(st)) {
      return [MessageQuery06(messageProtocolVersion)];
    }
    if (_subtypeQuery07.contains(st)) {
      return [MessageQuery07(messageProtocolVersion)];
    }
    if (_subtypeQuery01.contains(st)) {
      return [MessageQuery01(messageProtocolVersion)];
    }
    return [
      MessageQuery(messageProtocolVersion),
      MessageQuery01(messageProtocolVersion),
      MessageQueryFF(messageProtocolVersion),
    ];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageEDResponse(msg);
    final newStatus = <String, dynamic>{};

    if (message.deviceClass != null) {
      _deviceClass = message.deviceClass!;
    }

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        final value = _getAttribute(message, attr);
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageEDResponse msg, String attr) {
    switch (attr) {
      case EdDeviceAttributes.power:
        return msg.power != null;
      case EdDeviceAttributes.waterConsumption:
        return msg.waterConsumption != null;
      case EdDeviceAttributes.inTds:
        return msg.inTds != null;
      case EdDeviceAttributes.outTds:
        return msg.outTds != null;
      case EdDeviceAttributes.filter1:
        return msg.filter1 != null;
      case EdDeviceAttributes.filter2:
        return msg.filter2 != null;
      case EdDeviceAttributes.filter3:
        return msg.filter3 != null;
      case EdDeviceAttributes.life1:
        return msg.life1 != null;
      case EdDeviceAttributes.life2:
        return msg.life2 != null;
      case EdDeviceAttributes.life3:
        return msg.life3 != null;
      case EdDeviceAttributes.childLock:
        return msg.childLock != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageEDResponse msg, String attr) {
    switch (attr) {
      case EdDeviceAttributes.power:
        return msg.power;
      case EdDeviceAttributes.waterConsumption:
        return msg.waterConsumption;
      case EdDeviceAttributes.inTds:
        return msg.inTds;
      case EdDeviceAttributes.outTds:
        return msg.outTds;
      case EdDeviceAttributes.filter1:
        return msg.filter1;
      case EdDeviceAttributes.filter2:
        return msg.filter2;
      case EdDeviceAttributes.filter3:
        return msg.filter3;
      case EdDeviceAttributes.life1:
        return msg.life1;
      case EdDeviceAttributes.life2:
        return msg.life2;
      case EdDeviceAttributes.life3:
        return msg.life3;
      case EdDeviceAttributes.childLock:
        return msg.childLock;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    MessageRequest? message;
    if (_useNewSet()) {
      if (attr == EdDeviceAttributes.power ||
          attr == EdDeviceAttributes.childLock) {
        final newSet = MessageNewSet(messageProtocolVersion);
        if (attr == EdDeviceAttributes.power) {
          if (value is! bool) {
            throw MideaLocalError('[ed] Expected bool');
          }
          newSet.power = value;
        } else if (attr == EdDeviceAttributes.childLock) {
          if (value is! bool) {
            throw MideaLocalError('[ed] Expected bool');
          }
          newSet.lock = value;
        }
        message = newSet;
      }
    }
    if (message != null) {
      buildSend(message);
    }
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaEDDevice {
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
