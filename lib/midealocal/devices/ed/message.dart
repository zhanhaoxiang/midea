/// Midea local ED device message. Mirrors midealocal/devices/ed/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// EDListTypes
// ---------------------------------------------------------------------------

class EDListTypes {
  static const int x00 = 0x00;
  static const int x01 = 0x01;
  static const int x03 = 0x03;
  static const int x04 = 0x04;
  static const int x05 = 0x05;
  static const int x06 = 0x06;
  static const int x07 = 0x07;
  static const int x15 = 0x15;
  static const int ff = 0xFF;
}

// ---------------------------------------------------------------------------
// Attributes
// ---------------------------------------------------------------------------

class Attributes {
  static const int childLock = 0x000;
  static const int life = 0x10;
  static const int tds = 0x013;
  static const int waterConsumption = 0x011;
}

// ---------------------------------------------------------------------------
// NewSetTags
// ---------------------------------------------------------------------------

class NewSetTags {
  static const int power = 0x0100;
  static const int lock = 0x0201;
}

// ---------------------------------------------------------------------------
// EDNewSetParamPack
// ---------------------------------------------------------------------------

class EDNewSetParamPack {
  static Uint8List pack(int param, int value, [int addition = 0]) {
    return Uint8List.fromList([
      param & 0xFF,
      param >> 8,
      value,
      addition & 0xFF,
      addition >> 8,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageEDBase
// ---------------------------------------------------------------------------

abstract class MessageEDBase extends MessageRequest {
  MessageEDBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ed,
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

class MessageQuery extends MessageEDBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery01
// ---------------------------------------------------------------------------

class MessageQuery01 extends MessageEDBase {
  MessageQuery01(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery03
// ---------------------------------------------------------------------------

class MessageQuery03 extends MessageEDBase {
  MessageQuery03(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x03,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery04
// ---------------------------------------------------------------------------

class MessageQuery04 extends MessageEDBase {
  MessageQuery04(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x04,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery05
// ---------------------------------------------------------------------------

class MessageQuery05 extends MessageEDBase {
  MessageQuery05(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x05,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery06
// ---------------------------------------------------------------------------

class MessageQuery06 extends MessageEDBase {
  MessageQuery06(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x06,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQuery07
// ---------------------------------------------------------------------------

class MessageQuery07 extends MessageEDBase {
  MessageQuery07(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.x07,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageQueryFF
// ---------------------------------------------------------------------------

class MessageQueryFF extends MessageEDBase {
  MessageQueryFF(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: EDListTypes.ff,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

// ---------------------------------------------------------------------------
// MessageNewSet
// ---------------------------------------------------------------------------

class MessageNewSet extends MessageEDBase {
  MessageNewSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: EDListTypes.x15,
      );

  bool? power;
  bool? lock;

  @override
  Uint8List buildBody() {
    var packCount = 0;
    final payload = Uint8List.fromList([0x01, 0x00]);
    if (power != null) {
      packCount++;
      payload.addAll(
        EDNewSetParamPack.pack(NewSetTags.power, power! ? 0x01 : 0x00),
      );
    }
    if (lock != null) {
      packCount++;
      payload.addAll(
        EDNewSetParamPack.pack(NewSetTags.lock, lock! ? 0x01 : 0x00),
      );
    }
    payload[1] = packCount;
    return payload;
  }
}

// ---------------------------------------------------------------------------
// MessageOldSet
// ---------------------------------------------------------------------------

class MessageOldSet extends MessageEDBase {
  MessageOldSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: EDListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// EDMessageBody01
// ---------------------------------------------------------------------------

class EDMessageBody01 extends MessageBody {
  EDMessageBody01(Uint8List body) : super(body) {
    power = (body[2] & 0x01) > 0;
    waterConsumption = body[7] + (body[8] << 8);
    inTds = body[36] + (body[37] << 8);
    outTds = body[38] + (body[39] << 8);
    childLock = body[15] > 0;
    filter1 = ((body[25] + (body[26] << 8)) / 24).round();
    filter2 = ((body[27] + (body[28] << 8)) / 24).round();
    filter3 = ((body[29] + (body[30] << 8)) / 24).round();
    life1 = body[16];
    life2 = body[17];
    life3 = body[18];
  }

  late bool power;
  late int waterConsumption;
  late int inTds;
  late int outTds;
  late bool childLock;
  late int filter1;
  late int filter2;
  late int filter3;
  late int life1;
  late int life2;
  late int life3;
}

// ---------------------------------------------------------------------------
// EDMessageBody03
// ---------------------------------------------------------------------------

class EDMessageBody03 extends MessageBody {
  EDMessageBody03(Uint8List body) : super(body) {
    power = (body[51] & 0x01) > 0;
    childLock = (body[51] & 0x08) > 0;
    waterConsumption = body[20] + (body[21] << 8);
    life1 = body[22];
    life2 = body[23];
    life3 = body[24];
    inTds = body[27] + (body[28] << 8);
    outTds = body[29] + (body[30] << 8);
  }

  late bool power;
  late bool childLock;
  late int waterConsumption;
  late int life1;
  late int life2;
  late int life3;
  late int inTds;
  late int outTds;
}

// ---------------------------------------------------------------------------
// EDMessageBody05
// ---------------------------------------------------------------------------

class EDMessageBody05 extends MessageBody {
  EDMessageBody05(Uint8List body) : super(body) {
    power = (body[51] & 0x01) > 0;
    childLock = (body[51] & 0x08) > 0;
    waterConsumption = body[20] + (body[21] << 8);
  }

  late bool power;
  late bool childLock;
  late int waterConsumption;
}

// ---------------------------------------------------------------------------
// EDMessageBody06
// ---------------------------------------------------------------------------

class EDMessageBody06 extends MessageBody {
  EDMessageBody06(Uint8List body) : super(body) {
    power = (body[51] & 0x01) > 0;
    childLock = (body[51] & 0x08) > 0;
    waterConsumption = body[25] + (body[26] << 8);
  }

  late bool power;
  late bool childLock;
  late int waterConsumption;
}

// ---------------------------------------------------------------------------
// EDMessageBody07
// ---------------------------------------------------------------------------

class EDMessageBody07 extends MessageBody {
  EDMessageBody07(Uint8List body) : super(body) {
    waterConsumption = (body[21] << 8) + body[20];
    power = (body[51] & 0x01) > 0;
    childLock = (body[51] & 0x08) > 0;
  }

  late int waterConsumption;
  late bool power;
  late bool childLock;
}

// ---------------------------------------------------------------------------
// EDMessageBodyFF
// ---------------------------------------------------------------------------

class EDMessageBodyFF extends MessageBody {
  EDMessageBodyFF(Uint8List body) : super(body) {
    var dataOffset = 2;
    while (true) {
      final length = (body[dataOffset + 2] >> 4) + 2;
      final attr = ((body[dataOffset + 2] % 16) << 8) + body[dataOffset + 1];
      if (attr == Attributes.childLock) {
        childLock = (body[dataOffset + 5] & 0x01) > 0;
        power = (body[dataOffset + 6] & 0x01) > 0;
      } else if (attr == Attributes.waterConsumption) {
        waterConsumption =
            (body[dataOffset + 3] +
                (body[dataOffset + 4] << 8) +
                (body[dataOffset + 5] << 16) +
                (body[dataOffset + 6] << 24)) /
            1000;
      } else if (attr == Attributes.tds) {
        inTds = body[dataOffset + 3] + (body[dataOffset + 4] << 8);
        outTds = body[dataOffset + 5] + (body[dataOffset + 6] << 8);
      } else if (attr == Attributes.life) {
        life1 = body[dataOffset + 3];
        life2 = body[dataOffset + 4];
        life3 = body[dataOffset + 5];
      }
      if (dataOffset + length + 6 > body.length) {
        break;
      }
      dataOffset += length;
    }
  }

  bool? childLock;
  bool? power;
  double? waterConsumption;
  int? inTds;
  int? outTds;
  int? life1;
  int? life2;
  int? life3;
}

// ---------------------------------------------------------------------------
// MessageEDResponse
// ---------------------------------------------------------------------------

class MessageEDResponse extends MessageResponse {
  MessageEDResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.set ||
        messageType == MessageType.query ||
        (messageType == MessageType.notify1)) {
      deviceClass = bodyType;
      if (bodyType == EDListTypes.x00 ||
          bodyType == EDListTypes.x15 ||
          bodyType == EDListTypes.ff) {
        final msgBody = EDMessageBodyFF(body);
        setBody(msgBody);
        _assignAttrsFF(msgBody);
      } else if (bodyType == EDListTypes.x01) {
        final msgBody = EDMessageBody01(body);
        setBody(msgBody);
        _assignAttrs01(msgBody);
      } else if (bodyType == EDListTypes.x03 || bodyType == EDListTypes.x04) {
        final msgBody = EDMessageBody03(body);
        setBody(msgBody);
        _assignAttrs03(msgBody);
      } else if (bodyType == EDListTypes.x05) {
        final msgBody = EDMessageBody05(body);
        setBody(msgBody);
        _assignAttrs05(msgBody);
      } else if (bodyType == EDListTypes.x06) {
        final msgBody = EDMessageBody06(body);
        setBody(msgBody);
        _assignAttrs06(msgBody);
      } else if (bodyType == EDListTypes.x07) {
        final msgBody = EDMessageBody07(body);
        setBody(msgBody);
        _assignAttrs07(msgBody);
      }
    }
  }

  int? deviceClass;

  bool? power;
  bool? childLock;
  int? waterConsumption;
  int? inTds;
  int? outTds;
  int? filter1;
  int? filter2;
  int? filter3;
  int? life1;
  int? life2;
  int? life3;

  void _assignAttrsFF(EDMessageBodyFF b) {
    power = b.power;
    childLock = b.childLock;
    waterConsumption = b.waterConsumption?.toInt();
    inTds = b.inTds;
    outTds = b.outTds;
    life1 = b.life1;
    life2 = b.life2;
    life3 = b.life3;
  }

  void _assignAttrs01(EDMessageBody01 b) {
    power = b.power;
    waterConsumption = b.waterConsumption;
    inTds = b.inTds;
    outTds = b.outTds;
    childLock = b.childLock;
    filter1 = b.filter1;
    filter2 = b.filter2;
    filter3 = b.filter3;
    life1 = b.life1;
    life2 = b.life2;
    life3 = b.life3;
  }

  void _assignAttrs03(EDMessageBody03 b) {
    power = b.power;
    childLock = b.childLock;
    waterConsumption = b.waterConsumption;
    life1 = b.life1;
    life2 = b.life2;
    life3 = b.life3;
    inTds = b.inTds;
    outTds = b.outTds;
  }

  void _assignAttrs05(EDMessageBody05 b) {
    power = b.power;
    childLock = b.childLock;
    waterConsumption = b.waterConsumption;
  }

  void _assignAttrs06(EDMessageBody06 b) {
    power = b.power;
    childLock = b.childLock;
    waterConsumption = b.waterConsumption;
  }

  void _assignAttrs07(EDMessageBody07 b) {
    waterConsumption = b.waterConsumption;
    power = b.power;
    childLock = b.childLock;
  }
}
