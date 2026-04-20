/// Midea local EA device message. Mirrors midealocal/devices/ea/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

class Progress {
  static const int cooking = 2;
  static const int keepWarm = 3;
}

abstract class MessageEABase extends MessageRequest {
  MessageEABase({
    required int protocolVersion,
    required MessageType messageType,
    int bodyType = ListTypes.x00,
  }) : super(
         deviceType: DeviceType.ea,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQuery extends MessageEABase {
  MessageQuery(int protocolVersion)
    : super(protocolVersion: protocolVersion, messageType: MessageType.query);

  @override
  Uint8List get body => Uint8List.fromList([0xAA, 0x55, 0x01, 0x03, 0x00]);
}

class EABody1 {
  EABody1(Uint8List body) {
    mode = body[6] + (body[7] << 8);
    progress = body[14];
    cooking = progress == Progress.cooking;
    keepWarm = progress == Progress.keepWarm;
    topTemperature = body[18];
    bottomTemperature = body[19];
    timeRemaining = body[22] * 60 + body[23];
    keepWarmTime = body[26] * 60 + body[27];
  }

  late int mode;
  late int progress;
  late bool cooking;
  late bool keepWarm;
  late int? topTemperature;
  late int? bottomTemperature;
  late int? timeRemaining;
  late int? keepWarmTime;
}

class EABody2 {
  EABody2(Uint8List body) {
    progress = body[9];
    cooking = progress == Progress.cooking;
    keepWarm = progress == Progress.keepWarm;
    mode = body[58] + (body[59] << 8);
    timeRemaining = body[50] * 60 + body[51];
    keepWarmTime = body[54] * 60 + body[55];
    topTemperature = body[21];
    bottomTemperature = body[20];
  }

  late int progress;
  late bool cooking;
  late bool keepWarm;
  late int mode;
  late int? timeRemaining;
  late int? keepWarmTime;
  late int? topTemperature;
  late int? bottomTemperature;
}

class EABody3 {
  EABody3(Uint8List body) {
    mode = body[4] + (body[5] << 8);
    progress = body[8];
    cooking = progress == Progress.cooking;
    keepWarm = progress == Progress.keepWarm;
    timeRemaining = body[12] * 60 + body[13];
    topTemperature = body[20];
    bottomTemperature = body[21];
    keepWarmTime = body[22] * 60 + body[23];
  }

  late int mode;
  late int progress;
  late bool cooking;
  late bool keepWarm;
  late int? timeRemaining;
  late int? topTemperature;
  late int? bottomTemperature;
  late int? keepWarmTime;
}

class EABodyNew {
  EABodyNew(Uint8List body) {
    if (body[6] == 2 ||
        body[6] == 4 ||
        body[6] == 6 ||
        body[6] == 8 ||
        body[6] == 10 ||
        body[6] == 0x62) {
      mode = body[7] + (body[8] << 8);
      progress = body[11];
      cooking = progress == Progress.cooking;
      keepWarm = progress == Progress.keepWarm;
      timeRemaining = body[16] * 60 + body[17];
      topTemperature = body[60];
      bottomTemperature = body[61];
      keepWarmTime = body[19] * 60 + body[20];
    }
  }

  late int mode;
  late int progress;
  late bool cooking;
  late bool keepWarm;
  late int? timeRemaining;
  late int? topTemperature;
  late int? bottomTemperature;
  late int? keepWarmTime;
}

class MessageEAResponse extends MessageResponse {
  MessageEAResponse(super.message) {
    if (messageType == MessageType.notify1 && body[3] == ListTypes.x01) {
      _bodyNew = EABodyNew(body);
      _useBodyNew = true;
    } else if (protocolVersion == 0) {
      if (messageType == MessageType.set && body[5] == 0x16) {
        _body1 = EABody1(body);
      } else if (messageType == MessageType.query) {
        if (body[6] == ListTypes.x52 && body[7] == ListTypes.c3) {
          _body2 = EABody2(body);
        } else if (body[5] == 0x3D) {
          _body1 = EABody1(body);
        }
      } else if (messageType == MessageType.notify1 && body[5] == 0x3D) {
        _body1 = EABody1(body);
      }
    } else if (messageType == MessageType.set && body[3] == ListTypes.x02) {
      _body3 = EABody3(body);
    } else if (messageType == MessageType.query && body[3] == ListTypes.x03) {
      _body3 = EABody3(body);
    } else if (messageType == MessageType.notify1 && body[3] == ListTypes.x04) {
      _body3 = EABody3(body);
    } else if (messageType == MessageType.notify1 && body[3] == ListTypes.x06) {
      _mode = body[4] + (body[5] << 8);
    }
  }

  EABody1? _body1;
  EABody2? _body2;
  EABody3? _body3;
  EABodyNew? _bodyNew;
  int? _mode;
  bool _useBodyNew = false;

  int? get mode {
    if (_body1 != null) return _body1!.mode;
    if (_body2 != null) return _body2!.mode;
    if (_body3 != null) return _body3!.mode;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.mode;
    return _mode;
  }

  int? get progress {
    if (_body1 != null) return _body1!.progress;
    if (_body2 != null) return _body2!.progress;
    if (_body3 != null) return _body3!.progress;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.progress;
    return null;
  }

  bool? get cooking {
    if (_body1 != null) return _body1!.cooking;
    if (_body2 != null) return _body2!.cooking;
    if (_body3 != null) return _body3!.cooking;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.cooking;
    return null;
  }

  bool? get keepWarm {
    if (_body1 != null) return _body1!.keepWarm;
    if (_body2 != null) return _body2!.keepWarm;
    if (_body3 != null) return _body3!.keepWarm;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.keepWarm;
    return null;
  }

  int? get topTemperature {
    if (_body1 != null) return _body1!.topTemperature;
    if (_body2 != null) return _body2!.topTemperature;
    if (_body3 != null) return _body3!.topTemperature;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.topTemperature;
    return null;
  }

  int? get bottomTemperature {
    if (_body1 != null) return _body1!.bottomTemperature;
    if (_body2 != null) return _body2!.bottomTemperature;
    if (_body3 != null) return _body3!.bottomTemperature;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.bottomTemperature;
    return null;
  }

  int? get timeRemaining {
    if (_body1 != null) return _body1!.timeRemaining;
    if (_body2 != null) return _body2!.timeRemaining;
    if (_body3 != null) return _body3!.timeRemaining;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.timeRemaining;
    return null;
  }

  int? get keepWarmTime {
    if (_body1 != null) return _body1!.keepWarmTime;
    if (_body2 != null) return _body2!.keepWarmTime;
    if (_body3 != null) return _body3!.keepWarmTime;
    if (_bodyNew != null && _useBodyNew) return _bodyNew!.keepWarmTime;
    return null;
  }
}
