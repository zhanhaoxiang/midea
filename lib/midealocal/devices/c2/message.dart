/// Midea local C2 device message. Mirrors midealocal/devices/c2/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// C2MessageEnum
// ---------------------------------------------------------------------------

class C2MessageEnum {
  static const int none = 0x00;
  static const int sensorLight = 0x01;
  static const int childLock = 0x10;
  static const int foamShield = 0x1F;
  static const int waterTempLevel = 0x09;
  static const int seatTempLevel = 0x0A;
  static const int dryLevel = 0x0C;
}

// ---------------------------------------------------------------------------
// C2MessageKeys
// ---------------------------------------------------------------------------

class C2MessageKeys {
  static const Map<int, int> childLock = {1: 0x01 << 4, 0: 0x00};
  static const Map<int, int> sensorLight = {1: 0x01 << 1, 0: 0x00};
  static const Map<int, int> foamShield = {1: 0x01 << 2, 0: 0x00};
  static const Map<int, int> dryLevel = {
    0: 0x00,
    1: 0x01 << 1,
    2: 0x02 << 1,
    3: 0x03 << 1,
  };
  static const Map<int, int> seatTempLevel = {
    0: 0x00,
    1: 0x01 << 3,
    2: 0x02 << 3,
    3: 0x03 << 3,
    4: 0x04 << 3,
    5: 0x05 << 3,
  };
  static const Map<int, int> waterTempLevel = {
    0: 0x00,
    1: 0x01,
    2: 0x02,
    3: 0x03,
    4: 0x04,
    5: 0x05,
  };
}

// ---------------------------------------------------------------------------
// MessageC2Base
// ---------------------------------------------------------------------------

abstract class MessageC2Base extends MessageRequest {
  MessageC2Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.c2,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

// ---------------------------------------------------------------------------
// MessageQuery
// ---------------------------------------------------------------------------

class MessageQuery extends MessageC2Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessagePower
// ---------------------------------------------------------------------------

class MessagePower extends MessageC2Base {
  MessagePower(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      );

  bool power = false;

  @override
  int get bodyType {
    if (power) {
      return ListTypes.x01;
    }
    return ListTypes.x02;
  }

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessagePowerOff
// ---------------------------------------------------------------------------

class MessagePowerOff extends MessageC2Base {
  MessagePowerOff(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x02,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageC2Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      );

  bool? childLock;
  bool? sensorLight;
  int? waterTempLevel;
  int? seatTempLevel;
  int? dryLevel;
  bool? foamShield;

  @override
  int get bodyType => ListTypes.x24;

  @override
  Uint8List buildBody() {
    int key = C2MessageEnum.none;
    dynamic value = 0x00;

    if (childLock != null) {
      key = C2MessageEnum.childLock;
      value = childLock;
    } else if (sensorLight != null) {
      key = C2MessageEnum.sensorLight;
      value = sensorLight;
    } else if (waterTempLevel != null) {
      key = C2MessageEnum.waterTempLevel;
      value = waterTempLevel;
    } else if (seatTempLevel != null) {
      key = C2MessageEnum.seatTempLevel;
      value = seatTempLevel;
    } else if (dryLevel != null) {
      key = C2MessageEnum.dryLevel;
      value = dryLevel;
    } else if (foamShield != null) {
      key = C2MessageEnum.foamShield;
      value = foamShield;
    }

    final keyMap = _getKeyMap(key);
    final mappedValue = keyMap[value] ?? 0x00;
    return Uint8List.fromList([key, mappedValue]);
  }

  Map<int, int> _getKeyMap(int key) {
    switch (key) {
      case C2MessageEnum.childLock:
        return C2MessageKeys.childLock;
      case C2MessageEnum.sensorLight:
        return C2MessageKeys.sensorLight;
      case C2MessageEnum.foamShield:
        return C2MessageKeys.foamShield;
      case C2MessageEnum.dryLevel:
        return C2MessageKeys.dryLevel;
      case C2MessageEnum.seatTempLevel:
        return C2MessageKeys.seatTempLevel;
      case C2MessageEnum.waterTempLevel:
        return C2MessageKeys.waterTempLevel;
      default:
        return {};
    }
  }
}

// ---------------------------------------------------------------------------
// C2MessageBody
// ---------------------------------------------------------------------------

class C2MessageBody extends MessageBody {
  C2MessageBody(Uint8List body) : super(body) {
    power = (body[2] & 0x01) > 0;
    seatStatus = (body[3] & 0x01) > 0;
    dryLevel = (body[6] & 0x7E) >> 1;
    waterTempLevel = body[9] & 0x07;
    seatTempLevel = (body[9] & 0x38) >> 3;
    lidStatus = (body[12] & 0x40) > 0;
    foamShield = (body[13] & 0x80) > 0;
    sensorLight = (body[14] & 0x01) > 0;
    lightStatus = (body[14] & 0x02) > 0;
    childLock = (body[14] & 0x04) > 0;
    waterTemperature = body[11];
    seatTemperature = body[11];
    filterLife = 100 - body[19];
  }

  late bool power;
  late bool seatStatus;
  late int dryLevel;
  late int waterTempLevel;
  late int seatTempLevel;
  late bool lidStatus;
  late bool foamShield;
  late bool sensorLight;
  late bool lightStatus;
  late bool childLock;
  late int waterTemperature;
  late int seatTemperature;
  late int filterLife;
}

// ---------------------------------------------------------------------------
// C2Notify1MessageBody
// ---------------------------------------------------------------------------

class C2Notify1MessageBody extends MessageBody {
  C2Notify1MessageBody(Uint8List body) : super(body);
}

// ---------------------------------------------------------------------------
// MessageC2Response
// ---------------------------------------------------------------------------

class MessageC2Response extends MessageResponse {
  MessageC2Response(Uint8List message) : super(message) {
    if (messageType == MessageType.notify1 ||
        messageType == MessageType.query ||
        messageType == MessageType.set) {
      final msgBody = C2MessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? seatStatus;
  int? dryLevel;
  int? waterTempLevel;
  int? seatTempLevel;
  bool? lidStatus;
  bool? foamShield;
  bool? sensorLight;
  bool? lightStatus;
  bool? childLock;
  int? waterTemperature;
  int? seatTemperature;
  int? filterLife;

  void _assignAttrs(C2MessageBody b) {
    power = b.power;
    seatStatus = b.seatStatus;
    dryLevel = b.dryLevel;
    waterTempLevel = b.waterTempLevel;
    seatTempLevel = b.seatTempLevel;
    lidStatus = b.lidStatus;
    foamShield = b.foamShield;
    sensorLight = b.sensorLight;
    lightStatus = b.lightStatus;
    childLock = b.childLock;
    waterTemperature = b.waterTemperature;
    seatTemperature = b.seatTemperature;
    filterLife = b.filterLife;
  }
}
