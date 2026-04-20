import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxByteValue = 255;

abstract class MessageCEBase extends MessageRequest {
  MessageCEBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ce,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageCEBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x01,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageSet extends MessageCEBase {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x01,
      ) {
    power = false;
    fanSpeed = 0;
    linkToAc = false;
    sleepMode = false;
    ecoMode = false;
    auxHeating = false;
    powerfulPurify = false;
    scheduled = false;
    childLock = false;
  }

  bool power = false;
  int fanSpeed = 0;
  bool linkToAc = false;
  bool sleepMode = false;
  bool ecoMode = false;
  bool auxHeating = false;
  bool powerfulPurify = false;
  bool scheduled = false;
  bool childLock = false;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x80 : 0x00;
    final linkToAcB = linkToAc ? 0x01 : 0x00;
    final sleepModeB = sleepMode ? 0x02 : 0x00;
    final ecoModeB = ecoMode ? 0x04 : 0x00;
    final auxHeatingB = auxHeating ? 0x08 : 0x00;
    final powerfulPurifyB = powerfulPurify ? 0x10 : 0x00;
    final scheduledB = scheduled ? 0x01 : 0x00;
    final childLockB = childLock ? 0x7F : 0x00;
    return Uint8List.fromList([
      powerB | 0x01,
      fanSpeed,
      linkToAcB | sleepModeB | ecoModeB | auxHeatingB | powerfulPurifyB,
      scheduledB,
      0x00,
      childLockB,
    ]);
  }
}

class CEGeneralMessageBody extends MessageBody {
  CEGeneralMessageBody(Uint8List body) : super(body);

  bool? power;
  bool? childLock;
  bool? scheduled;
  int? fanSpeed;
  int? pm25;
  int? co2;
  double? currentHumidity;
  double? currentTemperature;
  double? hcho;
  bool? auxHeating;
  bool? linkToAc;
  bool? sleepMode;
  bool? ecoMode;
  bool? powerfulPurify;
  bool? filterCleaningReminder;
  bool? filterChangeReminder;
  int? errorCode;

  void parse(Uint8List body) {
    power = (body[1] & 0x80) > 0;
    childLock = (body[1] & 0x20) > 0;
    scheduled = (body[1] & 0x40) > 0;
    fanSpeed = body[2];
    pm25 = (body[3] << 8) + body[4];
    co2 = (body[5] << 8) + body[6];
    currentHumidity = null;
    currentTemperature = null;
    hcho = null;
    auxHeating = null;

    if (body[7] != maxByteValue) {
      currentHumidity = (body[7] << 8) + body[8] / 10;
    }
    if (body[9] != maxByteValue) {
      currentTemperature = (body[9] << 8) + (body[10] - 60) / 2;
    }
    if (body[11] != maxByteValue) {
      hcho = (body[11] << 8) + body[12] / 1000;
    }
    linkToAc = (body[17] & 0x01) > 0;
    sleepMode = (body[17] & 0x02) > 0;
    ecoMode = (body[17] & 0x04) > 0;
    if ((body[19] & 0x02) > 0) {
      auxHeating = (body[17] & 0x08) > 0;
    }
    powerfulPurify = (body[17] & 0x10) > 0;
    filterCleaningReminder = (body[18] & 0x01) > 0;
    filterChangeReminder = (body[18] & 0x02) > 0;
    errorCode = body[24];
  }
}

class CENotifyMessageBody extends MessageBody {
  CENotifyMessageBody(Uint8List body) : super(body);

  double? currentHumidity;
  double? currentTemperature;
  double? hcho;
  int? pm25;
  int? co2;
  int? errorCode;

  void parse(Uint8List body) {
    currentHumidity = null;
    currentTemperature = null;
    hcho = null;

    pm25 = (body[1] << 8) + body[2];
    co2 = (body[3] << 8) + body[4];
    if (body[5] != maxByteValue) {
      currentHumidity = (body[5] << 8) + body[6] / 10;
    }
    if (body[7] != maxByteValue) {
      currentTemperature = (body[7] << 8) + (body[8] - 60) / 2;
    }
    if (body[9] != maxByteValue) {
      hcho = (body[9] << 8) + body[10] / 1000;
    }
    errorCode = body[12];
  }
}

class MessageCEResponse extends MessageResponse {
  MessageCEResponse(Uint8List message) : super(message) {
    final isQueryOrSet =
        (messageType == MessageType.query || messageType == MessageType.set) &&
        bodyType == ListTypes.x01;
    final isNotify1X02 =
        messageType == MessageType.notify1 && bodyType == ListTypes.x02;
    final isNotify1X01 =
        messageType == MessageType.notify1 && bodyType == ListTypes.x01;

    if (isQueryOrSet || isNotify1X02) {
      final generalBody = CEGeneralMessageBody(super.body);
      generalBody.parse(super.body);
      _generalBody = generalBody;
    } else if (isNotify1X01) {
      final notifyBody = CENotifyMessageBody(super.body);
      notifyBody.parse(super.body);
      _notifyBody = notifyBody;
    }
    _setAttr();
  }

  CEGeneralMessageBody? _generalBody;
  CENotifyMessageBody? _notifyBody;

  bool? get power => _generalBody?.power;
  bool? get childLock => _generalBody?.childLock;
  bool? get scheduled => _generalBody?.scheduled;
  int? get fanSpeed => _generalBody?.fanSpeed;
  int? get pm25 => _generalBody?.pm25 ?? _notifyBody?.pm25;
  int? get co2 => _generalBody?.co2 ?? _notifyBody?.co2;
  double? get currentHumidity =>
      _generalBody?.currentHumidity ?? _notifyBody?.currentHumidity;
  double? get currentTemperature =>
      _generalBody?.currentTemperature ?? _notifyBody?.currentTemperature;
  double? get hcho => _generalBody?.hcho ?? _notifyBody?.hcho;
  bool? get auxHeating => _generalBody?.auxHeating;
  bool? get linkToAc => _generalBody?.linkToAc;
  bool? get sleepMode => _generalBody?.sleepMode;
  bool? get ecoMode => _generalBody?.ecoMode;
  bool? get powerfulPurify => _generalBody?.powerfulPurify;
  bool? get filterCleaningReminder => _generalBody?.filterCleaningReminder;
  bool? get filterChangeReminder => _generalBody?.filterChangeReminder;
  int? get errorCode => _generalBody?.errorCode ?? _notifyBody?.errorCode;

  @override
  void _setAttr() {}
}
