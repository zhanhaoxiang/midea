import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';

class MideaB1Device extends MideaDevice {
  MideaB1Device({
    required super.name,
    required super.deviceId,
    required super.ipAddress,
    required super.port,
    required super.token,
    required super.key,
    required ProtocolVersion deviceProtocol,
    required super.model,
    required super.subtype,
    String? customize,
  }) : super(
         deviceType: DeviceType.b1,
         deviceProtocol: deviceProtocol,
         attributes: Map<String, dynamic>.from(_defaultAttributes),
       );

  static const Map<int, String> _statusMap = {
    0x01: 'Standby',
    0x02: 'Idle',
    0x03: 'Working',
    0x04: 'Finished',
    0x05: 'Delay',
    0x06: 'Paused',
  };

  static final Map<String, dynamic> _defaultAttributes = {
    DeviceAttributes.door: false,
    DeviceAttributes.status: null,
    DeviceAttributes.timeRemaining: null,
    DeviceAttributes.currentTemperature: null,
    DeviceAttributes.tankEjected: false,
    DeviceAttributes.waterChangeReminder: false,
    DeviceAttributes.waterShortage: false,
  };

  @override
  List<MessageRequest> buildQuery() {
    return [MessageQuery(messageProtocolVersion)];
  }

  @override
  Map<String, dynamic> processMessage(Uint8List msg) {
    final message = MessageB1Response(msg);
    final newStatus = <String, dynamic>{};

    for (final status in attrs.keys) {
      final attrStr = status.toString();
      if (message.hasAttribute(attrStr)) {
        final value = message.getAttribute(attrStr);
        if (status == DeviceAttributes.status) {
          attrs[DeviceAttributes.status] = _statusMap[value] ?? null;
          newStatus[DeviceAttributes.status] = attrs[DeviceAttributes.status];
        } else {
          attrs[status] = value;
          newStatus[status] = value;
        }
      }
    }
    return newStatus;
  }

  @override
  void setAttribute(String attr, dynamic value) {}
}
