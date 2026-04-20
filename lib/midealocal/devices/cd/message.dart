/// Midea local CD device message. Mirrors midealocal/devices/cd/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int oldBodyLength = 29;
const int newBodyLength = 35;

// ---------------------------------------------------------------------------
// MessageCDBase
// ---------------------------------------------------------------------------

abstract class MessageCDBase extends MessageRequest {
  MessageCDBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.cd,
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

class MessageQuery extends MessageCDBase {
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
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageCDBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x01,
      );

  bool power = false;
  double targetTemperature = 0;
  bool auxHeating = false;
  Map<String, dynamic> fields = {};
  int mode = 0;
  bool useOldProtocol = true;

  int readField(String field) {
    final value = fields[field];
    return (value as int?) ?? 0;
  }

  @override
  Uint8List buildBody() {
    final powerByte = power ? 0x01 : 0x00;
    final targetTemperature = useOldProtocol
        ? round(this.targetTemperature * 2 + 30)
        : round(this.targetTemperature);
    return Uint8List.fromList([
      0x01,
      powerByte,
      mode,
      targetTemperature,
      readField('trValue'),
      readField('openPTC'),
      readField('ptcTemp'),
      readField('byte8'),
    ]);
  }

  static int round(double value) => value.round();
}

// ---------------------------------------------------------------------------
// CDGeneralMessageBody
// ---------------------------------------------------------------------------

class CDGeneralMessageBody extends MessageBody {
  CDGeneralMessageBody(Uint8List body) : super(body) {
    power = (body[2] & 0x01) > 0;
    mode = 0x00;
    disinfect = false;

    if ((body[2] & 0x02) > 0) {
      mode = 0x01;
    } else if ((body[2] & 0x04) > 0) {
      mode = 0x02;
    } else if ((body[2] & 0x08) > 0) {
      mode = 0x03;
    }

    heat = body[2] & 0x10;
    dualHeat = body[2] & 0x20;
    eco = body[2] & 0x40;
    targetTemperature = body[3].toDouble();
    currentTemperature = body[4].toDouble();
    topTemperature = body[5].toDouble();
    bottomTemperature = body[6].toDouble();
    condenserTemperature = body[7].toDouble();
    outdoorTemperature = body[8].toDouble();
    compressorTemperature = body[9].toDouble();
    maxTemperature = body[10].toDouble();
    minTemperature = body[11].toDouble();
    errorCode = body[20];
    bottomElecHeat = (body[27] & 0x01) > 0;
    topElecHeat = (body[27] & 0x02) > 0;
    waterPump = (body[27] & 0x04) > 0;
    compressorStatus = (body[27] & 0x08) > 0;

    if ((body[27] & 0x10) > 0) {
      wind = 'middle';
    } else if ((body[27] & 0x40) > 0) {
      wind = 'low';
    } else if ((body[27] & 0x80) > 0) {
      wind = 'high';
    }

    fourWay = (body[27] & 0x20) > 0;
    elecHeat = (body[28] & 0x01) > 0;

    final smartFlag = (body[28] & 0x20) > 0;
    if (smartFlag) {
      mode = 0x04;
    }

    backWater = (body[28] & 0x40) > 0;
    sterilize = (body[28] & 0x80) > 0;
    typeinfo = body[29];

    if (!smartFlag && mode == 0x00 && typeinfo == 0x04) {
      mode = 0x04;
    }

    waterLevel = body.length > oldBodyLength ? body[34] : null;

    vacationMode = false;
    vacationDays = 0;
    if (body.length > 25 && (body[25] & 0x01) > 0) {
      mode = 0x05;
      vacationMode = true;
      if (body.length > 27) {
        vacationDays = (body[26] << 8) | body[27];
      }
    }

    smartGrid = body.length > 25 ? ((body[25] & 0x02) > 0) : false;
    multiTerminal = body.length > 25 ? ((body[25] & 0x40) > 0) : false;
    fahrenheit = body.length > 25 ? ((body[25] & 0x80) > 0) : false;

    muteEffect = body.length > newBodyLength ? ((body[39] & 0x40) > 0) : false;
    muteStatus = body.length > newBodyLength ? ((body[39] & 0x80) > 0) : false;

    disinfectionSetTemperature = _parseDisinfectionSetTemperature(body);
    disinfect = _parseDisinfect(body);
  }

  late bool power;
  late int mode;
  late bool disinfect;
  late int heat;
  late int dualHeat;
  late int eco;
  late double targetTemperature;
  late double currentTemperature;
  late double topTemperature;
  late double bottomTemperature;
  late double condenserTemperature;
  late double outdoorTemperature;
  late double compressorTemperature;
  late double maxTemperature;
  late double minTemperature;
  late int errorCode;
  late bool bottomElecHeat;
  late bool topElecHeat;
  late bool waterPump;
  late bool compressorStatus;
  String? wind;
  late bool fourWay;
  late bool elecHeat;
  late bool backWater;
  late bool sterilize;
  late int typeinfo;
  int? waterLevel;
  late bool vacationMode;
  late int vacationDays;
  late bool smartGrid;
  late bool multiTerminal;
  late bool fahrenheit;
  late bool muteEffect;
  late bool muteStatus;
  double? disinfectionSetTemperature;

