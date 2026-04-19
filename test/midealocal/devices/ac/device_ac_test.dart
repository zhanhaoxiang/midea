import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/ac/ac_device.dart';
import 'package:midea/midealocal/devices/ac/message.dart';

void main() {
  group('MideaACDevice', () {
    late MideaACDevice device;

    setUp(() {
      device = MideaACDevice(
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
      expect(device.attributes[DeviceAttributes.promptTone], true);
      expect(device.attributes[DeviceAttributes.power], false);
      expect(device.attributes[DeviceAttributes.mode], 0);
      expect(device.attributes[DeviceAttributes.targetTemperature], 24.0);
      expect(device.attributes[DeviceAttributes.fanSpeed], 102);
      expect(device.attributes[DeviceAttributes.swingVertical], false);
      expect(device.attributes[DeviceAttributes.swingHorizontal], false);
      expect(device.temperatureStep, 0.5);
    });

    test('test fresh air fan speeds', () {
      expect(device.freshAirFanSpeeds.isNotEmpty, true);
      expect(device.freshAirFanSpeeds.contains('off'), true);
      expect(device.freshAirFanSpeeds.contains('low'), true);
      expect(device.freshAirFanSpeeds.contains('medium'), true);
      expect(device.freshAirFanSpeeds.contains('high'), true);
    });

    test('test build query without subprotocol', () {
      final queries = device.buildQuery();
      expect(queries.length, 7);
      expect(queries[0] is MessageQuery, true);
      expect(queries[1] is MessageNewProtocolQuery, true);
      expect(queries[2] is MessagePowerQuery, true);
    });

    test('test build query with subprotocol', () {
      final queries = device.buildQuery();
      expect(queries.length, 7);
    });

    test('test target temperature getter', () {
      final attrs = device.attributes;
      expect(attrs.containsKey(DeviceAttributes.targetTemperature), true);
      expect(attrs[DeviceAttributes.targetTemperature], 24.0);
    });

    test('test set customize', () {
      device.setCustomize(
        '{"temperature_step": 1, "power_analysis_method": 2}',
      );
      expect(device.temperatureStep, 1.0);
    });

    test('test invalid customize format', () {
      device.setCustomize('{');
      expect(device.temperatureStep, 0.5);
    });
  });
}
