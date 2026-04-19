import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/db/midea_db_device.dart';
import 'package:midea/midealocal/devices/db/message.dart';

void main() {
  group('MideaDBDevice', () {
    late MideaDBDevice device;

    setUp(() {
      device = MideaDBDevice(
        name: 'Test Device',
        deviceId: 1,
        ipAddress: '192.168.1.1',
        port: 12345,
        token: 'AA',
        key: 'BB',
        deviceProtocol: ProtocolVersion.v1,
        model: 'test_model',
        subtype: 1,
      );
    });

    test('test initial attributes', () {
      expect(device.attributes[DeviceAttributes.power], false);
      expect(device.attributes[DeviceAttributes.start], false);
      expect(device.attributes[DeviceAttributes.status], null);
    });

    test('test build query', () {
      final queries = device.buildQuery();
      expect(queries.length, 1);
      expect(queries[0] is MessageQuery, true);
    });
  });
}
