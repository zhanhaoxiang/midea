/// Midea local C2 device. Mirrors midealocal/devices/c2/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String power = 'power';
  static const String childLock = 'child_lock';
  static const String sensorLight = 'sensor_light';
  static const String foamShield = 'foam_shield';
  static const String seatStatus = 'seat_status';
  static const String lidStatus = 'lid_status';
  static const String lightStatus = 'light_status';
  static const String dryLevel = 'dry_level';
  static const String waterTempLevel = 'water_temp_level';
  static const String seatTempLevel = 'seat_temp_level';
  static const String waterTemperature = 'water_temperature';
  static const String seatTemperature = 'seat_temperature';
  static const String filterLife = 'filter_life';
}

// ---------------------------------------------------------------------------
// MideaC2Device
// ---------------------------------------------------------------------------

class MideaC2Device extends MideaDevice {
  MideaC2Device({
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
         deviceType: DeviceType.c2,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       ) {
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.power: false,
    DeviceAttributes.childLock: false,
    DeviceAttributes.sensorLight: false,
    DeviceAttributes.foamShield: false,
    DeviceAttributes.lightStatus: null,
    DeviceAttributes.seatStatus: null,
    DeviceAttributes.lidStatus: null,
    DeviceAttributes.dryLevel: 0,
    DeviceAttributes.waterTempLevel: 0,
    DeviceAttributes.seatTempLevel: 0,
    DeviceAttributes.waterTemperature: null,
    DeviceAttributes.seatTemperature: null,
    DeviceAttributes.filterLife: null,
  };

  int? _maxDryLevel;
  int? _maxWaterTempLevel;
  int? _maxSeatTempLevel;

  static const int _defaultMaxDryLevel = 3;
  static const int _defaultMaxWaterTempLevel = 5;
  static const int _defaultMaxSeatTempLevel = 5;

  int? get maxDryLevel => _maxDryLevel;
  int? get maxWaterTempLevel => _maxWaterTempLevel;
  int? get maxSeatTempLevel => _maxSeatTempLevel;

  @override
  List<MessageQuery> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageC2Response(msg);
    final newStatus = <String, dynamic>{};
    for (final status in attrs.keys) {
      final value = _getAttrValue(message, status);
      if (value != null) {
        attrs[status] = value;
        newStatus[status] = value;
      }
    }
    return newStatus;
  }

  dynamic _getAttrValue(MessageC2Response message, String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return message.power;
      case DeviceAttributes.childLock:
        return message.childLock;
      case DeviceAttributes.sensorLight:
        return message.sensorLight;
      case DeviceAttributes.foamShield:
        return message.foamShield;
      case DeviceAttributes.seatStatus:
        return message.seatStatus;
      case DeviceAttributes.lidStatus:
        return message.lidStatus;
      case DeviceAttributes.lightStatus:
        return message.lightStatus;
      case DeviceAttributes.dryLevel:
        return message.dryLevel;
      case DeviceAttributes.waterTempLevel:
        return message.waterTempLevel;
      case DeviceAttributes.seatTempLevel:
        return message.seatTempLevel;
      case DeviceAttributes.waterTemperature:
        return message.waterTemperature;
      case DeviceAttributes.seatTemperature:
        return message.seatTemperature;
      case DeviceAttributes.filterLife:
        return message.filterLife;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.power) {
      final message = MessagePower(messageProtocolVersion);
      message.power = value == true;
      buildSend(message);
    } else if (_isSettableAttr(attr)) {
      final message = MessageSet(messageProtocolVersion);
      _setAttrOnMessage(message, attr, value);
      buildSend(message);
    }
  }

  bool _isSettableAttr(String attr) {
    return attr == DeviceAttributes.childLock ||
        attr == DeviceAttributes.sensorLight ||
        attr == DeviceAttributes.foamShield ||
        attr == DeviceAttributes.waterTempLevel ||
        attr == DeviceAttributes.seatTempLevel ||
        attr == DeviceAttributes.dryLevel;
  }

  void _setAttrOnMessage(MessageSet message, String attr, dynamic value) {
    switch (attr) {
      case DeviceAttributes.childLock:
        message.childLock = value == true;
        break;
      case DeviceAttributes.sensorLight:
        message.sensorLight = value == true;
        break;
      case DeviceAttributes.foamShield:
        message.foamShield = value == true;
        break;
      case DeviceAttributes.waterTempLevel:
        message.waterTempLevel = value as int?;
        break;
      case DeviceAttributes.seatTempLevel:
        message.seatTempLevel = value as int?;
        break;
      case DeviceAttributes.dryLevel:
        message.dryLevel = value as int?;
        break;
    }
  }

  void setCustomize(String customize) {
    _maxDryLevel = _defaultMaxDryLevel;
    _maxWaterTempLevel = _defaultMaxWaterTempLevel;
    _maxSeatTempLevel = _defaultMaxSeatTempLevel;

    if (customize.isNotEmpty) {
      try {
        final params = jsonDecode(customize) as Map<String, dynamic>;
        if (params['max_dry_level'] != null) {
          _maxDryLevel = params['max_dry_level'] as int?;
        }
        if (params['max_water_temp_level'] != null) {
          _maxWaterTempLevel = params['max_water_temp_level'] as int?;
        }
        if (params['max_seat_temp_level'] != null) {
          _maxSeatTempLevel = params['max_seat_temp_level'] as int?;
        }
      } catch (_) {}
    }

    updateAll({
      DeviceAttributes.dryLevel: {'max_dry_level': _maxDryLevel},
      DeviceAttributes.waterTempLevel: {
        'max_water_temp_level': _maxWaterTempLevel,
      },
      DeviceAttributes.seatTempLevel: {
        'max_seat_temp_level': _maxSeatTempLevel,
      },
    });
  }
}
