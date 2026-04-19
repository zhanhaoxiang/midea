/// Midea local packet builder. Mirrors midealocal/packet_builder.py.

import 'dart:typed_data';
import 'security.dart';

class PacketBuilder {
  PacketBuilder(int deviceId, Uint8List command) {
    _security = LocalSecurity();
    _command = command;

    // 40-byte header (same layout as Python)
    _packet = List<int>.from([
      // Static header
      0x5A, 0x5A,
      // mMessageType
      0x01, 0x11,
      // PacketLength (placeholder)
      0x00, 0x00,
      // padding
      0x20, 0x00,
      // MessageId
      0x00, 0x00, 0x00, 0x00,
      // Date&Time (8 bytes – filled below)
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      // DeviceID (8 bytes – filled below)
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      // 12 zero bytes
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]);

    // Fill Date&Time at [12..20]
    final t = _packetTime();
    for (var i = 0; i < 8; i++) _packet[12 + i] = t[i];

    // Fill DeviceID at [20..28] (little-endian, 8 bytes)
    for (var i = 0; i < 8; i++) _packet[20 + i] = (deviceId >> (i * 8)) & 0xFF;
  }

  late final LocalSecurity _security;
  late final Uint8List _command;
  late final List<int> _packet;

  Uint8List finalize({int msgType = 1}) {
    if (msgType != 1) {
      _packet[3] = 0x10;
      _packet[6] = 0x7B;
    } else {
      _packet.addAll(_security.aesEncrypt(_command));
    }
    // PacketLength = len(packet) + 16
    final length = _packet.length + 16;
    _packet[4] = length & 0xFF;
    _packet[5] = (length >> 8) & 0xFF;
    // Append 16-byte MD5 checksum (encode32)
    _packet.addAll(_security.encode32Data(Uint8List.fromList(_packet)));
    return Uint8List.fromList(_packet);
  }

  /// Build a time bytes array matching Python's packet_time().
  /// Format: reverse pairs of "YYMMDDHHmmSSuuuu" where uuuu = microseconds/100
  static Uint8List _packetTime() {
    final now = DateTime.now().toUtc();
    final t = now.year.toString().padLeft(4, '0').substring(2) +
        now.month.toString().padLeft(2, '0') +
        now.day.toString().padLeft(2, '0') +
        now.hour.toString().padLeft(2, '0') +
        now.minute.toString().padLeft(2, '0') +
        now.second.toString().padLeft(2, '0') +
        (now.millisecond * 10).toString().padLeft(4, '0');
    // build reversed like Python
    final b = <int>[];
    for (var i = 0; i < 16; i += 2) {
      b.insert(0, int.parse(t.substring(i, i + 2)));
    }
    return Uint8List.fromList(b);
  }
}
