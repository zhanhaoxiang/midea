/// Midea local EA device. Mirrors midealocal/devices/ea/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String cooking = 'cooking';
  static const String keepWarm = 'keep_warm';
  static const String mode = 'mode';
  static const String timeRemaining = 'time_remaining';
  static const String keepWarmTime = 'keep_warm_time';
  static const String topTemperature = 'top_temperature';
  static const String bottomTemperature = 'bottom_temperature';
  static const String progress = 'progress';
}

class MideaEADevice extends MideaDevice {
  static const List<String> modeList = [
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
  ];

  static const List<String> progressList = [
    'Idle',
    'Delay',
    'Cooking',
    'Keep-warm',
  ];

  MideaEADevice({
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
         deviceType: DeviceType.ea,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.cooking: false,
    DeviceAttributes.keepWarm: false,
    DeviceAttributes.mode: 0,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.topTemperature: null,
    DeviceAttributes.bottomTemperature: null,
    DeviceAttributes.keepWarmTime: null,
    DeviceAttributes.progress: 'Unknown',
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageEAResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DeviceAttributes.progress && value != null) {
          if (value is int && value < progressList.length) {
            value = progressList[value];
          } else {
            value = 'Unknown';
          }
        } else if (attr == DeviceAttributes.mode && value != null) {
          if (value is int) {
            final modeListWithExtra = [
              ...modeList,
              ...List.filled(98, 'unknown'),
              'clean',
              ...List.filled(5, 'unknown'),
              'keep_warm',
            ];
            if (value < modeListWithExtra.length) {
              value = modeListWithExtra[value];
            } else {
              value = 'Cloud';
            }
          }
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageEAResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.cooking:
        return msg.cooking != null;
      case DeviceAttributes.keepWarm:
        return msg.keepWarm != null;
      case DeviceAttributes.mode:
        return msg.mode != null;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining != null;
      case DeviceAttributes.keepWarmTime:
        return msg.keepWarmTime != null;
      case DeviceAttributes.topTemperature:
        return msg.topTemperature != null;
      case DeviceAttributes.bottomTemperature:
        return msg.bottomTemperature != null;
      case DeviceAttributes.progress:
        return msg.progress != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageEAResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.cooking:
        return msg.cooking;
      case DeviceAttributes.keepWarm:
        return msg.keepWarm;
      case DeviceAttributes.mode:
        return msg.mode;
      case DeviceAttributes.timeRemaining:
        return msg.timeRemaining;
      case DeviceAttributes.keepWarmTime:
        return msg.keepWarmTime;
      case DeviceAttributes.topTemperature:
        return msg.topTemperature;
      case DeviceAttributes.bottomTemperature:
        return msg.bottomTemperature;
      case DeviceAttributes.progress:
        return msg.progress;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}

class MideaAppliance extends MideaEADevice {
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
