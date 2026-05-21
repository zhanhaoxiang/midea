/// Midea local X26 device. Mirrors midealocal/devices/x26/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

const int directionMinValue = 60;
const int directionMaxValue = 120;

class DeviceAttributes {
  static const String mainLight = 'main_light';
  static const String nightLight = 'night_light';
  static const String mode = 'mode';
  static const String direction = 'direction';
  static const String currentHumidity = 'current_humidity';
  static const String currentRadar = 'current_radar';
  static const String currentTemperature = 'current_temperature';
}

class Midea26Device extends MideaDevice {
  Midea26Device({
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
         deviceType: DeviceType.x26,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const List<String> modes = [
    'Off',
    'Heat(high)',
    'Heat(low)',
    'Bath',
    'Blow',
    'Ventilation',
    'Dry',
  ];

  static const List<String> directions = [
    '60',
    '70',
    '80',
    '90',
    '100',
    '110',
    '120',
    'Oscillate',
  ];

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.mainLight: false,
    DeviceAttributes.nightLight: false,
    DeviceAttributes.mode: null,
    DeviceAttributes.direction: null,
    DeviceAttributes.currentHumidity: null,
    DeviceAttributes.currentRadar: null,
    DeviceAttributes.currentTemperature: null,
  };

  Map<String, dynamic> _fields = {};

  static int _convertToMideaDirection(String direction) {
    if (direction == 'Oscillate') {
      return 0xFD;
    }
    final index = directions.indexOf(direction);
    if (index == -1) return 0xFD;
    return index * 10 + 60;
  }

  static int _convertFromMideaDirection(int direction) {
    if (direction > directionMaxValue || direction < directionMinValue) {
      return 7;
    }
    return ((direction - 60 + 5) / 10).floor();
  }

  List<String> get presetModes => modes;

  List<String> get deviceDirections => directions;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = Message26Response(msg);
    final newStatus = <String, dynamic>{};
    _fields = Map<String, dynamic>.from(message.fields);

    if (message.mainLight != null) {
      attrs[DeviceAttributes.mainLight] = message.mainLight;
      newStatus[DeviceAttributes.mainLight] = message.mainLight;
    }
    if (message.nightLight != null) {
      attrs[DeviceAttributes.nightLight] = message.nightLight;
      newStatus[DeviceAttributes.nightLight] = message.nightLight;
    }
    if (message.mode != null) {
      final modeIndex = message.mode!;
      if (modeIndex >= 0 && modeIndex < modes.length) {
        attrs[DeviceAttributes.mode] = modes[modeIndex];
        newStatus[DeviceAttributes.mode] = modes[modeIndex];
      }
    }
    if (message.direction != null) {
      final dirIndex = _convertFromMideaDirection(message.direction!);
      if (dirIndex >= 0 && dirIndex < directions.length) {
        attrs[DeviceAttributes.direction] = directions[dirIndex];
        newStatus[DeviceAttributes.direction] = directions[dirIndex];
      }
    }
    if (message.currentHumidity != null) {
      attrs[DeviceAttributes.currentHumidity] = message.currentHumidity;
      newStatus[DeviceAttributes.currentHumidity] = message.currentHumidity;
    }
    if (message.currentRadar != null) {
      attrs[DeviceAttributes.currentRadar] = message.currentRadar;
      newStatus[DeviceAttributes.currentRadar] = message.currentRadar;
    }
    if (message.currentTemperature != null) {
      attrs[DeviceAttributes.currentTemperature] = message.currentTemperature;
      newStatus[DeviceAttributes.currentTemperature] =
          message.currentTemperature;
    }

    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {
    final settableAttrs = <String>[
      DeviceAttributes.mainLight,
      DeviceAttributes.nightLight,
      DeviceAttributes.mode,
      DeviceAttributes.direction,
    ];
    if (!settableAttrs.contains(attr)) {
      return;
    }

    final message = MessageSet(messageProtocolVersion);
    message.fields = _fields.map((k, v) => MapEntry(k, v as int));

    final currentMainLight =
        attrs[DeviceAttributes.mainLight] as bool? ?? false;
    final currentNightLight =
        attrs[DeviceAttributes.nightLight] as bool? ?? false;
    final currentMode = attrs[DeviceAttributes.mode];
    final currentDirection = attrs[DeviceAttributes.direction];

    message.mainLight = currentMainLight;
    message.nightLight = currentNightLight;
    if (currentMode != null) {
      final modeIndex = modes.indexOf(currentMode as String);
      if (modeIndex >= 0) message.mode = modeIndex;
    }
    if (currentDirection != null) {
      message.direction = _convertToMideaDirection(currentDirection as String);
    }

    if (attr == DeviceAttributes.mainLight ||
        attr == DeviceAttributes.nightLight) {
      message.mainLight = false;
      message.nightLight = false;
      if (attr == DeviceAttributes.mainLight) {
        message.mainLight = value as bool;
      } else if (attr == DeviceAttributes.nightLight) {
        message.nightLight = value as bool;
      }
    } else if (attr == DeviceAttributes.mode) {
      final modeIndex = modes.indexOf(value as String);
      if (modeIndex >= 0) message.mode = modeIndex;
    } else if (attr == DeviceAttributes.direction) {
      message.direction = _convertToMideaDirection(value as String);
    }

    buildSend(message);
  }
}