  double? _parseDisinfectionSetTemperature(Uint8List body) {
    const disinfectMarker = 0x3c;
    const minTemp = 25;
    const maxTemp = 90;

    for (
      var i = body.length - 2;
      i >= (body.length - 10).clamp(0, body.length);
      i--
    ) {
      if (body[i] == disinfectMarker) {
        final val = body[i + 1];
        if (minTemp <= val && val <= maxTemp) {
          return val.toDouble();
        }
      }
    }
    return null;
  }

  bool _parseDisinfect(Uint8List body) {
    const disinfectMarker = 0x3c;
    const minTemp = 25;
    const maxTemp = 90;

    for (
      var i = body.length - 2;
      i >= (body.length - 10).clamp(0, body.length);
      i--
    ) {
      if (body[i] == disinfectMarker) {
        final val = body[i + 1];
        if (minTemp <= val && val <= maxTemp) {
          final tailFlagIndex = i + 2;
          if (tailFlagIndex < body.length) {
            final tailFlag = body[tailFlagIndex];
            return tailFlag == 0x01;
          }
        }
      }
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// CD01MessageBody
// ---------------------------------------------------------------------------

class CD01MessageBody extends MessageBody {
  CD01MessageBody(Uint8List body) : super(body) {
    fields = {};
    power = (body[2] & 0x01) > 0;
    mode = body[3];
    targetTemperature = body[4].toDouble();
    fields['trValue'] = body[5];
    fields['openPTC'] = body[6];
    fields['ptcTemp'] = body[7];
    fields['byte8'] = body[8];
  }

  late Map<String, dynamic> fields;
  late bool power;
  late int mode;
  late double targetTemperature;
}

// ---------------------------------------------------------------------------
// MessageCDResponse
// ---------------------------------------------------------------------------

class MessageCDResponse extends MessageResponse {
  MessageCDResponse(Uint8List message) : super(message) {
    if ((messageType == MessageType.query ||
            messageType == MessageType.notify2) &&
        bodyType == 0x01) {
      final msgBody = CDGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrsGeneral(msgBody);
    } else if (messageType == MessageType.set && bodyType == 0x01) {
      final msgBody = CD01MessageBody(body);
      setBody(msgBody);
      _assignAttrs01(msgBody);
    }
  }

  bool? power;
  int? mode;
  bool? disinfect;
  int? heat;
  int? dualHeat;
  int? eco;
  double? targetTemperature;
  double? currentTemperature;
  double? topTemperature;
  double? bottomTemperature;
  double? condenserTemperature;
  double? outdoorTemperature;
  double? compressorTemperature;
  double? maxTemperature;
  double? minTemperature;
  int? errorCode;
  bool? bottomElecHeat;
  bool? topElecHeat;
  bool? waterPump;
  bool? compressorStatus;
  String? wind;
  bool? fourWay;
  bool? elecHeat;
  bool? backWater;
  bool? sterilize;
  int? typeinfo;
  int? waterLevel;
  bool? vacationMode;
  int? vacationDays;
  bool? smartGrid;
  bool? multiTerminal;
  bool? fahrenheit;
  bool? muteEffect;
  bool? muteStatus;
  double? disinfectionSetTemperature;
  Map<String, dynamic>? fields;

  void _assignAttrsGeneral(CDGeneralMessageBody msgBody) {
    power = msgBody.power;
    mode = msgBody.mode;
    disinfect = msgBody.disinfect;
    heat = msgBody.heat;
    dualHeat = msgBody.dualHeat;
    eco = msgBody.eco;
    targetTemperature = msgBody.targetTemperature;
    currentTemperature = msgBody.currentTemperature;
    topTemperature = msgBody.topTemperature;
    bottomTemperature = msgBody.bottomTemperature;
    condenserTemperature = msgBody.condenserTemperature;
    outdoorTemperature = msgBody.outdoorTemperature;
    compressorTemperature = msgBody.compressorTemperature;
    maxTemperature = msgBody.maxTemperature;
    minTemperature = msgBody.minTemperature;
    errorCode = msgBody.errorCode;
    bottomElecHeat = msgBody.bottomElecHeat;
    topElecHeat = msgBody.topElecHeat;
    waterPump = msgBody.waterPump;
    compressorStatus = msgBody.compressorStatus;
    wind = msgBody.wind;
    fourWay = msgBody.fourWay;
    elecHeat = msgBody.elecHeat;
    backWater = msgBody.backWater;
    sterilize = msgBody.sterilize;
    typeinfo = msgBody.typeinfo;
    waterLevel = msgBody.waterLevel;
    vacationMode = msgBody.vacationMode;
    vacationDays = msgBody.vacationDays;
    smartGrid = msgBody.smartGrid;
    multiTerminal = msgBody.multiTerminal;
    fahrenheit = msgBody.fahrenheit;
    muteEffect = msgBody.muteEffect;
    muteStatus = msgBody.muteStatus;
    disinfectionSetTemperature = msgBody.disinfectionSetTemperature;
  }

  void _assignAttrs01(CD01MessageBody msgBody) {
    power = msgBody.power;
    mode = msgBody.mode;
    targetTemperature = msgBody.targetTemperature;
    fields = msgBody.fields;
  }

  @override
  void setAttr() {}
}
