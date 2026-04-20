/// Midea local B6 device message. Mirrors midealocal/devices/b6/message.dart.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int fanLevelRange1 = 130;
const int fanLevelRange2 = 140;
const int fanLevelRange3 = 170;
const int minFanLevelRange = 100;

const int messageProtocolVersion = 2;

class B6ListTypes {
  static const int x01 = 0x01;
  static const int x02 = 0x02;
  static const int x0A = 0x0A;
  static const int x11 = 0x11;
  static const int x22 = 0x22;
  static const int x31 = 0x31;
  static const int x32 = 0x32;
  static const int x41 = 0x41;
  static const int a1 = 0xA1;
  static const int a2 = 0xA2;
}

abstract class MessageB6Base extends MessageRequest {
  MessageB6Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b6,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageB6Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: protocolVersion == messageProtocolVersion
            ? B6ListTypes.x11
            : B6ListTypes.x31,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQueryTips extends MessageB6Base {
  MessageQueryTips(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: B6ListTypes.x02,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

class MessageSet extends MessageB6Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: (protocolVersion == 0x00 || protocolVersion == 0x01)
            ? B6ListTypes.x22
            : B6ListTypes.x11,
      );

  bool? light;
  bool? power;
  int? fanLevel;

  @override
  Uint8List buildBody() {
    if (protocolVersion == 0x00 || protocolVersion == 0x01) {
      int lightVal = maxByteValue;
      int value2 = maxByteValue;
      int value3 = maxByteValue;
      if (light != null) {
        lightVal = light! ? 0x1A : 0x00;
      } else if (power != null) {
        if (power!) {
          value2 = 0x02;
          value3 = fanLevel ?? 0x01;
        } else {
          value2 = 0x03;
        }
      } else if (fanLevel != null) {
        if (fanLevel == 0) {
          value2 = 0x03;
        } else {
          value2 = 0x02;
          value3 = fanLevel!;
        }
      }
      return Uint8List.fromList([
        0x01,
        lightVal,
        value2,
        value3,
        maxByteValue,
        maxByteValue,
        maxByteValue,
        maxByteValue,
        maxByteValue,
      ]);
    }
    int value13 = maxByteValue;
    int value14 = maxByteValue;
    int value15 = maxByteValue;
    int value16 = maxByteValue;
    if (power != null) {
      value13 = 0x01;
      if (power!) {
        value15 = 0x02;
        value16 = fanLevel ?? 0x01;
      } else {
        value15 = 0x01;
      }
    } else if (fanLevel != null) {
      value13 = 0x01;
      if (fanLevel == 0) {
        value15 = 0x01;
      } else {
        value15 = 0x02;
        value16 = fanLevel!;
      }
    } else if (light != null) {
      value13 = 0x02;
      value14 = 0x02;
      value15 = light! ? 0x01 : 0x00;
    }
    return Uint8List.fromList([
      0x01,
      value13,
      value14,
      value15,
      value16,
      maxByteValue,
      maxByteValue,
    ]);
  }
}

class B6FeedbackBody extends MessageBody {
  B6FeedbackBody(Uint8List body) : super(body);
}

class B6GeneralBody extends MessageBody {
  B6GeneralBody(Uint8List body) : super(body) {
    if (body[1] != maxByteValue) {
      light = body[1] > 0x00;
    }
    power = false;
    int fan_level = 0;
    if (body[2] != maxByteValue) {
      power =
          body[2] == 0x02 ||
          body[2] == 0x06 ||
          body[2] == 0x07 ||
          body[2] == 0x14 ||
          body[2] == 0x15 ||
          body[2] == 0x16;
      if (body[2] == 0x14 || body[2] == 0x16) {
        fan_level = 0x16;
      }
    }
    if (fan_level == 0 && body[3] != maxByteValue) {
      fan_level = body[3];
    }
    if (fan_level > minFanLevelRange) {
      if (fan_level < fanLevelRange1) {
        fan_level = 1;
      } else if (fan_level < fanLevelRange2) {
        fan_level = 2;
      } else if (fan_level < fanLevelRange3) {
        fan_level = 3;
      } else {
        fan_level = 4;
      }
    }
    this.fanLevel = fan_level;
    oilCupFull = (body[5] & 0x01) > 0;
    cleaningReminder = (body[5] & 0x02) > 0;
  }

