import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/db/message.dart';

// Standard 10-byte header: query, DB device, proto v1.
final _header = Uint8List.fromList([
  0xAA, 0x00, 0xDB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03,
]);

// MessageResponse strips the last byte as checksum, so include a trailing 0x00
// to keep the full 31-byte body intact after extraction.
Uint8List _msg(Uint8List header, Uint8List body) =>
    Uint8List.fromList([...header, ...body, 0x00]);

// Build a 31-byte DB response body.
// MessageResponse will strip the trailing 0x00 checksum we add in _msg(),
// leaving 31 bytes so all indices 0..30 are accessible.
Uint8List _makeBody({
  int bodyType = 0x03,
  int power = 1,
  int status = 2,
  int mode = 3,
  int program = 4,
  int waterLevel = 5,
  int temperature = 6,
  int dehydrationSpeed = 7,
  int washTime = 8,
  int dehydrationTime = 9,
  int detergent = 10,
  int softener = 11,
  int progressByte = 0x04, // bit 2 set → progress = 3
  int timeRemLo = 15,
  int timeRemHi = 1,       // timeRemaining = 15 + (1 << 8) = 271
  int stains = 20,
  int washTimeValue = 30,
  int dehydrationTimeValue = 40,
  int dirtyDegree = 50,
}) {
  final b = Uint8List(31);
  b[0] = bodyType;
  b[1] = power;
  b[2] = status;
  b[3] = mode;
  b[4] = program;
  b[5] = waterLevel;
  b[7] = temperature;
  b[8] = dehydrationSpeed;
  b[9] = washTime;
  b[10] = dehydrationTime;
  b[11] = detergent;
  b[12] = softener;
  b[16] = progressByte;
  b[17] = timeRemLo;
  b[18] = timeRemHi;
  b[26] = stains;
  b[27] = washTimeValue;
  b[28] = dehydrationTimeValue;
  b[30] = dirtyDegree;
  return b;
}

void main() {
  // -------------------------------------------------------------------------
  // MessageQuery  –  body type 0x03, no payload
  // Python: query.body == bytearray([0x03])
  // -------------------------------------------------------------------------
  group('MessageQuery', () {
    test('body == [0x03]', () {
      final msg = MessageQuery(ProtocolVersion.v1.value);
      expect(msg.body, [0x03]);
    });
  });

  // -------------------------------------------------------------------------
  // MessagePower  –  body type 0x02 + 21-byte payload
  // Python: power.body == [0x02, 0x00, 0xFF*20]  (power=false)
  //         power.body == [0x02, 0x01, 0xFF*20]  (power=true)
  // -------------------------------------------------------------------------
  group('MessagePower', () {
    test('power=false body', () {
      final msg = MessagePower(ProtocolVersion.v1.value);
      expect(msg.body, [0x02, 0x00, ...List.filled(20, 0xFF)]);
    });

    test('power=true body', () {
      final msg = MessagePower(ProtocolVersion.v1.value)..power = true;
      expect(msg.body, [0x02, 0x01, ...List.filled(20, 0xFF)]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageStart  –  body type 0x02 + variable payload
  // Python: start.body == [0x02, 0xFF, 0x00]           (start=false)
  //         start.body == [0x02, 0xFF, 0x01] + washing_data
  // -------------------------------------------------------------------------
  group('MessageStart', () {
    test('start=false body', () {
      final msg = MessageStart(ProtocolVersion.v1.value);
      expect(msg.body, [0x02, 0xFF, 0x00]);
    });

    test('start=true with washing_data appended', () {
      final msg = MessageStart(ProtocolVersion.v1.value)
        ..start = true
        ..washingData = Uint8List.fromList([0x01, 0x02, 0x03]);
      expect(msg.body, [0x02, 0xFF, 0x01, 0x01, 0x02, 0x03]);
    });

    test('start=true empty washing_data', () {
      final msg = MessageStart(ProtocolVersion.v1.value)..start = true;
      expect(msg.body, [0x02, 0xFF, 0x01]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageDBResponse – response parsing
  // -------------------------------------------------------------------------
  group('MessageDBResponse', () {
    test('parses all attributes from a full response body', () {
      final r = MessageDBResponse(_msg(_header, _makeBody()));

      expect(r.power, true);
      expect(r.start, true);   // status=2 ∈ {2, 6}
      expect(r.status, 2);
      expect(r.mode, 3);
      expect(r.program, 4);
      expect(r.waterLevel, 5);
      expect(r.temperature, 6);
      expect(r.dehydrationSpeed, 7);
      expect(r.washTime, 8);
      expect(r.dehydrationTime, 9);
      expect(r.detergent, 10);
      expect(r.softener, 11);
      expect(r.progress, 3);      // bit 2 set → i=2 → progress=3
      expect(r.timeRemaining, 271); // 15 + (1 << 8) = 271
      expect(r.stains, 20);
      expect(r.washTimeValue, 30);
      expect(r.dehydrationTimeValue, 40);
      expect(r.dirtyDegree, 50);
    });

    test('power=false → timeRemaining is null', () {
      final r = MessageDBResponse(_msg(_header, _makeBody(power: 0)));
      expect(r.power, false);
      expect(r.timeRemaining, isNull);
    });

    test('status=6 → start=true; status=1 → start=false', () {
      expect(
        MessageDBResponse(_msg(_header, _makeBody(status: 6))).start,
        true,
      );
      expect(
        MessageDBResponse(_msg(_header, _makeBody(status: 1))).start,
        false,
      );
    });

    test('progress bit 0 → progress=1', () {
      final r = MessageDBResponse(_msg(_header, _makeBody(progressByte: 0x01)));
      expect(r.progress, 1);
    });

    test('progress=0 when no bits set', () {
      final r = MessageDBResponse(_msg(_header, _makeBody(progressByte: 0x00)));
      expect(r.progress, 0);
    });

    test('notify1 + bodyType 0x04 is parsed', () {
      final notify1Header = Uint8List.fromList([
        0xAA, 0x00, 0xDB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x04,
      ]);
      // bodyType must be 0x04 to satisfy the notify1 branch check.
      final r = MessageDBResponse(
        _msg(notify1Header, _makeBody(bodyType: 0x04, power: 4)),
      );
      expect(r.power, true); // power = 4 > 0
    });
  });
}
