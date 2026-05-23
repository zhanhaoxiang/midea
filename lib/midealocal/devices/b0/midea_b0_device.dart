/// Midea local B0 device. Mirrors midealocal/devices/b0/__init__.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class B0DeviceAttributes {
  static const String door = 'door';
  static const String status = 'status';
  static const String timeRemaining = 'time_remaining';
  static const String currentTemperature = 'current_temperature';
  static const String tankEjected = 'tank_ejected';
  static const String waterChangeReminder = 'water_change_reminder';
  static const String waterShortage = 'water_shortage';
  static const String mode = 'mode';
  static const String firePower = 'fire_power';
  static const String childLock = 'child_lock';
}

class MideaB0Device extends MideaDevice {
  MideaB0Device({
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
         deviceType: DeviceType.b0,
         deviceProtocol: deviceProtocol,
         attributes: {
           B0DeviceAttributes.door: false,
           B0DeviceAttributes.status: null,
           B0DeviceAttributes.timeRemaining: null,
           B0DeviceAttributes.currentTemperature: null,
           B0DeviceAttributes.tankEjected: false,
           B0DeviceAttributes.waterChangeReminder: false,
           B0DeviceAttributes.waterShortage: false,
           B0DeviceAttributes.mode: null,
           B0DeviceAttributes.firePower: null,
           B0DeviceAttributes.childLock: false,
         },
       );

  static const Map<int, String> _status = {
    0x01: 'Cancel',
    0x02: 'Working',
    0x03: 'Pause',
    0x04: 'Finished',
    0x06: 'Order',
    0x07: 'Save Power',
    0x08: 'Heat',
    0x09: 'Three',
    0x0D: 'Reaction',
    0x66: 'Cloud',
    0xFF: 'Default',
  };

  static const Map<int, String> _status31 = {
    0x01: 'Save Power',
    0x02: 'Idle',
    0x03: 'Working',
    0x04: 'Finished',
    0x05: 'Delay',
    0x06: 'Paused',
    0x07: 'Pause Cancel',
    0x08: 'Three',
    0xFF: 'Default',
  };

  static const Map<int, String> _mode = {
    0x00: 'None',
    0x01: 'Microwave',
    0x02: 'Baking',
    0x03: 'Ferment',
    0x04: 'Unfreeze',
    0x05: 'Roast',
    0x06: 'Host Steam',
    0x07: 'Fast Steam',
    0x08: 'Fast Hot',
    0x09: 'Pure Steam',
    0x0A: 'Metal Sterilize',
    0x0B: 'Remove Odor',
    0x0C: 'Scale Clean',
    0x0D: 'Smart Clean',
    0x11: 'Smart Steam Fish',
    0x12: 'Rice',
    0x13: 'Steam Ribs',
    0x14: 'Code to Hot',
    0x15: 'Wing',
    0x16: 'Kebab',
    0x18: 'Egg',
    0x19: 'Instant Noodle',
    0x1A: 'Vegetable',
    0x1B: 'Meat',
    0x1C: 'Tofu',
    0x1D: 'Chicken Soup',
    0x1E: 'Dumplings',
    0x1F: 'Porridge',
    0x20: 'Chicken Block',
    0x21: 'Pumpkin',
    0x22: 'Popcorn',
    0x23: 'Meat Eggplant',
    0x24: 'Bake Shrimp',
    0x25: 'Baby Milk',
    0x26: 'Baby Egg',
    0x27: 'Carrots',
    0x28: 'Baby Fruit',
    0x29: 'Snow Pear',
    0x2A: 'Papaya Milk',
    0x2B: 'Jujube Longan',
    0x2C: 'Lotus Seed',
    0x2D: 'Fast Soup',
    0x2E: 'Sirloin',
    0x2F: 'Coconut Sogo',
    0x30: 'Meat Tofu',
    0x31: 'Spicy Tofu',
    0x32: 'Sauted Meat',
    0x33: 'Steam Corn',
    0x34: 'Pearl Meat',
    0x35: 'Bun',
    0x36: 'Coix Bean',
    0x37: 'Bake Ribs',
    0x38: 'Sausage',
    0x39: 'Bake Cake',
    0x3A: 'Bake Cookies',
    0x3B: 'Sweet Potato',
    0x3C: 'Steam Seafood',
    0x3D: 'Fans Scallops',
    0x3E: 'Steam Bun',
    0x3F: 'Sauerkraut Fish',
    0x41: 'Warm',
    0x42: 'Pre Hot',
    0x43: 'Baking',
    0x44: 'Brittle',
    0x50: 'Frozen Food',
    0x51: 'Milk Coffee',
    0x52: 'Spicy Sausage',
    0x53: 'Bake Swing',
    0x54: 'Pure Steam Fish',
  };

  static const Map<int, String> _mode31 = {
    0x00: 'None',
    0x01: 'Microwave',
    0x40: 'Above Tube',
    0xA0: 'Unfreeze',
    0xC3: 'Remove Odor',
    0xE0: 'Auto',
    0xE2: 'Humidit Auto',
    0xFF: 'Default',
  };

  static const Map<int, String> _firePower31 = {
    0x01: 'Low',
    0x03: 'Medium Low',
    0x05: 'Medium',
    0x08: 'Medium High',
    0x0A: 'High',
    0xFF: 'Default',
  };

  @override
  List<MessageRequest> buildQuery() {
    return [
      MessageQuery00(messageProtocolVersion),
      MessageQuery01(messageProtocolVersion),
      MessageQuery31(messageProtocolVersion),
    ];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB0Response(msg);
    final newStatus = <String, dynamic>{};
    for (final attr in attributes.keys) {
      if (attr == B0DeviceAttributes.door) {
        if (message.door != null) {
          attributes[attr] = message.door;
          newStatus[attr] = message.door;
        }
      } else if (attr == B0DeviceAttributes.status) {
        if (message.status != null) {
          if (subtype > 0) {
            attributes[attr] = _status31[message.status];
          } else {
            attributes[attr] = _status[message.status];
          }
          newStatus[attr] = attributes[attr];
        }
      } else if (attr == B0DeviceAttributes.timeRemaining) {
        if (message.timeRemaining != null) {
          attributes[attr] = message.timeRemaining;
          newStatus[attr] = message.timeRemaining;
        }
      } else if (attr == B0DeviceAttributes.currentTemperature) {
        if (message.currentTemperature != null) {
          attributes[attr] = message.currentTemperature;
          newStatus[attr] = message.currentTemperature;
        }
      } else if (attr == B0DeviceAttributes.tankEjected) {
        if (message.tankEjected != null) {
          attributes[attr] = message.tankEjected;
          newStatus[attr] = message.tankEjected;
        }
      } else if (attr == B0DeviceAttributes.waterChangeReminder) {
        if (message.waterChangeReminder != null) {
          attributes[attr] = message.waterChangeReminder;
          newStatus[attr] = message.waterChangeReminder;
        }
      } else if (attr == B0DeviceAttributes.waterShortage) {
        if (message.waterShortage != null) {
          attributes[attr] = message.waterShortage;
          newStatus[attr] = message.waterShortage;
        }
      } else if (attr == B0DeviceAttributes.mode) {
        if (message.mode != null) {
          if (subtype > 0) {
            attributes[attr] = _mode31[message.mode];
          } else {
            attributes[attr] = _mode[message.mode];
          }
          newStatus[attr] = attributes[attr];
        }
      } else if (attr == B0DeviceAttributes.firePower) {
        if (message.firePower != null) {
          if (subtype > 0) {
            attributes[attr] = _firePower31[message.firePower];
          } else {
            attributes[attr] = message.firePower;
          }
          newStatus[attr] = attributes[attr];
        }
      } else if (attr == B0DeviceAttributes.childLock) {
        if (message.childLock != null) {
          attributes[attr] = message.childLock;
          newStatus[attr] = message.childLock;
        }
      }
    }
    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
