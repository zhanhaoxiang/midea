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
        NewProtocolTags;

void main() {
  group('MessageQuery', () {
    test('test query body', () {
      final msg = MessageQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body[0], 0x41);
      expect(body[1], 0x81);
    });
  });

  group('MessageCapabilitiesQuery', () {
    test('test capabilities query body', () {
      final msg = MessageCapabilitiesQuery(ProtocolVersion.v1.value, false);
      final body = msg.body;
      expect(body[0], 0xB5);
    });

    test('test capabilities query body additional', () {
      final msg = MessageCapabilitiesQuery(ProtocolVersion.v1.value, true);
      final body = msg.body;
      expect(body[0], 0xB5);
      expect(body[2], 0x01);
    });
  });

  group('MessagePowerQuery', () {
    test('test power query body', () {
      final msg = MessagePowerQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body[0], 0x41);
      expect(body[1], 0x21);
    });
  });

  group('MessageToggleDisplay', () {
    test('test toggle display body', () {
      final msg = MessageToggleDisplay(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.length >= 20, true);
      expect(body[1], 0x02);
    });

    test('test toggle display with prompt tone', () {
      final msg = MessageToggleDisplay(ProtocolVersion.v1.value)
        ..promptTone = true;
      final body = msg.body;
      expect(body.length >= 20, true);
      expect(body[1] & 0x40, 0x40);
    });
  });

  group('MessageNewProtocolQuery', () {
    test('test new protocol query body', () {
      final msg = MessageNewProtocolQuery(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body[0], 0xB1);
      expect(msg.buildBody().length, 17);
    });
  });

  group('MessageSubProtocol', () {
    test('test sub protocol body', () {
      final msg = MessageSubProtocolQuery(ProtocolVersion.v1.value, 0xAA);
      final body = msg.body;
      expect(body[0], 0xAA);
    });
  });

  group('MessageSubProtocolSet', () {
    test('test sub protocol set body default', () {
      final msg = MessageSubProtocolSet(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.isNotEmpty, true);
      expect(msg.power, false);
      expect(msg.targetTemperature, 20.0);
    });

    test('test sub protocol set body with values', () {
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

      expect(msg.power, true);
      expect(msg.targetTemperature, 24.0);
      expect(msg.fanSpeed, 90);
    });
  });

  group('MessageGeneralSet', () {
    test('test general set body', () {
      final msg = MessageGeneralSet(ProtocolVersion.v1.value);
      final body = msg.body;
      expect(body.isNotEmpty, true);
    });

    test('test general set body with values', () {
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
      expect(body[1] & 0x01, 0x01);
    });
  });
}
