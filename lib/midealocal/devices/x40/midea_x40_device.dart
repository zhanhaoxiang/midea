/// Midea local X40 device. Mirrors midealocal/devices/x40/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

const int directionMinValue = 60;
const int directionMaxValue = 100;
const int ventilationFanSpeed = 2;

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String light = 'light';
  static const String fanSpeed = 'fan_speed';
  static const String direction = 'direction';
  static const String ventilation = 'ventilation';
  static const String smellySensor = 'smelly_sensor';
  static const String currentTemperature = 'current_temperature';
}

// ---------------------------------------------------------------------------
// MideaX40Device
// ---------------------------------------------------------------------------

class MideaX40Device extends MideaDevice {
  MideaX40Device({
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
  }) : _deviceProtocolVersion = deviceProtocol,
       _precisionHalves = false,
       super(
         name: name,
         deviceId: deviceId,
         deviceType: DeviceType.x40,
         ipAddress: ipAddress,
         port: port,
         token: token,
         key: key,
         deviceProtocol: deviceProtocol,
         model: model,
         subtype: subtype,
         attributes: _defaultAttributes,
       ) {
    _fields = {};
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const List<String> _directions = [
    '60',
    '70',
    '80',
    '90',
    '100',
    'Oscillate',
  ];

  static const Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.light: false,
    DeviceAttributes.fanSpeed: 0,
    DeviceAttributes.direction: false,
    DeviceAttributes.ventilation: false,
    DeviceAttributes.smellySensor: false,
    DeviceAttributes.currentTemperature: null,
  };

  final ProtocolVersion _deviceProtocolVersion;
  Map<String, int> _fields = {};
  bool _precisionHalves = false;

  bool get precisionHalves => _precisionHalves;

  List<String> get directions => _directions;

  int _convertToMideaDirection(String direction) {
    if (direction == 'Oscillate' || !_directions.contains(direction)) {
      return 0xFD;
    }
    return _directions.indexOf(direction) * 10 + 60;
  }

  int _convertFromMideaDirection(int direction) {
    if (direction > directionMaxValue || direction < directionMinValue) {
      return 5;
    }
    return ((direction - 60 + 5) / 10).floor();
  }

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(_deviceProtocolVersion.value)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageX40Response(msg);
    final newStatus = <String, dynamic>{};
    _fields = message.fields;
    for (final status in attrs.keys) {
      final statusStr = status.toString();
      if (_hasAttr(message, statusStr)) {
        dynamic value = _getAttr(message, statusStr);
        if (_precisionHalves && status == DeviceAttributes.currentTemperature) {
          value = (value as int) / 2;
        }
        if (status == DeviceAttributes.direction) {
          attrs[status] = _directions[_convertFromMideaDirection(value as int)];
        } else {
          attrs[status] = value;
        }
        newStatus[statusStr] = attrs[status];
      }
    }
    return newStatus;
  }

  bool _hasAttr(MessageX40Response message, String attr) {
    switch (attr) {
      case DeviceAttributes.light:
      case DeviceAttributes.fanSpeed:
      case DeviceAttributes.direction:
      case DeviceAttributes.ventilation:
      case DeviceAttributes.smellySensor:
      case DeviceAttributes.currentTemperature:
        return true;
      default:
        return false;
    }
  }

  dynamic _getAttr(MessageX40Response message, String attr) {
    switch (attr) {
      case DeviceAttributes.light:
        return message.light;
      case DeviceAttributes.fanSpeed:
        return message.fanSpeed;
      case DeviceAttributes.direction:
        return message.direction;
      case DeviceAttributes.ventilation:
        return message.ventilation;
      case DeviceAttributes.smellySensor:
        return message.smellySensor;
      case DeviceAttributes.currentTemperature:
        return message.currentTemperature;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.light ||
        attr == DeviceAttributes.fanSpeed ||
        attr == DeviceAttributes.direction ||
        attr == DeviceAttributes.ventilation ||
        attr == DeviceAttributes.smellySensor) {
      final message = MessageSet(_deviceProtocolVersion.value);
      message.fields = Map<String, int>.from(_fields);
      message.light = attrs[DeviceAttributes.light] as bool;
      message.ventilation = attrs[DeviceAttributes.ventilation] as bool;
      message.smellySensor = attrs[DeviceAttributes.smellySensor] as bool;
      message.fanSpeed = attrs[DeviceAttributes.fanSpeed] as int;
      message.direction = _convertToMideaDirection(
        attrs[DeviceAttributes.direction].toString(),
      );
      if (attr == DeviceAttributes.direction) {
        message.direction = _convertToMideaDirection(value.toString());
      } else if (attr == DeviceAttributes.ventilation &&
          message.fanSpeed == ventilationFanSpeed) {
        message.fanSpeed = 1;
        message.ventilation = value as bool;
      } else {
        switch (attr) {
          case DeviceAttributes.light:
            message.light = value as bool;
            break;
          case DeviceAttributes.fanSpeed:
            message.fanSpeed = value as int;
            break;
          case DeviceAttributes.ventilation:
            message.ventilation = value as bool;
            break;
          case DeviceAttributes.smellySensor:
            message.smellySensor = value as bool;
            break;
        }
      }
      buildSend(message);
    }
  }

  void setCustomize(String customize) {
    _precisionHalves = false;
    if (customize.isNotEmpty) {
      try {
        final params = jsonDecode(customize);
        if (params is Map && params.containsKey('precision_halves')) {
          _precisionHalves = params['precision_halves'];
        }
      } catch (_) {}
      updateAll({'precision_halves': _precisionHalves});
    }
  }
}

// ---------------------------------------------------------------------------
// MideaAppliance
// ---------------------------------------------------------------------------

class MideaAppliance extends MideaX40Device {
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
