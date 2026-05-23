/// Midea local CF device. Mirrors midealocal/devices/cf/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// CfDeviceAttributes
// ---------------------------------------------------------------------------

class CfDeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String targetTemperature = 'target_temperature';
  static const String auxHeating = 'aux_heating';
  static const String currentTemperature = 'current_temperature';
  static const String maxTemperature = 'max_temperature';
  static const String minTemperature = 'min_temperature';
  static const String defrost = 'defrost';
  static const String freeze = 'freeze';
}

// ---------------------------------------------------------------------------
// MideaCFDevice
// ---------------------------------------------------------------------------

class MideaCFDevice extends MideaDevice {
  MideaCFDevice({
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
         deviceType: DeviceType.cf,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    CfDeviceAttributes.power: false,
    CfDeviceAttributes.mode: 0,
    CfDeviceAttributes.defrost: false,
    CfDeviceAttributes.freeze: false,
    CfDeviceAttributes.targetTemperature: null,
    CfDeviceAttributes.auxHeating: false,
    CfDeviceAttributes.currentTemperature: 0,
    CfDeviceAttributes.maxTemperature: 55,
    CfDeviceAttributes.minTemperature: 5,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageCFResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        final value = _getAttribute(message, attr);
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageCFResponse msg, String attr) {
    switch (attr) {
      case CfDeviceAttributes.power:
        return msg.power != null;
      case CfDeviceAttributes.mode:
        return msg.mode != null;
      case CfDeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      case CfDeviceAttributes.auxHeating:
        return msg.auxHeating != null;
      case CfDeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case CfDeviceAttributes.maxTemperature:
        return msg.maxTemperature != null;
      case CfDeviceAttributes.minTemperature:
        return msg.minTemperature != null;
      case CfDeviceAttributes.defrost:
        return msg.defrost != null;
      case CfDeviceAttributes.freeze:
        return msg.freeze != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCFResponse msg, String attr) {
    switch (attr) {
      case CfDeviceAttributes.power:
        return msg.power;
      case CfDeviceAttributes.mode:
        return msg.mode;
      case CfDeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      case CfDeviceAttributes.auxHeating:
        return msg.auxHeating;
      case CfDeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case CfDeviceAttributes.maxTemperature:
        return msg.maxTemperature;
      case CfDeviceAttributes.minTemperature:
        return msg.minTemperature;
      case CfDeviceAttributes.defrost:
        return msg.defrost;
      case CfDeviceAttributes.freeze:
        return msg.freeze;
      default:
        return null;
    }
  }

  void setTargetTemperature(double targetTemperature, {int? mode, int? zone}) {
    final message = MessageSet(messageProtocolVersion);
    message.power = true;
    message.mode = attrs[CfDeviceAttributes.mode] as int? ?? 0;
    message.targetTemperature = targetTemperature;
    if (mode != null) {
      message.mode = mode;
    }
    buildSend(message);
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == CfDeviceAttributes.power && value is! bool) {
      throw MideaLocalError('[cf] Expected bool');
    }
    if (attr == CfDeviceAttributes.auxHeating && value is! bool) {
      throw MideaLocalError('[cf] Expected bool');
    }
    final message = MessageSet(messageProtocolVersion);
    message.power = true;
    message.mode = attrs[CfDeviceAttributes.mode] as int? ?? 0;
    if (attr == CfDeviceAttributes.power) {
      message.power = value as bool;
    } else if (attr == CfDeviceAttributes.mode) {
      message.power = true;
      message.mode = value as int;
    } else if (attr == CfDeviceAttributes.targetTemperature) {
      message.targetTemperature = (value as num).toDouble();
    } else if (attr == CfDeviceAttributes.auxHeating) {
      message.auxHeating = value as bool;
    }
    buildSend(message);
  }
}
