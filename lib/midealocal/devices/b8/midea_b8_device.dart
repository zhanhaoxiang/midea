/// Midea local B8 device. Mirrors midealocal/devices/b8/__init__.py.

import 'dart:typed_data';

import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'const.dart';
import 'message.dart';

class MideaB8Device extends MideaDevice {
  MideaB8Device({
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
         deviceType: DeviceType.b8,
         deviceProtocol: deviceProtocol,
         attributes: _defaultAttributes,
       );

  static final Map<String, dynamic> _defaultAttributes = {
    B8DeviceAttributes.workStatus: B8WorkStatus.none.name,
    B8DeviceAttributes.functionType: B8FunctionType.none.name,
    B8DeviceAttributes.controlType: B8ControlType.none.name,
    B8DeviceAttributes.moveDirection: B8Moviment.none.name,
    B8DeviceAttributes.cleanMode: B8CleanMode.none.name,
    B8DeviceAttributes.fanLevel: B8FanLevel.off.name,
    B8DeviceAttributes.area: 0,
    B8DeviceAttributes.waterLevel: B8WaterLevel.off.name,
    B8DeviceAttributes.voiceVolume: 0,
    B8DeviceAttributes.mop: B8MopState.off.name,
    B8DeviceAttributes.carpetSwitch: false,
    B8DeviceAttributes.speed: B8Speed.high.name,
    B8DeviceAttributes.haveReserveTask: false,
    B8DeviceAttributes.batteryPercent: 0,
    B8DeviceAttributes.workTime: 0,
    B8DeviceAttributes.uvSwitch: false,
    B8DeviceAttributes.wifiSwitch: false,
    B8DeviceAttributes.voiceSwitch: false,
    B8DeviceAttributes.commandSource: false,
    B8DeviceAttributes.errorType: B8ErrorType.no.name,
    B8DeviceAttributes.errorDesc: B8ErrorCanFixDescription.no.name,
    B8DeviceAttributes.deviceError: false,
    B8DeviceAttributes.boardCommunicationError: false,
    B8DeviceAttributes.laserSensorShelter: false,
    B8DeviceAttributes.laserSensorError: false,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB8Response(msg);
    final newStatus = <String, dynamic>{};

    for (final attr in attrs.keys) {
      if (_hasAttribute(message, attr)) {
        var value = _getAttribute(message, attr);
        if (value is B8WorkStatus) {
          value = value.name;
        } else if (value is B8FunctionType) {
          value = value.name;
        } else if (value is B8ControlType) {
          value = value.name;
        } else if (value is B8Moviment) {
          value = value.name;
        } else if (value is B8CleanMode) {
          value = value.name;
        } else if (value is B8FanLevel) {
          value = value.name;
        } else if (value is B8WaterLevel) {
          value = value.name;
        } else if (value is B8MopState) {
          value = value.name;
        } else if (value is B8Speed) {
          value = value.name;
        } else if (value is B8ErrorType) {
          value = value.name;
        }
        attrs[attr] = value;
        newStatus[attr] = value;
      }
    }
    return newStatus;
  }

  bool _hasAttribute(MessageB8Response msg, String attr) {
    switch (attr) {
      case B8DeviceAttributes.workStatus:
        return msg.workStatus != null;
      case B8DeviceAttributes.functionType:
        return msg.functionType != null;
      case B8DeviceAttributes.controlType:
        return msg.controlType != null;
      case B8DeviceAttributes.moveDirection:
        return msg.moveDirection != null;
      case B8DeviceAttributes.cleanMode:
        return msg.cleanMode != null;
      case B8DeviceAttributes.fanLevel:
        return msg.fanLevel != null;
      case B8DeviceAttributes.area:
        return msg.area != null;
      case B8DeviceAttributes.waterLevel:
        return msg.waterLevel != null;
      case B8DeviceAttributes.voiceVolume:
        return msg.voiceVolume != null;
      case B8DeviceAttributes.mop:
        return msg.mop != null;
      case B8DeviceAttributes.carpetSwitch:
        return msg.carpetSwitch != null;
      case B8DeviceAttributes.speed:
        return msg.speed != null;
      case B8DeviceAttributes.haveReserveTask:
        return msg.haveReserveTask != null;
      case B8DeviceAttributes.batteryPercent:
        return msg.batteryPercent != null;
      case B8DeviceAttributes.workTime:
        return msg.workTime != null;
      case B8DeviceAttributes.uvSwitch:
        return msg.uvSwitch != null;
      case B8DeviceAttributes.wifiSwitch:
        return msg.wifiSwitch != null;
      case B8DeviceAttributes.voiceSwitch:
        return msg.voiceSwitch != null;
      case B8DeviceAttributes.commandSource:
        return msg.commandSource != null;
      case B8DeviceAttributes.errorType:
        return msg.errorType != null;
      case B8DeviceAttributes.errorDesc:
        return msg.errorDesc != null;
      case B8DeviceAttributes.deviceError:
        return msg.deviceError != null;
      case B8DeviceAttributes.boardCommunicationError:
        return msg.boardCommunicationError != null;
      case B8DeviceAttributes.laserSensorShelter:
        return msg.laserSensorShelter != null;
      case B8DeviceAttributes.laserSensorError:
        return msg.laserSensorError != null;
      default:
        return false;
    }
  }

  dynamic _getAttribute(MessageB8Response msg, String attr) {
    switch (attr) {
      case B8DeviceAttributes.workStatus:
        return msg.workStatus;
      case B8DeviceAttributes.functionType:
        return msg.functionType;
      case B8DeviceAttributes.controlType:
        return msg.controlType;
      case B8DeviceAttributes.moveDirection:
        return msg.moveDirection;
      case B8DeviceAttributes.cleanMode:
        return msg.cleanMode;
      case B8DeviceAttributes.fanLevel:
        return msg.fanLevel;
      case B8DeviceAttributes.area:
        return msg.area;
      case B8DeviceAttributes.waterLevel:
        return msg.waterLevel;
      case B8DeviceAttributes.voiceVolume:
        return msg.voiceVolume;
      case B8DeviceAttributes.mop:
        return msg.mop;
      case B8DeviceAttributes.carpetSwitch:
        return msg.carpetSwitch;
      case B8DeviceAttributes.speed:
        return msg.speed;
      case B8DeviceAttributes.haveReserveTask:
        return msg.haveReserveTask;
      case B8DeviceAttributes.batteryPercent:
        return msg.batteryPercent;
      case B8DeviceAttributes.workTime:
        return msg.workTime;
      case B8DeviceAttributes.uvSwitch:
        return msg.uvSwitch;
      case B8DeviceAttributes.wifiSwitch:
        return msg.wifiSwitch;
      case B8DeviceAttributes.voiceSwitch:
        return msg.voiceSwitch;
      case B8DeviceAttributes.commandSource:
        return msg.commandSource;
      case B8DeviceAttributes.errorType:
        return msg.errorType;
      case B8DeviceAttributes.errorDesc:
        return msg.errorDesc;
      case B8DeviceAttributes.deviceError:
        return msg.deviceError;
      case B8DeviceAttributes.boardCommunicationError:
        return msg.boardCommunicationError;
      case B8DeviceAttributes.laserSensorShelter:
        return msg.laserSensorShelter;
      case B8DeviceAttributes.laserSensorError:
        return msg.laserSensorError;
      default:
        return null;
    }
  }

  MessageSet _genSetMsgDefaultValues() {
    final msg = MessageSet(messageProtocolVersion);
    msg.cleanMode = B8CleanMode.values.firstWhere(
      (e) =>
          e.name == _toTitleCase(attrs[B8DeviceAttributes.cleanMode] as String),
      orElse: () => B8CleanMode.auto,
    );
    msg.fanLevel = B8FanLevel.values.firstWhere(
      (e) =>
          e.name == _toTitleCase(attrs[B8DeviceAttributes.fanLevel] as String),
      orElse: () => B8FanLevel.normal,
    );
    msg.waterLevel = B8WaterLevel.values.firstWhere(
      (e) =>
          e.name ==
          _toTitleCase(attrs[B8DeviceAttributes.waterLevel] as String),
      orElse: () => B8WaterLevel.low,
    );
    msg.voiceVolume = attrs[B8DeviceAttributes.voiceVolume] as int? ?? 0;
    return msg;
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  void setWorkMode(B8WorkMode workMode) {
    if (workMode == B8WorkMode.work) {
      setAttribute(
        B8DeviceAttributes.cleanMode,
        attrs[B8DeviceAttributes.cleanMode] as String,
      );
      return;
    }

    final msg = MessageSetCommand(messageProtocolVersion, workMode: workMode);
    buildSend(msg);
  }

  @override
  void setAttribute(String attr, dynamic value) {
    try {
      final msg = _genSetMsgDefaultValues();
      if (attr == B8DeviceAttributes.cleanMode) {
        msg.cleanMode = B8CleanMode.values.firstWhere(
          (e) => e.name == _toTitleCase(value as String),
          orElse: () => B8CleanMode.auto,
        );
      } else if (attr == B8DeviceAttributes.fanLevel) {
        msg.fanLevel = B8FanLevel.values.firstWhere(
          (e) => e.name == _toTitleCase(value as String),
          orElse: () => B8FanLevel.normal,
        );
      } else if (attr == B8DeviceAttributes.waterLevel) {
        msg.waterLevel = B8WaterLevel.values.firstWhere(
          (e) => e.name == _toTitleCase(value as String),
          orElse: () => B8WaterLevel.low,
        );
      } else if (attr == B8DeviceAttributes.voiceVolume) {
        msg.voiceVolume = value as int? ?? 0;
      } else {
        return;
      }
      buildSend(msg);
    } catch (e) {
      // Log error but don't throw
    }
  }
}

class MideaAppliance extends MideaB8Device {
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
