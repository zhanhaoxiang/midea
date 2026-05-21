import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/ed/message.dart';

// 10-byte header used by the response tests.
// device type byte (index 2) is 0xDA — matches midea-local Python tests.
// messageType byte (index 9) is 0x03 = query.
final _header = Uint8List.fromList([
  0xAA, 0x00, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03,
]);

// Appends a trailing 0x00 (checksum) so MessageResponse's strip
// of the last byte leaves the body intact.
Uint8List _msg(Uint8List header, List<int> body) =>
    Uint8List.fromList([...header, ...body, 0x00]);

// The FF body used by both the body-class test and the response test.
// 27 bytes — indices 0..26 after MessageResponse strips the trailing checksum.
final _ffBody = [
  0xFF,  // body_type
  0x01,
  0x07,  // category
  0x00,  // part 1 attr bit1
  0x40,  // part 1 attr bit2 + length
  0x00,
  0x00,
  0x01,  // child_lock
  0x01,  // power
  0x10,  // part 2 attr bit1
  0x40,  // part 2 attr bit2 + length
  0x01,  // life1
  0x02,  // life2
  0x03,  // life3
  0x00,
  0x11,  // part 3 attr bit1
  0x40,  // part 3 attr bit2 + length
  0x01,  // water_consumption byte1
  0x02,  // water_consumption byte2
  0x03,  // water_consumption byte3
  0x04,  // water_consumption byte4
  0x13,  // part 4 attr bit1
  0x40,  // part 4 attr bit2 + length
  0x04,  // in_tds byte1
  0x03,  // in_tds byte2
  0x02,  // out_tds byte1
  0x01,  // out_tds byte2
];

