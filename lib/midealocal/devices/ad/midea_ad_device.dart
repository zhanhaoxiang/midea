/// Midea local AD device. Mirrors midealocal/devices/ad/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String tvoc = 'tvoc';
  static const String co2 = 'co2';
  static const String pm25 = 'pm25';
  static const String hcho = 'hcho';
  static const String presetsFunction = 'presets_function';
  static const String fallAsleepStatus = 'fall_asleep_status';
  static const String portableSense = 'portable_sense';
  static const String nightMode = 'night_mode';
  static const String screenExtinctionTimeout = 'screen_extinction_timeout';
  static const String screenStatus = 'screen_status';
  static const String ledStatus = 'led_status';
  static const String arofeneLink = 'arofene_link';
  static const String headerExist = 'header_exist';
  static const String radarExist = 'radar_exist';
  static const String headerLedStatus = 'header_led_status';
  static const String temperatureRaw = 'temperature_raw';
  static const String humidityRaw = 'humidity_raw';
  static const String temperatureCompensate = 'temperature_compensate';
  static const String humidityCompensate = 'humidity_compensate';
}

const int standbyDetectLength = 2;

class MideaADDevice extends MideaDevice {
  MideaADDevice({
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
         deviceType: DeviceType.ad,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.temperature: null,
    DeviceAttributes.humidity: null,
    DeviceAttributes.tvoc: null,
    DeviceAttributes.co2: null,
    DeviceAttributes.pm25: null,
    DeviceAttributes.hcho: null,
    DeviceAttributes.presetsFunction: false,
    DeviceAttributes.fallAsleepStatus: false,
    DeviceAttributes.portableSense: false,
    DeviceAttributes.nightMode: false,
    DeviceAttributes.screenExtinctionTimeout: null,
    DeviceAttributes.screenStatus: false,
    DeviceAttributes.ledStatus: false,
    DeviceAttributes.arofeneLink: false,
    DeviceAttributes.headerExist: false,
    DeviceAttributes.radarExist: false,
    DeviceAttributes.headerLedStatus: false,
    DeviceAttributes.temperatureRaw: null,
    DeviceAttributes.humidityRaw: null,
    DeviceAttributes.temperatureCompensate: null,
    DeviceAttributes.humidityCompensate: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [
      Message21Query(messageProtocolVersion),
      Message31Query(messageProtocolVersion),
    ];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageADResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      final value = _getMessageAttribute(message, status);
      if (value != null) {
        attrs[status] = value;
        newStatus[status] = value;
      }
    }
    return newStatus;
  }

  dynamic _getMessageAttribute(MessageADResponse message, String attr) {
    switch (attr) {
      case DeviceAttributes.temperature:
        return message.temperature;
      case DeviceAttributes.humidity:
        return message.humidity;
      case DeviceAttributes.tvoc:
        return message.tvoc;
      case DeviceAttributes.co2:
        return message.co2;
      case DeviceAttributes.pm25:
        return message.pm25;
      case DeviceAttributes.hcho:
        return message.hcho;
      case DeviceAttributes.presetsFunction:
        return message.presetsFunction;
      case DeviceAttributes.fallAsleepStatus:
        return message.fallAsleepStatus;
      case DeviceAttributes.portableSense:
        return message.portableSense;
      case DeviceAttributes.nightMode:
        return message.nightMode;
      case DeviceAttributes.screenExtinctionTimeout:
        return message.screenExtinctionTimeout;
      case DeviceAttributes.screenStatus:
        return message.screenStatus;
      case DeviceAttributes.ledStatus:
        return message.ledStatus;
      case DeviceAttributes.arofeneLink:
        return message.arofeneLink;
      case DeviceAttributes.headerExist:
        return message.headerExist;
      case DeviceAttributes.radarExist:
        return message.radarExist;
      case DeviceAttributes.headerLedStatus:
        return message.headerLedStatus;
      case DeviceAttributes.temperatureRaw:
        return message.temperatureRaw;
      case DeviceAttributes.humidityRaw:
        return message.humidityRaw;
      case DeviceAttributes.temperatureCompensate:
        return message.temperatureCompensate;
      case DeviceAttributes.humidityCompensate:
        return message.humidityCompensate;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
