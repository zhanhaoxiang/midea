/// Midea local X13 device. Mirrors midealocal/devices/x13/__init__.py.

import 'dart:convert';
import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String brightness = 'brightness';
  static const String colorTemperature = 'color_temperature';
  static const String rgbColor = 'rgb_color';
  static const String effect = 'effect';
  static const String power = 'power';
}

class MideaX13Device extends MideaDevice {
  static const List<String> _effects = [
    'Manual',
    'Living',
    'Reading',
    'Mildly',
    'Cinema',
    'Night',
  ];

  MideaX13Device({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
  }) : super(
         deviceType: DeviceType.x13,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       ) {
    _colorTempRange = _defaultColorTempRange;
    setCustomize('');
  }

  List<int> _colorTempRange = [];
  static const List<int> _defaultColorTempRange = [2700, 6500];

  List<String> get effects => MideaX13Device._effects;

  List<int> get colorTempRange => _colorTempRange;

  int kelvinToMidea(int kelvin) {
    return ((kelvin - _colorTempRange[0]) /
            (_colorTempRange[1] - _colorTempRange[0]) *
            255)
        .round();
  }

  int mideaToKelvin(int midea) {
    return ((_colorTempRange[1] - _colorTempRange[0]) / 255 * midea).round() +
        _colorTempRange[0];
  }

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = Message13Response(msg);
    final newStatus = <String, dynamic>{};

    if (message.controlSuccess != null) {
      newStatus['control_success'] = message.controlSuccess;
      if (message.controlSuccess == true) {
        refreshStatus();
      }
    } else {
      for (final status in attrs.keys) {
        final attrValue = _getMessageAttribute(message, status);
        if (attrValue != null) {
          if (status == DeviceAttributes.effect) {
            attrs[status] = _effects[attrValue as int];
            newStatus[status] = attrs[status];
          } else if (status == DeviceAttributes.colorTemperature) {
            attrs[status] = mideaToKelvin(attrValue as int);
            newStatus[status] = attrs[status];
          } else {
            attrs[status] = attrValue;
            newStatus[status] = attrValue;
          }
        }
      }
    }
    return newStatus;
  }

  dynamic _getMessageAttribute(Message13Response msg, String attr) {
    switch (attr) {
      case DeviceAttributes.brightness:
        return msg.brightness;
      case DeviceAttributes.colorTemperature:
        return msg.colorTemperature;
      case DeviceAttributes.effect:
        return msg.effect;
      case DeviceAttributes.power:
        return msg.power;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DeviceAttributes.brightness ||
        attr == DeviceAttributes.colorTemperature ||
        attr == DeviceAttributes.effect ||
        attr == DeviceAttributes.power) {
      final message = MessageSet(messageProtocolVersion);
      if (attr == DeviceAttributes.effect && _effects.contains(value)) {
        message.effect = _effects.indexOf(value as String);
      } else if (attr == DeviceAttributes.colorTemperature) {
        message.colorTemperature = kelvinToMidea(value as int);
      } else {
        switch (attr) {
          case DeviceAttributes.power:
            message.power = value as bool;
            break;
          case DeviceAttributes.brightness:
            message.brightness = value as int;
            break;
        }
      }
      buildSend(message);
    }
  }

  void setCustomize(String customize) {
    _colorTempRange = List<int>.from(_defaultColorTempRange);
    if (customize.isNotEmpty) {
      try {
        final params = jsonDecode(customize) as Map<String, dynamic>;
        if (params.containsKey('color_temp_range_kelvin')) {
          final range = params['color_temp_range_kelvin'];
          if (range is List) {
            _colorTempRange = range.cast<int>();
          }
        }
      } catch (_) {
        // ignore
      }
    }
    updateAll({'color_temp_range': _colorTempRange});
  }

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.brightness: null,
    DeviceAttributes.colorTemperature: null,
    DeviceAttributes.rgbColor: null,
    DeviceAttributes.effect: null,
    DeviceAttributes.power: false,
  };
}

class MideaX13Appliance extends MideaX13Device {
  MideaX13Appliance({
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
