/// Midea local CA device. Mirrors midealocal/devices/ca/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class DeviceAttributes {
  static const String mode = 'mode';
  static const String energyConsumption = 'energy_consumption';
  static const String refrigeratorActualTemp = 'refrigerator_actual_temp';
  static const String freezerActualTemp = 'freezer_actual_temp';
  static const String flexZoneActualTemp = 'flex_zone_actual_temp';
  static const String rightFlexZoneActualTemp = 'right_flex_zone_actual_temp';
  static const String refrigeratorSettingTemp = 'refrigerator_setting_temp';
  static const String freezerSettingTemp = 'freezer_setting_temp';
  static const String flexZoneSettingTemp = 'flex_zone_setting_temp';
  static const String rightFlexZoneSettingTemp = 'right_flex_zone_setting_temp';
  static const String refrigeratorDoorOvertime = 'refrigerator_door_overtime';
  static const String freezerDoorOvertime = 'freezer_door_overtime';
  static const String barDoorOvertime = 'bar_door_overtime';
  static const String flexZoneDoorOvertime = 'flex_zone_door_overtime';
  static const String refrigeratorDoor = 'refrigerator_door';
  static const String freezerDoor = 'freezer_door';
  static const String barDoor = 'bar_door';
  static const String flexZoneDoor = 'flex_zone_door';
  static const String microcrystalFresh = 'microcrystal_fresh';
  static const String electronicSmell = 'electronic_smell';
  static const String humidity = 'humidity';
  static const String variableMode = 'variable_mode';
}

class MideaCADevice extends MideaDevice {
  static const Map<int, String> variableModeMap = {
    0x00: 'none',
    0x01: 'soft_freezing',
    0x02: 'zero_fresh',
    0x03: 'cold_drink',
    0x04: 'fresh_product',
    0x05: 'partial_freezing',
    0x06: 'dry_zone',
    0x07: 'freeze_warm',
    0x08: 'partial_freezing',
  };

  static const Map<int, String> humidityMap = {0x10: 'high', 0x20: 'low'};

