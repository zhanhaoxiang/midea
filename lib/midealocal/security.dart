/// Midea local security. Mirrors midealocal/security.py.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

import 'exceptions.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int header8370_1stByte = 0x83;
const int header8370_2ndByte = 0x70;
const int header8370_4thByte = 0x20;
const int minDecode8370DataLength = 6;
const int msgtypeHandshakeRequest = 0x0;
const int msgtypeHandshakeResponse = 0x1;
const int msgtypeEncryptedResponse = 0x3;
const int msgtypeEncryptedRequest = 0x6;
const int tcpKeyResponseLength = 64;
const int maxDoubleByteValue = 0xFFFF;

// ---------------------------------------------------------------------------
// LocalSecurity
// ---------------------------------------------------------------------------

/// Handles local (LAN) encryption/decryption for the Midea protocol.
class LocalSecurity {
  LocalSecurity() {
    // Key: bytes.fromhex(format(141661095494369103254425781617665632877, "x"))
    _aesKey = _hexToBytes('6a92ef406bad2f0359baad994171ea6d');
    // Salt for encode32: bytes.fromhex(format(...long number..., "x"))
    _salt = _parseHexBigInt(
      BigInt.parse(
        '233912452794221312800602098970898185176935770387238278451789080441632479840061417076563',
      ),
    );
    _iv = Uint8List(16); // all zeros
  }

  late final Uint8List _aesKey;
  late final Uint8List _salt;
  late final Uint8List _iv;
  late Uint8List _tcpKey;
  int _requestCount = 0;
  int _responseCount = 0;

  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _parseHexBigInt(BigInt value) {
    final hex = value.toRadixString(16);
    final paddedHex = hex.length.isOdd ? '0$hex' : hex;
    return _hexToBytes(paddedHex);
  }

  // ── ECB ───────────────────────────────────────────────────────────────────

