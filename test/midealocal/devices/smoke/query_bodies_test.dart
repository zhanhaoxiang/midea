// Structural smoke tests for query message bodyType bytes.
// For each device: verify MessageQuery(1).body[0] == expected bodyType.
// No physical device needed – pure serialisation check.

import 'package:flutter_test/flutter_test.dart';

import 'package:midea/midealocal/devices/ad/message.dart' as msgAD;
import 'package:midea/midealocal/devices/b0/message.dart' as msgB0;
import 'package:midea/midealocal/devices/b1/message.dart' as msgB1;
import 'package:midea/midealocal/devices/b3/message.dart' as msgB3;
import 'package:midea/midealocal/devices/b4/message.dart' as msgB4;
import 'package:midea/midealocal/devices/b6/message.dart' as msgB6;
import 'package:midea/midealocal/devices/bf/message.dart' as msgBF;
import 'package:midea/midealocal/devices/c2/message.dart' as msgC2;
import 'package:midea/midealocal/devices/ca/message.dart' as msgCA;
import 'package:midea/midealocal/devices/cc/message.dart' as msgCC;
import 'package:midea/midealocal/devices/cd/message.dart' as msgCD;
import 'package:midea/midealocal/devices/ce/message.dart' as msgCE;
import 'package:midea/midealocal/devices/cf/message.dart' as msgCF;
import 'package:midea/midealocal/devices/da/message.dart' as msgDA;
import 'package:midea/midealocal/devices/dc/message.dart' as msgDC;
import 'package:midea/midealocal/devices/e1/message.dart' as msgE1;
import 'package:midea/midealocal/devices/e2/message.dart' as msgE2;
import 'package:midea/midealocal/devices/e3/message.dart' as msgE3;
import 'package:midea/midealocal/devices/e6/message.dart' as msgE6;
import 'package:midea/midealocal/devices/e8/message.dart' as msgE8;
import 'package:midea/midealocal/devices/ea/message.dart' as msgEA;
import 'package:midea/midealocal/devices/ec/message.dart' as msgEC;
import 'package:midea/midealocal/devices/fa/message.dart' as msgFA;
import 'package:midea/midealocal/devices/fb/message.dart' as msgFB;
import 'package:midea/midealocal/devices/fc/message.dart' as msgFC;
import 'package:midea/midealocal/devices/fd/message.dart' as msgFD;
import 'package:midea/midealocal/devices/x13/message.dart' as msgX13;
import 'package:midea/midealocal/devices/x26/message.dart' as msgX26;
import 'package:midea/midealocal/devices/x34/message.dart' as msgX34;

