/// Midea local AC device. Mirrors midealocal/devices/ac/__init__.py.

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
  static const String promptTone = 'prompt_tone';
  static const String power = 'power';
  static const String mode = 'mode';
  static const String targetTemperature = 'target_temperature';
  static const String fanSpeed = 'fan_speed';
  static const String swingVertical = 'swing_vertical';
  static const String swingHorizontal = 'swing_horizontal';
  static const String boostMode = 'boost_mode';
  static const String smartEye = 'smart_eye';
  static const String dry = 'dry';
  static const String ecoMode = 'eco_mode';
  static const String auxHeating = 'aux_heating';
  static const String sleepMode = 'sleep_mode';
  static const String naturalWind = 'natural_wind';
  static const String tempFahrenheit = 'temp_fahrenheit';
  static const String screenDisplay = 'screen_display';
  static const String screenDisplayAlternate = 'screen_display_alternate';
  static const String fullDust = 'full_dust';
  static const String frostProtect = 'frost_protect';
  static const String comfortMode = 'comfort_mode';
  static const String indoorTemperature = 'indoor_temperature';
  static const String outdoorTemperature = 'outdoor_temperature';
  static const String indirectWind = 'indirect_wind';
  static const String indoorHumidity = 'indoor_humidity';
  static const String breezeless = 'breezeless';
  static const String freshAirPower = 'fresh_air_power';
  static const String freshAirFanSpeed = 'fresh_air_fan_speed';
  static const String freshAirMode = 'fresh_air_mode';
  static const String freshAir1 = 'fresh_air_1';
  static const String freshAir2 = 'fresh_air_2';
  static const String totalEnergyConsumption = 'total_energy_consumption';
  static const String currentEnergyConsumption = 'current_energy_consumption';
  static const String realtimePower = 'realtime_power';
  static const String windLrAngle = 'wind_lr_angle';
  static const String windUdAngle = 'wind_ud_angle';
}

// ---------------------------------------------------------------------------
// MideaACDevice
// ---------------------------------------------------------------------------

class MideaACDevice extends MideaDevice {
  MideaACDevice({
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
         deviceType: DeviceType.ac,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _temperatureStep = _defaultTemperatureStep;
    _powerAnalysisMethod = _defaultPowerAnalysisMethod;
    if (customize != null && customize.isNotEmpty) {
      setCustomize(customize);
    }
  }

  static const Map<int, String> _freshAirFanSpeeds = {
    0: 'off',
    20: 'silent',
    40: 'low',
    60: 'medium',
    80: 'high',
    100: 'full',
  };

  static const Map<int, String> _windLrAngles = {
    0: 'off',
    1: 'left',
    25: 'left-mid',
    50: 'middle',
    75: 'right-mid',
    100: 'right',
  };

  static const Map<int, String> _windUdAngles = {
    0: 'off',
    1: 'up',
    25: 'up-mid',
    50: 'middle',
    75: 'down-mid',
    100: 'down',
  };

  static const Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.promptTone: true,
    DeviceAttributes.power: false,
    DeviceAttributes.mode: 0,
    DeviceAttributes.targetTemperature: 24.0,
    DeviceAttributes.fanSpeed: 102,
    DeviceAttributes.swingVertical: false,
    DeviceAttributes.swingHorizontal: false,
    DeviceAttributes.smartEye: false,
    DeviceAttributes.dry: false,
    DeviceAttributes.auxHeating: false,
    DeviceAttributes.boostMode: false,
    DeviceAttributes.sleepMode: false,
    DeviceAttributes.frostProtect: false,
    DeviceAttributes.comfortMode: false,
    DeviceAttributes.ecoMode: false,
    DeviceAttributes.naturalWind: false,
    DeviceAttributes.tempFahrenheit: false,
    DeviceAttributes.screenDisplay: false,
    DeviceAttributes.screenDisplayAlternate: false,
    DeviceAttributes.fullDust: false,
    DeviceAttributes.indoorTemperature: null,
    DeviceAttributes.outdoorTemperature: null,
    DeviceAttributes.indirectWind: false,
    DeviceAttributes.indoorHumidity: null,
    DeviceAttributes.breezeless: false,
    DeviceAttributes.totalEnergyConsumption: null,
    DeviceAttributes.currentEnergyConsumption: null,
    DeviceAttributes.realtimePower: null,
    DeviceAttributes.freshAirPower: false,
    DeviceAttributes.freshAirFanSpeed: 0,
    DeviceAttributes.freshAirMode: null,
    DeviceAttributes.freshAir1: null,
    DeviceAttributes.freshAir2: null,
    DeviceAttributes.windLrAngle: null,
    DeviceAttributes.windUdAngle: null,
  };

