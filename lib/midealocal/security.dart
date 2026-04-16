/// Midea local security. Mirrors midealocal/security.py (LocalSecurity only).

import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// Handles local (LAN) encryption/decryption for the Midea protocol.
class LocalSecurity {
  LocalSecurity() {
    // Key: bytes.fromhex(format(141661095494369103254425781617665632877, "x"))
    _aesKey = _hexToBytes('6a92ef406bad2f0359baad994171ea6d');
    // Salt for encode32: bytes.fromhex(format(...long number..., "x"))
    _salt = _hexToBytes(
      '78686469776a6e6368656b6434643531326368646a783564386534633339344432443753',
    );
    _iv = Uint8List(16); // all zeros
  }

  late final Uint8List _aesKey;
  late final Uint8List _salt; // ignore: unused_field
  late final Uint8List _iv; // ignore: unused_field

  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// Decrypt AES-128 ECB with PKCS7 unpadding. Returns empty on failure.
  Uint8List aesDecrypt(Uint8List raw) {
    try {
      final key = enc.Key(_aesKey);
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.ecb),
      );
      final decrypted = encrypter.decryptBytes(enc.Encrypted(raw));
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// Encrypt AES-128 ECB with PKCS7 padding.
  Uint8List aesEncrypt(Uint8List raw) {
    final key = enc.Key(_aesKey);
    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.ecb),
    );
    return Uint8List.fromList(
      encrypter.encryptBytes(raw).bytes,
    );
  }
}
