/// Midea local E6 device message. Mirrors midealocal/devices/e6/message.py.

import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

abstract class MessageE6Base extends MessageRequest {
  MessageE6Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.e6,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody();
}

class MessageQuery extends MessageE6Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() {
    return Uint8List.fromList([0x01, 0x01] + List.filled(28, 0));
  }
}

class MessageSet extends MessageE6Base {
  MessageSet(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.set,
        bodyType: ListTypes.x00,
      );

  bool? mainPower;
  double? heatingTemperature;
  double? bathingTemperature;
  bool? heatingPower;
  String? heatingModes;
  bool? coldWaterSingle;
  bool? coldWaterDot;

  @override
  Uint8List buildBody() {
    List<int> body = [];
    if (mainPower != null) {
      final mainPowerValue = mainPower! ? 0x01 : 0x02;
      body = [mainPowerValue, 0x01];
    } else if (heatingTemperature != null) {
      body = [0x04, 0x13, heatingTemperature!.toInt()];
    } else if (bathingTemperature != null) {
      body = [0x04, 0x12, bathingTemperature!.toInt()];
    } else if (heatingPower != null) {
      final heatingPowerValue = heatingPower! ? 0x01 : 0x02;
      body = [0x04, 0x01, heatingPowerValue];
    } else if (coldWaterSingle != null) {
      final coldWaterSingleValue = coldWaterSingle! ? 0x01 : 0x00;
      body = [0x04, 0x1A, coldWaterSingleValue];
    } else if (coldWaterDot != null) {
      final coldWaterDotValue = coldWaterDot! ? 0x01 : 0x00;
      body = [0x04, 0x1B, coldWaterDotValue];
    } else if (heatingModes != null) {
      if (heatingModes == 'normal_mode') {
        body = [0x04, 0x02, 0x01];
      } else if (heatingModes == 'out_mode') {
        body = [0x04, 0x02, 0x02];
      } else if (heatingModes == 'home_mode') {
        body = [0x04, 0x02, 0x04];
      } else if (heatingModes == 'sleep_mode') {
        body = [0x04, 0x02, 0x08];
      }
    }
    final bodyLen = body.length;
    return Uint8List.fromList(body + List.filled(30 - bodyLen, 0));
  }
}

class E6GeneralMessageBody {
  E6GeneralMessageBody(List<int> body) {
    mainPower = (body[2] & 0x04) > 0;
    heatingWorking = (body[2] & 0x10) > 0;
    bathingWorking = (body[2] & 0x20) > 0;
    heatingPower = (body[4] & 0x01) > 0;
    minTemperature = [body[16].toDouble(), body[11].toDouble()];
    maxTemperature = [body[15].toDouble(), body[10].toDouble()];
    heatingTemperature = body[17].toDouble();
    bathingTemperature = body[12].toDouble();
    heatingLeavingTemperature = body[14].toDouble();
    bathingLeavingTemperature = body[8].toDouble();
    coldWaterSingle = (body[25] & 0x01) > 0;
    coldWaterDot = (body[25] & 0x02) > 0;
    if (body[4] & 0x08 != 0) {
      heatingModes = 'out_mode';
    } else if (body[4] & 0x04 != 0) {
      heatingModes = 'normal_mode';
    } else if (body[4] & 0x10 != 0) {
      heatingModes = 'home_mode';
    } else if (body[4] & 0x20 != 0) {
      heatingModes = 'sleep_mode';
    } else {
      heatingModes = 'normal_mode';
    }
  }

  late bool mainPower;
  late bool heatingWorking;
  late bool bathingWorking;
  late bool heatingPower;
  late List<double> minTemperature;
  late List<double> maxTemperature;
  late double heatingTemperature;
  late double bathingTemperature;
  late double heatingLeavingTemperature;
  late double bathingLeavingTemperature;
  late bool coldWaterSingle;
  late bool coldWaterDot;
  late String heatingModes;
}

class MessageE6Response extends MessageResponse {
  MessageE6Response(Uint8List message) : super(message) {
    final bodyData = body;
    _bodyData = E6GeneralMessageBody(bodyData);
    _attributes['main_power'] = _bodyData!.mainPower;
    _attributes['heating_working'] = _bodyData!.heatingWorking;
    _attributes['bathing_working'] = _bodyData!.bathingWorking;
    _attributes['heating_power'] = _bodyData!.heatingPower;
    _attributes['temperature_min'] = _bodyData!.minTemperature;
    _attributes['temperature_max'] = _bodyData!.maxTemperature;
    _attributes['heating_temperature'] = _bodyData!.heatingTemperature;
    _attributes['bathing_temperature'] = _bodyData!.bathingTemperature;
    _attributes['heating_leaving_temperature'] =
        _bodyData!.heatingLeavingTemperature;
    _attributes['bathing_leaving_temperature'] =
        _bodyData!.bathingLeavingTemperature;
    _attributes['cold_water_single'] = _bodyData!.coldWaterSingle;
    _attributes['cold_water_dot'] = _bodyData!.coldWaterDot;
    _attributes['heating_modes'] = _bodyData!.heatingModes;
  }

  late E6GeneralMessageBody? _bodyData;
  final Map<String, dynamic> _attributes = {};

  bool hasAttribute(String attr) => _attributes.containsKey(attr);

  dynamic getAttribute(String attr) => _attributes[attr];
}
