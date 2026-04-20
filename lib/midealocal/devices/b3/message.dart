/// Midea local B3 device message. Mirrors midealocal/devices/b3/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int _x21BottomCompartmentRemainingByte = 18;
const int _x21MiddleCompartmentRemainingByte = 19;
const int _x21TopCompartmentRemainingByte = 17;
const int _x31BottomCompartmentRemainingByte = 24;
const int _x31MiddleCompartmentRemainingByte = 25;
const int _x31TopCompartmentRemainingByte = 23;

// ---------------------------------------------------------------------------
// MessageB3Base
// ---------------------------------------------------------------------------

abstract class MessageB3Base extends MessageRequest {
  MessageB3Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b3,
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

class MessageQuery extends MessageB3Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x31,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// B3MessageBody00
// ---------------------------------------------------------------------------

class B3MessageBody00 extends MessageBody {
  B3MessageBody00(Uint8List body) : super(body) {
    topCompartmentStatus = body[1];
    topCompartmentMode = body[2];
    topCompartmentTemperature = body[3];
    final topHour = body[4] != maxByteValue ? body[4] * 60 : 0;
    final topMinutes = body[5] != maxByteValue ? body[5] : 0;
    final topSeconds = body[6] != maxByteValue ? (body[6] / 60).round() : 0;
    topCompartmentRemaining = topHour + topMinutes + topSeconds;

    bottomCompartmentStatus = body[10];
    bottomCompartmentMode = body[11];
    bottomCompartmentTemperature = body[12];
    final bottomHour = body[13] != maxByteValue ? body[13] * 60 : 0;
    final bottomMinutes = body[14] != maxByteValue ? body[14] : 0;
    final bottomSeconds = body[15] != maxByteValue
        ? (body[15] / 60).round()
        : 0;
    bottomCompartmentRemaining = bottomHour + bottomMinutes + bottomSeconds;

    middleCompartmentStatus = body[19];
    middleCompartmentMode = body[20];
    middleCompartmentTemperature = body[21];
    final middleHour = body[22] != maxByteValue ? body[22] * 60 : 0;
    final middleMinutes = body[23] != maxByteValue ? body[23] : 0;
    final middleSeconds = body[24] != maxByteValue
        ? (body[24] / 60).round()
        : 0;
    middleCompartmentRemaining = middleHour + middleMinutes + middleSeconds;

    lock = (body[30] & 0x01) > 0;
    bottomCompartmentDoor = (body[30] & 0x02) > 0;
    topCompartmentDoor = (body[30] & 0x04) > 0;
    middleCompartmentDoor = (body[30] & 0x08) > 0;

    bottomCompartmentPreheating = (body[31] & 0x01) > 0;
    topCompartmentPreheating = (body[31] & 0x02) > 0;
    middleCompartmentPreheating = (body[31] & 0x10) > 0;

    bottomCompartmentCooling = (body[31] & 0x04) > 0;
    topCompartmentCooling = (body[31] & 0x08) > 0;
    middleCompartmentCooling = (body[31] & 0x20) > 0;
  }

