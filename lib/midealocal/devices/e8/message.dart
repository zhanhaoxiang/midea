/// Midea local E8 device message. Mirrors midealocal/devices/e8/message.dart.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

const int minResponseBodyLength = 6;

class SubCommand {
  static const int x02 = 0x02;
  static const int x04 = 0x04;
  static const int x06 = 0x06;
}

abstract class MessageE8Base extends MessageRequest {
  MessageE8Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.e8,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageE8Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x41,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x55, 0x00, 0x01, 0x00, 0x00]);
  }
}

class E8MessageBody extends MessageBody {
  E8MessageBody(Uint8List body) : super(body) {
    status = body[11];
    timeRemaining = body[16] * 3600 + body[17] * 60 + body[18];
    keepWarmRemaining = body[19] * 3600 + body[20] * 60 + body[21];
    workingTime = body[28] * 3600 + body[29] * 60 + body[30];
    targetTemperature = body[39];
    currentTemperature = body[39];
    finished = (body[41] & 0x01) > 0;
    waterShortage = body[43] > 0;
  }

  late int status;
  late int timeRemaining;
  late int keepWarmRemaining;
  late int workingTime;
  late int targetTemperature;
  late int currentTemperature;
  late bool finished;
  late bool waterShortage;
}

class MessageE8Response extends MessageResponse {
  MessageE8Response(Uint8List message) : super(message) {
    if (body.length > minResponseBodyLength) {
      final subCmd = body[6];
      final isSetWithValidSubCmd =
          messageType == MessageType.set &&
          (subCmd == SubCommand.x02 ||
              subCmd == SubCommand.x04 ||
              subCmd == SubCommand.x06);
      final isQueryOrNotifyWithX02 =
          (messageType == MessageType.query ||
              messageType == MessageType.notify1) &&
          subCmd == SubCommand.x02;
      if (isSetWithValidSubCmd || isQueryOrNotifyWithX02) {
        final e8Body = E8MessageBody(body);
        setBody(e8Body);
        _assignAttrs(e8Body);
      }
    }
  }

  int? status;
  int? timeRemaining;
  int? keepWarmRemaining;
  int? workingTime;
  int? targetTemperature;
  int? currentTemperature;
  bool? finished;
  bool? waterShortcut;

  void _assignAttrs(E8MessageBody b) {
    status = b.status;
    timeRemaining = b.timeRemaining;
    keepWarmRemaining = b.keepWarmRemaining;
    workingTime = b.workingTime;
    targetTemperature = b.targetTemperature;
    currentTemperature = b.currentTemperature;
    finished = b.finished;
    waterShortcut = b.waterShortage;
  }
}
