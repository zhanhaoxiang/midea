/// Midea local FC device message. Mirrors midealocal/devices/fc/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxMsgSerialNum = 254;

class DeviceAttributesMessage {
  static const String power = 'power';
  static const String mode = 'mode';
  static const String fanSpeed = 'fan_speed';
  static const String screenDisplay = 'screen_display';
  static const String pm25 = 'pm25';
  static const String tvoc = 'tvoc';
  static const String hcho = 'hcho';
  static const String anion = 'anion';
  static const String standby = 'standby';
  static const String childLock = 'child_lock';
  static const String filter1Life = 'filter1_life';
  static const String filter2Life = 'filter2_life';
  static const String detectMode = 'detect_mode';
}

const int anionGetByte = 19;
const int anionNotifyByte = 10;
const int childLockGetByte = 8;
const int childLockNotifyByte = 10;
const int detectModeGetByte = 29;
const int detectModeNotifyByte = 22;
const int filter1LifeByte = 23;
const int filter2LifeByte = 24;
const int hchoGetByte = 38;
const int hchoNotifyByte = 31;
const int pm25Byte = 14;
const int standbyGetByte = 34;
const int standbyNotifyByte = 27;
const int standbyValue = 0x14;
const int tvocByte = 15;

abstract class MessageFCBase extends MessageRequest {
  MessageFCBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.fc,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       ) {
    _messageSerial = (_messageSerial + 1) % maxMsgSerialNum;
    if (_messageSerial == 0) _messageSerial = 1;
    _messageId = _messageSerial;
  }

  static int _messageSerial = 0;
  late int _messageId;

  @override
  Uint8List buildBody();

  @override
  Uint8List get body {
    final result = <int>[];
    result.add(bodyType);
    result.addAll(buildBody());
    result.add(_messageId);
    result.add(_crc8(result));
    return Uint8List.fromList(result);
  }

  static int _crc8(List<int> data) {
    var crc = 0;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        if (crc & 0x80 != 0) {
          crc = (crc << 1) ^ 0x31;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFF;
  }
}

class MessageQuery extends MessageFCBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      0x00,
      0x00,
      0xFF,
      0x03,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
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

class MessageSet extends MessageFCBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0x48,
      );

  bool power = false;
  int mode = 0;
  int fanSpeed = 0;
  bool childLock = false;
  bool promptTone = false;
  bool anion = false;
  bool standby = false;
  int screenDisplay = 0;
  int detectMode = 0;
  List<int> standbyDetect = [40, 20];

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x01 : 0x00;
    final detect = detectMode > 0 ? 0x08 : 0x00;
    final detectModeVal = detectMode > 0 ? detectMode - 1 : 0;
    final childLockB = childLock ? 0x80 : 0x00;
    final anionB = anion ? 0x20 : 0x00;
    final promptToneB = promptTone ? 0x40 : 0x00;

    final standbyB = standby ? 0x04 : 0x08;
    final standbyDetectHigh = standby ? standbyDetect[0] : 0;
    final standbyDetectLow = standby ? standbyDetect[1] : 0;

    return Uint8List.fromList([
      powerB | promptToneB | detect | 0x02,
      mode,
      fanSpeed,
      0x00,
      0x00,
      0x00,
      0x00,
      childLockB,
      screenDisplay,
      anionB,
      0x00,
      0x00,
      0x00,
      detectModeVal,
      standbyB,
      standbyDetectHigh,
      standbyDetectLow,
      0x00,
      0x00,
      0x00,
    ]);
  }
}

class FCGeneralMessageBody extends MessageBody {
  FCGeneralMessageBody(Uint8List body) : super(body) {
    power = (body[1] & 0x01) > 0;
    mode = body[2] & 0xF0;
    fanSpeed = body[3] & 0x7F;
    screenDisplay = body[9] & 0x07;

    if (body.length > pm25Byte && body[14] != maxByteValue) {
      pm25 = body[13] + (body[14] << 8);
    }
    if (body.length > tvocByte && body[15] != maxByteValue) {
      tvoc = body[15];
    }
    if (body.length > anionGetByte) {
      anion = (body[anionGetByte] & 0x40) > 0;
    } else {
      anion = false;
    }
    if (body.length > standbyGetByte) {
      standby = (body[standbyGetByte] & 0xFF) == standbyValue;
    } else {
      standby = false;
    }
    if (body.length > childLockGetByte) {
      childLock = (body[childLockGetByte] & 0x80) > 0;
    } else {
      childLock = false;
    }
    if (body.length > filter1LifeByte) {
      filter1Life = body[filter1LifeByte];
    }
    if (body.length > filter2LifeByte) {
      filter2Life = body[filter2LifeByte];
    }
    if (body.length > detectModeGetByte) {
      if ((body[1] & 0x08) > 0) {
        detectMode = body[detectModeGetByte] + 1;
      } else {
        detectMode = 0;
      }
    }
    if (body.length > hchoGetByte && body[hchoGetByte] != maxByteValue) {
      hcho = body[hchoGetByte - 1] + (body[hchoGetByte] << 8);
    }
  }