  late int topCompartmentStatus;
  late int topCompartmentMode;
  late int topCompartmentTemperature;
  late int topCompartmentRemaining;
  late int bottomCompartmentStatus;
  late int bottomCompartmentMode;
  late int bottomCompartmentTemperature;
  late int bottomCompartmentRemaining;
  late int middleCompartmentStatus;
  late int middleCompartmentMode;
  late int middleCompartmentTemperature;
  late int middleCompartmentRemaining;
  late bool lock;
  late bool bottomCompartmentDoor;
  late bool topCompartmentDoor;
  late bool middleCompartmentDoor;
  late bool bottomCompartmentPreheating;
  late bool topCompartmentPreheating;
  late bool middleCompartmentPreheating;
  late bool bottomCompartmentCooling;
  late bool topCompartmentCooling;
  late bool middleCompartmentCooling;
}

// ---------------------------------------------------------------------------
// B3MessageBody31
// ---------------------------------------------------------------------------

class B3MessageBody31 extends MessageBody {
  B3MessageBody31(Uint8List body) : super(body) {
    topCompartmentStatus = body[1];
    topCompartmentMode = body[2];
    topCompartmentTemperature = body[3];
    if (body.length > _x31TopCompartmentRemainingByte &&
        body[_x31TopCompartmentRemainingByte] != maxByteValue) {
      topCompartmentRemaining = body[_x31TopCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[4] != maxByteValue) {
        remaining += body[4] * 60;
      }
      if (body[5] != maxByteValue) {
        remaining += body[5];
      }
      topCompartmentRemaining = remaining;
    }

    bottomCompartmentStatus = body[6];
    bottomCompartmentMode = body[7];
    bottomCompartmentTemperature = body[8];
    if (body.length > _x31BottomCompartmentRemainingByte &&
        body[_x31BottomCompartmentRemainingByte] != maxByteValue) {
      bottomCompartmentRemaining =
          body[_x31BottomCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[9] != maxByteValue) {
        remaining += body[9] * 60;
      }
      if (body[10] != maxByteValue) {
        remaining += body[10];
      }
      bottomCompartmentRemaining = remaining;
    }

    middleCompartmentStatus = body[17];
    middleCompartmentMode = body[18];
    middleCompartmentTemperature = body[19];
    if (body.length > _x31MiddleCompartmentRemainingByte &&
        body[_x31MiddleCompartmentRemainingByte] != maxByteValue) {
      middleCompartmentRemaining =
          body[_x31MiddleCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[20] != maxByteValue) {
        remaining += body[20] * 60;
      }
      if (body[21] != maxByteValue) {
        remaining += body[21];
      }
      middleCompartmentRemaining = remaining;
    }

    lock = (body[11] & 0x01) > 0;
    bottomCompartmentDoor = (body[11] & 0x02) > 0;
    topCompartmentDoor = (body[11] & 0x04) > 0;
    middleCompartmentDoor = (body[11] & 0x10) > 0;

    bottomCompartmentPreheating = (body[16] & 0x01) > 0;
    topCompartmentPreheating = (body[16] & 0x02) > 0;
    middleCompartmentPreheating = (body[16] & 0x10) > 0;

    bottomCompartmentCooling = (body[16] & 0x04) > 0;
    topCompartmentCooling = (body[16] & 0x08) > 0;
    middleCompartmentCooling = (body[16] & 0x20) > 0;
  }

  late int topCompartmentStatus;
  late int topCompartmentMode;
  late int topCompartmentTemperature;
  late int topCompartmentRemaining;
  late int bottomCompartmentStatus;
  late int bottomCompartmentMode;
  late int bottomCompartmentTemperature;
  late int bottomCompartmentRemaining;
  late int middleCompartmentStatus;
  late int middleCompartmentMode;
  late int middleCompartmentTemperature;
  late int middleCompartmentRemaining;
  late bool lock;
  late bool bottomCompartmentDoor;
  late bool topCompartmentDoor;
  late bool middleCompartmentDoor;
  late bool bottomCompartmentPreheating;
  late bool topCompartmentPreheating;
  late bool middleCompartmentPreheating;
  late bool bottomCompartmentCooling;
  late bool topCompartmentCooling;
  late bool middleCompartmentCooling;
}

// ---------------------------------------------------------------------------
// B3MessageBody21
// ---------------------------------------------------------------------------

class B3MessageBody21 extends MessageBody {
  B3MessageBody21(Uint8List body) : super(body) {
    topCompartmentStatus = body[1];
    topCompartmentMode = body[2];
    topCompartmentTemperature = body[3];
    if (body.length > _x21TopCompartmentRemainingByte &&
        body[_x21TopCompartmentRemainingByte] != maxByteValue) {
      topCompartmentRemaining = body[_x21TopCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[4] != maxByteValue) {
        remaining += body[4] * 60;
      }
      if (body[5] != maxByteValue) {
        remaining += body[5];
      }
      topCompartmentRemaining = remaining;
    }

    bottomCompartmentStatus = body[6];
    bottomCompartmentMode = body[7];
    bottomCompartmentTemperature = body[8];
    if (body.length > _x21BottomCompartmentRemainingByte &&
        body[_x21BottomCompartmentRemainingByte] != maxByteValue) {
      bottomCompartmentRemaining =
          body[_x21BottomCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[9] != maxByteValue) {
        remaining += body[9] * 60;
      }
      if (body[10] != maxByteValue) {
        remaining += body[10];
      }
      bottomCompartmentRemaining = remaining;
    }

    middleCompartmentStatus = body[12];
    middleCompartmentMode = body[13];
    middleCompartmentTemperature = body[14];
    if (body.length > _x21MiddleCompartmentRemainingByte &&
        body[_x21MiddleCompartmentRemainingByte] != maxByteValue) {
      middleCompartmentRemaining =
          body[_x21MiddleCompartmentRemainingByte] * 3600;
    } else {
      int remaining = 0;
      if (body[15] != maxByteValue) {
        remaining += body[15] * 60;
      }
      if (body[16] != maxByteValue) {
        remaining += body[16];
      }
      middleCompartmentRemaining = remaining;
    }

    lock = (body[11] & 0x01) > 0;
  }

