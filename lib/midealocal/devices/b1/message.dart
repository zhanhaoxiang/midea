import 'dart:typed_data';
import '../../const.dart';
import '../../message.dart';

class MessageB1Base extends MessageRequest {
  MessageB1Base({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(
         deviceType: DeviceType.b1,
         protocolVersion: protocolVersion,
         messageType: messageType,
         bodyType: bodyType,
       );

  @override
  Uint8List buildBody() => Uint8List(0);
}

class MessageQuery extends MessageB1Base {
  MessageQuery(int protocolVersion)
    : super(
        protocolVersion: protocolVersion,
        messageType: MessageType.query,
        bodyType: ListTypes.x00,
      );
}

class B1MessageBody extends MessageBody {
  B1MessageBody(super.body) {
    final data = super.data;
    _door = (data[16] & 0x02) > 0;
    _status = data[1];
    final hours = data[6] == maxByteValue ? 0 : data[6];
    final minutes = data[7] == maxByteValue ? 0 : data[7];
    final seconds = data[8] == maxByteValue ? 0 : data[8];
    _timeRemaining = hours * 3600 + minutes * 60 + seconds;
    _currentTemperature = data[19];
    _tankEjected = (data[16] & 0x04) > 0;
    _waterShortage = (data[16] & 0x08) > 0;
    _waterChangeReminder = (data[16] & 0x10) > 0;
  }

  late bool _door;
  late int _status;
  late int _timeRemaining;
  late int _currentTemperature;
  late bool _tankEjected;
  late bool _waterShortage;
  late bool _waterChangeReminder;

  bool get door => _door;
  int get status => _status;
  int get timeRemaining => _timeRemaining;
  int get currentTemperature => _currentTemperature;
  bool get tankEjected => _tankEjected;
  bool get waterShortage => _waterShortage;
  bool get waterChangeReminder => _waterChangeReminder;
}

class DeviceAttributes {
  static const String door = 'door';
  static const String status = 'status';
  static const String timeRemaining = 'time_remaining';
  static const String currentTemperature = 'current_temperature';
  static const String tankEjected = 'tank_ejected';
  static const String waterChangeReminder = 'water_change_reminder';
  static const String waterShortage = 'water_shortage';
}

class MessageB1Response extends MessageResponse {
  MessageB1Response(Uint8List message) : super(message) {
    if (messageType == MessageType.notify1 ||
        messageType == MessageType.query) {
      final bodyData = Uint8List.fromList(
        message.sublist(MessageBase.headerLength, message.length - 1),
      );
      final b1Body = B1MessageBody(bodyData);
      setBody(b1Body);
      _door = b1Body.door;
      _status = b1Body.status;
      _timeRemaining = b1Body.timeRemaining;
      _currentTemperature = b1Body.currentTemperature;
      _tankEjected = b1Body.tankEjected;
      _waterShortage = b1Body.waterShortage;
      _waterChangeReminder = b1Body.waterChangeReminder;
      _attributes[DeviceAttributes.door] = _door;
      _attributes[DeviceAttributes.status] = _status;
      _attributes[DeviceAttributes.timeRemaining] = _timeRemaining;
      _attributes[DeviceAttributes.currentTemperature] = _currentTemperature;
      _attributes[DeviceAttributes.tankEjected] = _tankEjected;
      _attributes[DeviceAttributes.waterShortage] = _waterShortage;
      _attributes[DeviceAttributes.waterChangeReminder] = _waterChangeReminder;
    }
  }

  final Map<String, dynamic> _attributes = {};

  late bool _door;
  late int _status;
  late int _timeRemaining;
  late int _currentTemperature;
  late bool _tankEjected;
  late bool _waterShortage;
  late bool _waterChangeReminder;

  bool get door => _door;
  int get status => _status;
  int get timeRemaining => _timeRemaining;
  int get currentTemperature => _currentTemperature;
  bool get tankEjected => _tankEjected;
  bool get waterShortage => _waterShortage;
  bool get waterChangeReminder => _waterChangeReminder;

  bool hasAttribute(String attr) => _attributes.containsKey(attr);

  dynamic getAttribute(String attr) => _attributes[attr];
}
