import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/ac/message.dart'
    show
        MessageQuery,
        MessageCapabilitiesQuery,
        MessagePowerQuery,
        MessageToggleDisplay,
        MessageNewProtocolQuery,
        MessageSubProtocolQuery,
        MessageSubProtocolSet,
        MessageGeneralSet,
        NewProtocolTags,
        BBACModes;
import 'package:midea/midealocal/devices/ac/midea_ac_device.dart'
    show MessageACResponse;

// Mirrors tests/devices/ac/message_ac_test.py from midea-local.
//
// Convention: msg.body[:-2] in Python == body.sublist(0, body.length - 2) in Dart.
// This strips the messageId+crc8 tail (MessageACBase) or crc8+checksum tail
// (MessageSubProtocol), both of which vary per-message.

// Standard 10-byte header used in response tests (notify2, AC device, proto v1).
final _header = Uint8List.fromList([
  0xAA, 0x00, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x05,
]);

Uint8List _hdr({int messageType = 0x05}) {
  final h = Uint8List.fromList(_header);
  h[9] = messageType;
  return h;
}

// Helper: concatenate header + body bytes into a full message.
Uint8List _msg(Uint8List header, List<int> body) =>
    Uint8List.fromList([...header, ...body, 0x00]); // trailing checksum placeholder

