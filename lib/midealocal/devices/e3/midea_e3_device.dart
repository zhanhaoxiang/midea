/// Midea local E3 device. Mirrors midealocal/devices/e3/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class E3DeviceAttributes {
  static const String power = 'power';
  static const String burningState = 'burning_state';
  static const String zeroColdWater = 'zero_cold_water';
  static const String protection = 'protection';
  static const String zeroColdPulse = 'zero_cold_pulse';
  static const String smartVolume = 'smart_volume';
  static const String currentTemperature = 'current_temperature';
  static const String targetTemperature = 'target_temperature';
}

class MideaE3Device extends MideaDevice {
  MideaE3Device({
    required String name,
    required int deviceId,
    required String ipAddress,
    required int port,
    required String token,
    required String key,
    required ProtocolVersion deviceProtocol,
    required String model,
    required int subtype,
  }) : _oldSubtypes = const [32, 33, 34, 35, 36, 37, 40, 43, 48, 49, 80],
       super(
         name: name,
         deviceId: deviceId,
         ipAddress: ipAddress,
         port: port,
         token: token,
         key: key,
         deviceProtocol: deviceProtocol,
         model: model,
         subtype: subtype,
         deviceType: DeviceType.e3,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _precisionHalves = _defaultPrecisionHalves;
    _temperatureStep = _defaultTemperatureStep;
  }

  static const bool _defaultPrecisionHalves = false;
  static const double _defaultTemperatureStep = 1.0;

  final List<int> _oldSubtypes;
  bool? _precisionHalves;
  double? _temperatureStep;

  bool? get precisionHalves => _precisionHalves;
  double? get temperatureStep => _temperatureStep;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageE3Response(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      if (_hasAttribute(message, status)) {
        var value = _getAttribute(message, status);
        if (_precisionHalves == true &&
            (status == E3DeviceAttributes.currentTemperature ||
                status == E3DeviceAttributes.targetTemperature)) {
          value = (value as double) / 2;
        }
        attrs[status] = value;
        newStatus[status] = value;
      }
    }

    return newStatus;
  }

  bool _hasAttribute(MessageE3Response msg, String attr) {
    switch (attr) {
      case E3DeviceAttributes.power:
        return msg.power != null;
      case E3DeviceAttributes.burningState:
        return msg.burningState != null;
      case E3DeviceAttributes.zeroColdWater:
        return msg.zeroColdWater != null;
      case E3DeviceAttributes.protection:
        return msg.protection != null;
      case E3DeviceAttributes.zeroColdPulse:
        return msg.zeroColdPulse != null;
      case E3DeviceAttributes.smartVolume:
        return msg.smartVolume != null;
      case E3DeviceAttributes.currentTemperature:
        return msg.currentTemperature != null;
      case E3DeviceAttributes.targetTemperature:
        return msg.targetTemperature != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageE3Response msg, String attr) {
    switch (attr) {
      case E3DeviceAttributes.power:
        return msg.power;
      case E3DeviceAttributes.burningState:
        return msg.burningState;
      case E3DeviceAttributes.zeroColdWater:
        return msg.zeroColdWater;
      case E3DeviceAttributes.protection:
        return msg.protection;
      case E3DeviceAttributes.zeroColdPulse:
        return msg.zeroColdPulse;
      case E3DeviceAttributes.smartVolume:
        return msg.smartVolume;
      case E3DeviceAttributes.currentTemperature:
        return msg.currentTemperature;
      case E3DeviceAttributes.targetTemperature:
        return msg.targetTemperature;
      default:
        return null;
    }
  }

  MessageSet _makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.zeroColdWater =
        attrs[E3DeviceAttributes.zeroColdWater] as bool? ?? false;
    message.protection = attrs[E3DeviceAttributes.protection] as bool? ?? false;
    message.zeroColdPulse =
        attrs[E3DeviceAttributes.zeroColdPulse] as bool? ?? false;
    message.smartVolume = attrs[E3DeviceAttributes.smartVolume] as bool? ?? false;
    message.targetTemperature =
        attrs[E3DeviceAttributes.targetTemperature] as double? ?? 40.0;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == E3DeviceAttributes.burningState ||
        attr == E3DeviceAttributes.currentTemperature ||
        attr == E3DeviceAttributes.protection) {
      return;
    }

    var adjustedValue = value;
    if (_precisionHalves == true &&
        attr == E3DeviceAttributes.targetTemperature) {
      adjustedValue = (value as double) * 2;
    }

    if (attr == E3DeviceAttributes.power) {
      final message = MessagePower(messageProtocolVersion);
      message.power = adjustedValue as bool;
      buildSend(message);
    } else if (_oldSubtypes.contains(subtype)) {
      final message = _makeMessageSet();
      switch (attr) {
        case E3DeviceAttributes.zeroColdWater:
          message.zeroColdWater = adjustedValue as bool;
          break;
        case E3DeviceAttributes.protection:
          message.protection = adjustedValue as bool;
          break;
        case E3DeviceAttributes.zeroColdPulse:
          message.zeroColdPulse = adjustedValue as bool;
          break;
        case E3DeviceAttributes.smartVolume:
          message.smartVolume = adjustedValue as bool;
          break;
        case E3DeviceAttributes.targetTemperature:
          message.targetTemperature = adjustedValue as double;
          break;
      }
      buildSend(message);
    } else {
      final message = MessageNewProtocolSet(messageProtocolVersion);
      message.key = _attrToKey(attr);
      message.value = adjustedValue;
      buildSend(message);
    }
  }

  String _attrToKey(String attr) {
    switch (attr) {
      case E3DeviceAttributes.zeroColdWater:
        return 'zero_cold_water';
      case E3DeviceAttributes.zeroColdPulse:
        return 'zero_cold_pulse';
      case E3DeviceAttributes.smartVolume:
        return 'smart_volume';
      case E3DeviceAttributes.targetTemperature:
        return 'target_temperature';
      default:
        return 'none';
    }
  }

  void setCustomize(String? customize) {
    _precisionHalves = _defaultPrecisionHalves;
    _temperatureStep = _defaultTemperatureStep;
    if (customize != null && customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>;
        if (params.containsKey('temperature_step')) {
          _temperatureStep = (params['temperature_step'] as num).toDouble();
        }
        if (params.containsKey('precision_halves')) {
          _precisionHalves = params['precision_halves'] as bool;
        }
      } catch (_) {}
    }
    updateAll({
      'temperature_step': _temperatureStep,
      'precision_halves': _precisionHalves,
    });
  }

  static final Map<String, dynamic> _defaultAttributes = {
    E3DeviceAttributes.power: false,
    E3DeviceAttributes.burningState: false,
    E3DeviceAttributes.zeroColdWater: false,
    E3DeviceAttributes.protection: false,
    E3DeviceAttributes.zeroColdPulse: false,
    E3DeviceAttributes.smartVolume: false,
    E3DeviceAttributes.currentTemperature: null,
    E3DeviceAttributes.targetTemperature: 40.0,
  };
}

class MideaAppliance extends MideaE3Device {
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