  late bool power;
  late int mode;
  late int fanSpeed;
  late int screenDisplay;
  int? pm25;
  int? tvoc;
  int? hcho;
  late bool anion;
  late bool standby;
  late bool childLock;
  int? filter1Life;
  int? filter2Life;
  late int detectMode;
}

class FCNotifyMessageBody extends MessageBody {
  FCNotifyMessageBody(Uint8List body) : super(body) {
    power = (body[1] & 0x01) > 0;
    mode = body[2] & 0xF0;
    fanSpeed = body[3] & 0x7F;
    screenDisplay = body[9] & 0x07;

    if (body.length > pm25Byte && body[14] != maxByteValue) {
      pm25 = body[13] + (body[14] << 8);
    }
    if (body.length > tvocByte && body[15] != maxByteValue) {
      tvoc = body[15];
    }
    if (body.length > anionNotifyByte) {
      anion = (body[anionNotifyByte - 1] & 0x20) > 0;
    } else {
      anion = false;
    }
    if (body.length > standbyNotifyByte) {
      standby = (body[standbyNotifyByte] == maxByteValue);
    } else {
      standby = false;
    }
    if (body.length > childLockNotifyByte) {
      childLock = (body[childLockNotifyByte - 1] & 0x10) > 0;
    } else {
      childLock = false;
    }
    if (body.length > detectModeNotifyByte) {
      if ((body[1] & 0x08) > 0) {
        detectMode = body[detectModeNotifyByte] + 1;
      } else {
        detectMode = 0;
      }
    }
    if (body.length > hchoNotifyByte && body[hchoNotifyByte] != maxByteValue) {
      hcho = body[hchoNotifyByte - 1] + (body[hchoNotifyByte] << 8);
    }
  }

  late bool power;
  late int mode;
  late int fanSpeed;
  late int screenDisplay;
  int? pm25;
  int? tvoc;
  int? hcho;
  late bool anion;
  late bool standby;
  late bool childLock;
  late int detectMode;
}

class MessageFCResponse extends MessageResponse {
  MessageFCResponse(Uint8List message) : super(message) {
    if (bodyType == 0xB0 || bodyType == 0xB1) {
    } else if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        (messageType == MessageType.notify1 && bodyType == 0xC8)) {
      final msgBody = FCGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    } else if (messageType == MessageType.notify1 && bodyType == 0xA0) {
      final msgBody = FCNotifyMessageBody(body);
      setBody(msgBody);
      _assignAttrsNotify(msgBody);
    }
  }

  bool? power;
  int? mode;
  int? fanSpeed;
  int? screenDisplay;
  int? pm25;
  int? tvoc;
  int? hcho;
  bool? anion;
  bool? standby;
  bool? childLock;
  int? filter1Life;
  int? filter2Life;
  int? detectMode;

  bool hasAttribute(String attr) => _attributes.containsKey(attr);

  dynamic getAttribute(String attr) => _attributes[attr];

  void _assignAttrs(FCGeneralMessageBody b) {
    power = b.power;
    mode = b.mode;
    fanSpeed = b.fanSpeed;
    screenDisplay = b.screenDisplay;
    pm25 = b.pm25;
    tvoc = b.tvoc;
    hcho = b.hcho;
    anion = b.anion;
    standby = b.standby;
    childLock = b.childLock;
    filter1Life = b.filter1Life;
    filter2Life = b.filter2Life;
    detectMode = b.detectMode;
    _updateAttributes(b);
  }

  void _assignAttrsNotify(FCNotifyMessageBody b) {
    power = b.power;
    mode = b.mode;
    fanSpeed = b.fanSpeed;
    screenDisplay = b.screenDisplay;
    pm25 = b.pm25;
    tvoc = b.tvoc;
    hcho = b.hcho;
    anion = b.anion;
    standby = b.standby;
    childLock = b.childLock;
    detectMode = b.detectMode;
    _updateAttributes(b);
  }

  void _updateAttributes(dynamic b) {
    _attributes[DeviceAttributesMessage.power] = power;
    _attributes[DeviceAttributesMessage.mode] = mode;
    _attributes[DeviceAttributesMessage.fanSpeed] = fanSpeed;
    _attributes[DeviceAttributesMessage.screenDisplay] = screenDisplay;
    _attributes[DeviceAttributesMessage.pm25] = pm25;
    _attributes[DeviceAttributesMessage.tvoc] = tvoc;
    _attributes[DeviceAttributesMessage.hcho] = hcho;
    _attributes[DeviceAttributesMessage.anion] = anion;
    _attributes[DeviceAttributesMessage.standby] = standby;
    _attributes[DeviceAttributesMessage.childLock] = childLock;
    _attributes[DeviceAttributesMessage.filter1Life] = filter1Life;
    _attributes[DeviceAttributesMessage.filter2Life] = filter2Life;
    _attributes[DeviceAttributesMessage.detectMode] = detectMode;
  }

  final Map<String, dynamic> _attributes = {};
}
