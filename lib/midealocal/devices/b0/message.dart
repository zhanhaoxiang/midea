/// Midea local B0 device message. Mirrors midealocal/devices/b0/message.dart.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxByteValue = 0xFF;
const int minMsgBody = 15;

class B0ListTypes {
  static const int x00 = 0x00;
  static const int x01 = 0x01;
  static const int x22 = 0x22;
  static const int x31 = 0x31;
  static const int x41 = 0x41;
}

abstract class MessageB0Base extends MessageRequest {
  MessageB0Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b0,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery00 extends MessageB0Base {
  MessageQuery00(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: B0ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQuery01 extends MessageB0Base {
  MessageQuery01(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: B0ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQuery31 extends MessageB0Base {
  MessageQuery31(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: B0ListTypes.x31,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageSetWorkMode extends MessageB0Base {
  MessageSetWorkMode(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: B0ListTypes.x22,
      );

  int mode = maxByteValue;
  int firePower = maxByteValue;
  int workTime = 60;
  int temperature = 0;

  @override
  Uint8List buildBody() {
    final workHours = workTime ~/ 3600;
    final workMinutes = (workTime % 3600) ~/ 60;
    final workSeconds = workTime % 60;

    final temperatureHigh = temperature > 0 ? temperature ~/ 256 : 0;
    final temperatureLow = temperature > 0 ? temperature % 256 : 0;

    return Uint8List.fromList([
      0x01,
      0x00,
      0x00,
      0x00,
      0x11,
      0x00,
      workHours,
      workMinutes,
      workSeconds,
      mode,
      temperatureHigh,
      temperatureLow,
      temperatureHigh,
      temperatureLow,
      firePower,
      0xFF,
      0xFF,
      0x00,
    ]);
  }
}

class MessageSetNotWorkMode extends MessageB0Base {
  MessageSetNotWorkMode(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: B0ListTypes.x22,
      );

  int status = maxByteValue;
  int power = maxByteValue;
  int childLock = maxByteValue;
  int door = maxByteValue;

  @override
  Uint8List buildBody() {
    int statusVal;
    if (status < maxByteValue) {
      statusVal = status;
    } else if (power < maxByteValue) {
      statusVal = power;
    } else {
      statusVal = maxByteValue;
    }

    return Uint8List.fromList([0x02, statusVal, childLock, 0xFF, 0xFF, door]);
  }
}

class MessageIncreaseControl extends MessageB0Base {
  MessageIncreaseControl(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: B0ListTypes.x22,
      );

  int timeIncrease = 0;
  int temperatureIncrease = 0;

  @override
  Uint8List buildBody() {
    final hoursInc = timeIncrease ~/ 3600;
    final minutesInc = (timeIncrease % 3600) ~/ 60;
    final secondsInc = timeIncrease % 60;

    final temperatureInc = temperatureIncrease > 0 ? temperatureIncrease : 0xFF;

    return Uint8List.fromList([
      0x03,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      hoursInc,
      minutesInc,
      secondsInc,
      0xFF,
      0xFF,
      temperatureInc,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
    ]);
  }
}

class MessageSetControl extends MessageB0Base {
  MessageSetControl(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: B0ListTypes.x22,
      );

  int workTime = 0;
  int firePower = maxByteValue;
  int temperature = 0;

  @override
  Uint8List buildBody() {
    final hoursWork = workTime ~/ 3600;
    final minutesWork = (workTime % 3600) ~/ 60;
    final secondsWork = workTime % 60;

    final hoursSet = hoursWork > 0 ? hoursWork : 0xFF;
    final minutesSet = minutesWork > 0 ? minutesWork : 0xFF;
    final secondsSet = secondsWork > 0 ? secondsWork : 0xFF;

    final temperatureEnable = temperature > 0 ? 0x00 : 0xFF;
    final temperatureSet = temperature > 0 ? temperature : 0xFF;

    return Uint8List.fromList([
      0x04,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      hoursSet,
      minutesSet,
      secondsSet,
      0xFF,
      temperatureEnable,
      temperatureSet,
      0xFF,
      0xFF,
      firePower,
      0xFF,
      0xFF,
      0xFF,
    ]);
  }
}

class B0MessageBody extends MessageBody {
  B0MessageBody(Uint8List body) : super(body) {
    if (body.length > minMsgBody) {
      door = (body[0] & 0x80) > 0;
      status = body[0] & 0x7F;
      mode = body[1];
      timeRemaining = body[2] * 60 + body[3];
      workStage = body[4];
      errorCode = body[5];
      tipsCode = body[6];
      maintain = body[7];
      firePower = body[14];
    }
  }

  late bool door;
  late int status;
  late int mode;
  late int timeRemaining;
  late int workStage;
  late int errorCode;
  late int tipsCode;
  late int maintain;
  late int firePower;
}

class B0Message01Body extends MessageBody {
  B0Message01Body(Uint8List body) : super(body) {
    if (body.length > minMsgBody) {
      door = (body[32] & 0x02) > 0;
      status = body[31];
      timeRemaining = _parseTime(body, 22);
      currentTemperature = _parseTemp(body, 25, body[27], body[28]);
      tankEjected = (body[32] & 0x04) > 0;
      waterShortage = (body[32] & 0x08) > 0;
      waterChangeReminder = (body[32] & 0x10) > 0;
    }
  }

  int _parseTime(Uint8List body, int offset) {
    final hour = body[offset] == maxByteValue ? 0 : body[offset];
    final min = body[offset + 1] == maxByteValue ? 0 : body[offset + 1];
    final sec = body[offset + 2] == maxByteValue ? 0 : body[offset + 2];
    return hour * 3600 + min * 60 + sec;
  }

  int _parseTemp(Uint8List body, int offset, int altOffset1, int altOffset2) {
    var temp = (body[offset] << 8) + body[offset + 1];
    if (temp == 0) {
      temp = (body[altOffset1] << 8) + body[altOffset2];
    }
    return temp;
  }

  late bool door;
  late int status;
  late int timeRemaining;
  late int currentTemperature;
  late bool tankEjected;
  late bool waterShortage;
  late bool waterChangeReminder;
}

class B0Message31Body extends MessageBody {
  B0Message31Body(Uint8List body) : super(body) {
    if (body.length > minMsgBody) {
      status = body[1];
      cloudmenuid = body[2] * 65536 + body[3] * 256 + body[4];
      totalStep = body[5] / 16;
      stepNum = body[5];
      timeRemaining = _parseTime(body, 6);
      mode = body[9];
      currentTemperature = _parseTemperature(body);
      firePower = body[14];
      weight = body[15] == maxByteValue ? 0 : body[15] * 10;
      peopleNumber = body[15] == maxByteValue ? 0 : body[15];
      childLock = _getBit(body[16], 0) > 0;
      door = _getBit(body[16], 1) > 0;
      tankEjected = _getBit(body[16], 2) > 0;
      waterShortage = _getBit(body[16], 3) > 0;
      waterChangeReminder = _getBit(body[16], 4) > 0;
      preHeat = _getPreHeat(body[16]);
      errorCode = _getBit(body[16], 7);
    }
  }

  int _parseTime(Uint8List body, int offset) {
    final hour = body[offset] == maxByteValue ? 0 : body[offset];
    final min = body[offset + 1] == maxByteValue ? 0 : body[offset + 1];
    final sec = body[offset + 2] == maxByteValue ? 0 : body[offset + 2];
    return hour * 3600 + min * 60 + sec;
  }

  int _parseTemperature(Uint8List body) {
    final tempAbove = body[11];
    final tempUnder = body[13];
    if (0 < tempAbove && tempAbove < maxByteValue) {
      return tempAbove;
    }
    if (0 < tempUnder && tempUnder < maxByteValue) {
      return tempUnder;
    }
    return 0;
  }

  int _getBit(int byte, int bit) => (byte >> bit) & 1;

  String _getPreHeat(int byte) {
    final preheat = _getBit(byte, 5);
    final preheatEnd = _getBit(byte, 6);
    if (preheatEnd == 1) {
      return 'End';
    } else if (preheat == 1) {
      return 'Working';
    }
    return 'Off';
  }

  late int status;
  late int cloudmenuid;
  late double totalStep;
  late int stepNum;
  late int timeRemaining;
  late int mode;
  late int currentTemperature;
  late int firePower;
  late int weight;
  late int peopleNumber;
  late bool childLock;
  late bool door;
  late bool tankEjected;
  late bool waterShortage;
  late bool waterChangeReminder;
  late String preHeat;
  late int errorCode;
}

class MessageB0Response extends MessageResponse {
  MessageB0Response(Uint8List message) : super(message) {
    if (messageType == MessageType.set ||
        messageType == MessageType.notify1 ||
        messageType == MessageType.query) {
      if (bodyType == B0ListTypes.x01) {
        setBody(B0Message01Body(body));
        _assignAttrs(B0Message01Body(body));
      } else if (bodyType == B0ListTypes.x31 || bodyType == B0ListTypes.x41) {
        setBody(B0Message31Body(body));
        _assignAttrs(B0Message31Body(body));
      } else {
        setBody(B0MessageBody(body));
        _assignAttrs(B0MessageBody(body));
      }
    }
  }

  void _assignAttrs(MessageBody body) {
    if (body is B0MessageBody) {
      door = body.door;
      status = body.status;
      mode = body.mode;
      timeRemaining = body.timeRemaining;
      firePower = body.firePower;
    } else if (body is B0Message01Body) {
      door = body.door;
      status = body.status;
      timeRemaining = body.timeRemaining;
      currentTemperature = body.currentTemperature;
      tankEjected = body.tankEjected;
      waterShortage = body.waterShortage;
      waterChangeReminder = body.waterChangeReminder;
    } else if (body is B0Message31Body) {
      status = body.status;
      timeRemaining = body.timeRemaining;
      mode = body.mode;
      currentTemperature = body.currentTemperature;
      firePower = body.firePower;
      childLock = body.childLock;
      door = body.door;
      tankEjected = body.tankEjected;
      waterShortage = body.waterShortage;
      waterChangeReminder = body.waterChangeReminder;
    }
  }

  bool? door;
  int? status;
  int? mode;
  int? timeRemaining;
  int? currentTemperature;
  int? firePower;
  bool? tankEjected;
  bool? waterShortage;
  bool? waterChangeReminder;
  bool? childLock;
}
