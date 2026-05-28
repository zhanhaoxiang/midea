import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/greelocal/gree_ac_device.dart';
import 'package:midea/greelocal/gree_crypto.dart';

void main() {
  group('ScanResult', () {
    test('stores Python-shaped fields', () {
      final result = ScanResult('192.168.1.2', 7000, 'abc', 'Bedroom', 'ECB');

      expect(result.ip, '192.168.1.2');
      expect(result.port, 7000);
      expect(result.id, 'abc');
      expect(result.name, 'Bedroom');
      expect(result.encryptionType, 'ECB');
    });
  });

  group('request helpers', () {
    test('createRequest builds ECB request exactly like Python', () {
      final request = createRequest('cid-1', 'encrypted-pack');

      expect(
        request,
        '{"cid":"app","i":0,"t":"pack","uid":0,"tcid":"cid-1","pack":"encrypted-pack"}',
      );
    });

    test('createStatusRequestPack uses the Python column order', () {
      expect(
        createStatusRequestPack('cid-1'),
        '{"cols":["Pow","Mod","SetTem","WdSpd","Air","Blo","Health","SwhSlp","Lig","SwingLfRig","SwUpDn","Quiet","Tur","StHt","TemUn","HeatCoolType","TemRec","SvSt"],"mac":"cid-1","t":"status"}',
      );
    });

    test('createRequest builds GCM request exactly like Python', () {
      final request = createRequest('cid-1', {
        'tag': 'tag-value',
        'pack': 'pack-value',
      });

      expect(
        request,
        '{"cid":"app","i":0,"t":"pack","uid":0,"tcid":"cid-1","tag":"tag-value","pack":"pack-value"}',
      );
    });
  });

  group('crypto helper parity', () {
    test('encryptGeneric and decryptGeneric round-trip text', () {
      final encrypted = encryptGeneric('{"t":"dev"}');
      final decrypted = decryptGeneric(encrypted);

      expect(decrypted, '{"t":"dev"}');
    });

    test('encryptGcmGeneric and decryptGcmGeneric round-trip text', () {
      final encrypted = encryptGcmGeneric('{"t":"dev"}');
      final decrypted = decryptGcmGeneric(
        encrypted['pack']!,
        encrypted['tag']!,
      );

      expect(decrypted, '{"t":"dev"}');
    });
  });

  group('scan parsing parity', () {
    Uint8List makeScanResponse({
      String? cid,
      String? outerCid,
      String? name = 'TestAC',
      String? ver,
    }) {
      final pack = jsonEncode({
        if (cid != null) 'cid': cid,
        if (name != null) 'name': name,
        't': 'dev',
        if (ver != null) 'ver': ver,
      });
      final encryptedPack = GreeCrypto.encryptGenericEcb(pack);
      return Uint8List.fromList(utf8.encode(jsonEncode({
        't': 'pack',
        if (outerCid != null) 'cid': outerCid,
        'pack': encryptedPack,
      })));
    }

    test('parseScanResponse applies Python fallback defaults', () {
      final result = parseScanResponse(
        '10.0.0.8',
        7000,
        makeScanResponse(name: null),
      );

      expect(result, isNotNull);
      expect(result!.id, '<unknown-cid>');
      expect(result.name, '<unknown>');
      expect(result.encryptionType, 'ECB');
    });
  });

  group('bind parity', () {
    Uint8List makeBindOkResponse(String key) {
      final encryptedPack = GreeCrypto.encryptGenericEcb(
        jsonEncode({'t': 'bindok', 'key': key}),
      );
      return Uint8List.fromList(
        utf8.encode(jsonEncode({'t': 'pack', 'pack': encryptedPack})),
      );
    }

    test('bindDevice always sends to port 7000', () async {
      final server = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        7000,
      );
      addTearDown(server.close);

      final requestSeen = Completer<String>();
      server.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        final datagram = server.receive();
        if (datagram == null) {
          return;
        }
        requestSeen.complete(utf8.decode(datagram.data));
        server.send(
          makeBindOkResponse('secret-key'),
          datagram.address,
          datagram.port,
        );
      });

      final result = ScanResult(
        InternetAddress.loopbackIPv4.address,
        7001,
        'aabbccddeeff',
        'Bedroom',
        'ECB',
      );

      final key = await bindDevice(result);

      expect(key, 'secret-key');
      expect(await requestSeen.future, contains('"tcid":"aabbccddeeff"'));
    });

    test('bindDevice keeps GCM after ECB timeout retry fails', () async {
      final result = ScanResult(
        InternetAddress.loopbackIPv4.address,
        7001,
        'aabbccddeeff',
        'Bedroom',
        'ECB',
      );

      final key = await bindDevice(result);

      expect(key, isNull);
      expect(result.encryptionType, 'GCM');
    });
  });

  group('status and command parity', () {
    Uint8List makeStatusResponse(String key) {
      final encryptedPack = GreeCrypto.encryptEcb(
        jsonEncode({
          'cols': ['Pow', 'Mod'],
          'dat': [1, 4],
        }),
        key,
      );
      return Uint8List.fromList(
        utf8.encode(jsonEncode({'t': 'pack', 'pack': encryptedPack})),
      );
    }

    test('getParam returns decrypted cols/dat pairs for ECB', () async {
      final server = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        7000,
      );
      addTearDown(server.close);

      server.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        final datagram = server.receive();
        if (datagram == null) {
          return;
        }
        server.send(
          makeStatusResponse('secret-key-12345'),
          datagram.address,
          datagram.port,
        );
      });

      encryptionType = 'ECB';
      final result = await getParam(
        client: InternetAddress.loopbackIPv4.address,
        id: 'cid-1',
        key: 'secret-key-12345',
        params: const ['Pow', 'Mod'],
      );

      expect(result, isNotNull);
      expect(result, {'Pow': 1, 'Mod': 4});
    });

    test('setParam rejects malformed key value pairs before sending', () async {
      await expectLater(
        () => setParam(
          client: '127.0.0.1',
          id: 'cid-1',
          key: 'secret-key-12345',
          params: const ['Pow'],
        ),
        throwsArgumentError,
      );
    });
  });
}
