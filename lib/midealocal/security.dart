/// Midea local security. Mirrors midealocal/security.py.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

// ---------------------------------------------------------------------------
// Cloud security classes (mirror of CloudSecurity / MeijuCloudSecurity in
// midealocal/security.py).
// ---------------------------------------------------------------------------

/// Base cloud security: signing, password hashing, AES ECB/CBC.
class CloudSecurity {
  CloudSecurity({
    required String loginKey,
    String? iotKey,
    String? hmacKey,
    int? fixedKey,
    int? fixedIv,
  })  : _loginKey = loginKey,
        _iotKey = iotKey,
        _hmacKey = hmacKey {
    if (fixedKey != null) {
      // format(fixedKey, "x").encode("ascii") in Python
      _fixedKey = Uint8List.fromList(
        fixedKey.toRadixString(16).codeUnits,
      );
    }
    if (fixedIv != null) {
      _fixedIv = Uint8List.fromList(
        fixedIv.toRadixString(16).codeUnits,
      );
    }
  }

  final String _loginKey;
  final String? _iotKey;
  final String? _hmacKey;
  Uint8List? _fixedKey;
  Uint8List? _fixedIv;
  Uint8List? _aesKey;
  Uint8List? _aesIv;

  /// sha256("Hello, {username}!")[:16]
  static String getDeviceId(String username) =>
      sha256.convert(utf8.encode('Hello, $username!')).toString().substring(0, 16);

  /// Compute UDP ID used for token lookup.
  /// method 0 = REVERSED_BIG (8 bytes little-endian)
  /// method 1 = BIG (6 bytes big-endian)
  /// method 2 = LITTLE (6 bytes little-endian)
  static String? getUdpId(int applianceId, int method) {
    List<int> bytesId;
    switch (method) {
      case 0:
        // to_bytes(8,"big") then reversed == 8 bytes little-endian
        bytesId = List.generate(8, (i) => (applianceId >> (i * 8)) & 0xFF);
      case 1:
        bytesId = List.generate(6, (i) => (applianceId >> ((5 - i) * 8)) & 0xFF);
      case 2:
        bytesId = List.generate(6, (i) => (applianceId >> (i * 8)) & 0xFF);
      default:
        return null;
    }
    final digest = List<int>.from(sha256.convert(bytesId).bytes);
    for (var i = 0; i < 16; i++) {
      digest[i] ^= digest[i + 16];
    }
    return digest
        .sublist(0, 16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// HMAC-SHA256(iot_key + data + random)
  /// [data] is a JSON String for MeijuCloud.
  String? sign(String url, dynamic data, String random) {
    if (_hmacKey == null) return null;
    final dataStr = data is String ? data : '';
    final msg = (_iotKey ?? '') + dataStr + random;
    return Hmac(sha256, utf8.encode(_hmacKey!))
        .convert(utf8.encode(msg))
        .toString();
  }

  /// sha256(login_id + sha256(password) + login_key)
  String encryptPassword(String loginId, String data) {
    final hash1 = sha256.convert(utf8.encode(data)).toString();
    return sha256.convert(utf8.encode(loginId + hash1 + _loginKey)).toString();
  }

  /// Subclasses override with cloud-specific IAM password encryption.
  String encryptIamPassword(String loginId, String data) =>
      throw UnimplementedError();

  /// Store the AES key and IV for subsequent encrypt/decrypt calls.
  void setAesKeys(String key, Uint8List iv) {
    _aesKey = Uint8List.fromList(key.codeUnits);
    _aesIv = iv;
  }

  bool _isEcb(Uint8List? iv) =>
      iv == null || (iv.length == 1 && iv[0] == 0x30);

  /// Decrypt a hex-encoded AES-encrypted string; returns plain text.
  String aesDecrypt(String data, {Uint8List? key, Uint8List? iv}) {
    if (data.isEmpty) return '';
    final aesKey = key ?? _aesKey;
    final aesIv = iv ?? _aesIv;
    if (aesKey == null) throw StateError('No AES key set');
    final dataBytes = _hexToBytes(data);
    final k = enc.Key(aesKey);
    if (_isEcb(aesIv)) {
      return String.fromCharCodes(
        enc.Encrypter(enc.AES(k, mode: enc.AESMode.ecb))
            .decryptBytes(enc.Encrypted(dataBytes)),
      );
    }
    return String.fromCharCodes(
      enc.Encrypter(enc.AES(k, mode: enc.AESMode.cbc))
          .decryptBytes(enc.Encrypted(dataBytes), iv: enc.IV(aesIv!)),
    );
  }

  /// Decrypt using the fixed key/iv (used to unwrap the session key).
  String aesDecryptWithFixedKey(String data) =>
      aesDecrypt(data, key: _fixedKey, iv: _fixedIv);

  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

/// Meiju ("美的美居") cloud security.
/// fixed_key = format(10864842703515613082, "x") = "96c7acdfdb8af79a"
/// encrypt_iam_password = MD5(MD5(password))
class MeijuCloudSecurity extends CloudSecurity {
  MeijuCloudSecurity({
    required String loginKey,
    required String iotKey,
    required String hmacKey,
  }) : super(
          loginKey: loginKey,
          iotKey: iotKey,
          hmacKey: hmacKey,
          // Provide hex string as precomputed bytes to avoid 64-bit overflow.
          // format(10864842703515613082, "x") == "96c7acdfdb8af79a"
        ) {
    _fixedKey = Uint8List.fromList('96c7acdfdb8af79a'.codeUnits);
  }

  @override
  String encryptIamPassword(String loginId, String data) {
    final md1 = md5.convert(utf8.encode(data)).toString();
    return md5.convert(utf8.encode(md1)).toString();
  }
}

/// Midea Air ("NetHome Plus" / "Midea Air") cloud security.
/// sign = SHA256(url_path + sorted_form_params + login_key)
class MideaAirSecurity extends CloudSecurity {
  MideaAirSecurity({required String loginKey})
      : super(loginKey: loginKey, iotKey: null, hmacKey: null);

  /// Sign using sorted form-encoded params.
  /// [data] must be a Map<String, dynamic>.
  @override
  String? sign(String url, dynamic data, String random) {
    if (data is! Map<String, dynamic>) return null;
    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    // Python: unquote_plus(urlencode(sorted_items)) — for ASCII-only values
    // this equals plain "key=value&..." concatenation.
    final payload = sorted.map((e) => '${e.key}=${e.value}').join('&');
    final urlPath = Uri.parse(url).path;
    return sha256.convert(utf8.encode(urlPath + payload + _loginKey)).toString();
  }
}