  late int topCompartmentStatus;
  late int topCompartmentMode;
  late int topCompartmentTemperature;
  late int topCompartmentRemaining;
  late int bottomCompartmentStatus;
  late int bottomCompartmentMode;
  late int bottomCompartmentTemperature;
  late int bottomCompartmentRemaining;
  late int middleCompartmentStatus;
  late int middleCompartmentMode;
  late int middleCompartmentTemperature;
  late int middleCompartmentRemaining;
  late bool lock;
}

// ---------------------------------------------------------------------------
// B3MessageBody24
// ---------------------------------------------------------------------------

class B3MessageBody24 extends MessageBody {
  B3MessageBody24(Uint8List body) : super(body) {
    topCompartmentStatus = body[5];
    topCompartmentMode = body[6];
    topCompartmentTemperature = body[7];
    if (body[8] != maxByteValue) {
      topCompartmentRemaining = body[8] * 60;
    } else if (body[9] != maxByteValue) {
      topCompartmentRemaining = body[9];
    } else {
      topCompartmentRemaining = 0;
    }

    bottomCompartmentStatus = body[10];
    bottomCompartmentMode = body[11];
    bottomCompartmentTemperature = body[12];
    if (body[13] != maxByteValue) {
      bottomCompartmentRemaining = body[13] * 60;
    } else if (body[14] != maxByteValue) {
      bottomCompartmentRemaining = body[14];
    } else {
      bottomCompartmentRemaining = 0;
    }

    middleCompartmentStatus = body[15];
    middleCompartmentMode = body[16];
    middleCompartmentTemperature = body[17];
    if (body[18] != maxByteValue) {
      middleCompartmentRemaining = body[18] * 60;
    } else if (body[19] != maxByteValue) {
      middleCompartmentRemaining = body[19];
    } else {
      middleCompartmentRemaining = 0;
    }
  }

  late int topCompartmentStatus;
  late int topCompartmentMode;
  late int topCompartmentTemperature;
  late int topCompartmentRemaining;
  late int bottomCompartmentStatus;
  late int bottomCompartmentMode;
  late int bottomCompartmentTemperature;
  late int bottomCompartmentRemaining;
  late int middleCompartmentStatus;
  late int middleCompartmentMode;
  late int middleCompartmentTemperature;
  late int middleCompartmentRemaining;
}

// ---------------------------------------------------------------------------
// MessageB3Response
// ---------------------------------------------------------------------------

class MessageB3Response extends MessageResponse {
  MessageB3Response(Uint8List message) : super(message) {
    final isQuery = messageType == MessageType.query;
    final isNotify1 = messageType == MessageType.notify1;
    final bodyTypeX31 = bodyType == ListTypes.x31;
    final bodyTypeX41 = bodyType == ListTypes.x41;
    final bodyTypeX00 = bodyType == ListTypes.x00;
    final bodyTypeX21 = bodyType == ListTypes.x21;
    final bodyTypeX24 = bodyType == ListTypes.x24;

    if ((isQuery && bodyTypeX31) || (isNotify1 && bodyTypeX41)) {
      final msgBody = B3MessageBody31(body);
      setBody(msgBody);
      _assignAttrs31(msgBody);
    } else if ((isQuery && bodyTypeX00) || (isNotify1 && bodyTypeX00)) {
      final msgBody = B3MessageBody00(body);
      setBody(msgBody);
      _assignAttrs00(msgBody);
    } else if ((isQuery && bodyTypeX21) || (isNotify1 && bodyTypeX21)) {
      final msgBody = B3MessageBody21(body);
      setBody(msgBody);
      _assignAttrs21(msgBody);
    } else if (bodyTypeX24) {
      final msgBody = B3MessageBody24(body);
      setBody(msgBody);
      _assignAttrs24(msgBody);
    }
  }

  int? topCompartmentStatus;
  int? topCompartmentMode;
  int? topCompartmentTemperature;
  int? topCompartmentRemaining;
  int? bottomCompartmentStatus;
  int? bottomCompartmentMode;
  int? bottomCompartmentTemperature;
  int? bottomCompartmentRemaining;
  int? middleCompartmentStatus;
  int? middleCompartmentMode;
  int? middleCompartmentTemperature;
  int? middleCompartmentRemaining;
  bool? lock;
  bool? bottomCompartmentDoor;
  bool? topCompartmentDoor;
  bool? middleCompartmentDoor;
  bool? bottomCompartmentPreheating;
  bool? topCompartmentPreheating;
  bool? middleCompartmentPreheating;
  bool? bottomCompartmentCooling;
  bool? topCompartmentCooling;
  bool? middleCompartmentCooling;