  static const double _defaultTemperatureStep = 0.5;
  static const int _defaultPowerAnalysisMethod = 1;

  double _temperatureStep = _defaultTemperatureStep;
  int _powerAnalysisMethod = _defaultPowerAnalysisMethod;
  bool _usedSubprotocol = false;
  bool _bbSn8Flag = false;
  bool _bbTimer = false;
  String? _freshAirVersion;

  double? get temperatureStep => _temperatureStep;

  List<String> get freshAirFanSpeeds => _freshAirFanSpeeds.values.toList();

  List<String> get windLrAngles => _windLrAngles.values.toList();

  List<String> get windUdAngles => _windUdAngles.values.toList();

  @override
  List<MessageRequest> buildQuery() {
    if (_usedSubprotocol) {
      return [
        MessageSubProtocolQuery(messageProtocolVersion, 0x10),
        MessageSubProtocolQuery(messageProtocolVersion, 0x11),
        MessageSubProtocolQuery(messageProtocolVersion, 0x30),
      ];
    }
    return [
      MessageQuery(messageProtocolVersion),
      MessageNewProtocolQuery(messageProtocolVersion),
      MessagePowerQuery(messageProtocolVersion),
      MessageHumidityQuery(messageProtocolVersion),
      MessageGroupZeroQuery(messageProtocolVersion),
      MessageCapabilitiesQuery(messageProtocolVersion, false),
      MessageCapabilitiesAdditionalQuery(messageProtocolVersion),
    ];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageACResponse(msg, _powerAnalysisMethod);
    print('$deviceId Received: $message');
    final newStatus = <String, dynamic>{};
    var hasFreshAir = false;

    if (message.usedSubprotocol == true) {
      _usedSubprotocol = true;
      if (message.sn8Flag != null) {
        _bbSn8Flag = message.sn8Flag!;
      }
      if (message.timer != null) {
        _bbTimer = message.timer!;
      }
    }

    for (final attr in attrs.keys) {
      if (message.hasAttribute(attr)) {
        var value = message.getAttribute(attr);
        if (attr == DeviceAttributes.freshAirPower) {
          hasFreshAir = true;
        }
        if (attr == DeviceAttributes.windLrAngle && value != null) {
          value = _windLrAngles[value] ?? value;
        } else if (attr == DeviceAttributes.windUdAngle && value != null) {
          value = _windUdAngles[value] ?? value;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }

    if (hasFreshAir) {
      if (attrs[DeviceAttributes.freshAirPower] == true) {
        final fanSpeed = attrs[DeviceAttributes.freshAirFanSpeed] as int? ?? 0;
        String mode = 'off';
        for (final entry in _freshAirFanSpeeds.entries) {
          if (fanSpeed < entry.key) break;
          mode = entry.value;
        }
        attrs[DeviceAttributes.freshAirMode] = mode;
      } else {
        attrs[DeviceAttributes.freshAirMode] = 'off';
      }
      newStatus[DeviceAttributes.freshAirMode] =
          attrs[DeviceAttributes.freshAirMode];
    }

    final power = attrs[DeviceAttributes.power] as bool? ?? false;
    if (!power ||
        (newStatus.containsKey(DeviceAttributes.swingVertical) &&
            attrs[DeviceAttributes.swingVertical] == true)) {
      attrs[DeviceAttributes.indirectWind] = false;
      newStatus[DeviceAttributes.indirectWind] = false;
    }
    if (!power) {
      attrs[DeviceAttributes.screenDisplay] = false;
      newStatus[DeviceAttributes.screenDisplay] = false;
    }

    if (attrs[DeviceAttributes.freshAir1] != null) {
      _freshAirVersion = DeviceAttributes.freshAir1;
    } else if (attrs[DeviceAttributes.freshAir2] != null) {
      _freshAirVersion = DeviceAttributes.freshAir2;
    }

    return newStatus;
  }

  MessageGeneralSet makeMessageSet() {
    final message = MessageGeneralSet(messageProtocolVersion);
    message.power = attrs[DeviceAttributes.power] as bool? ?? false;
    message.promptTone = attrs[DeviceAttributes.promptTone] as bool? ?? true;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 0;
    message.targetTemperature =
        (attrs[DeviceAttributes.targetTemperature] as num?)?.toDouble() ?? 24.0;
    message.fanSpeed = attrs[DeviceAttributes.fanSpeed] as int? ?? 102;
    message.swingVertical =
        attrs[DeviceAttributes.swingVertical] as bool? ?? false;
    message.swingHorizontal =
        attrs[DeviceAttributes.swingHorizontal] as bool? ?? false;
    message.boostMode = attrs[DeviceAttributes.boostMode] as bool? ?? false;
    message.smartEye = attrs[DeviceAttributes.smartEye] as bool? ?? false;
    message.dry = attrs[DeviceAttributes.dry] as bool? ?? false;
    message.ecoMode = attrs[DeviceAttributes.ecoMode] as bool? ?? false;
    message.auxHeating = attrs[DeviceAttributes.auxHeating] as bool? ?? false;
    message.sleepMode = attrs[DeviceAttributes.sleepMode] as bool? ?? false;
    message.naturalWind = attrs[DeviceAttributes.naturalWind] as bool? ?? false;
    message.tempFahrenheit =
        attrs[DeviceAttributes.tempFahrenheit] as bool? ?? false;
    message.frostProtect =
        attrs[DeviceAttributes.frostProtect] as bool? ?? false;
    message.comfortMode = attrs[DeviceAttributes.comfortMode] as bool? ?? false;
    return message;
  }

  MessageSubProtocolSet makeSubprotocolMessageSet() {
    final message = MessageSubProtocolSet(messageProtocolVersion);
    message.power = attrs[DeviceAttributes.power] as bool? ?? false;
    message.promptTone = attrs[DeviceAttributes.promptTone] as bool? ?? false;
    message.auxHeating = attrs[DeviceAttributes.auxHeating] as bool? ?? false;
    message.mode = attrs[DeviceAttributes.mode] as int? ?? 0;
    message.targetTemperature =
        (attrs[DeviceAttributes.targetTemperature] as num?)?.toDouble() ?? 20.0;
    message.fanSpeed = attrs[DeviceAttributes.fanSpeed] as int? ?? 102;
    message.boostMode = attrs[DeviceAttributes.boostMode] as bool? ?? false;
    message.dry = attrs[DeviceAttributes.dry] as bool? ?? false;
    message.ecoMode = attrs[DeviceAttributes.ecoMode] as bool? ?? false;
    message.sleepMode = attrs[DeviceAttributes.sleepMode] as bool? ?? false;
    message.sn8Flag = _bbSn8Flag;
    message.timer = _bbTimer;
    return message;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final readOnlyAttrs = <String>[
      DeviceAttributes.indoorTemperature,
      DeviceAttributes.outdoorTemperature,
      DeviceAttributes.indoorHumidity,
      DeviceAttributes.fullDust,
      DeviceAttributes.totalEnergyConsumption,
      DeviceAttributes.currentEnergyConsumption,
      DeviceAttributes.realtimePower,
    ];
    if (readOnlyAttrs.contains(attr)) {
      return;
    }

    if (attr == DeviceAttributes.promptTone) {
      attrs[DeviceAttributes.promptTone] = value;
      updateAll({DeviceAttributes.promptTone: value});
      return;
    }

    if (attr == DeviceAttributes.screenDisplay) {
      final msg = MessageToggleDisplay(messageProtocolVersion);
      msg.promptTone = attrs[DeviceAttributes.promptTone] as bool? ?? true;
      buildSend(msg);
      return;
    }

    final newProtocolAttrs = <String>[
      DeviceAttributes.indirectWind,
      DeviceAttributes.breezeless,
      DeviceAttributes.screenDisplayAlternate,
      DeviceAttributes.freshAirPower,
      DeviceAttributes.freshAirFanSpeed,
      DeviceAttributes.freshAirMode,
      DeviceAttributes.windLrAngle,
      DeviceAttributes.windUdAngle,
    ];
    if (newProtocolAttrs.contains(attr)) {
      final msg = MessageNewProtocolSet(messageProtocolVersion);
      if (attr == DeviceAttributes.windLrAngle) {
        final key = _getMapKey(_windLrAngles, value as String);
        msg.windLrAngle = key;
      } else if (attr == DeviceAttributes.windUdAngle) {
        final key = _getMapKey(_windUdAngles, value as String);
        msg.windUdAngle = key;
      } else if (attr == DeviceAttributes.freshAirPower) {
        _setFreshAirAttribute(msg, attr, value);
      } else if (attr == DeviceAttributes.freshAirMode) {
        _setFreshAirAttribute(msg, attr, value);
      } else if (attr == DeviceAttributes.freshAirFanSpeed) {
        _setFreshAirAttribute(msg, attr, value);
      } else {
        _setNewProtocolAttr(msg, attr, value);
      }
      msg.promptTone = attrs[DeviceAttributes.promptTone] as bool?;
      buildSend(msg);
      return;
    }

    if (attrs.containsKey(attr)) {
      final message = _usedSubprotocol
          ? makeSubprotocolMessageSet()
          : makeMessageSet();
      _setMessageAttrs(message, attr, value);
      if (attr == DeviceAttributes.mode) {
        _setMessageAttrs(message, DeviceAttributes.power, true);
        if (message is MessageGeneralSet) {
          message.dry = false;
        }
        final currentMode = attrs[DeviceAttributes.mode] as int? ?? 0;
        if (currentMode == dryMode && message is MessageSubProtocolSet) {
          message.fanSpeed = 102;
        }
      }
      buildSend(message);
    }
  }

  int? _getMapKey(Map<int, String> map, String value) {
    for (final entry in map.entries) {
      if (entry.value == value) return entry.key;
    }
    return null;
  }

  void _setFreshAirAttribute(
    MessageNewProtocolSet msg,
    String attr,
    dynamic value,
  ) {
    if (_freshAirVersion == null) return;
    final fanSpeed = attrs[DeviceAttributes.freshAirFanSpeed] as int? ?? 0;
    List<int>? freshAir;

    if (attr == DeviceAttributes.freshAirPower) {
      freshAir = value == true ? [1, fanSpeed] : [0, fanSpeed];
    } else if (attr == DeviceAttributes.freshAirMode) {
      final speed = _getMapKey(_freshAirFanSpeeds, value as String);
      if (speed != null) {
        freshAir = speed > 0 ? [1, speed] : [0, speed];
      }
    } else if (attr == DeviceAttributes.freshAirFanSpeed) {
      final speed = value as int;
      freshAir = speed > 0 ? [1, speed] : [0, speed];
    }

    if (freshAir != null) {
      if (_freshAirVersion == DeviceAttributes.freshAir1) {
        msg.freshAir1 = freshAir;
      } else {
        msg.freshAir2 = freshAir;
      }
    }
  }

  void _setNewProtocolAttr(
    MessageNewProtocolSet msg,
    String attr,
    dynamic value,
  ) {
    if (attr == DeviceAttributes.breezeless) {
      msg.breezeless = value as bool?;
    } else if (attr == DeviceAttributes.indirectWind) {
      msg.indirectWind = value as bool?;
    } else if (attr == DeviceAttributes.screenDisplayAlternate) {
      msg.screenDisplayAlternate = value as bool?;
    }
  }

  void _setMessageAttrs(dynamic message, String attr, dynamic value) {
    if (attr == DeviceAttributes.power) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.power = boolValue;
      if (message is MessageSubProtocolSet) message.power = boolValue;
    } else if (attr == DeviceAttributes.mode) {
      final intValue = value as int;
      if (message is MessageGeneralSet) message.mode = intValue;
      if (message is MessageSubProtocolSet) message.mode = intValue;
    } else if (attr == DeviceAttributes.targetTemperature) {
      final doubleValue = (value as num).toDouble();
      if (message is MessageGeneralSet) message.targetTemperature = doubleValue;
      if (message is MessageSubProtocolSet) {
        message.targetTemperature = doubleValue;
      }
    } else if (attr == DeviceAttributes.fanSpeed) {
      final intValue = value as int;
      if (message is MessageGeneralSet) message.fanSpeed = intValue;
      if (message is MessageSubProtocolSet) message.fanSpeed = intValue;
    } else if (attr == DeviceAttributes.swingVertical) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.swingVertical = boolValue;
    } else if (attr == DeviceAttributes.swingHorizontal) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.swingHorizontal = boolValue;
    } else if (attr == DeviceAttributes.boostMode) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.boostMode = boolValue;
      if (message is MessageSubProtocolSet) message.boostMode = boolValue;
    } else if (attr == DeviceAttributes.dry) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.dry = boolValue;
      if (message is MessageSubProtocolSet) message.dry = boolValue;
    } else if (attr == DeviceAttributes.ecoMode) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.ecoMode = boolValue;
      if (message is MessageSubProtocolSet) message.ecoMode = boolValue;
    } else if (attr == DeviceAttributes.sleepMode) {
      final boolValue = value as bool;
      if (message is MessageGeneralSet) message.sleepMode = boolValue;
      if (message is MessageSubProtocolSet) message.sleepMode = boolValue;
    }
  }

  void setTargetTemperature(double targetTemperature, {int? mode, int? zone}) {
    final message = _usedSubprotocol
        ? makeSubprotocolMessageSet()
        : makeMessageSet();
    if (message is MessageGeneralSet) {
      message.targetTemperature = targetTemperature;
    } else if (message is MessageSubProtocolSet) {
      message.targetTemperature = targetTemperature;
    }
    if (mode != null) {
      if (message is MessageGeneralSet) {
        message.power = true;
        message.mode = mode;
      } else if (message is MessageSubProtocolSet) {
        message.power = true;
        message.mode = mode;
      }
    }
    buildSend(message);
  }

  void setSwing(bool swingVertical, bool swingHorizontal) {
    final message = _usedSubprotocol
        ? makeSubprotocolMessageSet()
        : makeMessageSet();
    if (message is MessageGeneralSet) {
      message.swingVertical = swingVertical;
      message.swingHorizontal = swingHorizontal;
    }
    buildSend(message);
  }

  void setCustomize(String customize) {
    _temperatureStep = _defaultTemperatureStep;
    _powerAnalysisMethod = _defaultPowerAnalysisMethod;
    try {
      final params = json.decode(customize) as Map<String, dynamic>?;
      if (params != null) {
        if (params.containsKey('temperature_step')) {
          _temperatureStep =
              (params['temperature_step'] as num?)?.toDouble() ??
              _defaultTemperatureStep;
        }
        if (params.containsKey('power_analysis_method')) {
          _powerAnalysisMethod =
              params['power_analysis_method'] as int? ??
              _defaultPowerAnalysisMethod;
        }
      }
    } catch (_) {}
    updateAll({'temperature_step': _temperatureStep});
  }
}

