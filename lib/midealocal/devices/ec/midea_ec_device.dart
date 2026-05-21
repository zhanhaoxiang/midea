/// Midea local EC device. Mirrors midealocal/devices/ec/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

// ---------------------------------------------------------------------------
// DeviceAttributes
// ---------------------------------------------------------------------------

class DeviceAttributes {
  static const String cooking = 'cooking';
  static const String mode = 'mode';
  static const String timeRemaining = 'time_remaining';
  static const String keepWarmTime = 'keep_warm_time';
  static const String topTemperature = 'top_temperature';
  static const String bottomTemperature = 'bottom_temperature';
  static const String progress = 'progress';
  static const String withPressure = 'with_pressure';
}

// ---------------------------------------------------------------------------
// MideaECDevice
// ---------------------------------------------------------------------------

class MideaECDevice extends MideaDevice {
  MideaECDevice({
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
         deviceType: DeviceType.ec,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const List<String> _modeList = [
    'smart',
    'reserve',
    'cook_rice',
    'fast_cook_rice',
    'standard_cook_rice',
    'gruel',
    'cook_congee',
    'stew_soup',
    'stewing',
    'heat_rice',
    'make_cake',
    'yoghourt',
    'soup_rice',
    'coarse_rice',
    'five_ceeals_rice',
    'eight_treasures_rice',
    'crispy_rice',
    'shelled_rice',
    'eight_treasures_congee',
    'infant_congee',
    'older_rice',
    'rice_soup',
    'rice_paste',
    'egg_custard',
    'warm_milk',
    'hot_spring_egg',
    'millet_congee',
    'firewood_rice',
    'few_rice',
    'red_potato',
    'corn',
    'quick_freeze_bun',
    'steam_ribs',
    'steam_egg',
    'coarse_congee',
    'steep_rice',
    'appetizing_congee',
    'corn_congee',
    'sprout_rice',
    'luscious_rice',
    'luscious_boiled',
    'fast_rice',
    'fast_boil',
    'bean_rice_congee',
    'fast_congee',
    'baby_congee',
    'cook_soup',
    'congee_coup',
    'steam_corn',
    'steam_red_potato',
    'boil_congee',
    'delicious_steam',
    'boil_egg',
    'rice_wine',
    'fruit_vegetable_paste',
    'vegetable_porridge',
    'pork_porridge',
    'fragrant_rice',
    'assorte_rice',
    'steame_fish',
    'baby_rice',
    'essence_rice',
    'fragrant_dense_congee',
    'one_two_cook',
    'original_steame',
    'hot_fast_rice',
    'online_celebrity_rice',
    'sushi_rice',
    'stone_bowl_rice',
    'no_water_treat',
    'keep_fresh',
    'low_sugar_rice',
    'black_buckwheat_rice',
    'resveratrol_rice',
    'yellow_wheat_rice',
    'green_buckwheat_rice',
    'roughage_rice',
    'millet_mixed_rice',
    'iron_pan_rice',
    'olla_pan_rice',
    'vegetable_rice',
    'baby_side',
    'regimen_congee',
    'earthen_pot_congee',
    'regimen_soup',
    'pottery_jar_soup',
    'canton_soup',
    'nutrition_stew',
    'northeast_stew',
    'uncap_boil',
    'trichromatic_coarse_grain',
    'four_color_vegetables',
    'egg',
    'chop',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'clean',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'unknown',
    'keep_warm',
    'diy',
  ];

  static const List<String> _progress = [
    'Idle',
    'Cooking',
    'Delay',
    'Keep-warm',
    'Lid-open',
    'Relieving',
    'Keep-pressure',
    'Relieving',
    'Cooking',
    'Relieving',
    'Lid-open',
  ];

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.cooking: false,
    DeviceAttributes.mode: 0,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.topTemperature: null,
    DeviceAttributes.bottomTemperature: null,
    DeviceAttributes.keepWarmTime: null,
    DeviceAttributes.progress: 'Unknown',
    DeviceAttributes.withPressure: null,
  };

  late MessageECResponse _message;

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    _message = MessageECResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      final fieldName = status;
      if (fieldName == DeviceAttributes.progress) {
        final value = _message.progress;
        if (value != null && value < _progress.length) {
          attrs[status] = _progress[value];
        } else {
          attrs[status] = 'Unknown';
        }
      } else if (fieldName == DeviceAttributes.mode) {
        final value = _message.mode;
        if (value != null && value < _modeList.length) {
          attrs[status] = _modeList[value];
        } else {
          attrs[status] = 'Cloud';
        }
      } else {
        final value = _getMessageValue(fieldName);
        attrs[status] = value;
      }
      newStatus[fieldName] = attrs[status];
    }
    return newStatus;
  }

  dynamic _getMessageValue(String fieldName) {
    switch (fieldName) {
      case DeviceAttributes.cooking:
        return _message.cooking;
      case DeviceAttributes.mode:
        return _message.mode;
      case DeviceAttributes.timeRemaining:
        return _message.timeRemaining;
      case DeviceAttributes.keepWarmTime:
        return _message.keepWarmTime;
      case DeviceAttributes.topTemperature:
        return _message.topTemperature;
      case DeviceAttributes.bottomTemperature:
        return _message.bottomTemperature;
      case DeviceAttributes.progress:
        return _message.progress;
      case DeviceAttributes.withPressure:
        return _message.withPressure;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
