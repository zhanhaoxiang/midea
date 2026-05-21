/// Midea local FB device. Mirrors midealocal/devices/fb/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// FbDeviceAttributes
// ---------------------------------------------------------------------------

class FbDeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String heatingLevel = 'heating_level';
  static const String targetTemperature = 'target_temperature';
  static const String currentTemperature = 'current_temperature';
  static const String childLock = 'child_lock';
}

// ---------------------------------------------------------------------------
// MideaFBDevice
// ---------------------------------------------------------------------------

class MideaFBDevice extends MideaDevice {
  static const Map<int, String> _modes = {
    0x01: 'Auto',
    0x02: 'ECO',
    0x03: 'Sleep',
    0x04: 'Anti-freezing',
    0x05: 'Comfort',
    0x06: 'Constant-temperature',
    0x07: 'Normal',
    0x08: 'Fast-heating',
    0x10: 'Standby',
  };

  static final Map<String, dynamic> _defaultAttributes = {
    FbDeviceAttributes.power: false,
    FbDeviceAttributes.mode: null,
    FbDeviceAttributes.heatingLevel: 0,
    FbDeviceAttributes.targetTemperature: null,
    FbDeviceAttributes.currentTemperature: null,
    FbDeviceAttributes.childLock: false,
  };

  MideaFBDevice({
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
         deviceType: DeviceType.fb,
         ipAddress: ipAddress,
         port: port,
         token: token,
         key: key,
         deviceProtocol: deviceProtocol,
         model: model,
         subtype: subtype,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  List<String> get modes => _modes.values.toList();

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageFBResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == FbDeviceAttributes.mode) {
          if (value is int && _modes.containsKey(value)) {
            value = _modes[value];
          } else {
            value = null;
          }
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageFBResponse msg, String attr) {
    switch (attr) {
      case FbDeviceAttributes.power:
        return msg.power != null;
      case FbDeviceAttributes.mode:
        return msg.mode != null;
      case FbDeviceAttributes.heatingLevel:
        return msg.heatingLevel != null;
      case FbDeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      case FbDeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case FbDeviceAttributes.childLock:
        return msg.childLock != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageFBResponse msg, String attr) {
    switch (attr) {
      case FbDeviceAttributes.power:
        return msg.power;
      case FbDeviceAttributes.mode:
        return msg.mode;
      case FbDeviceAttributes.heatingLevel:
        return msg.heatingLevel;
      case FbDeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      case FbDeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case FbDeviceAttributes.childLock:
        return msg.childLock;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final message = MessageSet(messageProtocolVersion, subtype);
    if (attr == FbDeviceAttributes.mode) {
      if (value is String && _modes.containsValue(value)) {
        final modeKey = _modes.keys.firstWhere((k) => _modes[k] == value);
        message.mode = modeKey;
      }
    } else {
      switch (attr) {
        case FbDeviceAttributes.power:
          message.power = value as bool;
          break;
        case FbDeviceAttributes.heatingLevel:
          message.heatingLevel = value as int;
          break;
        case FbDeviceAttributes.targetTemperature:
          message.targetTemperature = value as int;
          break;
        case FbDeviceAttributes.childLock:
          message.childLock = value as bool;
          break;
      }
    }
    buildSend(message);
  }

  void setTargetTemperature(double targetTemperature, {int? mode, int? zone}) {
    final message = MessageSet(messageProtocolVersion, subtype);
    message.targetTemperature = targetTemperature.round();
    buildSend(message);
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaFBDevice {
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
