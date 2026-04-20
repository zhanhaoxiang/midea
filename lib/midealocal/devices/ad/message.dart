/// Midea local AD device message. Mirrors midealocal/devices/ad/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int maxMsgSerialNum = 254;

class ADListTypes {
  static const int x11 = 0x11;
  static const int x21 = 0x21;
  static const int x31 = 0x31;
  static const int x04 = 0x04;
  static const int x0d = 0x0D;
  static const int ff = 0xFF;
}

abstract class MessageADBase extends MessageRequest {
  MessageADBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ad,
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

class Message21Query extends MessageADBase {
  Message21Query(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ADListTypes.x21,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

class Message31Query extends MessageADBase {
  Message31Query(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ADListTypes.x31,
      );

  @override
  Uint8List buildBody() => Uint8List.fromList([0x01]);
}

class X31MessageBody extends MessageBody {
  X31MessageBody(Uint8List body) : super(body) {
    screenStatus = body[2] > 0
        ? (body[2] != ADListTypes.ff ? true : null)
        : null;
    ledStatus = body[3] > 0 ? (body[3] != ADListTypes.ff ? true : null) : null;
    arofeneLink = body[4] > 0
        ? (body[4] != ADListTypes.ff ? true : null)
        : null;
    headerExist = body[5] > 0
        ? (body[5] != ADListTypes.ff ? true : null)
        : null;
    radarExist = body[6] > 0 ? (body[6] != ADListTypes.ff ? true : null) : null;
    headerLedStatus = body[7] > 0
        ? (body[7] != ADListTypes.ff ? true : null)
        : null;
    temperatureRaw = body[8] != ADListTypes.ff
        ? (body[8] << 8) + body[9]
        : null;
    humidityRaw = body[10] != ADListTypes.ff
        ? (body[10] << 8) + body[11]
        : null;
    temperatureCompensate =
        body[1] > ADListTypes.x0d && body[12] != ADListTypes.ff
        ? (body[12] << 8) + body[13]
        : null;
    humidityCompensate = body[1] > ADListTypes.x0d && body[14] != ADListTypes.ff
        ? (body[14] << 8) + body[15]
        : null;
  }

  bool? screenStatus;
  bool? ledStatus;
  bool? arofeneLink;
  bool? headerExist;
  bool? radarExist;
  bool? headerLedStatus;
  int? temperatureRaw;
  int? humidityRaw;
  int? temperatureCompensate;
  int? humidityCompensate;
}

class X21MessageBody extends MessageBody {
  X21MessageBody(Uint8List body) : super(body) {
    portableSense = body[2] > 0;
    nightMode = body[3] > 0;
    screenExtinctionTimeout = body[4] != ADListTypes.ff ? body[4] : null;
  }

  bool? portableSense;
  bool? nightMode;
  int? screenExtinctionTimeout;
}

class ADNotifyMessageBody extends MessageBody {
  ADNotifyMessageBody(Uint8List body) : super(body) {
    if (body[1] == 0x01) {
      temperature = body[3] >= 0x80
          ? (((((body[3] << 8) + body[4]) - 65535) - 1) / 100)
          : (((body[3] << 8) + body[4]) / 100);
      humidity = body[5] != ADListTypes.ff
          ? ((body[5] << 8) + body[6]) / 100
          : null;
      tvoc = body[7] != ADListTypes.ff ? (body[7] << 8) + body[8] : null;
      pm25 = body[9] != ADListTypes.ff ? (body[9] << 8) + body[10] : null;
      co2 = body[11] != ADListTypes.ff ? (body[11] << 8) + body[12] : null;
      hcho = body[13] != ADListTypes.ff
          ? ((body[13] << 8) + body[14]) / 0.1
          : null;
      arofeneLink = body[16] != ADListTypes.ff ? ((body[16] & 0x01) > 0) : null;
      radarExist = body[16] != ADListTypes.ff ? ((body[16] & 0x02) > 0) : null;
    } else if (body[1] == ADListTypes.x04) {
      if (body[3] == 0x01) {
        presetsFunction = body[4] == 0x01;
      } else if (body[3] == 0x02) {
        fallAsleepStatus = body[4] == 0x01;
      }
    }
  }

  double? temperature;
  double? humidity;
  int? tvoc;
  int? pm25;
  int? co2;
  double? hcho;
  bool? arofeneLink;
  bool? radarExist;
  bool? presetsFunction;
  bool? fallAsleepStatus;
}

class MessageADResponse extends MessageResponse {
  MessageADResponse(Uint8List message) : super(message) {
    if (bodyType == ADListTypes.x11) {
      final msgBody = ADNotifyMessageBody(body);
      setBody(msgBody);
      _assignNotifyAttrs(msgBody);
    } else if (bodyType == ADListTypes.x21) {
      final msgBody = X21MessageBody(body);
      setBody(msgBody);
      _assignX21Attrs(msgBody);
    } else if (bodyType == ADListTypes.x31) {
      final msgBody = X31MessageBody(body);
      setBody(msgBody);
      _assignX31Attrs(msgBody);
    }
  }

  double? temperature;
  double? humidity;
  int? tvoc;
  int? pm25;
  int? co2;
  double? hcho;
  bool? presetsFunction;
  bool? fallAsleepStatus;
  bool? portableSense;
  bool? nightMode;
  int? screenExtinctionTimeout;
  bool? screenStatus;
  bool? ledStatus;
  bool? arofeneLink;
  bool? headerExist;
  bool? radarExist;
  bool? headerLedStatus;
  int? temperatureRaw;
  int? humidityRaw;
  int? temperatureCompensate;
  int? humidityCompensate;

  void _assignNotifyAttrs(ADNotifyMessageBody b) {
    temperature = b.temperature;
    humidity = b.humidity;
    tvoc = b.tvoc;
    pm25 = b.pm25;
    co2 = b.co2;
    hcho = b.hcho;
    arofeneLink = b.arofeneLink;
    radarExist = b.radarExist;
    presetsFunction = b.presetsFunction;
    fallAsleepStatus = b.fallAsleepStatus;
  }

  void _assignX21Attrs(X21MessageBody b) {
    portableSense = b.portableSense;
    nightMode = b.nightMode;
    screenExtinctionTimeout = b.screenExtinctionTimeout;
  }

  void _assignX31Attrs(X31MessageBody b) {
    screenStatus = b.screenStatus;
    ledStatus = b.ledStatus;
    arofeneLink = b.arofeneLink;
    headerExist = b.headerExist;
    radarExist = b.radarExist;
    headerLedStatus = b.headerLedStatus;
    temperatureRaw = b.temperatureRaw;
    humidityRaw = b.humidityRaw;
    temperatureCompensate = b.temperatureCompensate;
    humidityCompensate = b.humidityCompensate;
  }
}
