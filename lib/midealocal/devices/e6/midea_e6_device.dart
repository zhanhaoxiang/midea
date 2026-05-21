/// Midea local E6 device. Mirrors midealocal/devices/e6/__init__.py.

import 'dart:convert';
import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class E6DeviceAttributes {
  static const String mainPower = 'main_power';
  static const String heatingPower = 'heating_power';
  static const String heatingWorking = 'heating_working';
  static const String bathingWorking = 'bathing_working';
  static const String minTemperature = 'temperature_min';
  static const String maxTemperature = 'temperature_max';
  static const String heatingTemperature = 'heating_temperature';
  static const String bathingTemperature = 'bathing_temperature';
  static const String heatingLeavingTemperature = 'heating_leaving_temperature';
  static const String bathingLeavingTemperature = 'bathing_leaving_temperature';
  static const String coldWaterSingle = 'cold_water_single';
  static const String coldWaterDot = 'cold_water_dot';
  static const String heatingModes = 'heating_modes';
}

class MideaE6Device extends MideaDevice {
  MideaE6Device({
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
         deviceType: DeviceType.e6,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _temperatureStep = _defaultTemperatureStep;
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const List<String> _heatingModes = [
    'normal_mode',
    'out_mode',
    'home_mode',
    'sleep_mode',
  ];

  static const double _defaultTemperatureStep = 1.0;

  static final Map<String, dynamic> _defaultAttributes = {
    E6DeviceAttributes.mainPower: false,
    E6DeviceAttributes.heatingPower: true,
    E6DeviceAttributes.heatingWorking: null,
    E6DeviceAttributes.bathingWorking: null,
    E6DeviceAttributes.minTemperature: [30.0, 35.0],
    E6DeviceAttributes.maxTemperature: [80.0, 60.0],
    E6DeviceAttributes.heatingTemperature: 50.0,
    E6DeviceAttributes.bathingTemperature: 40.0,
    E6DeviceAttributes.heatingLeavingTemperature: null,
    E6DeviceAttributes.bathingLeavingTemperature: null,
    E6DeviceAttributes.coldWaterSingle: null,
    E6DeviceAttributes.coldWaterDot: null,
    E6DeviceAttributes.heatingModes: null,
  };

  double? _temperatureStep;

  double? get temperatureStep => _temperatureStep;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageE6Response(msg);
    final newStatus = <String, dynamic>{};
    for (final status in attrs.keys) {
      if (message.hasAttribute(status)) {
        final value = message.getAttribute(status);
        attrs[status] = value;
        newStatus[status] = value;
      }
    }
    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == E6DeviceAttributes.mainPower ||
        attr == E6DeviceAttributes.heatingPower ||
        attr == E6DeviceAttributes.heatingTemperature ||
        attr == E6DeviceAttributes.bathingTemperature ||
        attr == E6DeviceAttributes.heatingModes ||
        attr == E6DeviceAttributes.coldWaterSingle ||
        attr == E6DeviceAttributes.coldWaterDot) {
      final message = MessageSet(messageProtocolVersion);
      switch (attr) {
        case E6DeviceAttributes.mainPower:
          message.mainPower = value as bool;
          break;
        case E6DeviceAttributes.heatingPower:
          message.heatingPower = value as bool;
          break;
        case E6DeviceAttributes.heatingTemperature:
          message.heatingTemperature = (value as num).toDouble();
          break;
        case E6DeviceAttributes.bathingTemperature:
          message.bathingTemperature = (value as num).toDouble();
          break;
        case E6DeviceAttributes.heatingModes:
          message.heatingModes = value as String;
          break;
        case E6DeviceAttributes.coldWaterSingle:
          message.coldWaterSingle = value as bool;
          break;
        case E6DeviceAttributes.coldWaterDot:
          message.coldWaterDot = value as bool;
          break;
      }
      buildSend(message);
    }
  }

  List<String> get heatingModesList => _heatingModes;

  void setCustomize(String customize) {
    if (customize.isNotEmpty) {
      try {
        final params = json.decode(customize) as Map<String, dynamic>;
        if (params.containsKey('temperature_step')) {
          _temperatureStep = (params['temperature_step'] as num).toDouble();
        }
      } catch (e) {
        // Log exception
      }
      updateAll({'temperature_step': _temperatureStep});
    }
  }
}

class MideaAppliance extends MideaE6Device {
  MideaAppliance({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required super.deviceProtocol,
    required super.model,
    required super.subtype,
    super.customize,
  });
}
