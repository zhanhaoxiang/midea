import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class CeDeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String childLock = 'child_lock';
  static const String scheduled = 'scheduled';
  static const String fanSpeed = 'fan_speed';
  static const String pm25 = 'pm25';
  static const String co2 = 'co2';
  static const String currentHumidity = 'current_humidity';
  static const String currentTemperature = 'current_temperature';
  static const String hcho = 'hcho';
  static const String linkToAc = 'link_to_ac';
  static const String sleepMode = 'sleep_mode';
  static const String ecoMode = 'eco_mode';
  static const String auxHeating = 'aux_heating';
  static const String powerfulPurify = 'powerful_purify';
  static const String filterCleaningReminder = 'filter_cleaning_reminder';
  static const String filterChangeReminder = 'filter_change_reminder';
  static const String errorCode = 'error_code';
}

class MideaCEDevice extends MideaDevice {
  MideaCEDevice({
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
         deviceType: DeviceType.ce,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _speedCount = _defaultSpeedCount;
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const List<String> _modes = ['Normal', 'Sleep mode', 'ECO mode'];

  static const int _defaultSpeedCount = 7;
  static final Map<String, dynamic> _defaultAttributes = {
    CeDeviceAttributes.power: false,
    CeDeviceAttributes.mode: null,
    CeDeviceAttributes.childLock: false,
    CeDeviceAttributes.scheduled: false,
    CeDeviceAttributes.fanSpeed: 0,
    CeDeviceAttributes.pm25: null,
    CeDeviceAttributes.co2: null,
    CeDeviceAttributes.currentHumidity: null,
    CeDeviceAttributes.currentTemperature: null,
    CeDeviceAttributes.hcho: null,
    CeDeviceAttributes.linkToAc: false,
    CeDeviceAttributes.sleepMode: false,
    CeDeviceAttributes.ecoMode: false,
    CeDeviceAttributes.auxHeating: null,
    CeDeviceAttributes.powerfulPurify: false,
    CeDeviceAttributes.filterCleaningReminder: false,
    CeDeviceAttributes.filterChangeReminder: false,
    CeDeviceAttributes.errorCode: 0,
  };

  int _speedCount = _defaultSpeedCount;

  int get speedCount => _speedCount;

  List<String> get presetModes => _modes;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageCEResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      final attrValue = _getMessageAttribute(message, status);
      if (attrValue != null) {
        attrs[status] = attrValue;
        newStatus[status] = attrValue;
      }
    }

    final sleepMode = attrs[CeDeviceAttributes.sleepMode] as bool? ?? false;
    final ecoMode = attrs[CeDeviceAttributes.ecoMode] as bool? ?? false;
    if (sleepMode) {
      attrs[CeDeviceAttributes.mode] = 'Sleep mode';
    } else if (ecoMode) {
      attrs[CeDeviceAttributes.mode] = 'ECO mode';
    } else {
      attrs[CeDeviceAttributes.mode] = 'None';
    }
    newStatus[CeDeviceAttributes.mode] = attrs[CeDeviceAttributes.mode];

    return newStatus;
  }

  dynamic _getMessageAttribute(MessageCEResponse message, String attr) {
    switch (attr) {
      case CeDeviceAttributes.power:
        return message.power;
      case CeDeviceAttributes.childLock:
        return message.childLock;
      case CeDeviceAttributes.scheduled:
        return message.scheduled;
      case CeDeviceAttributes.fanSpeed:
        return message.fanSpeed;
      case CeDeviceAttributes.pm25:
        return message.pm25;
      case CeDeviceAttributes.co2:
        return message.co2;
      case CeDeviceAttributes.currentHumidity:
        return message.currentHumidity;
      case CeDeviceAttributes.currentTemperature:
        return message.currentTemperature;
      case CeDeviceAttributes.hcho:
        return message.hcho;
      case CeDeviceAttributes.linkToAc:
        return message.linkToAc;
      case CeDeviceAttributes.sleepMode:
        return message.sleepMode;
      case CeDeviceAttributes.ecoMode:
        return message.ecoMode;
      case CeDeviceAttributes.auxHeating:
        return message.auxHeating;
      case CeDeviceAttributes.powerfulPurify:
        return message.powerfulPurify;
      case CeDeviceAttributes.filterCleaningReminder:
        return message.filterCleaningReminder;
      case CeDeviceAttributes.filterChangeReminder:
        return message.filterChangeReminder;
      case CeDeviceAttributes.errorCode:
        return message.errorCode;
      default:
        return null;
    }
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[CeDeviceAttributes.power] as bool? ?? false;
    message.fanSpeed = attrs[CeDeviceAttributes.fanSpeed] as int? ?? 0;
    message.linkToAc = attrs[CeDeviceAttributes.linkToAc] as bool? ?? false;
    message.sleepMode = attrs[CeDeviceAttributes.sleepMode] as bool? ?? false;
    message.ecoMode = attrs[CeDeviceAttributes.ecoMode] as bool? ?? false;
    message.auxHeating = attrs[CeDeviceAttributes.auxHeating] as bool? ?? false;
    message.powerfulPurify =
        attrs[CeDeviceAttributes.powerfulPurify] as bool? ?? false;
    message.scheduled = attrs[CeDeviceAttributes.scheduled] as bool? ?? false;
    message.childLock = attrs[CeDeviceAttributes.childLock] as bool? ?? false;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final message = makeMessageSet();
    if (attr == CeDeviceAttributes.mode) {
      message.sleepMode = false;
      message.ecoMode = false;
      if (value == 'Sleep mode') {
        message.sleepMode = true;
      } else if (value == 'ECO mode') {
        message.ecoMode = true;
      }
    } else {
      switch (attr) {
        case CeDeviceAttributes.power:
          message.power = value as bool;
          break;
        case CeDeviceAttributes.fanSpeed:
          message.fanSpeed = value as int;
          break;
        case CeDeviceAttributes.linkToAc:
          message.linkToAc = value as bool;
          break;
        case CeDeviceAttributes.sleepMode:
          message.sleepMode = value as bool;
          break;
        case CeDeviceAttributes.ecoMode:
          message.ecoMode = value as bool;
          break;
        case CeDeviceAttributes.auxHeating:
          message.auxHeating = value as bool;
          break;
        case CeDeviceAttributes.powerfulPurify:
          message.powerfulPurify = value as bool;
          break;
        case CeDeviceAttributes.scheduled:
          message.scheduled = value as bool;
          break;
        case CeDeviceAttributes.childLock:
          message.childLock = value as bool;
          break;
      }
    }
    buildSend(message);
  }

  void setCustomize(String customize) {
    _speedCount = _defaultSpeedCount;
    if (customize.isNotEmpty) {
      try {
        final params = _parseCustomize(customize);
        if (params.containsKey('speed_count')) {
          _speedCount = params['speed_count'] as int? ?? _defaultSpeedCount;
        }
      } catch (_) {}
    }
    updateAll({'speed_count': _speedCount});
  }

  Map<String, dynamic> _parseCustomize(String customize) {
    final result = <String, dynamic>{};
    final regex = RegExp(r'(\w+):\s*(\d+)');
    for (final match in regex.allMatches(customize)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        result[key] = int.tryParse(value);
      }
    }
    return result;
  }
}

class MideaAppliance extends MideaCEDevice {
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