// ---------------------------------------------------------------------------
// MessageACResponse
// ---------------------------------------------------------------------------

class MessageACResponse {
  MessageACResponse(Uint8List message, [int powerAnalysisMethod = 1]) {
    final response = MessageResponse(message);
    _messageType = response.messageType;
    _protocolVersion = response.protocolVersion;
    _bodyType = response.bodyType;
    final body = response.body;
    _body = Uint8List.fromList(body);
    if (body.isEmpty) return;

    if (response.bodyType == 0xBB &&
        (response.messageType == MessageType.set ||
            response.messageType == MessageType.query ||
            response.messageType == MessageType.notify2) &&
        body.length >= 21) {
      usedSubprotocol = true;
      _parseXbb(body);
    } else if (response.bodyType == 0xC0 &&
        (response.messageType == MessageType.set ||
            response.messageType == MessageType.query) &&
        body.length >= 16) {
      _parseC0(body);
    } else if (response.bodyType == 0xA0 &&
        response.messageType == MessageType.notify2 &&
        body.length >= 15) {
      _parseA0(body);
    }
  }

  final Map<String, dynamic> _attributes = {};
  MessageType? _messageType;
  int? _protocolVersion;
  int? _bodyType;
  Uint8List? _body;

  bool? usedSubprotocol;
  bool? promptTone;
  bool? power;
  int? mode;
  double? targetTemperature;
  int? fanSpeed;
  bool? swingVertical;
  bool? swingHorizontal;
  bool? boostMode;
  bool? smartEye;
  bool? dry;
  bool? auxHeating;
  bool? ecoMode;
  bool? sleepMode;
  bool? naturalWind;
  bool? tempFahrenheit;
  bool? screenDisplay;
  bool? screenDisplayAlternate;
  bool? screenDisplayNew;
  bool? fullDust;
  bool? frostProtect;
  bool? comfortMode;
  double? indoorTemperature;
  double? outdoorTemperature;
  int? indoorHumidity;
  bool? indirectWind;
  bool? breezeless;
  bool? freshAirPower;
  int? freshAirFanSpeed;
  bool? freshAir1;
  bool? freshAir2;
  double? totalEnergyConsumption;
  double? currentEnergyConsumption;
  double? realtimePower;
  int? windLrAngle;
  int? windUdAngle;
  bool? sn8Flag;
  bool? timer;

