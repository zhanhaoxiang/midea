import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/greelocal/gree_crypto.dart';

void main() {
  group('GreeCrypto ECB', () {
    const key = 'a3K8Bx%2r8Y7#xDh';
    const pack = '{"mac":"aabbccddeeff","t":"bind","uid":0}';

    test('encrypt/decrypt round-trip with explicit key', () {
      final encrypted = GreeCrypto.encryptEcb(pack, key);
      expect(GreeCrypto.decryptEcb(encrypted, key), pack);
    });

    test('encrypt produces valid base64', () {
      final encrypted = GreeCrypto.encryptGenericEcb(pack);
      expect(() => base64.decode(encrypted), returnsNormally);
    });

    test('generic encrypt/decrypt round-trip', () {
      final encrypted = GreeCrypto.encryptGenericEcb(pack);
      expect(GreeCrypto.decryptGenericEcb(encrypted), pack);
    });

    test('ciphertext length is a multiple of 16 bytes', () {
      final encrypted = GreeCrypto.encryptGenericEcb(pack);
      expect(base64.decode(encrypted).length % 16, 0);
    });

    test('different plaintext produces different ciphertext', () {
      final a = GreeCrypto.encryptGenericEcb('{"t":"cmd1"}');
      final b = GreeCrypto.encryptGenericEcb('{"t":"cmd2"}');
      expect(a, isNot(equals(b)));
    });

    test('round-trip with minimal JSON', () {
      const minimal = '{}';
      final encrypted = GreeCrypto.encryptEcb(minimal, key);
      expect(GreeCrypto.decryptEcb(encrypted, key), minimal);
    });

    test('round-trip with status-style JSON', () {
      const status =
          '{"cols":["Pow","Mod"],"mac":"aabbccddeeff","t":"status"}';
      final encrypted = GreeCrypto.encryptEcb(status, key);
      expect(GreeCrypto.decryptEcb(encrypted, key), status);
    });
  });

  group('GreeCrypto GCM', () {
    const key = '{yxAHAY_Lm6pbC/<';
    const pack = '{"mac":"aabbccddeeff","t":"bind","uid":0}';

    test('encrypt returns non-empty pack and tag', () {
      final encrypted = GreeCrypto.encryptGcm(pack, key);
      expect(encrypted.pack.isNotEmpty, true);
      expect(encrypted.tag.isNotEmpty, true);
    });

    test('tag decodes to exactly 16 bytes', () {
      final encrypted = GreeCrypto.encryptGenericGcm(pack);
      final tagBytes = base64.decode(encrypted.tag);
      expect(tagBytes.length, 16);
    });

    test('encrypt/decrypt round-trip with explicit key', () {
      final encrypted = GreeCrypto.encryptGcm(pack, key);
      final decrypted = GreeCrypto.decryptGcm(encrypted.pack, encrypted.tag, key);
      expect(decrypted, pack);
    });

    test('generic encrypt/decrypt round-trip', () {
      final encrypted = GreeCrypto.encryptGenericGcm(pack);
      expect(GreeCrypto.decryptGenericGcm(encrypted.pack, encrypted.tag), pack);
    });

    test('different plaintext produces different pack', () {
      final a = GreeCrypto.encryptGenericGcm('{"t":"cmd1"}');
      final b = GreeCrypto.encryptGenericGcm('{"t":"cmd2"}');
      expect(a.pack, isNot(equals(b.pack)));
    });

    test('tampered tag causes InvalidCipherTextException', () {
      final encrypted = GreeCrypto.encryptGenericGcm(pack);
      final badTag = base64.encode(Uint8List(16)); // all-zero tag
      expect(
        () => GreeCrypto.decryptGenericGcm(encrypted.pack, badTag),
        throwsA(anything),
      );
    });

    test('round-trip with cmd-style JSON', () {
      const cmd = '{"opt":["Pow"],"p":[1],"t":"cmd"}';
      final encrypted = GreeCrypto.encryptGcm(cmd, key);
      expect(GreeCrypto.decryptGcm(encrypted.pack, encrypted.tag, key), cmd);
    });
  });
}
