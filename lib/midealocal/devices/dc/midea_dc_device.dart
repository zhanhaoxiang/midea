/// Midea local DC device. Mirrors midealocal/devices/dc/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../exceptions.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DcDeviceAttributes
// ---------------------------------------------------------------------------

class DcDeviceAttributes {
  static const String power = 'power';
  static const String start = 'start';
  static const String status = 'status';
  static const String program = 'program';
  static const String intensity = 'intensity';
  static const String drynessLevel = 'dryness_level';
  static const String dryTemperature = 'dry_temperature';
  static const String errorCode = 'error_code';
  static const String doorWarn = 'door_warn';
  static const String aiSwitch = 'ai_switch';
  static const String material = 'material';
  static const String waterBox = 'water_box';
  static const String washingData = 'washing_data';
  static const String progress = 'progress';
  static const String timeRemaining = 'time_remaining';
}

// ---------------------------------------------------------------------------
// MideaDCDevice
// ---------------------------------------------------------------------------

class MideaDCDevice extends MideaDevice {
  static const Map<int, String> _statusMap = {
    0: 'idle',
    1: 'standby',
    2: 'start',
    3: 'pause',
    4: 'end',
    5: 'prevent_wrinkle_end',
    6: 'delay_choosing',
    7: 'fault',
    8: 'delay',
    9: 'delay_pause',
  };

  static const Map<int, String> _programMap = {
    0: 'cotton',
    1: 'fiber',
    2: 'mixed_wash',
    3: 'jean',
    4: 'bedsheet',
    5: 'outdoor',
    6: 'down_jacket',
    7: 'plush',
    8: 'wool',
    9: 'dehumidify',
    10: 'cold_air_fresh_air',
    11: 'hot_air_dry',
    12: 'sport_clothes',
    13: 'underwear',
    14: 'baby_clothes',
    15: 'shirt',
    16: 'standard',
    17: 'quick_dry',
    18: 'fresh_air',
    19: 'low_temp_dry',
    20: 'eco_dry',
    21: 'quick_dry_30',
    22: 'towel',
    23: 'intelligent_dry',
    24: 'steam_care',
    25: 'big',
    26: 'fixed_time_dry',
    27: 'night_dry',
    28: 'bracket_dry',
    29: 'western_trouser',
    30: 'dehumidification',
    31: 'smart_dry',
    32: 'four_piece_suit',
    33: 'warm_clothes',
    34: 'quick_dry_20',
    35: 'steam_sterilize',
    36: 'enzyme',
    37: 'big_60',
    38: 'steam_no_iron',
    39: 'air_wash',
    40: 'bed_clothes',
    41: 'little_fast_dry',
    42: 'small_piece_dry',
    43: 'big_dry',
    44: 'wool_nurse',
    45: 'sun_quilt',
    46: 'fresh_remove_smell',
    47: 'bucket_self_clean',
    48: 'silk',
    49: 'sterilize',
  };

  static final List<String> _progressList = [
    'Prog0',
    'Prog1',
    'Prog2',
    'Prog3',
    'Prog4',
    'Prog5',
    'Prog6',
    'Prog7',
  ];

  MideaDCDevice({
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
         deviceType: DeviceType.dc,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DcDeviceAttributes.power: false,
    DcDeviceAttributes.start: false,
    DcDeviceAttributes.status: null,
    DcDeviceAttributes.program: null,
    DcDeviceAttributes.intensity: null,
    DcDeviceAttributes.drynessLevel: null,
    DcDeviceAttributes.dryTemperature: null,
    DcDeviceAttributes.errorCode: null,
    DcDeviceAttributes.doorWarn: null,
    DcDeviceAttributes.aiSwitch: null,
    DcDeviceAttributes.material: null,
    DcDeviceAttributes.waterBox: null,
    DcDeviceAttributes.washingData: Uint8List(0),
    DcDeviceAttributes.progress: null,
    DcDeviceAttributes.timeRemaining: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageDCResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DcDeviceAttributes.progress && value != null) {
          final idx = value as int;
          value = idx >= 0 && idx < _progressList.length
              ? _progressList[idx]
              : null;
        } else if (attr == DcDeviceAttributes.status) {
          value = _statusMap[value] ?? value;
        } else if (attr == DcDeviceAttributes.program) {
          value = _programMap[value] ?? value;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageDCResponse msg, String attr) {
    switch (attr) {
      case DcDeviceAttributes.power:
        return msg.power != null;
      case DcDeviceAttributes.start:
        return msg.start != null;
      case DcDeviceAttributes.status:
        return msg.status != null;
      case DcDeviceAttributes.program:
        return msg.program != null;
      case DcDeviceAttributes.intensity:
        return msg.intensity != null;
      case DcDeviceAttributes.drynessLevel:
        return msg.drynessLevel != null;
      case DcDeviceAttributes.dryTemperature:
        return msg.dryTemperature != null;
      case DcDeviceAttributes.errorCode:
        return msg.errorCode != null;
      case DcDeviceAttributes.doorWarn:
        return msg.doorWarn != null;
      case DcDeviceAttributes.aiSwitch:
        return msg.aiSwitch != null;
      case DcDeviceAttributes.material:
        return msg.material != null;
      case DcDeviceAttributes.waterBox:
        return msg.waterBox != null;
      case DcDeviceAttributes.washingData:
        return msg.washingData != null;
      case DcDeviceAttributes.progress:
        return msg.progress != null;
      case DcDeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageDCResponse msg, String attr) {
    switch (attr) {
      case DcDeviceAttributes.power:
        return msg.power;
      case DcDeviceAttributes.start:
        return msg.start;
      case DcDeviceAttributes.status:
        return msg.status;
      case DcDeviceAttributes.program:
        return msg.program;
      case DcDeviceAttributes.intensity:
        return msg.intensity;
      case DcDeviceAttributes.drynessLevel:
        return msg.drynessLevel;
      case DcDeviceAttributes.dryTemperature:
        return msg.dryTemperature;
      case DcDeviceAttributes.errorCode:
        return msg.errorCode;
      case DcDeviceAttributes.doorWarn:
        return msg.doorWarn;
      case DcDeviceAttributes.aiSwitch:
        return msg.aiSwitch;
      case DcDeviceAttributes.material:
        return msg.material;
      case DcDeviceAttributes.waterBox:
        return msg.waterBox;
      case DcDeviceAttributes.washingData:
        return msg.washingData;
      case DcDeviceAttributes.progress:
        return msg.progress;
      case DcDeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {
    if (attr == DcDeviceAttributes.power) {
      if (value is! bool) {
        throw MideaLocalError('[dc] Expected bool');
      }
      final message = MessagePower(messageProtocolVersion);
      message.power = value;
      buildSend(message);
    } else if (attr == DcDeviceAttributes.start) {
      if (value is! bool) {
        throw MideaLocalError('[dc] Expected bool');
      }
      final message = MessageStart(messageProtocolVersion);
      message.start = value;
      message.washingData =
          attrs[DcDeviceAttributes.washingData] as Uint8List? ?? Uint8List(0);
      buildSend(message);
    }
  }
}
