/// Midea local device selector. Mirrors midealocal/devices/__init__.py.

import '../const.dart';
import '../device.dart';
import 'ac/midea_ac_device.dart';
import 'ad/midea_ad_device.dart';
import 'a1/midea_a1_device.dart';
import 'b0/midea_b0_device.dart';
import 'b1/midea_b1_device.dart';
import 'b3/midea_b3_device.dart';
import 'b4/midea_b4_device.dart';
import 'b6/midea_b6_device.dart';
import 'b8/midea_b8_device.dart';
import 'bf/midea_bf_device.dart';
import 'c2/midea_c2_device.dart';
import 'c3/midea_c3_device.dart';
import 'ca/midea_ca_device.dart';
import 'cc/midea_cc_device.dart';
import 'cd/midea_cd_device.dart';
import 'ce/midea_ce_device.dart';
import 'cf/midea_cf_device.dart';
import 'da/midea_da_device.dart';
import 'db/midea_db_device.dart';
import 'dc/midea_dc_device.dart';
import 'e1/midea_e1_device.dart';
import 'e2/midea_e2_device.dart';
import 'e3/midea_e3_device.dart';
import 'e6/midea_e6_device.dart';
import 'e8/midea_e8_device.dart';
import 'ea/midea_ea_device.dart';
import 'ec/midea_ec_device.dart';
import 'ed/midea_ed_device.dart';
import 'fa/midea_fa_device.dart';
import 'fb/midea_fb_device.dart';
import 'fc/midea_fc_device.dart';
import 'fd/midea_fd_device.dart';
import 'x13/midea_x13_device.dart';
import 'x26/midea_x26_device.dart';
import 'x34/midea_x34_device.dart';
import 'x40/midea_x40_device.dart';

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
    case DeviceType.a1:
      return MideaA1Device(
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
    case DeviceType.ad:
      return MideaADDevice(
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
    case DeviceType.b0:
      return MideaB0Device(
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
    case DeviceType.b1:
      return MideaB1Device(
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
    case DeviceType.b3:
      return MideaB3Device(
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
    case DeviceType.b4:
      return MideaB4Device(
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
    case DeviceType.b6:
      return MideaB6Device(
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
    case DeviceType.b8:
      return MideaB8Device(
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
    case DeviceType.bf:
      return MideaBFDevice(
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
    case DeviceType.c2:
      return MideaC2Device(
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
    case DeviceType.c3:
      return MideaC3Device(
        name: name,
        deviceId: deviceId,
        ipAddress: ipAddress,
        port: port,
        token: token,
        key: key,
        deviceProtocol: deviceProtocol,
        model: model,
        subtype: subtype,
        customize: customize ?? '',
      );
    case DeviceType.ca:
      return MideaCADevice(
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
    case DeviceType.cc:
      return MideaCCDevice(
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
    case DeviceType.cd:
      return MideaCDDevice(
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
    case DeviceType.ce:
      return MideaCEDevice(
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
    case DeviceType.cf:
      return MideaCFDevice(
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
    case DeviceType.da:
      return MideaDADevice(
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
    case DeviceType.dc:
      return MideaDCDevice(
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
    case DeviceType.e1:
      return MideaE1Device(
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
    case DeviceType.e2:
      return MideaE2Device(
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
    case DeviceType.e3:
      return MideaE3Device(
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
    case DeviceType.e6:
      return MideaE6Device(
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
    case DeviceType.e8:
      return MideaE8Device(
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
    case DeviceType.ea:
      return MideaEADevice(
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
    case DeviceType.ec:
      return MideaECDevice(
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
    case DeviceType.ed:
      return MideaEDDevice(
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
    case DeviceType.fa:
      return MideaFADevice(
        name: name,
        deviceId: deviceId,
        ipAddress: ipAddress,
        port: port,
        token: token,
        key: key,
        deviceProtocol: deviceProtocol,
        model: model,
        subtype: subtype,
        customize: customize ?? '',
      );
    case DeviceType.fb:
      return MideaFBDevice(
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
    case DeviceType.fc:
      return MideaFCDevice(
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
    case DeviceType.fd:
      return MideaFDDevice(
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
    case DeviceType.x13:
      return MideaX13Device(
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
    case DeviceType.x26:
      return Midea26Device(
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
    case DeviceType.x34:
      return Midea34Device(
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
    case DeviceType.x40:
      return MideaX40Device(
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