  MideaCADevice({
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
         deviceType: DeviceType.ca,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.energyConsumption: null,
    DeviceAttributes.refrigeratorActualTemp: null,
    DeviceAttributes.freezerActualTemp: null,
    DeviceAttributes.flexZoneActualTemp: null,
    DeviceAttributes.rightFlexZoneActualTemp: null,
    DeviceAttributes.refrigeratorSettingTemp: null,
    DeviceAttributes.freezerSettingTemp: null,
    DeviceAttributes.flexZoneSettingTemp: null,
    DeviceAttributes.rightFlexZoneSettingTemp: null,
    DeviceAttributes.refrigeratorDoorOvertime: false,
    DeviceAttributes.freezerDoorOvertime: false,
    DeviceAttributes.barDoorOvertime: false,
    DeviceAttributes.flexZoneDoorOvertime: false,
    DeviceAttributes.refrigeratorDoor: false,
    DeviceAttributes.freezerDoor: false,
    DeviceAttributes.barDoor: false,
    DeviceAttributes.flexZoneDoor: false,
    DeviceAttributes.microcrystalFresh: false,
    DeviceAttributes.electronicSmell: false,
    DeviceAttributes.humidity: null,
    DeviceAttributes.variableMode: null,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageCAResponse(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (attr == DeviceAttributes.variableMode && value != null) {
          value = variableModeMap[value] ?? value;
        } else if (attr == DeviceAttributes.humidity && value != null) {
          value = humidityMap[value] ?? value;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageCAResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.mode:
        return msg.codeMode != null;
      case DeviceAttributes.energyConsumption:
        return msg.energyConsumption != null;
      case DeviceAttributes.refrigeratorActualTemp:
        return msg.refrigeratorActualTemp != null;
      case DeviceAttributes.freezerActualTemp:
        return msg.freezerActualTemp != null;
      case DeviceAttributes.flexZoneActualTemp:
        return msg.flexZoneActualTemp != null;
      case DeviceAttributes.rightFlexZoneActualTemp:
        return msg.rightFlexZoneActualTemp != null;
      case DeviceAttributes.refrigeratorSettingTemp:
        return msg.refrigeratorSettingTemp != null;
      case DeviceAttributes.freezerSettingTemp:
        return msg.freezerSettingTemp != null;
      case DeviceAttributes.flexZoneSettingTemp:
        return msg.flexZoneSettingTemp != null;
      case DeviceAttributes.rightFlexZoneSettingTemp:
        return msg.rightFlexZoneSettingTemp != null;
      case DeviceAttributes.refrigeratorDoorOvertime:
        return msg.refrigeratorDoorOvertime != null;
      case DeviceAttributes.freezerDoorOvertime:
        return msg.freezerDoorOvertime != null;
      case DeviceAttributes.barDoorOvertime:
        return msg.barDoorOvertime != null;
      case DeviceAttributes.flexZoneDoorOvertime:
        return msg.flexZoneDoorOvertime != null;
      case DeviceAttributes.refrigeratorDoor:
        return msg.refrigeratorDoor != null;
      case DeviceAttributes.freezerDoor:
        return msg.freezerDoor != null;
      case DeviceAttributes.barDoor:
        return msg.barDoor != null;
      case DeviceAttributes.flexZoneDoor:
        return msg.flexZoneDoor != null;
      case DeviceAttributes.microcrystalFresh:
        return msg.microcrystalFresh != null;
      case DeviceAttributes.electronicSmell:
        return msg.electronicSmell != null;
      case DeviceAttributes.humidity:
        return msg.humidity != null;
      case DeviceAttributes.variableMode:
        return msg.variableMode != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCAResponse msg, String attr) {
    switch (attr) {
      case DeviceAttributes.mode:
        return msg.codeMode;
      case DeviceAttributes.energyConsumption:
        return msg.energyConsumption;
      case DeviceAttributes.refrigeratorActualTemp:
        return msg.refrigeratorActualTemp;
      case DeviceAttributes.freezerActualTemp:
        return msg.freezerActualTemp;
      case DeviceAttributes.flexZoneActualTemp:
        return msg.flexZoneActualTemp;
      case DeviceAttributes.rightFlexZoneActualTemp:
        return msg.rightFlexZoneActualTemp;
      case DeviceAttributes.refrigeratorSettingTemp:
        return msg.refrigeratorSettingTemp;
      case DeviceAttributes.freezerSettingTemp:
        return msg.freezerSettingTemp;
      case DeviceAttributes.flexZoneSettingTemp:
        return msg.flexZoneSettingTemp;
      case DeviceAttributes.rightFlexZoneSettingTemp:
        return msg.rightFlexZoneSettingTemp;
      case DeviceAttributes.refrigeratorDoorOvertime:
        return msg.refrigeratorDoorOvertime;
      case DeviceAttributes.freezerDoorOvertime:
        return msg.freezerDoorOvertime;
      case DeviceAttributes.barDoorOvertime:
        return msg.barDoorOvertime;
      case DeviceAttributes.flexZoneDoorOvertime:
        return msg.flexZoneDoorOvertime;
      case DeviceAttributes.refrigeratorDoor:
        return msg.refrigeratorDoor;
      case DeviceAttributes.freezerDoor:
        return msg.freezerDoor;
      case DeviceAttributes.barDoor:
        return msg.barDoor;
      case DeviceAttributes.flexZoneDoor:
        return msg.flexZoneDoor;
      case DeviceAttributes.microcrystalFresh:
        return msg.microcrystalFresh;
      case DeviceAttributes.electronicSmell:
        return msg.electronicSmell;
      case DeviceAttributes.humidity:
        return msg.humidity;
      case DeviceAttributes.variableMode:
        return msg.variableMode;
      default:
        return null;
    }
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}

class MideaAppliance extends MideaCADevice {
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
