/// Midea local AC device message. Mirrors midealocal/devices/ac/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int maxMsgSerialNum = 254;
const int dryMode = 3;

class NewProtocolTags {
  static const int indoorHumidity = 0x0015;
  static const int screenDisplay = 0x0017;
  static const int breezeless = 0x0018;
  static const int promptTone = 0x001A;
  static const int indirectWind = 0x0042;
  static const int freshAir1 = 0x0233;
  static const int freshAir2 = 0x004B;
  static const int windLrAngle = 0x000A;
  static const int windUdAngle = 0x0009;
}

class BBACModes {
  static const List<int> modes = [0, 3, 1, 2, 4, 5];
}

// ---------------------------------------------------------------------------
// MessageACBase
// ---------------------------------------------------------------------------

abstract class MessageACBase extends MessageRequest {
  MessageACBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.ac,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       ) {
    _messageSerial = (_messageSerial + 1) % maxMsgSerialNum;
    if (_messageSerial == 0) _messageSerial = 1;
    _messageId = _messageSerial;
  }

  static int _messageSerial = 0;
  int _messageId = 0;

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

// ---------------------------------------------------------------------------
// MessageQuery
// ---------------------------------------------------------------------------

class MessageQuery extends MessageACBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([
      0x81,
      0x00,
      0xFF,
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
      0x00,
      0x00,
      0x00,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageCapabilitiesQuery
// ---------------------------------------------------------------------------

class MessageCapabilitiesQuery extends MessageACBase {
  MessageCapabilitiesQuery(int protocolVersion, this._additional)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.b5,
      );

  final bool _additional;

  @override
  Uint8List buildBody() {
    if (_additional) {
      return Uint8List.fromList([0x01, 0x01, 0x01]);
    }
    return Uint8List.fromList([0x01, 0x00]);
  }
}

// ---------------------------------------------------------------------------
// MessageCapabilitiesAdditionalQuery
// ---------------------------------------------------------------------------

class MessageCapabilitiesAdditionalQuery extends MessageCapabilitiesQuery {
  MessageCapabilitiesAdditionalQuery(int protocolVersion)
    : super(protocolVersion, true);
}

// ---------------------------------------------------------------------------
// MessageGroupZeroQuery
// ---------------------------------------------------------------------------

class MessageGroupZeroQuery extends MessageACBase {
  MessageGroupZeroQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x21, 0x01, 0x40, 0x00, 0x01]);
  }
}

// ---------------------------------------------------------------------------
// MessagePowerQuery
// ---------------------------------------------------------------------------

class MessagePowerQuery extends MessageACBase {
  MessagePowerQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x21, 0x01, 0x44, 0x00, 0x01]);
  }
}

// ---------------------------------------------------------------------------
// MessageHumidityQuery
// ---------------------------------------------------------------------------

class MessageHumidityQuery extends MessageACBase {
  MessageHumidityQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x21, 0x01, 0x45, 0x00, 0x01]);
  }
}

// ---------------------------------------------------------------------------
// MessageNewProtocolQuery
// ---------------------------------------------------------------------------

class MessageNewProtocolQuery extends MessageACBase {
  MessageNewProtocolQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.b1,
      );

  @override
  Uint8List buildBody() {
    final queryParams = [
      NewProtocolTags.indirectWind,
      NewProtocolTags.breezeless,
      NewProtocolTags.indoorHumidity,
      NewProtocolTags.screenDisplay,
      NewProtocolTags.freshAir1,
      NewProtocolTags.freshAir2,
      NewProtocolTags.windLrAngle,
      NewProtocolTags.windUdAngle,
    ];
    final body = <int>[queryParams.length];
    for (final param in queryParams) {
      body.add(param & 0xFF);
      body.add(param >> 8);
    }
    return Uint8List.fromList(body);
  }
}

// ---------------------------------------------------------------------------
// MessageSubProtocol
// ---------------------------------------------------------------------------

class MessageSubProtocol extends MessageACBase {
  MessageSubProtocol({
    required int protocolVersion,
    required MessageType messageType,
    required this.subprotocolQueryType,
  }) : super(
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: 0xAA,
       );

  final int subprotocolQueryType;

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageSubProtocolQuery
// ---------------------------------------------------------------------------

class MessageSubProtocolQuery extends MessageSubProtocol {
  MessageSubProtocolQuery(int protocolVersion, int subprotocolQueryType)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        subprotocolQueryType: subprotocolQueryType,
      );
}

// ---------------------------------------------------------------------------
// MessageSubProtocolSet
// ---------------------------------------------------------------------------

