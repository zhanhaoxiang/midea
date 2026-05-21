/// Midea local C2 device. Mirrors midealocal/devices/c2/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// C2DeviceAttributes
// ---------------------------------------------------------------------------

class C2DeviceAttributes {
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
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static final Map<String, dynamic> _defaultAttributes = {
    C2DeviceAttributes.power: false,
    C2DeviceAttributes.childLock: false,
    C2DeviceAttributes.sensorLight: false,
    C2DeviceAttributes.foamShield: false,
    C2DeviceAttributes.lightStatus: null,
    C2DeviceAttributes.seatStatus: null,
    C2DeviceAttributes.lidStatus: null,
    C2DeviceAttributes.dryLevel: 0,
    C2DeviceAttributes.waterTempLevel: 0,
    C2DeviceAttributes.seatTempLevel: 0,
    C2DeviceAttributes.waterTemperature: null,
    C2DeviceAttributes.seatTemperature: null,
    C2DeviceAttributes.filterLife: null,
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
      case C2DeviceAttributes.power:
        return message.power;
      case C2DeviceAttributes.childLock:
        return message.childLock;
      case C2DeviceAttributes.sensorLight:
        return message.sensorLight;
      case C2DeviceAttributes.foamShield:
        return message.foamShield;
      case C2DeviceAttributes.seatStatus:
        return message.seatStatus;
      case C2DeviceAttributes.lidStatus:
        return message.lidStatus;
      case C2DeviceAttributes.lightStatus:
        return message.lightStatus;
      case C2DeviceAttributes.dryLevel:
        return message.dryLevel;
      case C2DeviceAttributes.waterTempLevel:
        return message.waterTempLevel;
      case C2DeviceAttributes.seatTempLevel:
        return message.seatTempLevel;
      case C2DeviceAttributes.waterTemperature:
        return message.waterTemperature;
      case C2DeviceAttributes.seatTemperature:
        return message.seatTemperature;
      case C2DeviceAttributes.filterLife:
        return message.filterLife;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == C2DeviceAttributes.power) {
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
    return attr == C2DeviceAttributes.childLock ||
        attr == C2DeviceAttributes.sensorLight ||
        attr == C2DeviceAttributes.foamShield ||
        attr == C2DeviceAttributes.waterTempLevel ||
        attr == C2DeviceAttributes.seatTempLevel ||
        attr == C2DeviceAttributes.dryLevel;
  }

  void _setAttrOnMessage(MessageSet message, String attr, dynamic value) {
    switch (attr) {
      case C2DeviceAttributes.childLock:
        message.childLock = value == true;
        break;
      case C2DeviceAttributes.sensorLight:
        message.sensorLight = value == true;
        break;
      case C2DeviceAttributes.foamShield:
        message.foamShield = value == true;
        break;
      case C2DeviceAttributes.waterTempLevel:
        message.waterTempLevel = value as int?;
        break;
      case C2DeviceAttributes.seatTempLevel:
        message.seatTempLevel = value as int?;
        break;
      case C2DeviceAttributes.dryLevel:
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
      C2DeviceAttributes.dryLevel: {'max_dry_level': _maxDryLevel},
      C2DeviceAttributes.waterTempLevel: {
        'max_water_temp_level': _maxWaterTempLevel,
      },
      C2DeviceAttributes.seatTempLevel: {
        'max_seat_temp_level': _maxSeatTempLevel,
      },
    });
  }
}
