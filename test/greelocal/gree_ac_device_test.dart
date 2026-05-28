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
      expect(result.encryption_type, 'ECB');
    });
  });

  group('request helpers', () {
    test('create_request builds ECB request exactly like Python', () {
      final request = create_request('cid-1', 'encrypted-pack');

      expect(
        request,
        '{"cid":"app","i":0,"t":"pack","uid":0,"tcid":"cid-1","pack":"encrypted-pack"}',
      );
    });

    test('create_status_request_pack uses the Python column order', () {
      expect(
        create_status_request_pack('cid-1'),
        '{"cols":["Pow","Mod","SetTem","WdSpd","Air","Blo","Health","SwhSlp","Lig","SwingLfRig","SwUpDn","Quiet","Tur","StHt","TemUn","HeatCoolType","TemRec","SvSt"],"mac":"cid-1","t":"status"}',
      );
    });

    test('create_request builds GCM request exactly like Python', () {
      final request = create_request('cid-1', {
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
    test('encrypt_generic and decrypt_generic round-trip text', () {
      final encrypted = encrypt_generic('{"t":"dev"}');
      final decrypted = decrypt_generic(encrypted);

      expect(decrypted, '{"t":"dev"}');
    });

    test('encrypt_GCM_generic and decrypt_GCM_generic round-trip text', () {
      final encrypted = encrypt_GCM_generic('{"t":"dev"}');
      final decrypted = decrypt_GCM_generic(
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

    test('parse_scan_response applies Python fallback defaults', () {
      final result = parse_scan_response(
        '10.0.0.8',
        7000,
        makeScanResponse(name: null),
      );

      expect(result, isNotNull);
      expect(result!.id, '<unknown-cid>');
      expect(result.name, '<unknown>');
      expect(result.encryption_type, 'ECB');
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

    test('bind_device always sends to port 7000', () async {
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

      final key = await bind_device(result);

      expect(key, 'secret-key');
      expect(await requestSeen.future, contains('"tcid":"aabbccddeeff"'));
    });

    test('bind_device keeps GCM after ECB timeout retry fails', () async {
      final result = ScanResult(
        InternetAddress.loopbackIPv4.address,
        7001,
        'aabbccddeeff',
        'Bedroom',
        'ECB',
      );

      final key = await bind_device(result);

      expect(key, isNull);
      expect(result.encryption_type, 'GCM');
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

    test('get_param returns decrypted cols/dat pairs for ECB', () async {
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

      ENCRYPTION_TYPE = 'ECB';
      final result = await get_param(
        client: InternetAddress.loopbackIPv4.address,
        id: 'cid-1',
        key: 'secret-key-12345',
        params: const ['Pow', 'Mod'],
      );

      expect(result, isNotNull);
      expect(result, {'Pow': 1, 'Mod': 4});
    });

    test('set_param rejects malformed key value pairs before sending', () async {
      await expectLater(
        () => set_param(
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
