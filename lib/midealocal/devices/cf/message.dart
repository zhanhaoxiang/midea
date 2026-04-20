/// Midea local CF device message. Mirrors midealocal/devices/cf/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// CFMode
// ---------------------------------------------------------------------------

class CFMode {
  static const int off = 0;
  static const int auto = 1;
  static const int cool = 2;
  static const int heat = 3;
}

// ---------------------------------------------------------------------------
// MessageCFBase
// ---------------------------------------------------------------------------

abstract class MessageCFBase extends MessageRequest {
  MessageCFBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.cf,
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

class MessageQuery extends MessageCFBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageCFBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x01,
      );

  bool power = false;
  int mode = 0;
  double? targetTemperature;
  bool? auxHeating;

  @override
  Uint8List buildBody() {
    final p = power ? 0x01 : 0x00;
    final m = mode;
    final tt = targetTemperature == null
        ? 0xFF
        : (targetTemperature!.toInt() & 0xFF);
    final ah = auxHeating == null ? 0xFF : (auxHeating! ? 0x01 : 0x00);
    return Uint8List.fromList([p, m, tt, ah]);
  }
}

// ---------------------------------------------------------------------------
// CFMessageBody
// ---------------------------------------------------------------------------

class CFMessageBody extends MessageBody {
  CFMessageBody(Uint8List body, {this.dataOffset = 0}) : super(body) {
    power = (body[dataOffset + 0] & 0x01) > 0;
    auxHeating = (body[dataOffset + 0] & 0x02) > 0;
    silent = (body[dataOffset + 0] & 0x04) > 0;
    heat = (body[dataOffset + 1] & 0x01) > 0;
    cool = (body[dataOffset + 1] & 0x02) > 0;
    tempType = (body[dataOffset + 1] & 0x04) > 0;
    roomTempCtrl = (body[dataOffset + 1] & 0x08) > 0;
    roomTempSet = (body[dataOffset + 1] & 0x10) > 0;
    comp = (body[dataOffset + 2] & 0x01) > 0;
    warn = (body[dataOffset + 2] & 0x10) > 0;
    defrost = (body[dataOffset + 2] & 0x20) > 0;
    freeze = (body[dataOffset + 2] & 0x40) > 0;
    holiday = (body[dataOffset + 2] & 0x80) > 0;
    mode = body[dataOffset + 3];
    targetTemperature = body[dataOffset + 4];
    currentTemperature = body[dataOffset + 5];
    if (mode == CFMode.cool) {
      maxTemperature = body[dataOffset + 8];
      minTemperature = body[dataOffset + 9];
    } else if (mode == CFMode.heat) {
      maxTemperature = body[dataOffset + 6];
      minTemperature = body[dataOffset + 7];
    } else {
      maxTemperature = body[dataOffset + 6];
      minTemperature = body[dataOffset + 9];
    }
  }

  final int dataOffset;

  late bool power;
  late bool auxHeating;
  late bool silent;
  late bool heat;
  late bool cool;
  late bool tempType;
  late bool roomTempCtrl;
  late bool roomTempSet;
  late bool comp;
  late bool warn;
  late bool defrost;
  late bool freeze;
  late bool holiday;
  late int mode;
  late int targetTemperature;
  late int currentTemperature;
  late int maxTemperature;
  late int minTemperature;
}

// ---------------------------------------------------------------------------
// MessageCFResponse
// ---------------------------------------------------------------------------

class MessageCFResponse extends MessageResponse {
  MessageCFResponse(Uint8List message) : super(message) {
    if ((messageType == MessageType.query || messageType == MessageType.set) &&
        bodyType == ListTypes.x01) {
      final msgBody = CFMessageBody(body, dataOffset: 1);
      setBody(msgBody);
      _assignAttrs(msgBody);
    } else if (messageType == MessageType.notify1 ||
        messageType == MessageType.notify2) {
      final msgBody = CFMessageBody(body, dataOffset: 0);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  bool? auxHeating;
  bool? silent;
  bool? heat;
  bool? cool;
  bool? tempType;
  bool? roomTempCtrl;
  bool? roomTempSet;
  bool? comp;
  bool? warn;
  bool? defrost;
  bool? freeze;
  bool? holiday;
  int? mode;
  int? targetTemperature;
  int? currentTemperature;
  int? maxTemperature;
  int? minTemperature;

  void _assignAttrs(CFMessageBody b) {
    power = b.power;
    auxHeating = b.auxHeating;
    silent = b.silent;
    heat = b.heat;
    cool = b.cool;
    tempType = b.tempType;
    roomTempCtrl = b.roomTempCtrl;
    roomTempSet = b.roomTempSet;
    comp = b.comp;
    warn = b.warn;
    defrost = b.defrost;
    freeze = b.freeze;
    holiday = b.holiday;
    mode = b.mode;
    targetTemperature = b.targetTemperature;
    currentTemperature = b.currentTemperature;
    maxTemperature = b.maxTemperature;
    minTemperature = b.minTemperature;
  }
}