  void _assignAttrs31(B3MessageBody31 b) {
    topCompartmentStatus = b.topCompartmentStatus;
    topCompartmentMode = b.topCompartmentMode;
    topCompartmentTemperature = b.topCompartmentTemperature;
    topCompartmentRemaining = b.topCompartmentRemaining;
    bottomCompartmentStatus = b.bottomCompartmentStatus;
    bottomCompartmentMode = b.bottomCompartmentMode;
    bottomCompartmentTemperature = b.bottomCompartmentTemperature;
    bottomCompartmentRemaining = b.bottomCompartmentRemaining;
    middleCompartmentStatus = b.middleCompartmentStatus;
    middleCompartmentMode = b.middleCompartmentMode;
    middleCompartmentTemperature = b.middleCompartmentTemperature;
    middleCompartmentRemaining = b.middleCompartmentRemaining;
    lock = b.lock;
    bottomCompartmentDoor = b.bottomCompartmentDoor;
    topCompartmentDoor = b.topCompartmentDoor;
    middleCompartmentDoor = b.middleCompartmentDoor;
    bottomCompartmentPreheating = b.bottomCompartmentPreheating;
    topCompartmentPreheating = b.topCompartmentPreheating;
    middleCompartmentPreheating = b.middleCompartmentPreheating;
    bottomCompartmentCooling = b.bottomCompartmentCooling;
    topCompartmentCooling = b.topCompartmentCooling;
    middleCompartmentCooling = b.middleCompartmentCooling;
  }

  void _assignAttrs00(B3MessageBody00 b) {
    topCompartmentStatus = b.topCompartmentStatus;
    topCompartmentMode = b.topCompartmentMode;
    topCompartmentTemperature = b.topCompartmentTemperature;
    topCompartmentRemaining = b.topCompartmentRemaining;
    bottomCompartmentStatus = b.bottomCompartmentStatus;
    bottomCompartmentMode = b.bottomCompartmentMode;
    bottomCompartmentTemperature = b.bottomCompartmentTemperature;
    bottomCompartmentRemaining = b.bottomCompartmentRemaining;
    middleCompartmentStatus = b.middleCompartmentStatus;
    middleCompartmentMode = b.middleCompartmentMode;
    middleCompartmentTemperature = b.middleCompartmentTemperature;
    middleCompartmentRemaining = b.middleCompartmentRemaining;
    lock = b.lock;
    bottomCompartmentDoor = b.bottomCompartmentDoor;
    topCompartmentDoor = b.topCompartmentDoor;
    middleCompartmentDoor = b.middleCompartmentDoor;
    bottomCompartmentPreheating = b.bottomCompartmentPreheating;
    topCompartmentPreheating = b.topCompartmentPreheating;
    middleCompartmentPreheating = b.middleCompartmentPreheating;
    bottomCompartmentCooling = b.bottomCompartmentCooling;
    topCompartmentCooling = b.topCompartmentCooling;
    middleCompartmentCooling = b.middleCompartmentCooling;
  }

  void _assignAttrs21(B3MessageBody21 b) {
    topCompartmentStatus = b.topCompartmentStatus;
    topCompartmentMode = b.topCompartmentMode;
    topCompartmentTemperature = b.topCompartmentTemperature;
    topCompartmentRemaining = b.topCompartmentRemaining;
    bottomCompartmentStatus = b.bottomCompartmentStatus;
    bottomCompartmentMode = b.bottomCompartmentMode;
    bottomCompartmentTemperature = b.bottomCompartmentTemperature;
    bottomCompartmentRemaining = b.bottomCompartmentRemaining;
    middleCompartmentStatus = b.middleCompartmentStatus;
    middleCompartmentMode = b.middleCompartmentMode;
    middleCompartmentTemperature = b.middleCompartmentTemperature;
    middleCompartmentRemaining = b.middleCompartmentRemaining;
    lock = b.lock;
  }

  void _assignAttrs24(B3MessageBody24 b) {
    topCompartmentStatus = b.topCompartmentStatus;
    topCompartmentMode = b.topCompartmentMode;
    topCompartmentTemperature = b.topCompartmentTemperature;
    topCompartmentRemaining = b.topCompartmentRemaining;
    bottomCompartmentStatus = b.bottomCompartmentStatus;
    bottomCompartmentMode = b.bottomCompartmentMode;
    bottomCompartmentTemperature = b.bottomCompartmentTemperature;
    bottomCompartmentRemaining = b.bottomCompartmentRemaining;
    middleCompartmentStatus = b.middleCompartmentStatus;
    middleCompartmentMode = b.middleCompartmentMode;
    middleCompartmentTemperature = b.middleCompartmentTemperature;
    middleCompartmentRemaining = b.middleCompartmentRemaining;
  }
}