  /// Decrypt AES-128 ECB with PKCS7 unpadding. Returns empty on failure.
  Uint8List aesDecrypt(Uint8List raw) {
    try {
      final key = enc.Key(_aesKey);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      final decrypted = encrypter.decryptBytes(enc.Encrypted(raw));
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// Encrypt AES-128 ECB with PKCS7 padding.
  Uint8List aesEncrypt(Uint8List raw) {
    final key = enc.Key(_aesKey);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
    return Uint8List.fromList(encrypter.encryptBytes(raw).bytes);
  }

  // ── CBC ───────────────────────────────────────────────────────────────────

  Uint8List aesCbcDecrypt(Uint8List raw, Uint8List key) {
    // Raw CBC without PKCS7 unpadding — matches Python's PyCryptodome AES.MODE_CBC .decrypt()
    final params = pc.ParametersWithIV<pc.KeyParameter>(
      pc.KeyParameter(key),
      _iv,
    );
    final cipher = pc.CBCBlockCipher(pc.AESEngine())..init(false, params);
    final output = Uint8List(raw.length);
    for (var i = 0; i < raw.length; i += 16) {
      cipher.processBlock(raw, i, output, i);
    }
    return output;
  }

  Uint8List aesCbcEncrypt(Uint8List raw, Uint8List key) {
    // Raw CBC without PKCS7 padding — matches Python's PyCryptodome AES.MODE_CBC .encrypt()
    final params = pc.ParametersWithIV<pc.KeyParameter>(
      pc.KeyParameter(key),
      _iv,
    );
    final cipher = pc.CBCBlockCipher(pc.AESEngine())..init(true, params);
    final output = Uint8List(raw.length);
    for (var i = 0; i < raw.length; i += 16) {
      cipher.processBlock(raw, i, output, i);
    }
    return output;
  }

  // ── encode32 (MD5 checksum) ────────────────────────────────────────────────

  /// MD5(data + salt) – 16 bytes. Matches encode32_data() in Python.
  Uint8List encode32Data(Uint8List raw) {
    final input = Uint8List(raw.length + _salt.length);
    input.setRange(0, raw.length, raw);
    input.setRange(raw.length, raw.length + _salt.length, _salt);
    return Uint8List.fromList(md5.convert(input).bytes);
  }

  // ── V3 TCP key ────────────────────────────────────────────────────────────

  /// Derive the TCP session key from the handshake response.
  Uint8List tcpKey(Uint8List response, Uint8List key) {
    if (response.length == 5 &&
        String.fromCharCodes(response) == 'ERROR') {
      throw CannotAuthenticate();
    }
    if (response.length != tcpKeyResponseLength) throw DataUnexpectedLength();

    final payload = response.sublist(0, 32);
    final sign = response.sublist(32);
    final plain = aesCbcDecrypt(payload, key);
    if (!_bytesEqual(Uint8List.fromList(sha256.convert(plain).bytes), sign)) {
      throw DataSignDoesntMatch();
    }
    _tcpKey = _xor(plain, key);
    _requestCount = 0;
    _responseCount = 0;
    return _tcpKey;
  }

  // ── 8370 encode/decode ────────────────────────────────────────────────────

  /// Encode data using the 8370 framing (V3 protocol).
  Uint8List encode8370(Uint8List data, int msgtype) {
    final header = <int>[0x83, 0x70];
    var size = data.length;
    var padding = 0;
    var workData = data;

    if (msgtype == msgtypeEncryptedResponse ||
        msgtype == msgtypeEncryptedRequest) {
      if ((size + 2) % 16 != 0) {
        padding = 16 - ((size + 2) & 0xF);
        size += padding + 32;
        final padded = Uint8List(data.length + padding);
        padded.setRange(0, data.length, data);
        // fill padding with random bytes
        final rng = Random.secure();
        for (var i = data.length; i < padded.length; i++) {
          padded[i] = rng.nextInt(256);
        }
        workData = padded;
      }
    }

    header.add((size >> 8) & 0xFF);
    header.add(size & 0xFF);
    header.addAll([0x20, (padding << 4) | msgtype]);

    // prepend request count (big-endian 2 bytes) then data
    final countedData = <int>[
      (_requestCount >> 8) & 0xFF,
      _requestCount & 0xFF,
      ...workData,
    ];
    _requestCount = (_requestCount + 1) & maxDoubleByteValue;

    List<int> finalData;
    if (msgtype == msgtypeEncryptedResponse ||
        msgtype == msgtypeEncryptedRequest) {
      final h = Uint8List.fromList([...header, ...countedData]);
      final sign = sha256.convert(h).bytes;
      final encrypted = aesCbcEncrypt(Uint8List.fromList(countedData), _tcpKey);
      finalData = [...encrypted, ...sign];
    } else {
      finalData = countedData;
    }

    return Uint8List.fromList([...header, ...finalData]);
  }

  /// Decode 8370-framed data (V3 protocol).
  /// Returns ([decoded messages], remaining bytes).
  (List<Uint8List>, Uint8List) decode8370(Uint8List data) {
    if (data.length < minDecode8370DataLength) return ([], data);

    final header = data.sublist(0, 6);
    if (header[0] != header8370_1stByte || header[1] != header8370_2ndByte) {
      throw MessageWrongFormat('not an 8370 message');
    }

    final size = ((header[2] << 8) | header[3]) + 8;
    Uint8List? leftover;

    Uint8List workData;
    if (data.length > size) {
      leftover = data.sublist(size);
      workData = data.sublist(0, size);
    } else if (data.length < size) {
      return ([], data);
    } else {
      workData = data;
    }

    if (header[4] != header8370_4thByte) {
      throw MessageWrongFormat('missing byte 4');
    }

    final padding = header[5] >> 4;
    final msgtype = header[5] & 0xF;
    var payload = workData.sublist(6);

    if (msgtype == msgtypeEncryptedResponse ||
        msgtype == msgtypeEncryptedRequest) {
      final sign = payload.sublist(payload.length - 32);
      payload = payload.sublist(0, payload.length - 32);
      payload = aesCbcDecrypt(payload, _tcpKey);
      final expectedSign = sha256.convert([...header, ...payload]).bytes;
      if (!_bytesEqual(sign, Uint8List.fromList(expectedSign))) {
        throw DataSignDoesntMatch();
      }
      if (padding > 0) {
        payload = payload.sublist(0, payload.length - padding);
      }
    }

    _responseCount = (payload[0] << 8) | payload[1];
    final result = payload.sublist(2);

    if (leftover != null) {
      final (morePackets, incomplete) = decode8370(leftover);
      return ([result, ...morePackets], incomplete);
    }
    return ([result], Uint8List(0));
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static Uint8List _xor(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length);
    for (var i = 0; i < a.length; i++) out[i] = a[i] ^ b[i];
    return out;
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Cloud security classes (mirror of CloudSecurity / MeijuCloudSecurity)
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
      _fixedKey = Uint8List.fromList(fixedKey.toRadixString(16).codeUnits);
    }
    if (fixedIv != null) {
      _fixedIv = Uint8List.fromList(fixedIv.toRadixString(16).codeUnits);
    }
  }

  final String _loginKey;
  final String? _iotKey;
  final String? _hmacKey;
  Uint8List? _fixedKey;
  Uint8List? _fixedIv;
  Uint8List? _aesKey;
  Uint8List? _aesIv;

  static String getDeviceId(String username) =>
      sha256.convert(utf8.encode('Hello, $username!')).toString().substring(0, 16);

  static String? getUdpId(int applianceId, int method) {
    List<int> bytesId;
    switch (method) {
      case 0:
        bytesId = List.generate(8, (i) => (applianceId >> (i * 8)) & 0xFF);
      case 1:
        bytesId = List.generate(6, (i) => (applianceId >> ((5 - i) * 8)) & 0xFF);
      case 2:
        bytesId = List.generate(6, (i) => (applianceId >> (i * 8)) & 0xFF);
      default:
        return null;
    }
    final digest = List<int>.from(sha256.convert(bytesId).bytes);
    for (var i = 0; i < 16; i++) digest[i] ^= digest[i + 16];
    return digest
        .sublist(0, 16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String? sign(String url, dynamic data, String random) {
    if (_hmacKey == null) return null;
    final dataStr = data is String ? data : '';
    final msg = (_iotKey ?? '') + dataStr + random;
    return Hmac(sha256, utf8.encode(_hmacKey!))
        .convert(utf8.encode(msg))
        .toString();
  }

  String encryptPassword(String loginId, String data) {
    final hash1 = sha256.convert(utf8.encode(data)).toString();
    return sha256.convert(utf8.encode(loginId + hash1 + _loginKey)).toString();
  }

  String encryptIamPassword(String loginId, String data) =>
      throw UnimplementedError();

  void setAesKeys(String key, Uint8List iv) {
    _aesKey = Uint8List.fromList(key.codeUnits);
    _aesIv = iv;
  }

  bool _isEcb(Uint8List? iv) => iv == null || (iv.length == 1 && iv[0] == 0x30);

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
class MeijuCloudSecurity extends CloudSecurity {
  MeijuCloudSecurity({
    required String loginKey,
    required String iotKey,
    required String hmacKey,
  }) : super(loginKey: loginKey, iotKey: iotKey, hmacKey: hmacKey) {
    _fixedKey = Uint8List.fromList('96c7acdfdb8af79a'.codeUnits);
  }

  @override
  String encryptIamPassword(String loginId, String data) {
    final md1 = md5.convert(utf8.encode(data)).toString();
    return md5.convert(utf8.encode(md1)).toString();
  }
}

/// Midea Air / NetHome Plus cloud security.
class MideaAirSecurity extends CloudSecurity {
  MideaAirSecurity({required String loginKey})
      : super(loginKey: loginKey, iotKey: null, hmacKey: null);

  @override
  String? sign(String url, dynamic data, String random) {
    if (data is! Map<String, dynamic>) return null;
    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final payload = sorted.map((e) => '${e.key}=${e.value}').join('&');
    final urlPath = Uri.parse(url).path;
    return sha256.convert(utf8.encode(urlPath + payload + _loginKey)).toString();
  }
}
