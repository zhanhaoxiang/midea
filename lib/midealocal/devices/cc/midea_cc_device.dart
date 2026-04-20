/// Midea local CC device. Mirrors midealocal/devices/cc/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
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
         attributes: _defaultAttributes,
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
    DeviceAttributes.power: false,
    DeviceAttributes.mode: 1,
    DeviceAttributes.targetTemperature: 26.0,
    DeviceAttributes.fanSpeed: 0x80,
    DeviceAttributes.sleepMode: false,
    DeviceAttributes.ecoMode: false,
    DeviceAttributes.nightLight: false,
    DeviceAttributes.ventilation: false,
    DeviceAttributes.auxHeating: false,
    DeviceAttributes.auxHeatStatus: 0,
    DeviceAttributes.autoAuxHeatRunning: false,
    DeviceAttributes.swing: false,
    DeviceAttributes.fanSpeedLevel: null,
    DeviceAttributes.indoorTemperature: null,
    DeviceAttributes.temperaturePrecision: 1,
    DeviceAttributes.tempFahrenheit: false,
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
        if (status == DeviceAttributes.fanSpeed) {
          fanSpeed = value;
        } else {
          attrs[status] = value;
          newStatus[status] = value;
        }
      }
    }

    if (fanSpeed != null && attrs[DeviceAttributes.fanSpeedLevel] != null) {
      if (_fanSpeeds == null) {
        if (attrs[DeviceAttributes.fanSpeedLevel] == true) {
          _fanSpeeds = _fanSpeeds3Level;
        } else {
          _fanSpeeds = _fanSpeeds7Level;
        }
      }
      if (_fanSpeeds!.containsKey(fanSpeed)) {
        attrs[DeviceAttributes.fanSpeed] = _fanSpeeds![fanSpeed];
      } else {
        attrs[DeviceAttributes.fanSpeed] = null;
      }
      newStatus[DeviceAttributes.fanSpeed] = attrs[DeviceAttributes.fanSpeed];
    }

    final auxHeating =
        (attrs[DeviceAttributes.auxHeatStatus] == 1 ||
        attrs[DeviceAttributes.autoAuxHeatRunning] == true);
    if (attrs[DeviceAttributes.auxHeating] != auxHeating) {
      attrs[DeviceAttributes.auxHeating] = auxHeating;
      newStatus[DeviceAttributes.auxHeating] = auxHeating;
    }

    return newStatus;
  }

  MessageSet makeMessageSet() {
    final message = MessageSet(messageProtocolVersion);
    message.power = attrs[DeviceAttributes.power] as bool? ?? false;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 1;
    message.targetTemperature =
        (attrs[DeviceAttributes.targetTemperature] as num?)?.toDouble() ?? 26.0;
    if (_fanSpeeds != null) {
      final fanSpeedValue = attrs[DeviceAttributes.fanSpeed] as String?;
      if (fanSpeedValue != null) {
        final idx = _fanSpeeds!.values.toList().indexOf(fanSpeedValue);
        if (idx >= 0) {
          message.fanSpeed = _fanSpeeds!.keys.toList()[idx];
        }
      }
    }
    message.ecoMode = attrs[DeviceAttributes.ecoMode] as bool? ?? false;
    message.sleepMode = attrs[DeviceAttributes.sleepMode] as bool? ?? false;
    message.nightLight = attrs[DeviceAttributes.nightLight] as bool? ?? false;
    message.auxHeatStatus = attrs[DeviceAttributes.auxHeatStatus] as int? ?? 0;
    message.swing = attrs[DeviceAttributes.swing] as bool? ?? false;
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
      DeviceAttributes.indoorTemperature,
      DeviceAttributes.temperaturePrecision,
      DeviceAttributes.fanSpeedLevel,
      DeviceAttributes.auxHeatStatus,
      DeviceAttributes.autoAuxHeatRunning,
    ];
    if (readOnlyAttrs.contains(attr)) {
      return;
    }

    final message = makeMessageSet();
    if (attr == DeviceAttributes.fanSpeed) {
      if (_fanSpeeds != null && value is String) {
        final keys = _fanSpeeds!.keys.toList();
        final values = _fanSpeeds!.values.toList();
        final idx = values.indexOf(value);
        if (idx >= 0) {
          message.fanSpeed = keys[idx];
        }
      }
    } else if (attr == DeviceAttributes.mode) {
      if (value is int) {
        message.mode = value;
        message.power = true;
      }
    } else if (attr == DeviceAttributes.ecoMode) {
      if (value == true) {
        message.sleepMode = false;
      }
      _setMessageValue(message, attr, value);
    } else if (attr == DeviceAttributes.sleepMode) {
      if (value == true) {
        message.ecoMode = false;
      }
      _setMessageValue(message, attr, value);
    } else if (attr == DeviceAttributes.auxHeating) {
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
    if (attr == DeviceAttributes.power && value is bool) {
      message.power = value;
    } else if (attr == DeviceAttributes.mode && value is int) {
      message.mode = value;
    } else if (attr == DeviceAttributes.targetTemperature && value is num) {
      message.targetTemperature = value.toDouble();
    } else if (attr == DeviceAttributes.fanSpeed && value is int) {
      message.fanSpeed = value;
    } else if (attr == DeviceAttributes.ecoMode && value is bool) {
      message.ecoMode = value;
    } else if (attr == DeviceAttributes.sleepMode && value is bool) {
      message.sleepMode = value;
    } else if (attr == DeviceAttributes.nightLight && value is bool) {
      message.nightLight = value;
    } else if (attr == DeviceAttributes.ventilation && value is bool) {
      message.ventilation = value;
    } else if (attr == DeviceAttributes.swing && value is bool) {
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
      case DeviceAttributes.power:
        return true;
      case DeviceAttributes.mode:
        return true;
      case DeviceAttributes.targetTemperature:
        return true;
      case DeviceAttributes.fanSpeed:
        return true;
      case DeviceAttributes.indoorTemperature:
        return true;
      case DeviceAttributes.ecoMode:
        return true;
      case DeviceAttributes.sleepMode:
        return true;
      case DeviceAttributes.nightLight:
        return true;
      case DeviceAttributes.ventilation:
        return true;
      case DeviceAttributes.auxHeatStatus:
        return true;
      case DeviceAttributes.autoAuxHeatRunning:
        return true;
      case DeviceAttributes.fanSpeedLevel:
        return true;
      case DeviceAttributes.temperaturePrecision:
        return true;
      case DeviceAttributes.swing:
        return true;
      case DeviceAttributes.tempFahrenheit:
        return true;
      default:
        return false;
    }
  }

  dynamic getAttribute(String attr) {
    switch (attr) {
      case DeviceAttributes.power:
        return power;
      case DeviceAttributes.mode:
        return mode;
      case DeviceAttributes.targetTemperature:
        return targetTemperature;
      case DeviceAttributes.fanSpeed:
        return fanSpeed;
      case DeviceAttributes.indoorTemperature:
        return indoorTemperature;
      case DeviceAttributes.ecoMode:
        return ecoMode;
      case DeviceAttributes.sleepMode:
        return sleepMode;
      case DeviceAttributes.nightLight:
        return nightLight;
      case DeviceAttributes.ventilation:
        return ventilation;
      case DeviceAttributes.auxHeatStatus:
        return auxHeatStatus;
      case DeviceAttributes.autoAuxHeatRunning:
        return autoAuxHeatRunning;
      case DeviceAttributes.fanSpeedLevel:
        return fanSpeedLevel;
      case DeviceAttributes.temperaturePrecision:
        return temperaturePrecision;
      case DeviceAttributes.swing:
        return swing;
      case DeviceAttributes.tempFahrenheit:
        return tempFahrenheit;
      default:
        return null;
    }
  }
}
