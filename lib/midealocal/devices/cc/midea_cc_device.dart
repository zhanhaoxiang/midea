/// Midea local CC device. Mirrors midealocal/devices/cc/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class CcDeviceAttributes {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String targetTemperature = 'target_temperature';
  static const String fanSpeed = 'fan_speed';
  static const String ecoMode = 'eco_mode';
  static const String sleepMode = 'sleep_mode';
  static const String nightLight = 'night_light';
  static const String auxHeating = 'aux_heating';
  static const String swing = 'swing';
  static const String ventilation = 'ventilation';
  static const String temperaturePrecision = 'temperature_precision';
  static const String fanSpeedLevel = 'fan_speed_level';
  static const String indoorTemperature = 'indoor_temperature';
  static const String auxHeatStatus = 'aux_heat_status';
  static const String autoAuxHeatRunning = 'auto_aux_heat_running';
  static const String tempFahrenheit = 'temp_fahrenheit';
}

class MideaCCDevice extends MideaDevice {
  MideaCCDevice({
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
         deviceType: DeviceType.cc,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const Map<int, String> _fanSpeeds7Level = {
    0x01: 'Level 1',
    0x02: 'Level 2',
    0x04: 'Level 3',
    0x08: 'Level 4',
    0x10: 'Level 5',
    0x20: 'Level 6',
    0x40: 'Level 7',
    0x80: 'Auto',
  };

  static const Map<int, String> _fanSpeeds3Level = {
    0x01: 'Low',
    0x08: 'Medium',
    0x40: 'High',
    0x80: 'Auto',
  };

  static final Map<String, dynamic> _defaultAttributes = {
    CcDeviceAttributes.power: false,
    CcDeviceAttributes.mode: 1,
    CcDeviceAttributes.targetTemperature: 26.0,
    CcDeviceAttributes.fanSpeed: 0x80,
    CcDeviceAttributes.sleepMode: false,
    CcDeviceAttributes.ecoMode: false,
    CcDeviceAttributes.nightLight: false,
    CcDeviceAttributes.ventilation: false,
    CcDeviceAttributes.auxHeating: false,
    CcDeviceAttributes.auxHeatStatus: 0,
    CcDeviceAttributes.autoAuxHeatRunning: false,
    CcDeviceAttributes.swing: false,
    CcDeviceAttributes.fanSpeedLevel: null,
    CcDeviceAttributes.indoorTemperature: null,
    CcDeviceAttributes.temperaturePrecision: 1,
    CcDeviceAttributes.tempFahrenheit: false,
  };

  Map<int, String>? _fanSpeeds;

  List<String>? get fanModes {
    return _fanSpeeds?.values.toList();
  }

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageCCResponse(msg);
    final newStatus = <String, dynamic>{};
    int? fanSpeed;

    for (final status in attrs.keys) {
      if (message.hasAttribute(status)) {
        final value = message.getAttribute(status);
        if (status == CcDeviceAttributes.fanSpeed) {
          fanSpeed = value;
        } else {
          attrs[status] = value;
          newStatus[status] = value;
        }
      }
    }

    if (fanSpeed != null && attrs[CcDeviceAttributes.fanSpeedLevel] != null) {
      if (_fanSpeeds == null) {
        if (attrs[CcDeviceAttributes.fanSpeedLevel] == true) {
          _fanSpeeds = _fanSpeeds3Level;
        } else {
          _fanSpeeds = _fanSpeeds7Level;
        }
      }
      if (_fanSpeeds!.containsKey(fanSpeed)) {
        attrs[CcDeviceAttributes.fanSpeed] = _fanSpeeds![fanSpeed];
      } else {
        attrs[CcDeviceAttributes.fanSpeed] = null;
      }
      newStatus[CcDeviceAttributes.fanSpeed] = attrs[CcDeviceAttributes.fanSpeed];
    }

    final auxHeating =
        (attrs[CcDeviceAttributes.auxHeatStatus] == 1 ||
        attrs[CcDeviceAttributes.autoAuxHeatRunning] == true);
    if (attrs[CcDeviceAttributes.auxHeating] != auxHeating) {
      attrs[CcDeviceAttributes.auxHeating] = auxHeating;
      newStatus[CcDeviceAttributes.auxHeating] = auxHeating;
    }

    return newStatus;
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[CcDeviceAttributes.power] as bool? ?? false;
    message.mode = attrs[CcDeviceAttributes.mode] as int? ?? 1;
    message.targetTemperature =
        (attrs[CcDeviceAttributes.targetTemperature] as num?)?.toDouble() ?? 26.0;
    if (_fanSpeeds != null) {
      final fanSpeedValue = attrs[CcDeviceAttributes.fanSpeed] as String?;
      if (fanSpeedValue != null) {
        final idx = _fanSpeeds!.values.toList().indexOf(fanSpeedValue);
        if (idx >= 0) {
          message.fanSpeed = _fanSpeeds!.keys.toList()[idx];
        }
      }
    }
    message.ecoMode = attrs[CcDeviceAttributes.ecoMode] as bool? ?? false;
    message.sleepMode = attrs[CcDeviceAttributes.sleepMode] as bool? ?? false;
    message.nightLight = attrs[CcDeviceAttributes.nightLight] as bool? ?? false;
    message.auxHeatStatus = attrs[CcDeviceAttributes.auxHeatStatus] as int? ?? 0;
    message.swing = attrs[CcDeviceAttributes.swing] as bool? ?? false;
    return message;
  }

  void setTargetTemperature(double targetTemperature, {int? mode, int? zone}) {
    final message = makeMessageSet();
    message.targetTemperature = targetTemperature;
    if (mode != null) {
      message.power = true;
      message.mode = mode;
    }
    buildSend(message);
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final readOnlyAttrs = <String>[
      CcDeviceAttributes.indoorTemperature,
      CcDeviceAttributes.temperaturePrecision,
      CcDeviceAttributes.fanSpeedLevel,
      CcDeviceAttributes.auxHeatStatus,
      CcDeviceAttributes.autoAuxHeatRunning,
    ];
    if (readOnlyAttrs.contains(attr)) {
      return;
    }

    final message = makeMessageSet();
    if (attr == CcDeviceAttributes.fanSpeed) {
      if (_fanSpeeds != null && value is String) {
        final keys = _fanSpeeds!.keys.toList();
        final values = _fanSpeeds!.values.toList();
        final idx = values.indexOf(value);
        if (idx >= 0) {
          message.fanSpeed = keys[idx];
        }
      }
    } else if (attr == CcDeviceAttributes.mode) {
      if (value is int) {
        message.mode = value;
        message.power = true;
      }
    } else if (attr == CcDeviceAttributes.ecoMode) {
      if (value == true) {
        message.sleepMode = false;
      }
      _setMessageValue(message, attr, value);
    } else if (attr == CcDeviceAttributes.sleepMode) {
      if (value == true) {
        message.ecoMode = false;
      }
      _setMessageValue(message, attr, value);
    } else if (attr == CcDeviceAttributes.auxHeating) {
      if (value == true) {
        message.auxHeatStatus = 1;
      } else {
        message.auxHeatStatus = 2;
      }
    } else {
      _setMessageValue(message, attr, value);
    }
    buildSend(message);
  }

  void _setMessageValue(MessageSet message, String attr, dynamic value) {
    if (attr == CcDeviceAttributes.power && value is bool) {
      message.power = value;
    } else if (attr == CcDeviceAttributes.mode && value is int) {
      message.mode = value;
    } else if (attr == CcDeviceAttributes.targetTemperature && value is num) {
      message.targetTemperature = value.toDouble();
    } else if (attr == CcDeviceAttributes.fanSpeed && value is int) {
      message.fanSpeed = value;
    } else if (attr == CcDeviceAttributes.ecoMode && value is bool) {
      message.ecoMode = value;
    } else if (attr == CcDeviceAttributes.sleepMode && value is bool) {
      message.sleepMode = value;
    } else if (attr == CcDeviceAttributes.nightLight && value is bool) {
      message.nightLight = value;
    } else if (attr == CcDeviceAttributes.ventilation && value is bool) {
      message.ventilation = value;
    } else if (attr == CcDeviceAttributes.swing && value is bool) {
      message.swing = value;
    }
  }
}

class MideaAppliance extends MideaCCDevice {
  MideaAppliance({
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
  }) : super(deviceProtocol: deviceProtocol, customize: customize);
}

extension MessageCCResponseExtension on MessageCCResponse {
  bool hasAttribute(String attr) {
    switch (attr) {
      case CcDeviceAttributes.power:
        return true;
      case CcDeviceAttributes.mode:
        return true;
      case CcDeviceAttributes.targetTemperature:
        return true;
      case CcDeviceAttributes.fanSpeed:
        return true;
      case CcDeviceAttributes.indoorTemperature:
        return true;
      case CcDeviceAttributes.ecoMode:
        return true;
      case CcDeviceAttributes.sleepMode:
        return true;
      case CcDeviceAttributes.nightLight:
        return true;
      case CcDeviceAttributes.ventilation:
        return true;
      case CcDeviceAttributes.auxHeatStatus:
        return true;
      case CcDeviceAttributes.autoAuxHeatRunning:
        return true;
      case CcDeviceAttributes.fanSpeedLevel:
        return true;
      case CcDeviceAttributes.temperaturePrecision:
        return true;
      case CcDeviceAttributes.swing:
        return true;
      case CcDeviceAttributes.tempFahrenheit:
        return true;
      default:
        return false;
    }
  }

  dynamic getAttribute(String attr) {
    switch (attr) {
      case CcDeviceAttributes.power:
        return power;
      case CcDeviceAttributes.mode:
        return mode;
      case CcDeviceAttributes.targetTemperature:
        return targetTemperature;
      case CcDeviceAttributes.fanSpeed:
        return fanSpeed;
      case CcDeviceAttributes.indoorTemperature:
        return indoorTemperature;
      case CcDeviceAttributes.ecoMode:
        return ecoMode;
      case CcDeviceAttributes.sleepMode:
        return sleepMode;
      case CcDeviceAttributes.nightLight:
        return nightLight;
      case CcDeviceAttributes.ventilation:
        return ventilation;
      case CcDeviceAttributes.auxHeatStatus:
        return auxHeatStatus;
      case CcDeviceAttributes.autoAuxHeatRunning:
        return autoAuxHeatRunning;
      case CcDeviceAttributes.fanSpeedLevel:
        return fanSpeedLevel;
      case CcDeviceAttributes.temperaturePrecision:
        return temperaturePrecision;
      case CcDeviceAttributes.swing:
        return swing;
      case CcDeviceAttributes.tempFahrenheit:
        return tempFahrenheit;
      default:
        return null;
    }
  }
}
