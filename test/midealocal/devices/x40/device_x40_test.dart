import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/x40/midea_x40_device.dart';

// Build a minimal X40 response message that MessageX40Response can parse.
// Header: 10 bytes (messageType=query=0x03, deviceType=0x40).
// Body:   47 bytes (bodyType=0x01 at index 0, rest set to specific values).
// Checksum: 1 trailing byte (stripped by MessageResponse).
Uint8List _x40Msg({int currentTemperature = 53}) {
  final body = Uint8List(47);
  body[0] = 0x01;              // bodyType must be 0x01 for MessageX40Body to parse
  body[1] = 0x01;              // light=true (>0)
  body[18] = 0x01;             // ventilation=true
  body[26] = 0x01;             // blow=true
  body[27] = 15;               // blowSpeed ≤ 30 → fanSpeed=1
  body[28] = 90;               // direction raw
  body[33] = currentTemperature;
  body[45] = 1;                // smellySensor
  return Uint8List.fromList([
    0xAA, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03,
    ...body,
    0x00,  // checksum (stripped)
  ]);
}

MideaX40Device _makeDevice() => MideaX40Device(
  name: 'Test',
  deviceId: 1,
  ipAddress: '192.168.1.1',
  port: 6444,
  token: 'AA',
  key: 'BB',
  deviceProtocol: ProtocolVersion.v3,
  model: 'test_model',
  subtype: 1,
);

void main() {
  // -------------------------------------------------------------------------
  // setCustomize – precision_halves flag
  // Mirrors TestMideaX40Device.test_customize.
  // -------------------------------------------------------------------------
  group('MideaX40Device setCustomize', () {
    test('precision_halves defaults to false', () {
      final device = _makeDevice();
      expect(device.precisionHalves, false);
    });

    test('{"precision_halves": true} sets flag', () {
      final device = _makeDevice();
      device.setCustomize('{"precision_halves": true}');
      expect(device.precisionHalves, true);
    });

    test('invalid JSON resets precision_halves to false', () {
      final device = _makeDevice()..setCustomize('{"precision_halves": true}');
      device.setCustomize('{');
      expect(device.precisionHalves, false);
    });
  });

  // -------------------------------------------------------------------------
  // processMessage – currentTemperature with and without precision_halves
  // -------------------------------------------------------------------------
  group('MideaX40Device processMessage currentTemperature', () {
    test('precision_halves=false → temperature = raw value (53)', () {
      final device = _makeDevice();
      final newStatus = device.processMessage(_x40Msg(currentTemperature: 53));
      expect(newStatus[DeviceAttributes.currentTemperature], 53);
    });

    test('precision_halves=true → temperature = raw / 2 (26.5)', () {
      final device = _makeDevice();
      device.setCustomize('{"precision_halves": true}');
      final newStatus = device.processMessage(_x40Msg(currentTemperature: 53));
      expect(newStatus[DeviceAttributes.currentTemperature], 26.5);
    });
  });
}