void main() {
  // -------------------------------------------------------------------------
  // Query messages – body == [bodyType, 0x01]
  // Python: expected_body = bytearray([bodyType, 0x01])
  // -------------------------------------------------------------------------
  group('MessageQuery', () {
    test('body == [0x00, 0x01]', () {
      expect(MessageQuery(ProtocolVersion.v1.value).body, [0x00, 0x01]);
    });
  });

  group('MessageQuery01', () {
    test('body == [0x01, 0x01]', () {
      expect(MessageQuery01(ProtocolVersion.v1.value).body, [0x01, 0x01]);
    });
  });

  group('MessageQuery03', () {
    test('body == [0x03, 0x01]', () {
      expect(MessageQuery03(ProtocolVersion.v1.value).body, [0x03, 0x01]);
    });
  });

  group('MessageQuery04', () {
    test('body == [0x04, 0x01]', () {
      expect(MessageQuery04(ProtocolVersion.v1.value).body, [0x04, 0x01]);
    });
  });

  group('MessageQuery05', () {
    test('body == [0x05, 0x01]', () {
      expect(MessageQuery05(ProtocolVersion.v1.value).body, [0x05, 0x01]);
    });
  });

  group('MessageQuery06', () {
    test('body == [0x06, 0x01]', () {
      expect(MessageQuery06(ProtocolVersion.v1.value).body, [0x06, 0x01]);
    });
  });

  group('MessageQuery07', () {
    test('body == [0x07, 0x01]', () {
      expect(MessageQuery07(ProtocolVersion.v1.value).body, [0x07, 0x01]);
    });
  });

  group('MessageQueryFF', () {
    test('body == [0xFF, 0x01]', () {
      expect(MessageQueryFF(ProtocolVersion.v1.value).body, [0xFF, 0x01]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageNewSet – variable-length body depending on set fields
  // Python: expected_body = bytearray([0x15, 0x01, 0x00])         (default)
  //         expected_body = bytearray([0x15, 0x01, 0x01, ...])    (power=true)
  //         etc.
  // -------------------------------------------------------------------------
  group('MessageNewSet', () {
    test('default body', () {
      expect(
        MessageNewSet(ProtocolVersion.v1.value).body,
        [0x15, 0x01, 0x00],
      );
    });

    test('power=true body', () {
      final msg = MessageNewSet(ProtocolVersion.v1.value)..power = true;
      expect(msg.body, [0x15, 0x01, 0x01, 0x00, 0x01, 0x01, 0x00, 0x00]);
    });

    test('power=true, lock=true body', () {
      final msg = MessageNewSet(ProtocolVersion.v1.value)
        ..power = true
        ..lock = true;
      expect(msg.body, [
        0x15, 0x01, 0x02,
        0x00, 0x01, 0x01, 0x00, 0x00,  // power pack
        0x01, 0x02, 0x01, 0x00, 0x00,  // lock pack
      ]);
    });

    test('power=null, lock=true body', () {
      final msg = MessageNewSet(ProtocolVersion.v1.value)..lock = true;
      expect(msg.body, [0x15, 0x01, 0x01, 0x01, 0x02, 0x01, 0x00, 0x00]);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBody01 – 40-byte body, bodyType=0x01
  // Python: water_consumption=770, in_tds=1284, out_tds=1798,
  //         filter1=54, filter2=64, filter3=75, life1=2, life2=3, life3=4
  // -------------------------------------------------------------------------
  group('EDMessageBody01', () {
    test('parses all attributes', () {
      final b = Uint8List(40);
      b[0] = 0x01;  // bodyType
      b[2] = 1;     // power
      b[7] = 2;     // waterConsumption lo
      b[8] = 3;     // waterConsumption hi  → 2 + (3<<8) = 770
      b[36] = 4;    // inTds lo
      b[37] = 5;    // inTds hi            → 4 + (5<<8) = 1284
      b[38] = 6;    // outTds lo
      b[39] = 7;    // outTds hi           → 6 + (7<<8) = 1798
      b[15] = 7;    // childLock (>0)
      b[25] = 4;    // filter1 lo
      b[26] = 5;    // filter1 hi          → (4+1280)/24 ≈ 53.5 → 54
      b[27] = 5;    // filter2 lo
      b[28] = 6;    // filter2 hi          → (5+1536)/24 ≈ 64.2 → 64
      b[29] = 6;    // filter3 lo
      b[30] = 7;    // filter3 hi          → (6+1792)/24 ≈ 74.9 → 75
      b[16] = 2;    // life1
      b[17] = 3;    // life2
      b[18] = 4;    // life3

      final body = EDMessageBody01(b);
      expect(body.power, true);
      expect(body.waterConsumption, 770);
      expect(body.inTds, 1284);
      expect(body.outTds, 1798);
      expect(body.childLock, true);
      expect(body.filter1, 54);
      expect(body.filter2, 64);
      expect(body.filter3, 75);
      expect(body.life1, 2);
      expect(body.life2, 3);
      expect(body.life3, 4);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBody03 – 52-byte body, bodyType=0x03
  // -------------------------------------------------------------------------
  group('EDMessageBody03', () {
    test('parses all attributes', () {
      final b = Uint8List(52);
      b[0] = 0x03;  // bodyType
      b[51] = 1;    // power (bit0) → power=true, childLock=false
      b[20] = 2;    // waterConsumption lo
      b[21] = 3;    // waterConsumption hi  → 2+(3<<8) = 770
      b[27] = 4;    // inTds lo
      b[28] = 5;    // inTds hi             → 4+(5<<8) = 1284
      b[29] = 6;    // outTds lo
      b[30] = 7;    // outTds hi            → 6+(7<<8) = 1798
      b[22] = 2;    // life1
      b[23] = 3;    // life2
      b[24] = 4;    // life3

      final body = EDMessageBody03(b);
      expect(body.power, true);
      expect(body.childLock, false);
      expect(body.waterConsumption, 770);
      expect(body.inTds, 1284);
      expect(body.outTds, 1798);
      expect(body.life1, 2);
      expect(body.life2, 3);
      expect(body.life3, 4);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBody05 – 52-byte body, bodyType=0x05
  // -------------------------------------------------------------------------
  group('EDMessageBody05', () {
    test('parses power, childLock, waterConsumption', () {
      final b = Uint8List(52);
      b[0] = 0x05;
      b[51] = 1;    // power=true, childLock=false
      b[20] = 2;
      b[21] = 3;    // waterConsumption = 770

      final body = EDMessageBody05(b);
      expect(body.power, true);
      expect(body.childLock, false);
      expect(body.waterConsumption, 770);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBody06 – 52-byte body, bodyType=0x06
  // -------------------------------------------------------------------------
  group('EDMessageBody06', () {
    test('parses power, childLock, waterConsumption', () {
      final b = Uint8List(52);
      b[0] = 0x06;
      b[51] = 1;    // power=true
      b[25] = 2;
      b[26] = 3;    // waterConsumption = 770

      final body = EDMessageBody06(b);
      expect(body.power, true);
      expect(body.childLock, false);
      expect(body.waterConsumption, 770);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBody07 – 52-byte body, bodyType=0x07
  // -------------------------------------------------------------------------
  group('EDMessageBody07', () {
    test('parses power, childLock, waterConsumption', () {
      final b = Uint8List(52);
      b[0] = 0x07;
      b[51] = 1;    // power=true
      b[20] = 2;
      b[21] = 3;    // waterConsumption = 770

      final body = EDMessageBody07(b);
      expect(body.power, true);
      expect(body.childLock, false);
      expect(body.waterConsumption, 770);
    });
  });

  // -------------------------------------------------------------------------
  // EDMessageBodyFF – variable-length TLV body, bodyType=0xFF
  // Python: water_consumption=67305.985, in_tds=772, out_tds=258
  // Note: in Dart waterConsumption is stored as double in the body class.
  // -------------------------------------------------------------------------
  group('EDMessageBodyFF', () {
    test('parses all TLV attributes', () {
      final body = EDMessageBodyFF(Uint8List.fromList(_ffBody));
      expect(body.power, true);
      expect(body.childLock, true);
      expect(body.waterConsumption, closeTo(67305.985, 0.001));
      expect(body.inTds, 772);
      expect(body.outTds, 258);
      expect(body.life1, 1);
      expect(body.life2, 2);
      expect(body.life3, 3);
    });
  });

  // -------------------------------------------------------------------------
  // MessageEDResponse – full message (header + FF body + checksum)
  // Mirrors TestMessageEDResponse.test_ed_general_response.
  // Note: waterConsumption is converted to int (67305) by _assignAttrsFF.
  // -------------------------------------------------------------------------
  group('MessageEDResponse', () {
    test('FF body: parses all attributes', () {
      final r = MessageEDResponse(_msg(_header, _ffBody));

      expect(r.power, true);
      expect(r.childLock, true);
      expect(r.waterConsumption, 67305);
      expect(r.inTds, 772);
      expect(r.outTds, 258);
      expect(r.life1, 1);
      expect(r.life2, 2);
      expect(r.life3, 3);
    });
  });
}
