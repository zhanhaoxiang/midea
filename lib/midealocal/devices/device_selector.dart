/// Midea local device selector. Mirrors midealocal/devices/__init__.py.

import '../const.dart';
import 'ac/midea_ac_device.dart';
import 'db/midea_db_device.dart';
import '../device.dart';

MideaDevice? selectDevice({
  required String name,
  required int deviceId,
  required DeviceType deviceType,
  required String ipAddress,
  required int port,
  required String token,
  required String key,
  required ProtocolVersion deviceProtocol,
  required String model,
  required int subtype,
  String? customize,
}) {
  switch (deviceType) {
    case DeviceType.ac:
      return MideaACDevice(
        name: name,
        deviceId: deviceId,
        ipAddress: ipAddress,
        port: port,
        token: token,
        key: key,
        deviceProtocol: deviceProtocol,
        model: model,
        subtype: subtype,
        customize: customize,
      );
    case DeviceType.db:
      return MideaDBDevice(
        name: name,
        deviceId: deviceId,
        ipAddress: ipAddress,
        port: port,
        token: token,
        key: key,
        deviceProtocol: deviceProtocol,
        model: model,
        subtype: subtype,
      );
    default:
      return null;
  }
}
