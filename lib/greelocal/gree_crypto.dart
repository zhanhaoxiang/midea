import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

const String _genericEcbKey = 'a3K8Bx%2r8Y7#xDh';
const String _genericGcmKey = '{yxAHAY_Lm6pbC/<';

final _gcmIv = Uint8List.fromList([
  0x54, 0x40, 0x78, 0x44, 0x49, 0x67, 0x5a, 0x51, 0x6c, 0x5e, 0x63, 0x13,
]);
final _gcmAad = Uint8List.fromList(utf8.encode('qualcomm-test'));

class GreeCrypto {
  // ---- ECB ----------------------------------------------------------------

  static String encryptEcb(String pack, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final padded = _pkcs7Pad(Uint8List.fromList(utf8.encode(pack)));
    final cipher = pc.ECBBlockCipher(pc.AESEngine())
      ..init(true, pc.KeyParameter(keyBytes));
    final out = Uint8List(padded.length);
    for (var i = 0; i < padded.length; i += 16) {
      cipher.processBlock(padded, i, out, i);
    }
    return base64.encode(out);
  }

  static String decryptEcb(String packEncoded, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final data = Uint8List.fromList(base64.decode(packEncoded));
    final cipher = pc.ECBBlockCipher(pc.AESEngine())
      ..init(false, pc.KeyParameter(keyBytes));
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i += 16) {
      cipher.processBlock(data, i, out, i);
    }
    // Mirror Python: find last '}' instead of stripping PKCS7 explicitly.
    final lastBrace = out.lastIndexOf(0x7D);
    if (lastBrace < 0) throw FormatException('No closing brace in decrypted data');
    return utf8.decode(out.sublist(0, lastBrace + 1));
  }

  static String encryptGenericEcb(String pack) => encryptEcb(pack, _genericEcbKey);
  static String decryptGenericEcb(String packEncoded) =>
      decryptEcb(packEncoded, _genericEcbKey);

  // ---- GCM ----------------------------------------------------------------

  /// Returns a record with `pack` (base64 ciphertext) and `tag` (base64 tag).
  static ({String pack, String tag}) encryptGcm(String pack, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final input = Uint8List.fromList(utf8.encode(pack));
    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(true, pc.AEADParameters(pc.KeyParameter(keyBytes), 128, _gcmIv, _gcmAad));
    final output = cipher.process(input); // ciphertext (N bytes) + tag (16 bytes)
    final ciphertext = output.sublist(0, output.length - 16);
    final tag = output.sublist(output.length - 16);
    return (pack: base64.encode(ciphertext), tag: base64.encode(tag));
  }

  static String decryptGcm(String packEncoded, String tagEncoded, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final ciphertext = base64.decode(packEncoded);
    final tag = base64.decode(tagEncoded);
    // pointycastle GCM decrypt expects ciphertext + tag appended.
    final combined = Uint8List(ciphertext.length + tag.length)
      ..setRange(0, ciphertext.length, ciphertext)
      ..setRange(ciphertext.length, ciphertext.length + tag.length, tag);
    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(false, pc.AEADParameters(pc.KeyParameter(keyBytes), 128, _gcmIv, _gcmAad));
    final decrypted = cipher.process(combined);
    // Mirror Python: strip 0xFF padding bytes.
    final cleaned = decrypted.where((b) => b != 0xFF).toList();
    return utf8.decode(cleaned);
  }

  static ({String pack, String tag}) encryptGenericGcm(String pack) =>
      encryptGcm(pack, _genericGcmKey);

  static String decryptGenericGcm(String packEncoded, String tagEncoded) =>
      decryptGcm(packEncoded, tagEncoded, _genericGcmKey);

  // ---- Helpers ------------------------------------------------------------

  static Uint8List _pkcs7Pad(Uint8List data) {
    final padLen = 16 - (data.length % 16);
    final padded = Uint8List(data.length + padLen);
    padded.setRange(0, data.length, data);
    for (var i = data.length; i < padded.length; i++) {
      padded[i] = padLen;
    }
    return padded;
  }
}
