/// Midea local B8 device message. Mirrors midealocal/devices/b8/message.dart.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';
import 'const.dart';

int _readByte(Uint8List data, int index, {int defaultValue = 0}) =>
    data.length > index ? data[index] : defaultValue;

abstract class MessageB8Base extends MessageRequest {
  MessageB8Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b8,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageB8Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x32,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x01]);
  }
}

class MessageSet extends MessageB8Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0x22,
      );

  B8CleanMode cleanMode = B8CleanMode.auto;
  B8FanLevel fanLevel = B8FanLevel.normal;
  B8WaterLevel waterLevel = B8WaterLevel.low;
  int voiceVolume = 0;
  int zoneId = 0;

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      0x02,
      0x02,
      cleanMode.value,
      fanLevel.value,
      waterLevel.value,
      voiceVolume,
      zoneId,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

class MessageSetCommand extends MessageB8Base {
  MessageSetCommand(int protocolVersion, {required B8WorkMode workMode})
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0x22,
      ) {
    this.workMode = workMode;
  }

  late B8WorkMode workMode;

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([workMode.value, 0x00, 0x00]);
  }
}

class MessageB8GenericBody extends MessageBody {
  MessageB8GenericBody(Uint8List body, {int offset = 0}) : super(body) {
    workStatus = B8WorkStatus.values.firstWhere(
      (e) => e.value == _readByte(data, 1 + offset),
      orElse: () => B8WorkStatus.none,
    );
    functionType = B8FunctionType.values.firstWhere(
      (e) => e.value == _readByte(data, 2 + offset),
      orElse: () => B8FunctionType.none,
    );
    controlType = B8ControlType.values.firstWhere(
      (e) => e.value == _readByte(data, 3 + offset),
      orElse: () => B8ControlType.none,
    );
    moveDirection = B8Moviment.values.firstWhere(
      (e) => e.value == _readByte(data, 4 + offset),
      orElse: () => B8Moviment.none,
    );
    cleanMode = B8CleanMode.values.firstWhere(
      (e) => e.value == _readByte(data, 5 + offset),
      orElse: () => B8CleanMode.none,
    );
    fanLevel = B8FanLevel.values.firstWhere(
      (e) => e.value == _readByte(data, 6 + offset),
      orElse: () => B8FanLevel.off,
    );
    area = _readByte(data, 7 + offset);
    waterLevel = B8WaterLevel.values.firstWhere(
      (e) => e.value == _readByte(data, 8 + offset),
      orElse: () => B8WaterLevel.off,
    );
    voiceVolume = _readByte(data, 9 + offset);
    haveReserveTask = (_readByte(data, 10 + offset) & 0x01) != 0;
    batteryPercent = _readByte(data, 11 + offset);
    workTime = _readByte(data, 12 + offset);
    uvSwitch = (_readByte(data, 13 + offset) & 0x01) != 0;
    wifiSwitch = ((_readByte(data, 13 + offset) >> 1) & 0x01) != 0;
    voiceSwitch = ((_readByte(data, 13 + offset) >> 2) & 0x01) != 0;
    commandSource = ((_readByte(data, 13 + offset) >> 6) & 0x01) != 0;
    deviceError = ((_readByte(data, 13 + offset) >> 7) & 0x01) != 0;
    errorType = B8ErrorType.values.firstWhere(
      (e) => e.value == _readByte(data, 14 + offset),
      orElse: () => B8ErrorType.no,
    );
    mop = B8MopState.values.firstWhere(
      (e) => e.value == _readByte(data, 16 + offset),
      orElse: () => B8MopState.lackWater,
    );
    carpetSwitch = (_readByte(data, 17 + offset) & 0x01) != 0;
    laserSensorError = (_readByte(data, 18 + offset) & 0x01) != 0;
    laserSensorShelter = ((_readByte(data, 18 + offset) >> 1) & 0x01) != 0;
    boardCommunicationError = ((_readByte(data, 18 + offset) >> 2) & 0x01) != 0;
    speed = B8Speed.values.firstWhere(
      (e) => e.value == _readByte(data, 19 + offset),
      orElse: () => B8Speed.high,
    );

    errorDesc = B8ErrorCanFixDescription.no;
    final errorTypeVal = errorType;
    if (errorTypeVal == B8ErrorType.canFix) {
      errorDesc = B8ErrorCanFixDescription.values.firstWhere(
        (e) => e.value == _readByte(data, 15 + offset),
        orElse: () => B8ErrorCanFixDescription.no,
      );
    } else if (errorTypeVal == B8ErrorType.reboot) {
      errorDesc = B8ErrorRebootDescription.values.firstWhere(
        (e) => e.value == _readByte(data, 15 + offset),
        orElse: () => B8ErrorRebootDescription.no,
      );
    } else if (errorTypeVal == B8ErrorType.warning) {
      errorDesc = B8ErrorWarningDescription.values.firstWhere(
        (e) => e.value == _readByte(data, 15 + offset),
        orElse: () => B8ErrorWarningDescription.no,
      );
    }
  }

