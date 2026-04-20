/// Midea local FB device message. Mirrors midealocal/devices/fb/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int childLockByte = 18;
const int energyConsumptionByte = 21;
const int maxHeatingLevel = 10;
const int maxHumidity = 100;
const int maxTargetTemp = 50;
const int minTargetTemp = -40;

// ---------------------------------------------------------------------------
// MessageFBBase
// ---------------------------------------------------------------------------

abstract class MessageFBBase extends MessageRequest {
  MessageFBBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.fb,
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

class MessageQuery extends MessageFBBase {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);
}

// ---------------------------------------------------------------------------
// MessageSet
// ---------------------------------------------------------------------------

class MessageSet extends MessageFBBase {
  MessageSet(int protocolVersion, this.subtype)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      );

  final int subtype;

  bool? power;
  int? mode;
  int? heatingLevel;
  int? targetTemperature;
  bool? childLock;

  @override
  Uint8List buildBody() {
    final powerB = power == null ? 0 : (power! ? 0x01 : 0x02);
    final modeB = mode ?? 0;
    final heatingLevelB = heatingLevel == null
        ? 0
        : (heatingLevel! >= 1 && heatingLevel! <= maxHeatingLevel
              ? heatingLevel! & 0xFF
              : 0);
    final targetTempB = targetTemperature == null
        ? 0
        : (targetTemperature! >= minTargetTemp &&
                  targetTemperature! <= maxTargetTemp
              ? (targetTemperature! + 41) & 0xFF
              : (targetTemperature == 0x80 || targetTemperature == 87
                    ? 0x80
                    : 0));
    final childLockB = childLock == null ? 0xFF : (childLock! ? 0x01 : 0x00);

    final body = <int>[
      powerB,
      0x00,
      0x00,
      0x00,
      modeB,
      heatingLevelB,
      targetTempB,
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
      childLockB,
      0x00,
    ];

    if (subtype > 0x05) {
      body.addAll([0x00, 0x00, 0x00]);
    }

    return Uint8List.fromList(body);
  }
}

// ---------------------------------------------------------------------------
// FBGeneralMessageBody
// ---------------------------------------------------------------------------

class FBGeneralMessageBody extends MessageBody {
  FBGeneralMessageBody(Uint8List body) : super(body) {
    power = (body[0] & 0x01) != 0 && (body[0] & 0x01) != 2;
    mode = body[4];
    heatingLevel = body[5];
    targetTemperature = body[6] - 41;
    if (body[7] >= 1 && body[7] <= maxHumidity) {
      targetHumidity = body[7];
      currentHumidity = body[12];
    }
    currentTemperature = body[13] - 20;
    if (body.length > childLockByte) {
      childLock = (body[childLockByte] & 0x01) > 0;
    }
    if (body.length > energyConsumptionByte) {
      energyConsumption = (body[energyConsumptionByte] << 8) + body[21];
    }
  }

  late bool power;
  late int mode;
  late int heatingLevel;
  late int targetTemperature;
  int? targetHumidity;
  int? currentHumidity;
  late int currentTemperature;
  bool? childLock;
  int? energyConsumption;
}

// ---------------------------------------------------------------------------
// MessageFBResponse
// ---------------------------------------------------------------------------

class MessageFBResponse extends MessageResponse {
  MessageFBResponse(Uint8List message) : super(message) {
    if (messageType == MessageType.query ||
        messageType == MessageType.set ||
        messageType == MessageType.notify1) {
      final msgBody = FBGeneralMessageBody(body);
      setBody(msgBody);
      _assignAttrs(msgBody);
    }
  }

  bool? power;
  int? mode;
  int? heatingLevel;
  int? targetTemperature;
  int? currentTemperature;
  bool? childLock;

  void _assignAttrs(FBGeneralMessageBody b) {
    power = b.power;
    mode = b.mode;
    heatingLevel = b.heatingLevel;
    targetTemperature = b.targetTemperature;
    currentTemperature = b.currentTemperature;
    childLock = b.childLock;
  }
}
