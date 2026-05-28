import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/greelocal/gree_ac_device.dart';
import 'package:midea/greelocal/gree_crypto.dart';

void main() {
  // -------------------------------------------------------------------------
  group('GreeParameter', () {
    test('all contains 18 parameters', () {
      expect(GreeParameter.all.length, 18);
    });

    test('all contains the expected keys', () {
      for (final key in [
        GreeParameter.power,
        GreeParameter.mode,
        GreeParameter.temperature,
        GreeParameter.fanSpeed,
        GreeParameter.health,
        GreeParameter.sleep,
        GreeParameter.light,
        GreeParameter.turbo,
        GreeParameter.quiet,
        GreeParameter.energySaving,
      ]) {
        expect(GreeParameter.all, contains(key));
      }
    });
  });

  // -------------------------------------------------------------------------
  group('GreeMode', () {
    test('enum values are correctly numbered', () {
      expect(GreeMode.auto.value, 0);
      expect(GreeMode.cool.value, 1);
      expect(GreeMode.dry.value, 2);
      expect(GreeMode.fan.value, 3);
      expect(GreeMode.heat.value, 4);
    });

    test('fromValue resolves known values', () {
      expect(GreeMode.fromValue(0), GreeMode.auto);
      expect(GreeMode.fromValue(1), GreeMode.cool);
      expect(GreeMode.fromValue(2), GreeMode.dry);
      expect(GreeMode.fromValue(3), GreeMode.fan);
      expect(GreeMode.fromValue(4), GreeMode.heat);
    });

    test('fromValue defaults to auto for unknown values', () {
      expect(GreeMode.fromValue(99), GreeMode.auto);
      expect(GreeMode.fromValue(-1), GreeMode.auto);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeFanSpeed', () {
    test('enum values are correctly numbered', () {
      expect(GreeFanSpeed.auto.value, 0);
      expect(GreeFanSpeed.low.value, 1);
      expect(GreeFanSpeed.medLow.value, 2);
      expect(GreeFanSpeed.medium.value, 3);
      expect(GreeFanSpeed.medHigh.value, 4);
      expect(GreeFanSpeed.high.value, 5);
    });

    test('fromValue resolves known values', () {
      expect(GreeFanSpeed.fromValue(0), GreeFanSpeed.auto);
      expect(GreeFanSpeed.fromValue(5), GreeFanSpeed.high);
    });

    test('fromValue defaults to auto for unknown values', () {
      expect(GreeFanSpeed.fromValue(99), GreeFanSpeed.auto);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeTemperatureUnit', () {
    test('enum values are correctly numbered', () {
      expect(GreeTemperatureUnit.celsius.value, 0);
      expect(GreeTemperatureUnit.fahrenheit.value, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeDeviceStatus.fromRaw', () {
    test('parses a typical device response', () {
      final raw = {
        'Pow': 1, 'Mod': 1, 'SetTem': 26, 'WdSpd': 2,
        'Air': 0, 'Blo': 0, 'Health': 1, 'SwhSlp': 0,
        'Lig': 1, 'SwingLfRig': 0, 'SwUpDn': 1,
        'Quiet': 0, 'Tur': 0, 'StHt': 0, 'TemUn': 0,
        'HeatCoolType': 0, 'TemRec': 0, 'SvSt': 1,
      };

      final status = GreeDeviceStatus.fromRaw(raw);

      expect(status.power, true);
      expect(status.mode, GreeMode.cool);
      expect(status.temperature, 26);
      expect(status.fanSpeed, GreeFanSpeed.medLow);
      expect(status.health, true);
      expect(status.light, true);
      expect(status.verticalSwing, 1);
      expect(status.energySaving, true);
      expect(status.temperatureUnit, GreeTemperatureUnit.celsius);
    });

    test('all-zero raw produces off/default status', () {
      final status = GreeDeviceStatus.fromRaw({
        for (final key in GreeParameter.all) key: 0,
      });

      expect(status.power, false);
      expect(status.mode, GreeMode.auto);
      expect(status.fanSpeed, GreeFanSpeed.auto);
      expect(status.health, false);
      expect(status.turbo, false);
      expect(status.temperatureUnit, GreeTemperatureUnit.celsius);
    });

    test('empty map uses sensible defaults', () {
      final status = GreeDeviceStatus.fromRaw({});
      expect(status.power, false);
      expect(status.mode, GreeMode.auto);
      expect(status.temperature, 24);
      expect(status.fanSpeed, GreeFanSpeed.auto);
    });

    test('Fahrenheit temperature unit is detected', () {
      final status = GreeDeviceStatus.fromRaw({'TemUn': 1});
      expect(status.temperatureUnit, GreeTemperatureUnit.fahrenheit);
    });

    test('all boolean flags detected correctly', () {
      final raw = {
        'Pow': 1, 'Air': 1, 'Blo': 1, 'Health': 1,
        'SwhSlp': 1, 'Lig': 1, 'Quiet': 1, 'Tur': 1,
        'StHt': 1, 'SvSt': 1,
      };
      final status = GreeDeviceStatus.fromRaw(raw);
      expect(status.power, true);
      expect(status.freshAir, true);
      expect(status.xfan, true);
      expect(status.health, true);
      expect(status.sleep, true);
      expect(status.light, true);
      expect(status.quiet, true);
      expect(status.turbo, true);
      expect(status.antiFreeze, true);
      expect(status.energySaving, true);
    });

    test('toString returns a non-empty string', () {
      final status = GreeDeviceStatus.fromRaw({'Pow': 1});
      expect(status.toString().isNotEmpty, true);
    });

    test('heat mode is parsed correctly', () {
      final status = GreeDeviceStatus.fromRaw({'Mod': 4});
      expect(status.mode, GreeMode.heat);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeAcDevice construction', () {
    late GreeAcDevice device;

    setUp(() {
      device = GreeAcDevice(
        ip: '192.168.1.100',
        port: 7000,
        deviceId: 'aabbccddeeff',
        name: 'Living Room AC',
        encryptionType: GreeEncryptionType.ecb,
        deviceKey: 'testKey1234567',
      );
    });

    test('fields are set from constructor', () {
      expect(device.ip, '192.168.1.100');
      expect(device.port, 7000);
      expect(device.deviceId, 'aabbccddeeff');
      expect(device.name, 'Living Room AC');
      expect(device.encryptionType, GreeEncryptionType.ecb);
      expect(device.deviceKey, 'testKey1234567');
    });

    test('isBound is true when deviceKey is set', () {
      expect(device.isBound, true);
    });

    test('isBound is false when deviceKey is null', () {
      final unbound = GreeAcDevice(
        ip: '192.168.1.1',
        port: 7000,
        deviceId: 'abc',
      );
      expect(unbound.isBound, false);
    });

    test('default encryption type is ECB', () {
      final d = GreeAcDevice(ip: '1.2.3.4', port: 7000, deviceId: 'x');
      expect(d.encryptionType, GreeEncryptionType.ecb);
    });

    test('toString contains ip and deviceId', () {
      final s = device.toString();
      expect(s.contains('192.168.1.100'), true);
      expect(s.contains('aabbccddeeff'), true);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeAcDevice.parseScanResponse', () {
    // Build a scan response the same way a real Gree device would.
    Uint8List _makeScanResponse({
      required String cid,
      String name = 'TestAC',
      String? ver,
    }) {
      final innerMap = {
        'cid': cid,
        'name': name,
        't': 'dev',
        if (ver != null) 'ver': ver,
      };
      final pack = jsonEncode(innerMap);
      final encryptedPack = GreeCrypto.encryptGenericEcb(pack);
      final outer = jsonEncode({'t': 'pack', 'cid': cid, 'pack': encryptedPack});
      return Uint8List.fromList(utf8.encode(outer));
    }

    test('returns null for empty data', () {
      expect(GreeAcDevice.parseScanResponse('1.2.3.4', 7000, Uint8List(0)), null);
    });

    test('returns null for garbage data', () {
      final garbage = Uint8List.fromList([0x01, 0x02, 0x03]);
      expect(GreeAcDevice.parseScanResponse('1.2.3.4', 7000, garbage), null);
    });

    test('parses a well-formed ECB scan response', () {
      final data = _makeScanResponse(cid: 'aabbccddeeff', name: 'BedroomAC');
      final device = GreeAcDevice.parseScanResponse('192.168.0.5', 7000, data);

      expect(device, isNotNull);
      expect(device!.ip, '192.168.0.5');
      expect(device.deviceId, 'aabbccddeeff');
      expect(device.name, 'BedroomAC');
      expect(device.encryptionType, GreeEncryptionType.ecb);
      expect(device.isBound, false);
    });

    test('upgrades encryption to GCM for firmware version >= 2', () {
      final data = _makeScanResponse(cid: 'aabbccddeeff', ver: 'V2.0.1');
      final device = GreeAcDevice.parseScanResponse('10.0.0.1', 7000, data);

      expect(device, isNotNull);
      expect(device!.encryptionType, GreeEncryptionType.gcm);
    });

    test('keeps ECB for firmware version < 2', () {
      final data = _makeScanResponse(cid: 'aabbccddeeff', ver: 'V1.9.0');
      final device = GreeAcDevice.parseScanResponse('10.0.0.1', 7000, data);

      expect(device, isNotNull);
      expect(device!.encryptionType, GreeEncryptionType.ecb);
    });
  });

  // -------------------------------------------------------------------------
  group('GreeAcDevice unbound returns false', () {
    late GreeAcDevice unbound;

    setUp(() {
      unbound = GreeAcDevice(ip: '192.168.1.1', port: 7000, deviceId: 'x');
    });

    test('setParameters returns false when not bound', () async {
      final result = await unbound.setParameters({'Pow': 1});
      expect(result, false);
    });

    test('getRawStatus returns null when not bound', () async {
      final result = await unbound.getRawStatus();
      expect(result, null);
    });

    test('getStatus returns null when not bound', () async {
      final result = await unbound.getStatus();
      expect(result, null);
    });

    test('setPower returns false when not bound', () async {
      expect(await unbound.setPower(true), false);
    });

    test('setMode returns false when not bound', () async {
      expect(await unbound.setMode(GreeMode.cool), false);
    });

    test('setTemperature returns false when not bound', () async {
      expect(await unbound.setTemperature(24), false);
    });

    test('setFanSpeed returns false when not bound', () async {
      expect(await unbound.setFanSpeed(GreeFanSpeed.low), false);
    });
  });
}
