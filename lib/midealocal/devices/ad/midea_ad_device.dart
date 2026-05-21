/// Midea local AD device. Mirrors midealocal/devices/ad/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class AdDeviceAttributes {
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
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    AdDeviceAttributes.temperature: null,
    AdDeviceAttributes.humidity: null,
    AdDeviceAttributes.tvoc: null,
    AdDeviceAttributes.co2: null,
    AdDeviceAttributes.pm25: null,
    AdDeviceAttributes.hcho: null,
    AdDeviceAttributes.presetsFunction: false,
    AdDeviceAttributes.fallAsleepStatus: false,
    AdDeviceAttributes.portableSense: false,
    AdDeviceAttributes.nightMode: false,
    AdDeviceAttributes.screenExtinctionTimeout: null,
    AdDeviceAttributes.screenStatus: false,
    AdDeviceAttributes.ledStatus: false,
    AdDeviceAttributes.arofeneLink: false,
    AdDeviceAttributes.headerExist: false,
    AdDeviceAttributes.radarExist: false,
    AdDeviceAttributes.headerLedStatus: false,
    AdDeviceAttributes.temperatureRaw: null,
    AdDeviceAttributes.humidityRaw: null,
    AdDeviceAttributes.temperatureCompensate: null,
    AdDeviceAttributes.humidityCompensate: null,
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
      case AdDeviceAttributes.temperature:
        return message.temperature;
      case AdDeviceAttributes.humidity:
        return message.humidity;
      case AdDeviceAttributes.tvoc:
        return message.tvoc;
      case AdDeviceAttributes.co2:
        return message.co2;
      case AdDeviceAttributes.pm25:
        return message.pm25;
      case AdDeviceAttributes.hcho:
        return message.hcho;
      case AdDeviceAttributes.presetsFunction:
        return message.presetsFunction;
      case AdDeviceAttributes.fallAsleepStatus:
        return message.fallAsleepStatus;
      case AdDeviceAttributes.portableSense:
        return message.portableSense;
      case AdDeviceAttributes.nightMode:
        return message.nightMode;
      case AdDeviceAttributes.screenExtinctionTimeout:
        return message.screenExtinctionTimeout;
      case AdDeviceAttributes.screenStatus:
        return message.screenStatus;
      case AdDeviceAttributes.ledStatus:
        return message.ledStatus;
      case AdDeviceAttributes.arofeneLink:
        return message.arofeneLink;
      case AdDeviceAttributes.headerExist:
        return message.headerExist;
      case AdDeviceAttributes.radarExist:
        return message.radarExist;
      case AdDeviceAttributes.headerLedStatus:
        return message.headerLedStatus;
      case AdDeviceAttributes.temperatureRaw:
        return message.temperatureRaw;
      case AdDeviceAttributes.humidityRaw:
        return message.humidityRaw;
      case AdDeviceAttributes.temperatureCompensate:
        return message.temperatureCompensate;
      case AdDeviceAttributes.humidityCompensate:
        return message.humidityCompensate;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