class MessageSubProtocolSet extends MessageSubProtocol {
  MessageSubProtocolSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        subprotocolQueryType: 0x20,
      );

  bool power = false;
  int mode = 0;
  double targetTemperature = 20.0;
  int fanSpeed = 102;
  bool boostMode = false;
  bool auxHeating = false;
  bool dry = false;
  bool ecoMode = false;
  bool sleepMode = false;
  bool sn8Flag = false;
  bool timer = false;
  bool promptTone = false;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x01 : 0;
    final dryB = power && dry ? 0x10 : 0;
    final boostB = boostMode ? 0x20 : 0;
    final auxB = auxHeating ? 0x40 : 0x80;
    final sleepB = sleepMode ? 0x80 : 0;
    int modeB;
    try {
      modeB = mode == 0 ? 0 : BBACModes.modes[mode] - 1;
    } catch (_) {
      modeB = 2;
    }
    final targetTemp = (targetTemperature * 2 + 30).round();
    final waterTemp = ((targetTemperature - 1) * 2 + 50).round();
    final fanB = fanSpeed;
    final ecoB = ecoMode ? 0x40 : 0;
    final promptB = promptTone ? 0x01 : 0;
    final timerB = sn8Flag && timer ? 0x04 : 0;

    return Uint8List.fromList([
      0x02 | boostB | powerB | dryB,
      auxB,
      sleepB,
      0x00,
      0x00,
      modeB,
      targetTemp,
      fanB,
      0x32,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x01,
      0x00,
      0x01,
      waterTemp,
      promptB,
      targetTemp,
      0x32,
      0x66,
      0x00,
      ecoB | timerB,
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
      0x08,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageGeneralSet
// ---------------------------------------------------------------------------

class MessageGeneralSet extends MessageACBase {
  MessageGeneralSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0x40,
      );

  bool power = false;
  bool promptTone = true;
  int mode = 0;
  double targetTemperature = 20.0;
  int fanSpeed = 102;
  bool swingVertical = false;
  bool swingHorizontal = false;
  bool boostMode = false;
  bool smartEye = false;
  bool dry = false;
  bool auxHeating = false;
  bool ecoMode = false;
  bool tempFahrenheit = false;
  bool sleepMode = false;
  bool naturalWind = false;
  bool frostProtect = false;
  bool comfortMode = false;

  @override
  Uint8List buildBody() {
    final powerB = power ? 0x01 : 0;
    final promptB = promptTone ? 0x40 : 0;
    final modeB = (mode << 5) & 0xE0;
    final targetTemp =
        (targetTemperature.round() & 0xF) |
        ((targetTemperature * 2).round() % 2 != 0 ? 0x10 : 0);
    final fanB = fanSpeed & 0x7F;
    final swingB =
        0x30 | (swingVertical ? 0x0C : 0) | (swingHorizontal ? 0x03 : 0);
    final boostB = boostMode ? 0x20 : 0;
    final smartB = smartEye ? 0x01 : 0;
    final dryB = dry ? 0x04 : 0;
    final auxB = auxHeating ? 0x08 : 0;
    final ecoB = ecoMode ? 0x80 : 0;
    final tempF = tempFahrenheit ? 0x04 : 0;
    final sleepB = sleepMode ? 0x01 : 0;
    final boost1B = boostMode ? 0x02 : 0;
    final naturalB = naturalWind ? 0x40 : 0;
    final frostB = frostProtect ? 0x80 : 0;
    final comfortB = comfortMode ? 0x01 : 0;

    return Uint8List.fromList([
      powerB | promptB,
      modeB | targetTemp,
      fanB,
      0x00,
      0x00,
      0x00,
      swingB,
      boostB,
      smartB | dryB | auxB | ecoB,
      tempF | sleepB | boost1B,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      naturalB,
      0x00,
      0x00,
      0x00,
      frostB,
      comfortB,
    ]);
  }
}

// ---------------------------------------------------------------------------
// MessageNewProtocolSet
// ---------------------------------------------------------------------------

class MessageNewProtocolSet extends MessageACBase {
  MessageNewProtocolSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: 0xB0,
      );

  bool? indirectWind;
  bool? promptTone;
  bool? breezeless;
  bool? screenDisplayAlternate;
  List<int>? freshAir1;
  List<int>? freshAir2;
  int? windLrAngle;
  int? windUdAngle;

  @override
  Uint8List buildBody() {
    var packCount = 0;
    final payload = <int>[0x00];

    if (breezeless != null) {
      packCount++;
      payload.addAll(
        _packParam(NewProtocolTags.breezeless, [breezeless! ? 0x01 : 0x00]),
      );
    }
    if (indirectWind != null) {
      packCount++;
      payload.addAll(
        _packParam(NewProtocolTags.indirectWind, [indirectWind! ? 0x02 : 0x01]),
      );
    }
    if (promptTone != null) {
      packCount++;
      payload.addAll(
        _packParam(NewProtocolTags.promptTone, [promptTone! ? 0x01 : 0x00]),
      );
    }
    if (screenDisplayAlternate != null) {
      packCount++;
      payload.addAll(
        _packParam(NewProtocolTags.screenDisplay, [
          screenDisplayAlternate! ? 0x64 : 0x00,
        ]),
      );
    }
    if (freshAir1 != null && freshAir1!.length == 2) {
      packCount++;
      final power = freshAir1![0] > 0 ? 2 : 1;
      final speed = freshAir1![1];
      payload.addAll(
        _packParam(NewProtocolTags.freshAir1, [
          power,
          speed,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
        ]),
      );
    }
    if (freshAir2 != null && freshAir2!.length == 2) {
      packCount++;
      final power = freshAir2![0] > 0 ? 1 : 0;
      final speed = freshAir2![1];
      payload.addAll(
        _packParam(NewProtocolTags.freshAir2, [power, speed, 0xFF]),
      );
    }
    if (windLrAngle != null) {
      packCount++;
      payload.addAll(_packParam(NewProtocolTags.windLrAngle, [windLrAngle!]));
    }
    if (windUdAngle != null) {
      packCount++;
      payload.addAll(_packParam(NewProtocolTags.windUdAngle, [windUdAngle!]));
    }

    payload[0] = packCount;
    return Uint8List.fromList(payload);
  }

  List<int> _packParam(int tag, List<int> value) {
    final result = <int>[];
    result.add(tag & 0xFF);
    result.add(tag >> 8);
    result.add(value.length);
    result.addAll(value);
    return result;
  }
}

// ---------------------------------------------------------------------------
// MessageToggleDisplay
// ---------------------------------------------------------------------------

class MessageToggleDisplay extends MessageACBase {
  MessageToggleDisplay(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: 0x41,
      );

  bool promptTone = false;

  @override
  Uint8List buildBody() {
    final promptB = promptTone ? 0x40 : 0;
    return Uint8List.fromList([
      0x02 | promptB,
      0x00,
      0xFF,
      0x02,
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
