import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/a1/message.dart';

// Build a full message: 10-byte header + body_data + no extra byte.
// Python test passes header(10) + body(21) = 31 bytes.
// MessageResponse strips last byte: body = message.sublist(10, 30) = 20 bytes.
Uint8List _msg({
  required int messageType,
  required List<int> body,
}) => Uint8List.fromList([
  0xAA, 0x00, 0xA1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, messageType,
  ...body,
]);

void main() {
  // -------------------------------------------------------------------------
  // MessageQuery – body[:-2] (strip trailing messageId + CRC)
  // Python: expected_body = bytearray([0x41, 0x81, 0x00, 0xFF, 0x00 * 16])
  // -------------------------------------------------------------------------
  group('MessageQuery', () {
    test('body without messageId+CRC matches Python expected', () {
      final msg = MessageQuery(ProtocolVersion.v1.value);
      final bodyNoTrail = msg.body.sublist(0, msg.body.length - 2);
      expect(bodyNoTrail, [
        0x41,  // bodyType
        0x81, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageSet – body[:-2] with default field values
  // Python: expected_body = [0x48, 0x02, mode=1, fan=40, 0,0,0,
  //                          humidity=40, 0,0,0,0,0, waterLevel=50,
  //                          0,0,0,0,0,0,0]
  // -------------------------------------------------------------------------
  group('MessageSet', () {
    test('default body without messageId+CRC matches Python expected', () {
      final msg = MessageSet(ProtocolVersion.v1.value);
      final bodyNoTrail = msg.body.sublist(0, msg.body.length - 2);
      expect(bodyNoTrail, [
        0x48,  // bodyType
        0x02,  // power=false | promptTone=false | 0x02
        1,     // mode
        40,    // fanSpeed
        0, 0, 0,
        40,    // targetHumidity
        0,     // childLock=false
        0,     // anion=false
        0,     // swing=false
        0, 0,
        50,    // waterLevelSet
        0, 0, 0, 0, 0, 0, 0,
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageA1Response – general query response
  // Mirrors TestMessageA1Response.test_a1_general_response.
  // Python body is 21 bytes; last byte acts as checksum (stripped by
  // MessageResponse). Extracted body = 20 bytes (indices 0..19).
  // -------------------------------------------------------------------------
  group('MessageA1Response – general query', () {
    test('parses all attributes', () {
      final body = List<int>.filled(21, 0);
      body[1] = 0x01;   // power bit
      body[2] = 0x02;   // mode
      body[3] = 0x04;   // fanSpeed raw=4; < 5 → 1
      body[7] = 40;     // targetHumidity
      body[8] = 0x80;   // childLock bit7
      body[9] = 0x40;   // anion bit6
      body[10] = 0x3F;  // tank = 63
      body[15] = 50;    // waterLevelSet
      body[16] = 45;    // currentHumidity
      body[17] = 100;   // (100-50)/2 = 25.0
      body[19] = 0x20;  // swing bit5

      final r = MessageA1Response(_msg(messageType: 0x03, body: body));

      expect(r.power, true);
      expect(r.mode, 2);
      expect(r.fanSpeed, 1);    // 4 < minFanSpeed(5) → 1
      expect(r.targetHumidity, 40);
      expect(r.childLock, true);
      expect(r.anion, true);
      expect(r.tank, 63);
      expect(r.waterLevelSet, 50);
      expect(r.currentHumidity, 45);
      expect(r.currentTemperature, 25.0);
      expect(r.swing, true);
    });
  });

  // -------------------------------------------------------------------------
  // MessageA1Response – notify1 (bodyType 0xA0)
  // Mirrors TestMessageA1Response.test_a1_general_notify_response.
  // fanSpeed=6 is ≥ minFanSpeed(5) so it stays 6.
  // -------------------------------------------------------------------------
  group('MessageA1Response – notify1', () {
    test('parses fan_speed=6 correctly', () {
      final body = List<int>.filled(21, 0);
      body[0] = 0xA0;   // bodyType (ignored by A1GeneralMessageBody)
      body[1] = 0x01;   // power
      body[2] = 0x02;   // mode
      body[3] = 0x06;   // fanSpeed raw=6; ≥ 5 → stays 6
      body[7] = 40;
      body[8] = 0x80;   // childLock
      body[9] = 0x40;   // anion
      body[10] = 0x3F;  // tank = 63
      body[15] = 50;
      body[16] = 45;
      body[17] = 100;
      body[19] = 0x20;  // swing

      final r = MessageA1Response(_msg(messageType: 0x04, body: body));

      expect(r.mode, 2);
      expect(r.fanSpeed, 6);
      expect(r.tank, 63);
      expect(r.currentTemperature, 25.0);
      expect(r.swing, true);
    });
  });
}