  bool hasAttribute(String attr) => _attributes.containsKey(attr);

  dynamic getAttribute(String attr) => _attributes[attr];

  void setAttribute(String attr, dynamic value) {
    _attributes[attr] = value;
  }

  @override
  String toString() {
    final attrs = <String, dynamic>{
      if (usedSubprotocol != null) 'used_subprotocol': usedSubprotocol,
      if (sn8Flag != null) 'sn8_flag': sn8Flag,
      if (timer != null) 'timer': timer,
      ..._attributes,
      'message_type': _messageType?.name,
      'body_type': _bodyType?.toRadixString(16).padLeft(2, '0'),
      'protocol_version': _protocolVersion,
      'body': _body == null ? null : _hex(_body!),
    };
    return 'MessageACResponse $attrs';
  }

  static String _hex(List<int> data) =>
      data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static double? _parseTemperature(int? integer, int? decimal) {
    if (integer == null || integer == 255) return null;
    var tempInteger = (integer - 50) / 2;
    if (decimal == 0 || decimal == null) return tempInteger;
    if (tempInteger < 0) {
      return tempInteger.floor() - decimal * 0.1;
    }
    return tempInteger.floor() + decimal * 0.1;
  }

  void _set(String attr, dynamic value) {
    setAttribute(attr, value);
  }