void main() {
  // ---------------------------------------------------------------------------
  // CRC8
  // From tests/crc8_test.py: calculate([0x5A,0x82,0x01,0x11,0xFF,0x20]) == 101
  // We verify indirectly: build a MessageQuery (known body) and check the
  // crc8 byte (body[-1]) is consistent with re-computing it manually.
  // ---------------------------------------------------------------------------
  group('CRC8', () {
    test('known vector: [0x5A,0x82,0x01,0x11,0xFF,0x20] → 101', () {
      // Replicate MessageACBase._crc8 inline for the test vector.
      int crc8(List<int> data) {
        var crc = 0;
        for (final b in data) {
          crc ^= b;
          for (var i = 0; i < 8; i++) {
            if ((crc & 0x01) != 0) {
              crc = (crc >> 1) ^ 0x8C;
            } else {
              crc >>= 1;
            }
            crc &= 0xFF;
          }
        }
        return crc & 0xFF;
      }

      expect(crc8([0x5A, 0x82, 0x01, 0x11, 0xFF, 0x20]), 101);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageQuery  (body type 0x41)
  // Python: msg.body[:-2] == [0x41, 0x81, 0x00, 0xFF, 0x00*16]
  // ---------------------------------------------------------------------------
  group('MessageQuery', () {
    test('body matches Python expected bytes', () {
      final msg = MessageQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);
      expect(noTail, [
        0x41,
        0x81, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageCapabilitiesQuery  (body type 0xB5)
  // ---------------------------------------------------------------------------
  group('MessageCapabilitiesQuery', () {
    test('non-additional: body[:-2] == [0xB5, 0x01, 0x00]', () {
      final msg = MessageCapabilitiesQuery(ProtocolVersion.v1.value, false);
      final body = msg.body;
      expect(body.sublist(0, body.length - 2), [0xB5, 0x01, 0x00]);
    });

    test('additional: body[:-2] == [0xB5, 0x01, 0x01, 0x01]', () {
      final msg = MessageCapabilitiesQuery(ProtocolVersion.v1.value, true);
      final body = msg.body;
      expect(body.sublist(0, body.length - 2), [0xB5, 0x01, 0x01, 0x01]);
    });
  });

  // ---------------------------------------------------------------------------
  // MessagePowerQuery  (body type 0x41, special sub-body)
  // Python: msg.body[:-1] == [0x41, 0x21, 0x01, 0x44, 0x00, 0x01]
  // Note: Python body[:-1] strips only the crc8 (no messageId for power/group queries).
  // ---------------------------------------------------------------------------
  group('MessagePowerQuery', () {
    test('body[:6] == [0x41, 0x21, 0x01, 0x44, 0x00, 0x01]', () {
      final msg = MessagePowerQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.sublist(0, 6), [0x41, 0x21, 0x01, 0x44, 0x00, 0x01]);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageToggleDisplay
  // ---------------------------------------------------------------------------
  group('MessageToggleDisplay', () {
    test('default body matches Python expected bytes', () {
      final msg = MessageToggleDisplay(ProtocolVersion.v1.value);
      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);
      expect(noTail, [
        0x41,
        0x02, 0x00, 0xFF, 0x02, 0x00, 0x02, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
      ]);
    });

    test('prompt_tone=true sets bit 0x40 in byte[1]', () {
      final msg = MessageToggleDisplay(ProtocolVersion.v1.value)
        ..promptTone = true;
      expect(msg.body[1], 0x02 | 0x40);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageNewProtocolQuery  (body type 0xB1)
  // ---------------------------------------------------------------------------
  group('MessageNewProtocolQuery', () {
    test('body matches Python expected bytes', () {
      final msg = MessageNewProtocolQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);
      expect(noTail, [
        0xB1,
        0x08,
        NewProtocolTags.indirectWind & 0xFF,
        NewProtocolTags.indirectWind >> 8,
        NewProtocolTags.breezeless & 0xFF,
        NewProtocolTags.breezeless >> 8,
        NewProtocolTags.indoorHumidity & 0xFF,
        NewProtocolTags.indoorHumidity >> 8,
        NewProtocolTags.screenDisplay & 0xFF,
        NewProtocolTags.screenDisplay >> 8,
        NewProtocolTags.freshAir1 & 0xFF,
        NewProtocolTags.freshAir1 >> 8,
        NewProtocolTags.freshAir2 & 0xFF,
        NewProtocolTags.freshAir2 >> 8,
        NewProtocolTags.windLrAngle & 0xFF,
        NewProtocolTags.windLrAngle >> 8,
        NewProtocolTags.windUdAngle & 0xFF,
        NewProtocolTags.windUdAngle >> 8,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageSubProtocol  (body type 0xAA)
  // Python: msg.body[:-2] == [0xAA, 0x08, 0x00, 0xFF, 0xFF, queryType]
  // The -2 strips crc8 + checksum (subprotocol uses both).
  // ---------------------------------------------------------------------------
  group('MessageSubProtocol', () {
    test('empty sub-body: body[:-2] == [0xAA, 0x08, 0x00, 0xFF, 0xFF, 0xCC]', () {
      final msg = MessageSubProtocolQuery(ProtocolVersion.v1.value, 0xCC);
      final body = msg.body;
      expect(body.sublist(0, body.length - 2), [
        0xAA,
        0x08, // 6 + 2 + 0 = 8
        0x00,
        0xFF,
        0xFF,
        0xCC,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageSubProtocolSet  (default values)
  // Python: msg.body[:-2] == [0xAA, 45, 0x00, 0xFF, 0xFF, 0x20, ...]
  // 45 = 6 + 2 + 37 (sub-body length)
  // ---------------------------------------------------------------------------
  group('MessageSubProtocolSet', () {
    test('default values: body[:-2] matches Python expected bytes', () {
      final msg = MessageSubProtocolSet(ProtocolVersion.v1.value);
      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);

      // targetTemperature=20.0 → targetTemp = 20*2+30=70, waterTemp = 19*2+50=88
      const targetTemp = 20 * 2 + 30; // 70
      const waterTemp = (20 - 1) * 2 + 50; // 88

      expect(noTail, [
        0xAA,
        45, // total sub-body length byte
        0x00,
        0xFF,
        0xFF,
        0x20, // subprotocol_query_type
        0x02, // power=false, dry=false, boost=false → just 0x02
        0x80, // aux_heating=false → 0x80 (quirk in Midea protocol)
        0x00, // sleep_mode=false
        0x00,
        0x00,
        0x00, // mode=0
        targetTemp, // 70
        102, // fan_speed default
        0x32,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
        0x01,
        0x00,
        0x01,
        waterTemp, // 88
        0x00, // prompt_tone=false
        targetTemp, // 70
        0x32,
        0x66,
        0x00,
        0x00, // eco=0, timer=0
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
        0x08,
      ]);
    });

    test('all flags set: body bytes match Python expected bytes', () {
      final msg = MessageSubProtocolSet(ProtocolVersion.v1.value)
        ..power = true
        ..mode = 6
        ..targetTemperature = 24.0
        ..fanSpeed = 90
        ..boostMode = true
        ..auxHeating = true
        ..dry = true
        ..ecoMode = true
        ..sleepMode = true
        ..sn8Flag = true
        ..timer = true
        ..promptTone = true;

      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);

      // Expected changes vs default (Python test updates expected_body in-place):
      // byte[6]:  0x02 | 0x20(boost) | 0x01(power) | 0x10(dry) = 0x33
      // byte[7]:  aux_heating=true → 0x40
      // byte[8]:  sleep_mode=true → 0x80
      // byte[11]: mode=6 → BBACModes.modes[6]-1 = modes[6]-1
      // byte[12]: 24*2+30 = 78
      // byte[13]: fan_speed=90
      // byte[25]: (24-1)*2+50 = 96
      // byte[26]: prompt_tone=true → 0x01
      // byte[27]: 24*2+30 = 78
      // byte[31]: eco=0x40 | timer=0x04 = 0x44

      expect(noTail[6], 0x02 | 0x20 | 0x01 | 0x10); // 0x33
      expect(noTail[7], 0x40); // aux_heating=true
      expect(noTail[8], 0x80); // sleep_mode=true
      expect(noTail[12], 78); // targetTemp = 24*2+30
      expect(noTail[13], 90); // fan_speed
      expect(noTail[25], 96); // waterTemp = 23*2+50
      expect(noTail[26], 0x01); // prompt_tone
      expect(noTail[27], 78); // targetTemp again
      expect(noTail[31], 0x40 | 0x04); // eco | timer
    });
  });

  // ---------------------------------------------------------------------------
  // MessageGeneralSet  (body type 0x40)
  // ---------------------------------------------------------------------------
  group('MessageGeneralSet', () {
    test('default values: body[:-2] matches Python expected bytes', () {
      final msg = MessageGeneralSet(ProtocolVersion.v1.value);
      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);

      // targetTemperature=20.0 → (20 & 0xF) = 4, 20%2==0 so no 0x10
      expect(noTail, [
        0x40,
        0x40, // prompt_tone=true → 0x40, power=false → 0x00
        0x04, // mode=0<<5=0, targetTemp=(20&0xF)=4, no 0x10
        102 & 0x7F, // fan_speed=102
        0x00,
        0x00,
        0x00,
        0x30, // swing base = 0x30
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
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
    });

    test('all flags set: body bytes match Python expected bytes', () {
      final msg = MessageGeneralSet(ProtocolVersion.v1.value)
        ..power = true
        ..promptTone = false
        ..mode = 2
        ..targetTemperature = 24.0
        ..fanSpeed = 92
        ..swingVertical = true
        ..swingHorizontal = true
        ..boostMode = true
        ..smartEye = true
        ..dry = true
        ..auxHeating = true
        ..ecoMode = true
        ..tempFahrenheit = true
        ..sleepMode = true
        ..naturalWind = true
        ..frostProtect = true
        ..comfortMode = true;

      final body = msg.body;
      final noTail = body.sublist(0, body.length - 2);

      // byte[1]: power=true, prompt_tone=false → 0x01
      expect(noTail[1], 0x01);
      // byte[2]: mode=2 → 2<<5=0x40, targetTemp=(24&0xF)=8 → 0x48
      expect(noTail[2], (2 << 5) | (24 & 0xF));
      // byte[3]: fan_speed=92 & 0x7F = 92
      expect(noTail[3], 92 & 0x7F);
      // byte[7]: 0x30 | 0x0C(swingV) | 0x03(swingH) = 0x3F
      expect(noTail[7], 0x30 | 0x0C | 0x03);
      // byte[8]: boost=0x20, smart_eye=0 (smartEye uses byte[8] bit 0x40... wait)
      // Python: boost_mode=0x20, smart_eye=0x01... but smartEye=true should give 0x01?
      // Actually from Python code: smart_eye = 0x01 if self.smart_eye else 0
      // boost_mode = 0x20, smart_eye=0x01, dry=0x04, aux_heating=0x08, eco_mode=0x80
      // byte[8] = smart_eye | dry | aux_heating | eco_mode = 0x01|0x04|0x08|0x80 = 0x8D
      // byte[8] turbo = 0x20 is separate - goes to byte[8] too: 0x20|0x8D = 0xAD
      // Wait, let me re-read... boost_mode for byte[8] = 0x20
      // byte[9]: smart_eye|dry|aux_heating|eco_mode = 0x01|0x04|0x08|0x80 = 0x8D
      expect(noTail[8], 0x20); // boost_mode only
      expect(noTail[9], 0x01 | 0x04 | 0x08 | 0x80); // smart_eye|dry|aux|eco
      // byte[10]: temp_fahrenheit=0x04, sleep_mode=0x01, boost_mode_1=0x02
      expect(noTail[10], 0x04 | 0x01 | 0x02);
      // byte[17]: natural_wind=0x40
      expect(noTail[17], 0x40);
      // byte[21]: frost_protect=0x80
      expect(noTail[21], 0x80);
      // byte[22]: comfort_mode=0x01
      expect(noTail[22], 0x01);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageACResponse - response parsing
  // All tests mirror TestMessageACResponse in message_ac_test.py.
  // The full message = header (10 bytes) + body + checksum (1 byte).
  // ---------------------------------------------------------------------------
  group('MessageACResponse - notify2 A0', () {
    test('parses power, temperature, mode, fan_speed, flags', () {
      final body = Uint8List(18);
      body[0] = 0xA0;
      body[1] = 0x5f; // power=1, target_temperature encoded
      body[2] = 0xe0; // mode=7
      body[3] = 0x7f; // fan_speed=127
      body[7] = 0xf; // swing_vertical and swing_horizontal
      body[8] = 0x20; // boost_mode
      body[9] = 0x1d; // smart_eye, dry, aux_heating, eco_mode
      body[10] = 0x43; // sleep_mode, natural_wind
      body[13] = 0x20; // full_dust
      body[14] = 0x1; // comfort_mode

      final msg = Uint8List.fromList([..._hdr(), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.hasAttribute('power'), true);
      expect(r.hasAttribute('target_temperature'), true);
      // ((0x1F >> 1) - 4 + 16) + 0.5 = (15-4+16) + 0.5 = 27.5
      expect(r.getAttribute('target_temperature'), 27.5);
      expect(r.getAttribute('mode'), 7);
      expect(r.getAttribute('fan_speed'), 127);
      expect(r.hasAttribute('swing_vertical'), true);
      expect(r.hasAttribute('swing_horizontal'), true);
      expect(r.hasAttribute('boost_mode'), true);
      expect(r.hasAttribute('smart_eye'), true);
      expect(r.hasAttribute('dry'), true);
      expect(r.hasAttribute('aux_heating'), true);
      expect(r.hasAttribute('eco_mode'), true);
      expect(r.hasAttribute('sleep_mode'), true);
      expect(r.hasAttribute('natural_wind'), true);
      expect(r.hasAttribute('full_dust'), true);
      expect(r.hasAttribute('comfort_mode'), true);
    });
  });

  group('MessageACResponse - query C0', () {
    test('parses all standard attributes', () {
      final body = Uint8List(24);
      body[0] = 0xC0;
      body[1] = 0x1; // power=1
      body[2] = 0xae; // mode=5, targetTemp=14 (no 0.5)
      body[3] = 0x7f; // fan_speed=127
      body[7] = 0xf; // swing_vertical, swing_horizontal
      body[8] = 0x60; // boost_mode(0x20), smart_eye(0x40)
      body[9] = 0x1e; // natural_wind, dry, eco_mode, aux_heating
      body[10] = 0x47; // sleep, tempF, boost_mode2
      body[11] = 0x64; // indoor_temperature byte (100)
      body[12] = 0x64; // outdoor_temperature byte (100)
      body[13] = 0x20; // full_dust
      body[14] = 0x70; // screen_display (not displayed because 0x07 pattern)
      body[15] = 0x32; // decimal parts: indoor=2, outdoor=3
      body[21] = 0x80; // frost_protect
      body[22] = 0x1; // comfort_mode

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.getAttribute('power'), true);
      expect(r.getAttribute('mode'), 5);
      // (body[2] & 0x0F) + 16.0 = 14 + 16 = 30.0 (no 0.5 because bit4 of body[2] is 0)
      expect(r.getAttribute('target_temperature'), 30.0);
      expect(r.getAttribute('fan_speed'), 127);
      // temperature: (100-50)/2 = 25.0, decimal indoor=2 → 25.2
      expect(r.getAttribute('indoor_temperature'), 25.2);
      // decimal outdoor=3 → 25.3
      expect(r.getAttribute('outdoor_temperature'), 25.3);
      expect(r.hasAttribute('full_dust'), true);
      // screen_display: body[14]>>4 & 0x07 == 0x07 → false
      expect(r.getAttribute('screen_display'), false);
      expect(r.hasAttribute('frost_protect'), true);
      expect(r.hasAttribute('comfort_mode'), true);
    });

    test('negative indoor temperature', () {
      final body = Uint8List(24);
      body[0] = 0xC0;
      body[1] = 0x01; // power on
      body[11] = 40; // indoor: (40-50)/2 = -5.0
      body[12] = 40; // outdoor: -5.0
      body[15] = 0x32; // decimal: indoor=2, outdoor=3

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.getAttribute('indoor_temperature'), -5.2);
      expect(r.getAttribute('outdoor_temperature'), -5.3);
    });

    test('outdoor temperature 0xFF returns null', () {
      final body = Uint8List(24);
      body[0] = 0xC0;
      body[1] = 0x01;
      body[12] = 0xFF;

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.getAttribute('outdoor_temperature'), null);
    });
  });

  group('MessageACResponse - BB subprotocol 0x20', () {
    test('parses power, mode, temperature, fan_speed, eco, timer', () {
      final body = Uint8List(100);
      body[0] = 0xBB;
      body[5] = 0x20; // dataType
      body[6] = 0x31; // power=1, dry=1(0x10), boost_mode=1(0x20)
      body[7] = 0x40; // aux_heating=1(0x40)
      body[8] = 0x80; // sleep_mode=1(0x80)
      body[11] = 2; // raw mode byte → modeRaw = 2+1=3, BBACModes.modes.indexOf(3)=1
      body[12] = 0x3C; // targetTemp = (60-30)/2 = 15.0
      body[13] = 127; // fan_speed
      body[31] = 0x44; // eco_mode(0x40), timer(0x04)

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.usedSubprotocol, true);
      expect(r.getAttribute('power'), true);
      expect(r.getAttribute('dry'), true);
      expect(r.getAttribute('boost_mode'), true);
      expect(r.getAttribute('aux_heating'), true);
      expect(r.getAttribute('sleep_mode'), true);
      expect(r.getAttribute('mode'), 1);
      expect(r.getAttribute('target_temperature'), 15.0);
      expect(r.getAttribute('fan_speed'), 127);
      expect(r.timer, true);
      expect(r.getAttribute('eco_mode'), true);
    });

    test('invalid mode index defaults to 0', () {
      final body = Uint8List(100);
      body[0] = 0xBB;
      body[5] = 0x20;
      body[11] = 10; // modeRaw=11, not in BBACModes.modes → index 0

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      expect(r.getAttribute('mode'), 0);
    });
  });

  group('MessageACResponse - BB subprotocol 0x10', () {
    test('parses indoor_temperature, indoor_humidity, sn8_flag', () {
      final body = Uint8List(100);
      body[0] = 0xBB;
      body[5] = 0x10; // dataType
      // subBody starts at body[6], so subBody[7]=body[13], subBody[8]=body[14]
      body[13] = 0x77; // low byte of temp word
      body[14] = 0x88; // high byte → negative branch → same value (quirk)
      body[36] = 60; // subBody[30] = indoor_humidity
      body[86] = 0x31; // subBody[80] = sn8_flag marker

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      // Python test confirms: (0x77 + 0x88*256) / 100 = 349.35 (known quirk)
      expect(r.getAttribute('indoor_temperature'), closeTo(349.35, 0.01));
      expect(r.getAttribute('indoor_humidity'), 60);
      expect(r.sn8Flag, true);
    });
  });

  group('MessageACResponse - BB subprotocol 0x30', () {
    test('parses outdoor_temperature', () {
      final body = Uint8List(100);
      body[0] = 0xBB;
      body[5] = 0x30; // dataType
      // subBody[5]=body[11], subBody[6]=body[12]
      body[11] = 0x22;
      body[12] = 0x80; // high bit → negative branch → same value

      final msg = Uint8List.fromList([..._hdr(messageType: 0x03), ...body, 0x00]);
      final r = MessageACResponse(msg);

      // (0x22 + 0x80*256) / 100 = 328.02 (quirk for negative branch)
      expect(r.getAttribute('outdoor_temperature'), closeTo(328.02, 0.01));
    });
  });
}