void main() {
  // AD: Message21Query bodyType=0x21, Message31Query bodyType=0x31
  group('AD query bodies', () {
    test('Message21Query body[0] == 0x21', () {
      final body = msgAD.Message21Query(1).body;
      expect(body[0], 0x21);
      expect(body.length, greaterThanOrEqualTo(2)); // bodyType + [0x01] + msgId + crc
    });
    test('Message31Query body[0] == 0x31', () {
      final body = msgAD.Message31Query(1).body;
      expect(body[0], 0x31);
      expect(body.length, greaterThanOrEqualTo(2));
    });
  });

  // B0: three query variants
  group('B0 query bodies', () {
    test('MessageQuery00 body[0] == 0x00', () {
      expect(msgB0.MessageQuery00(1).body[0], 0x00);
    });
    test('MessageQuery01 body[0] == 0x01', () {
      expect(msgB0.MessageQuery01(1).body[0], 0x01);
    });
    test('MessageQuery31 body[0] == 0x31', () {
      expect(msgB0.MessageQuery31(1).body[0], 0x31);
    });
  });

  // B1
  group('B1 query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgB1.MessageQuery(1).body[0], 0x00);
    });
  });

  // B3
  group('B3 query body', () {
    test('MessageQuery body[0] == 0x31', () {
      expect(msgB3.MessageQuery(1).body[0], 0x31);
    });
  });

  // B4
  group('B4 query body', () {
    test('MessageQuery body[0] == 0x01', () {
      expect(msgB4.MessageQuery(1).body[0], 0x01);
    });
  });

  // B6: v1 → bodyType=0x31; v2 → bodyType=0x11
  group('B6 query body', () {
    test('MessageQuery(v1) body[0] == 0x31', () {
      expect(msgB6.MessageQuery(1).body[0], 0x31);
    });
    test('MessageQuery(v2) body[0] == 0x11', () {
      expect(msgB6.MessageQuery(2).body[0], 0x11);
    });
  });

  // BF
  group('BF query body', () {
    test('MessageQuery body[0] == 0x01', () {
      expect(msgBF.MessageQuery(1).body[0], 0x01);
    });
  });

  // C2
  group('C2 query body', () {
    test('MessageQuery body[0] == 0x01 and body[1] == 0x01', () {
      final body = msgC2.MessageQuery(1).body;
      expect(body[0], 0x01);
      expect(body[1], 0x01);
    });
  });

  // CA
  group('CA query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgCA.MessageQuery(1).body[0], 0x00);
    });
  });

  // CC: buildBody returns 23 zeros → body length = 24
  group('CC query body', () {
    test('MessageQuery body[0] == 0x01 and length == 24', () {
      final body = msgCC.MessageQuery(1).body;
      expect(body[0], 0x01);
      expect(body.length, 24);
    });
  });

  // CD
  group('CD query body', () {
    test('MessageQuery body[0] == 0x01 and body[1] == 0x01', () {
      final body = msgCD.MessageQuery(1).body;
      expect(body[0], 0x01);
      expect(body[1], 0x01);
    });
  });

  // CE
  group('CE query body', () {
    test('MessageQuery body[0] == 0x01', () {
      expect(msgCE.MessageQuery(1).body[0], 0x01);
    });
  });

  // CF
  group('CF query body', () {
    test('MessageQuery body[0] == 0x01', () {
      expect(msgCF.MessageQuery(1).body[0], 0x01);
    });
  });

  // DA
  group('DA query body', () {
    test('MessageQuery body[0] == 0x03', () {
      expect(msgDA.MessageQuery(1).body[0], 0x03);
    });
  });

  // DC
  group('DC query body', () {
    test('MessageQuery body[0] == 0x03', () {
      expect(msgDC.MessageQuery(1).body[0], 0x03);
    });
  });

  // E1
  group('E1 query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgE1.MessageQuery(1).body[0], 0x00);
    });
  });

  // E2: buildBody returns [0x01] → body=[0x01, 0x01]
  group('E2 query body', () {
    test('MessageQuery body[0] == 0x01 and body[1] == 0x01', () {
      final body = msgE2.MessageQuery(1).body;
      expect(body[0], 0x01);
      expect(body[1], 0x01);
    });
  });

  // E3: buildBody returns [0x01] → body=[0x01, 0x01]
  group('E3 query body', () {
    test('MessageQuery body[0] == 0x01 and body[1] == 0x01', () {
      final body = msgE3.MessageQuery(1).body;
      expect(body[0], 0x01);
      expect(body[1], 0x01);
    });
  });

  // E6: buildBody returns [0x01, 0x01, ...28 zeros] → body[0]=0x00, length=31
  group('E6 query body', () {
    test('MessageQuery body[0] == 0x00 and length == 31', () {
      final body = msgE6.MessageQuery(1).body;
      expect(body[0], 0x00);
      expect(body.length, 31);
    });
  });

  // E8: buildBody returns [0x55, 0x00, 0x01, 0x00, 0x00] → body[0]=0x41
  group('E8 query body', () {
    test('MessageQuery body[0] == 0x41 and body[1] == 0x55', () {
      final body = msgE8.MessageQuery(1).body;
      expect(body[0], 0x41);
      expect(body[1], 0x55);
    });
  });

  // EA: MessageQuery overrides `get body` directly → [0xAA, 0x55, 0x01, 0x03, 0x00]
  group('EA query body', () {
    test('MessageQuery body == [0xAA, 0x55, 0x01, 0x03, 0x00]', () {
      expect(msgEA.MessageQuery(1).body, [0xAA, 0x55, 0x01, 0x03, 0x00]);
    });
  });

  // EC: bodyType=0x00, buildBody=[0xAA,0x55,...] → body[0]=0x00, length=11
  group('EC query body', () {
    test('MessageQuery body[0] == 0x00 and length == 11', () {
      final body = msgEC.MessageQuery(1).body;
      expect(body[0], 0x00);
      expect(body.length, 11);
    });
  });

  // FA
  group('FA query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgFA.MessageQuery(1).body[0], 0x00);
    });
  });

  // FB
  group('FB query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgFB.MessageQuery(1).body[0], 0x00);
    });
  });

  // FC: custom body with messageId+crc8 appended → body[0]=0x41, length=23
  group('FC query body', () {
    test('MessageQuery body[0] == 0x41 and length == 23', () {
      final body = msgFC.MessageQuery(1).body;
      expect(body[0], 0x41);
      expect(body.length, 23);
    });
  });

  // FD: custom body with messageId+crc8 appended → body[0]=0x41, length=22
  group('FD query body', () {
    test('MessageQuery body[0] == 0x41 and length == 22', () {
      final body = msgFD.MessageQuery(1).body;
      expect(body[0], 0x41);
      expect(body.length, 22);
    });
  });

  // X13: buildBody returns [0x00,0x00,0x00,0x00] → body[0]=0x24, length=5
  group('X13 query body', () {
    test('MessageQuery body[0] == 0x24 and length == 5', () {
      final body = msgX13.MessageQuery(1).body;
      expect(body[0], 0x24);
      expect(body.length, 5);
    });
  });

  // X26
  group('X26 query body', () {
    test('MessageQuery body[0] == 0x01', () {
      expect(msgX26.MessageQuery(1).body[0], 0x01);
    });
  });

  // X34
  group('X34 query body', () {
    test('MessageQuery body[0] == 0x00', () {
      expect(msgX34.MessageQuery(1).body[0], 0x00);
    });
  });
}