  late bool? light;
  late bool power;
  late int fanLevel;
  late bool oilCupFull;
  late bool cleaningReminder;
}

class B6NewProtocolBody extends MessageBody {
  B6NewProtocolBody(Uint8List body) : super(body) {
    if (body[1] == 0x01) {
      final packBytes = body.sublist(3, 3 + body[2]);
      if (packBytes[1] != maxByteValue) {
        power = true;
        power =
            packBytes[1] != 0x00 &&
            packBytes[1] != 0x01 &&
            packBytes[1] != 0x05 &&
            packBytes[1] != 0x07;
      }
      if (packBytes[2] != maxByteValue) {
        fanLevel = packBytes[2];
      }
      if (packBytes[6] != maxByteValue) {
        light = packBytes[6] > 0;
      }
      oilCupFull = (packBytes[18] & 0x02) > 0;
      cleaningReminder = (packBytes[18] & 0x04) > 0;
    }
  }

  late bool? light;
  late bool power = false;
  late int? fanLevel;
  late bool oilCupFull = false;
  late bool cleaningReminder = false;
}

class B6SpecialBody extends MessageBody {
  B6SpecialBody(Uint8List body) : super(body) {
    if (body[2] != maxByteValue) {
      light = body[2] > 0x00;
    }
    power = false;
    if (body[3] != maxByteValue) {
      power = body[3] == 0x00 || body[3] == 0x02 || body[3] == 0x04;
    }
    if (body[4] != maxByteValue) {
      fanLevel = body[4];
    }
  }

  late bool? light;
  late bool power;
  late int? fanLevel;
}

class B6ExceptionBody extends MessageBody {
  B6ExceptionBody(Uint8List body) : super(body);
}

class MessageB6Response extends MessageResponse {
  MessageB6Response(Uint8List message) : super(message) {
    if (messageType == MessageType.set &&
        bodyType == B6ListTypes.x22 &&
        super.body[1] == B6ListTypes.x01) {
      setBody(B6SpecialBody(super.body));
      _assignAttrs(B6SpecialBody(super.body));
    } else if (messageType == MessageType.set &&
        bodyType == B6ListTypes.x11 &&
        super.body[1] == B6ListTypes.x01) {
      // do nothing
    } else if (messageType == MessageType.query) {
      if (bodyType == B6ListTypes.x11 || bodyType == B6ListTypes.x31) {
        if (protocolVersion == 0 || protocolVersion == 1) {
          setBody(B6GeneralBody(super.body));
          _assignAttrs(B6GeneralBody(super.body));
        } else {
          setBody(B6NewProtocolBody(super.body));
          _assignAttrs(B6NewProtocolBody(super.body));
        }
      } else if (bodyType == B6ListTypes.x32 && super.body[1] == 0x01) {
        setBody(B6ExceptionBody(super.body));
      }
    } else if (messageType == MessageType.notify1) {
      if (bodyType == B6ListTypes.x11 || bodyType == B6ListTypes.x41) {
        if (protocolVersion == 0 || protocolVersion == 1) {
          setBody(B6GeneralBody(super.body));
          _assignAttrs(B6GeneralBody(super.body));
        } else {
          setBody(B6NewProtocolBody(super.body));
          _assignAttrs(B6NewProtocolBody(super.body));
        }
      } else if (bodyType == B6ListTypes.x0A) {
        if (super.body[1] == B6ListTypes.a1) {
          setBody(B6ExceptionBody(super.body));
        } else if (super.body[1] == B6ListTypes.a2) {
          oilCupFull = (super.body[2] & 0x01) > 0;
          cleaningReminder = (super.body[2] & 0x02) > 0;
        }
      }
    } else if (messageType == MessageType.exception2 &&
        bodyType == B6ListTypes.a1) {
      // do nothing
    }
    setAttr();
  }

  bool? light;
  bool? power;
  int? fanLevel;
  bool? oilCupFull;
  bool? cleaningReminder;

  void _assignAttrs(MessageBody b) {
    if (b is B6GeneralBody) {
      light = b.light;
      power = b.power;
      fanLevel = b.fanLevel;
      oilCupFull = b.oilCupFull;
      cleaningReminder = b.cleaningReminder;
    } else if (b is B6NewProtocolBody) {
      light = b.light;
      power = b.power;
      fanLevel = b.fanLevel;
      oilCupFull = b.oilCupFull;
      cleaningReminder = b.cleaningReminder;
    } else if (b is B6SpecialBody) {
      light = b.light;
      power = b.power;
      fanLevel = b.fanLevel;
    }
  }
}