  late B8WorkStatus workStatus;
  late B8FunctionType functionType;
  late B8ControlType controlType;
  late B8Moviment moveDirection;
  late B8CleanMode cleanMode;
  late B8FanLevel fanLevel;
  late int area;
  late B8WaterLevel waterLevel;
  late int voiceVolume;
  late bool haveReserveTask;
  late int batteryPercent;
  late int workTime;
  late bool uvSwitch;
  late bool wifiSwitch;
  late bool voiceSwitch;
  late bool commandSource;
  late bool deviceError;
  late B8ErrorType errorType;
  late dynamic errorDesc;
  late B8MopState mop;
  late bool carpetSwitch;
  late bool laserSensorError;
  late bool laserSensorShelter;
  late bool boardCommunicationError;
  late B8Speed speed;
}

class MessageB8WorkStatusBody extends MessageB8GenericBody {
  MessageB8WorkStatusBody(Uint8List body) : super(body, offset: 1);
}

class MessageB8NotifyBody extends MessageB8GenericBody {
  MessageB8NotifyBody(Uint8List body) : super(body, offset: 0);
}

class MessageB8Response extends MessageResponse {
  MessageB8Response(Uint8List message) : super(message) {
    MessageB8GenericBody? msgBody;
    if (messageType == MessageType.query &&
        bodyType == 0x32 &&
        _readByte(body, 1) == B8StatusType.x01.value) {
      msgBody = MessageB8WorkStatusBody(body);
    } else if (messageType == MessageType.notify1 && bodyType == 0x42) {
      msgBody = MessageB8NotifyBody(body);
    }
    if (msgBody != null) {
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  B8WorkStatus? workStatus;
  B8FunctionType? functionType;
  B8ControlType? controlType;
  B8Moviment? moveDirection;
  B8CleanMode? cleanMode;
  B8FanLevel? fanLevel;
  int? area;
  B8WaterLevel? waterLevel;
  int? voiceVolume;
  bool? haveReserveTask;
  int? batteryPercent;
  int? workTime;
  bool? uvSwitch;
  bool? wifiSwitch;
  bool? voiceSwitch;
  bool? commandSource;
  bool? deviceError;
  B8ErrorType? errorType;
  dynamic errorDesc;
  B8MopState? mop;
  bool? carpetSwitch;
  bool? laserSensorError;
  bool? laserSensorShelter;
  bool? boardCommunicationError;
  B8Speed? speed;

  void _assignAttrs(MessageB8GenericBody b) {
    workStatus = b.workStatus;
    functionType = b.functionType;
    controlType = b.controlType;
    moveDirection = b.moveDirection;
    cleanMode = b.cleanMode;
    fanLevel = b.fanLevel;
    area = b.area;
    waterLevel = b.waterLevel;
    voiceVolume = b.voiceVolume;
    haveReserveTask = b.haveReserveTask;
    batteryPercent = b.batteryPercent;
    workTime = b.workTime;
    uvSwitch = b.uvSwitch;
    wifiSwitch = b.wifiSwitch;
    voiceSwitch = b.voiceSwitch;
    commandSource = b.commandSource;
    deviceError = b.deviceError;
    errorType = b.errorType;
    errorDesc = b.errorDesc;
    mop = b.mop;
    carpetSwitch = b.carpetSwitch;
    laserSensorError = b.laserSensorError;
    laserSensorShelter = b.laserSensorShelter;
    boardCommunicationError = b.boardCommunicationError;
    speed = b.speed;
  }
}