  int _signedTempWord(int low, int high) {
    final value = low + high * 256;
    if ((high & 0x80) != 0) {
      return (0 - (~value + 1)) & 0xFFFF;
    }
    return value;
  }

  void _parseXbb(Uint8List body) {
    final subHead = body.sublist(0, 6);
    final subBody = body.sublist(6);
    if (subBody.isEmpty) return;
    final dataType = subHead.last;

    if (dataType == 0x11 || dataType == 0x20) {
      if (subBody.length <= 25) return;
      final modeRaw = subBody[5] + 1;
      final modeIndex = BBACModes.modes.indexOf(modeRaw);
      _set(DeviceAttributes.power, (subBody[0] & 0x01) > 0);
      _set(DeviceAttributes.dry, (subBody[0] & 0x10) > 0);
      _set(DeviceAttributes.boostMode, (subBody[0] & 0x20) > 0);
      _set(DeviceAttributes.auxHeating, (subBody[1] & 0x40) > 0);
      _set(DeviceAttributes.sleepMode, (subBody[2] & 0x80) > 0);
      _set(DeviceAttributes.mode, modeIndex >= 0 ? modeIndex : 0);
      _set(DeviceAttributes.targetTemperature, (subBody[6] - 30) / 2);
      _set(DeviceAttributes.fanSpeed, subBody[7]);
      timer = (subBody[25] & 0x04) > 0;
      _set(DeviceAttributes.ecoMode, (subBody[25] & 0x40) > 0);
    } else if (dataType == 0x10) {
      if (subBody.length <= 80) return;
      _set(
        DeviceAttributes.indoorTemperature,
        _signedTempWord(subBody[7], subBody[8]) / 100,
      );
      _set(
        DeviceAttributes.indoorHumidity,
        subBody[30] != 0 ? subBody[30] : null,
      );
      sn8Flag = subBody[80] == 0x31;
    } else if (dataType == 0x30) {
      if (subBody.length <= 6) return;
      _set(
        DeviceAttributes.outdoorTemperature,
        _signedTempWord(subBody[5], subBody[6]) / 100,
      );
    }
  }

