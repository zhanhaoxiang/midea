/// Midea local CF device. Mirrors midealocal/devices/cf/__init__.py.

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
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.power: false,
    DeviceAttributes.mode: 0,
    DeviceAttributes.defrost: false,
    DeviceAttributes.freeze: false,
    DeviceAttributes.targetTemperature: null,
    DeviceAttributes.auxHeating: false,
    DeviceAttributes.currentTemperature: 0,
    DeviceAttributes.maxTemperature: 55,
    DeviceAttributes.minTemperature: 5,
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
      case DeviceAttributes.power:
        return msg.power != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      case DeviceAttributes.auxHeating:
        return msg.auxHeating != null;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case DeviceAttributes.maxTemperature:
        return msg.maxTemperature != null;
      case DeviceAttributes.minTemperature:
        return msg.minTemperature != null;
      case DeviceAttributes.defrost:
        return msg.defrost != null;
      case DeviceAttributes.freeze:
        return msg.freeze != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCFResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return msg.power;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      case DeviceAttributes.auxHeating:
        return msg.auxHeating;
      case DeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case DeviceAttributes.maxTemperature:
        return msg.maxTemperature;
      case DeviceAttributes.minTemperature:
        return msg.minTemperature;
      case DeviceAttributes.defrost:
        return msg.defrost;
      case DeviceAttributes.freeze:
        return msg.freeze;
      default:
        return null;
    }
  }

  void setTargetTemperature(double targetTemperature, {int? mode, int? zone}) {
    final message = MessageSet(messageProtocolVersion);
    message.power = true;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 0;
    message.targetTemperature = targetTemperature;
    if (mode != null) {
      message.mode = mode;
    }
    buildSend(message);
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.power && value is! bool) {
      throw MideaLocalError('[cf] Expected bool');
    }
    if (attr == DeviceAttributes.auxHeating && value is! bool) {
      throw MideaLocalError('[cf] Expected bool');
    }
    final message = MessageSet(messageProtocolVersion);
    message.power = true;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 0;
    if (attr == DeviceAttributes.power) {
      message.power = value as bool;
    } else if (attr == DeviceAttributes.mode) {
      message.power = true;
      message.mode = value as int;
    } else if (attr == DeviceAttributes.targetTemperature) {
      message.targetTemperature = (value as num).toDouble();
    } else if (attr == DeviceAttributes.auxHeating) {
      message.auxHeating = value as bool;
    }
    buildSend(message);
  }
}
