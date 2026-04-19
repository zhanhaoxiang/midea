import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/db/message.dart';

void main() {
  group('MessageQuery', () {
    test('test query body', () {
      final msg = MessageQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body[0], 3);
    });
  });

  group('MessagePower', () {
    test('test power body off', () {
      final msg = MessagePower(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.length >= 1, true);
    });

    test('test power body on', () {
      final msg = MessagePower(ProtocolVersion.v1.value)..power = true;
      final body = msg.body;
      expect(body.length >= 1, true);
    });
  });

  group('MessageStart', () {
    test('test start body off', () {
      final msg = MessageStart(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.length >= 2, true);
    });

    test('test start body on', () {
      final msg = MessageStart(ProtocolVersion.v1.value)..start = true;
      final body = msg.body;
      expect(body.length >= 2, true);
    });
  });

  group('MessageDBResponse', () {
    test('test response parsing', () {
      final header = Uint8List.fromList([
        0xAA,
        0x00,
        0xDB,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
        0x03,
      ]);
      final body = Uint8List.fromList([
        0x03,
        0x01,
        0x02,
        0x00,
        0x01,
        0x02,
        0x00,
        0x03,
        0x04,
        0x05,
        0x06,
        0x01,
        0x02,
        0x03,
        0x04,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x03,
        0x10,
        0x20,
        0x00,
      ]);
      final msg = MessageDBResponse(Uint8List.fromList([...header, ...body]));
      expect(msg.power, true);
      expect(msg.status, 2);
    });
  });
}