  void _parseC0(Uint8List body) {
    _set(DeviceAttributes.power, (body[1] & 0x01) > 0);
    _set(DeviceAttributes.mode, (body[2] & 0xE0) >> 5);
    _set(
      DeviceAttributes.targetTemperature,
      (body[2] & 0x0F) + 16.0 + ((body[2] & 0x10) > 0 ? 0.5 : 0.0),
    );
    _set(DeviceAttributes.fanSpeed, body[3] & 0x7F);
    _set(DeviceAttributes.swingVertical, (body[7] & 0x0C) > 0);
    _set(DeviceAttributes.swingHorizontal, (body[7] & 0x03) > 0);
    _set(
      DeviceAttributes.boostMode,
      (body[8] & 0x20) > 0 || (body[10] & 0x02) > 0,
    );
    _set(DeviceAttributes.smartEye, (body[8] & 0x40) > 0);
    _set(DeviceAttributes.naturalWind, (body[9] & 0x02) > 0);
    _set(DeviceAttributes.dry, (body[9] & 0x04) > 0);
    _set(DeviceAttributes.auxHeating, (body[9] & 0x08) > 0);
    _set(DeviceAttributes.ecoMode, (body[9] & 0x10) > 0);
    _set(DeviceAttributes.tempFahrenheit, (body[10] & 0x04) > 0);
    _set(DeviceAttributes.sleepMode, (body[10] & 0x01) > 0);
    final decimal = body.length > 20 ? body[15] : 0;
    _set(
      DeviceAttributes.indoorTemperature,
      _parseTemperature(body[11], decimal & 0x0F),
    );
    _set(
      DeviceAttributes.outdoorTemperature,
      _parseTemperature(body[12], decimal >> 4),
    );
    _set(DeviceAttributes.fullDust, (body[13] & 0x20) > 0);
    _set(
      DeviceAttributes.screenDisplay,
      (((body[14] >> 4) & 0x07) != 0x07) && ((body[1] & 0x01) > 0),
    );
    _set(
      DeviceAttributes.frostProtect,
      body.length >= 22 ? (body[21] & 0x80) > 0 : false,
    );
    _set(
      DeviceAttributes.comfortMode,
      body.length >= 23 ? (body[22] & 0x01) > 0 : false,
    );
  }

