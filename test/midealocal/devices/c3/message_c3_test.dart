import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/c3/message.dart';
import 'package:midea/midealocal/message.dart' show ListTypes;

// Mirrors tests/devices/c3/message_c3_test.py from midea-local.

// Build a full message: 10-byte header + body + trailing 0x00 (checksum).
// MessageResponse strips header[0..9] and the last byte, so the 'body'
// argument here is preserved intact as the extracted body.
Uint8List _msg({required int messageType, required List<int> body}) {
  return Uint8List.fromList([
    0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, messageType,
    ...body,
    0x00, // checksum (stripped by MessageResponse)
  ]);
}

void main() {
  // -------------------------------------------------------------------------
  // Query messages – body == [bodyType]
  // Python: msg.body == bytearray([0x01]), [0x09], [0x05], [0x07]
  // -------------------------------------------------------------------------
  group('MessageQueryBasic', () {
    test('body == [0x01]', () {
      expect(MessageQueryBasic(ProtocolVersion.v1.value).body, [0x01]);
    });
  });

  group('MessageQueryDisinfect', () {
    test('body == [0x09]', () {
      expect(MessageQueryDisinfect(ProtocolVersion.v1.value).body, [0x09]);
    });
  });

  group('MessageQuerySilence', () {
    test('body == [0x05]', () {
      expect(MessageQuerySilence(ProtocolVersion.v1.value).body, [0x05]);
    });
  });

  group('MessageQueryECO', () {
    test('body == [0x07]', () {
      expect(MessageQueryECO(ProtocolVersion.v1.value).body, [0x07]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageSet
  // Python: expected_body == [bodyType, power_byte, mode, z1, z2, dhw,
  //                           room*2, curve_byte]
  // -------------------------------------------------------------------------
  group('MessageSet', () {
    test('all flags set – exact bytes match Python', () {
      final msg = MessageSet(ProtocolVersion.v1.value)
        ..zone1Power = true
        ..zone2Power = true
        ..dhwPower = true
        ..mode = 2 // C3DeviceMode.COOL
        ..zoneTargetTemp = [23.0, 22.0]
        ..dhwTargetTemp = 45
        ..roomTargetTemp = 24.0
        ..zone1Curve = true
        ..zone2Curve = true
        ..tbh = true
        ..fastDhw = true;

      expect(msg.body, [
        0x01,              // bodyType
        0x01 | 0x02 | 0x04, // zone1+zone2+dhwPower = 0x07
        0x02,              // mode = COOL
        23,                // zone1TargetTemp
        22,                // zone2TargetTemp
        45,                // dhwTargetTemp
        24 * 2,            // roomTargetTemp * 2 = 48
        0x01 | 0x02 | 0x04 | 0x08, // zone1Curve|zone2Curve|tbh|fastDhw = 0x0F
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageSetSilent
  // Python tests all 4 state transitions.
  // -------------------------------------------------------------------------
  group('MessageSetSilent', () {
    final off = [0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    final silent = [0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    final superSilent = [0x05, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

    test('default (off)', () {
      expect(MessageSetSilent(ProtocolVersion.v1.value).body, off);
    });

    test('silentMode=true, level unset → still off', () {
      final msg = MessageSetSilent(ProtocolVersion.v1.value)..silentMode = true;
      expect(msg.body, off);
    });

    test('silentMode=true, level=silent', () {
      final msg = MessageSetSilent(ProtocolVersion.v1.value)
        ..silentMode = true
        ..silentLevel = C3SilentLevel.silent;
      expect(msg.body, silent);
    });

    test('silentMode=false, level=silent → off', () {
      final msg = MessageSetSilent(ProtocolVersion.v1.value)
        ..silentMode = false
        ..silentLevel = C3SilentLevel.silent;
      expect(msg.body, off);
    });

    test('silentMode=true, level=superSilent', () {
      final msg = MessageSetSilent(ProtocolVersion.v1.value)
        ..silentMode = true
        ..silentLevel = C3SilentLevel.superSilent;
      expect(msg.body, superSilent);
    });
  });

  // -------------------------------------------------------------------------
  // MessageSetECO
  // Python: expected_body_off  == [0x07] + [0x00]*6
  //         expected_body_eco  == [0x07, 0x01] + [0x00]*5
  // -------------------------------------------------------------------------
  group('MessageSetECO', () {
    test('eco=false', () {
      expect(
        MessageSetECO(ProtocolVersion.v1.value).body,
        [0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
      );
    });

    test('eco=true', () {
      final msg = MessageSetECO(ProtocolVersion.v1.value)..ecoMode = true;
      expect(msg.body, [0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageC3Response – generic response (bodyType 0x01)
  // Mirrors TestMessageC3Response.test_message_generic_response.
  // MessageC3Response calls body.sublist(1) before parsing, so the body bytes
  // in the message start at the bodyType byte (index 0 of the extracted body).
  // -------------------------------------------------------------------------
  group('MessageC3Response – generic x01', () {
    // The body layout (25 payload bytes + bodyType + CRC):
    //   byte  0: bodyType = 0x01
    //   byte  1: zone_power/curve/tbh flags
    //   byte  2: zoneTempType flags
    //   byte  3: silent/eco flags
    //   byte  4: mode (HEAT=3)
    //   byte  5: modeAuto (COOL=2)
    //   byte  6: zone1TargetTemp
    //   byte  7: zone2TargetTemp
    //   byte  8: dhwTargetTemp
    //   byte  9: roomTargetTemp * 2
    //   bytes 10-17: heating/cooling temp max/min for zone1+zone2
    //   byte 18: roomTempMax * 2
    //   byte 19: roomTempMin * 2
    //   byte 20: dhwTempMax
    //   byte 21: dhwTempMin
    //   byte 22: tankActualTemperature
    //   byte 23: errorCode
    //   byte 24: tbhControl flags
    final body = [
      0x01,             // bodyType
      0x01 | 0x04 | 0x08 | 0x20, // zone1Power + dhwPower + zone1Curve + tbh
      0x30,             // zoneTempType [true, true]
      0x02 | 0x08,      // silentMode + ecoMode
      3,                // mode = HEAT
      2,                // modeAuto = COOL
      21,               // zone1TargetTemp
      22,               // zone2TargetTemp
      42,               // dhwTargetTemp
      45,               // roomTargetTemp*2 → 22.5
      30,               // zone1HeatingTempMax
      20,               // zone1HeatingTempMin
      25,               // zone1CoolingTempMax
      16,               // zone1CoolingTempMin
      35,               // zone2HeatingTempMax
      20,               // zone2HeatingTempMin
      30,               // zone2CoolingTempMax
      18,               // zone2CoolingTempMin
      61,               // roomTempMax*2 → 30.5
      32,               // roomTempMin*2 → 16.0
      50,               // dhwTempMax
      34,               // dhwTempMin
      44,               // tankActualTemperature
      0x00,             // errorCode
      0x00,             // tbhControl flags
    ];

    for (final msgType in [0x02, 0x03, 0x04, 0x05]) {
      test('messageType=0x${msgType.toRadixString(16)} parses all attributes', () {
        final r = MessageC3Response(_msg(messageType: msgType, body: body));

        expect(r.zone1Power, true);
        expect(r.zone2Power, false);
        expect(r.dhwPower, true);
        expect(r.zone1Curve, true);
        expect(r.zone2Curve, false);
        expect(r.tbh, true);
        expect(r.fastDhw, false);
        expect(r.zoneTempType, [true, true]);
        expect(r.silentMode, true);
        expect(r.ecoMode, true);
        expect(r.mode, 3);   // HEAT
        expect(r.modeAuto, 2); // COOL
        expect(r.zoneTargetTemp, [21.0, 22.0]);
        expect(r.dhwTargetTemp, 42.0);
        expect(r.roomTargetTemp, 22.5); // 45/2
        expect(r.zoneHeatingTempMax, [30.0, 35.0]);
        expect(r.zoneHeatingTempMin, [20.0, 20.0]);
        expect(r.zoneCoolingTempMax, [25.0, 30.0]);
        expect(r.zoneCoolingTempMin, [16.0, 18.0]);
        expect(r.roomTempMax, 30.5); // 61/2
        expect(r.roomTempMin, 16.0); // 32/2
        expect(r.dhwTempMax, 50.0);
        expect(r.dhwTempMin, 34.0);
        expect(r.tankActualTemperature, 44.0);
        expect(r.errorCode, 0);
        expect(r.tbhControl, false);
      });
    }
  });

  // -------------------------------------------------------------------------
  // MessageC3Response – energy response (bodyType 0x04, notify1)
  // Mirrors TestMessageC3Response.test_message_notify1_x04_response.
  // -------------------------------------------------------------------------
  group('MessageC3Response – energy x04', () {
    final body = [
      ListTypes.x04,          // bodyType
      0x01 | 0x04,            // statusHeating + statusDhw
      0x32, 0x1A, 0xB3, 0xC2, // totalEnergyConsumption bytes
      21, 22, 42, 45,         // totalProducedEnergy bytes
      30,                     // outdoorTemperature
      40,                     // zone1TempSet
      50,                     // zone2TempSet
      45,                     // t5s
      55,                     // tas
    ];

    test('parses energy and status attributes', () {
      final r = MessageC3Response(_msg(messageType: 0x04, body: body));

      expect(r.statusHeating, true);
      expect(r.statusDhw, true);
      expect(r.statusTbh, false);
      expect(r.statusIbh, false);
      // (0x32<<32) + (0x1A<<16) + (0xB3<<8) + 0xC2 = 214750114754
      expect(r.totalEnergyConsumption, 214750114754);
      // (21<<32) + (22<<16) + (42<<8) + 45 = 90195765805
      expect(r.totalProducedEnergy, 90195765805);
      expect(r.outdoorTemperature, 30.0);
      expect(r.zone1TempSet, 40.0);
      expect(r.zone2TempSet, 50.0);
      expect(r.t5s, 45);
      expect(r.tas, 55);
    });

    test('outdoor temperature 253 → -3.0', () {
      final negBody = List<int>.from(body)..[10] = 253;
      final r = MessageC3Response(_msg(messageType: 0x04, body: negBody));
      expect(r.outdoorTemperature, -3.0);
    });
  });

  // -------------------------------------------------------------------------
  // MessageC3Response – silence response (bodyType 0x05, query)
  // Mirrors TestMessageC3Response.test_message_silence_response.
  // -------------------------------------------------------------------------
  group('MessageC3Response – silence x05', () {
    Uint8List _silenceMsg(int silenceByte) => _msg(
      messageType: 0x03,
      body: [0x05, silenceByte, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    );

    test('byte=0x00 → silentMode=false, level=off', () {
      final r = MessageC3Response(_silenceMsg(0x00));
      expect(r.silentMode, false);
      expect(r.silentLevel, C3SilentLevel.off.name);
    });

    test('byte=0x01 → silentMode=true, level=silent', () {
      final r = MessageC3Response(_silenceMsg(0x01));
      expect(r.silentMode, true);
      expect(r.silentLevel, C3SilentLevel.silent.name);
    });

    test('byte=0x08 → silentMode=false (bit0 unset), level=off', () {
      final r = MessageC3Response(_silenceMsg(0x08));
      expect(r.silentMode, false);
      expect(r.silentLevel, C3SilentLevel.off.name);
    });

    test('byte=0x09 → silentMode=true, level=superSilent', () {
      final r = MessageC3Response(_silenceMsg(0x09));
      expect(r.silentMode, true);
      expect(r.silentLevel, C3SilentLevel.superSilent.name);
    });
  });
}
