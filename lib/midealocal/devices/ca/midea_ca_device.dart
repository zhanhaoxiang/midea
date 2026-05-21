/// Midea local CA device. Mirrors midealocal/devices/ca/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class CaDeviceAttributes {
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
    CaDeviceAttributes.energyConsumption: null,
    CaDeviceAttributes.refrigeratorActualTemp: null,
    CaDeviceAttributes.freezerActualTemp: null,
    CaDeviceAttributes.flexZoneActualTemp: null,
    CaDeviceAttributes.rightFlexZoneActualTemp: null,
    CaDeviceAttributes.refrigeratorSettingTemp: null,
    CaDeviceAttributes.freezerSettingTemp: null,
    CaDeviceAttributes.flexZoneSettingTemp: null,
    CaDeviceAttributes.rightFlexZoneSettingTemp: null,
    CaDeviceAttributes.refrigeratorDoorOvertime: false,
    CaDeviceAttributes.freezerDoorOvertime: false,
    CaDeviceAttributes.barDoorOvertime: false,
    CaDeviceAttributes.flexZoneDoorOvertime: false,
    CaDeviceAttributes.refrigeratorDoor: false,
    CaDeviceAttributes.freezerDoor: false,
    CaDeviceAttributes.barDoor: false,
    CaDeviceAttributes.flexZoneDoor: false,
    CaDeviceAttributes.microcrystalFresh: false,
    CaDeviceAttributes.electronicSmell: false,
    CaDeviceAttributes.humidity: null,
    CaDeviceAttributes.variableMode: null,
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
        if (attr == CaDeviceAttributes.variableMode && value != null) {
          value = variableModeMap[value] ?? value;
        } else if (attr == CaDeviceAttributes.humidity && value != null) {
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
      case CaDeviceAttributes.mode:
        return msg.codeMode != null;
      case CaDeviceAttributes.energyConsumption:
        return msg.energyConsumption != null;
      case CaDeviceAttributes.refrigeratorActualTemp:
        return msg.refrigeratorActualTemp != null;
      case CaDeviceAttributes.freezerActualTemp:
        return msg.freezerActualTemp != null;
      case CaDeviceAttributes.flexZoneActualTemp:
        return msg.flexZoneActualTemp != null;
      case CaDeviceAttributes.rightFlexZoneActualTemp:
        return msg.rightFlexZoneActualTemp != null;
      case CaDeviceAttributes.refrigeratorSettingTemp:
        return msg.refrigeratorSettingTemp != null;
      case CaDeviceAttributes.freezerSettingTemp:
        return msg.freezerSettingTemp != null;
      case CaDeviceAttributes.flexZoneSettingTemp:
        return msg.flexZoneSettingTemp != null;
      case CaDeviceAttributes.rightFlexZoneSettingTemp:
        return msg.rightFlexZoneSettingTemp != null;
      case CaDeviceAttributes.refrigeratorDoorOvertime:
        return msg.refrigeratorDoorOvertime != null;
      case CaDeviceAttributes.freezerDoorOvertime:
        return msg.freezerDoorOvertime != null;
      case CaDeviceAttributes.barDoorOvertime:
        return msg.barDoorOvertime != null;
      case CaDeviceAttributes.flexZoneDoorOvertime:
        return msg.flexZoneDoorOvertime != null;
      case CaDeviceAttributes.refrigeratorDoor:
        return msg.refrigeratorDoor != null;
      case CaDeviceAttributes.freezerDoor:
        return msg.freezerDoor != null;
      case CaDeviceAttributes.barDoor:
        return msg.barDoor != null;
      case CaDeviceAttributes.flexZoneDoor:
        return msg.flexZoneDoor != null;
      case CaDeviceAttributes.microcrystalFresh:
        return msg.microcrystalFresh != null;
      case CaDeviceAttributes.electronicSmell:
        return msg.electronicSmell != null;
      case CaDeviceAttributes.humidity:
        return msg.humidity != null;
      case CaDeviceAttributes.variableMode:
        return msg.variableMode != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageCAResponse msg, String attr) {
    switch (attr) {
      case CaDeviceAttributes.mode:
        return msg.codeMode;
      case CaDeviceAttributes.energyConsumption:
        return msg.energyConsumption;
      case CaDeviceAttributes.refrigeratorActualTemp:
        return msg.refrigeratorActualTemp;
      case CaDeviceAttributes.freezerActualTemp:
        return msg.freezerActualTemp;
      case CaDeviceAttributes.flexZoneActualTemp:
        return msg.flexZoneActualTemp;
      case CaDeviceAttributes.rightFlexZoneActualTemp:
        return msg.rightFlexZoneActualTemp;
      case CaDeviceAttributes.refrigeratorSettingTemp:
        return msg.refrigeratorSettingTemp;
      case CaDeviceAttributes.freezerSettingTemp:
        return msg.freezerSettingTemp;
      case CaDeviceAttributes.flexZoneSettingTemp:
        return msg.flexZoneSettingTemp;
      case CaDeviceAttributes.rightFlexZoneSettingTemp:
        return msg.rightFlexZoneSettingTemp;
      case CaDeviceAttributes.refrigeratorDoorOvertime:
        return msg.refrigeratorDoorOvertime;
      case CaDeviceAttributes.freezerDoorOvertime:
        return msg.freezerDoorOvertime;
      case CaDeviceAttributes.barDoorOvertime:
        return msg.barDoorOvertime;
      case CaDeviceAttributes.flexZoneDoorOvertime:
        return msg.flexZoneDoorOvertime;
      case CaDeviceAttributes.refrigeratorDoor:
        return msg.refrigeratorDoor;
      case CaDeviceAttributes.freezerDoor:
        return msg.freezerDoor;
      case CaDeviceAttributes.barDoor:
        return msg.barDoor;
      case CaDeviceAttributes.flexZoneDoor:
        return msg.flexZoneDoor;
      case CaDeviceAttributes.microcrystalFresh:
        return msg.microcrystalFresh;
      case CaDeviceAttributes.electronicSmell:
        return msg.electronicSmell;
      case CaDeviceAttributes.humidity:
        return msg.humidity;
      case CaDeviceAttributes.variableMode:
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