  void _parseA0(Uint8List body) {
    _set(DeviceAttributes.power, (body[1] & 0x01) > 0);
    _set(
      DeviceAttributes.targetTemperature,
      ((body[1] & 0x3E) >> 1) - 4 + 16.0 + ((body[1] & 0x40) > 0 ? 0.5 : 0.0),
    );
    _set(DeviceAttributes.mode, (body[2] & 0xE0) >> 5);
    _set(DeviceAttributes.fanSpeed, body[3] & 0x7F);
    _set(DeviceAttributes.swingVertical, (body[7] & 0x0C) > 0);
    _set(DeviceAttributes.swingHorizontal, (body[7] & 0x03) > 0);
    _set(
      DeviceAttributes.boostMode,
      (body[8] & 0x20) > 0 || (body[10] & 0x02) > 0,
    );
    _set(DeviceAttributes.smartEye, (body[9] & 0x01) > 0);
    _set(DeviceAttributes.dry, (body[9] & 0x04) > 0);
    _set(DeviceAttributes.auxHeating, (body[9] & 0x08) > 0);
    _set(DeviceAttributes.ecoMode, (body[9] & 0x10) > 0);
    _set(DeviceAttributes.sleepMode, (body[10] & 0x01) > 0);
    _set(DeviceAttributes.naturalWind, (body[10] & 0x40) > 0);
    _set(DeviceAttributes.fullDust, (body[13] & 0x20) > 0);
    _set(
      DeviceAttributes.comfortMode,
      body.length > 16 ? (body[14] & 0x01) > 0 : false,
    );
    _set(
      DeviceAttributes.screenDisplay,
      (((body[14] >> 4) & 0x07) != 0x07) && ((body[1] & 0x01) > 0),
    );
    _set(
      DeviceAttributes.frostProtect,
      body.length >= 22 ? (body[21] & 0x80) > 0 : false,
    );
  }
}
