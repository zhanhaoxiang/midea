/// Midea local device discovery. Mirrors midealocal/discover.py.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'exceptions.dart';
import 'security.dart';

const int _bytes2PortLength = 4;
const int _discoveryMinResponseLength = 104;
const int _serialType1Length = 32;
const int _serialType2Length = 22;

/// The broadcast discovery message (matches BROADCAST_MSG in discover.py).
final Uint8List broadcastMsg = Uint8List.fromList([
  0x5A, 0x5A, 0x01, 0x11, 0x48, 0x00, 0x92, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x7F, 0x75, 0xBD, 0x6B, 0x3E, 0x4F, 0x8B, 0x76,
  0x2E, 0x84, 0x9C, 0x6E, 0x57, 0x8D, 0x65, 0x90,
  0x03, 0x6E, 0x9D, 0x43, 0x42, 0xA5, 0x0F, 0x1F,
  0x56, 0x9E, 0xB8, 0xEC, 0x91, 0x8E, 0x92, 0xE5,
]);

/// The device-info request message (matches DEVICE_INFO_MSG in discover.py).
final Uint8List deviceInfoMsg = Uint8List.fromList([
  0x5A, 0x5A, 0x15, 0x00, 0x00, 0x38, 0x00, 0x04,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x27, 0x33, 0x05,
  0x13, 0x06, 0x14, 0x14, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x03, 0xE8, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xCA, 0x8D, 0x9B, 0xF9, 0xA0, 0x30, 0x1A, 0xE3,
  0xB7, 0xE4, 0x2D, 0x53, 0x49, 0x47, 0x62, 0xBE,
]);

/// Discover Midea devices on the LAN via UDP broadcast.
///
/// [discoverType] filters by device type (empty = accept all).
/// [ipAddress] targets specific broadcast addresses (null = auto-detect).
/// [timeout] controls how long to wait for responses (default 5s).
///
/// Returns a map of device_id -> device info map, matching Python's discover().
Future<Map<int, Map<String, dynamic>>> discover({
  List<int>? discoverType,
  List<String>? ipAddress,
  Duration timeout = const Duration(seconds: 5),
}) async {
  discoverType ??= [];

  final foundDevices = <int, Map<String, dynamic>>{};
  final security = LocalSecurity();
  // Pending async tasks for protocol-1 devices (need TCP to get device ID)
  final pendingTasks = <Future<void>>[];

  final addrs = ipAddress ?? await enumAllBroadcast();

  final sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  sock.broadcastEnabled = true;

  for (final addr in addrs) {
    try {
      sock.send(broadcastMsg, InternetAddress(addr), 6445);
      sock.send(broadcastMsg, InternetAddress(addr), 20086);
    } on SocketException catch (e) {
      stderr.writeln("Can't access network $addr: $e");
    }
  }

  final completer = Completer<Map<int, Map<String, dynamic>>>();

  Timer(timeout, () async {
    sock.close();
    await Future.wait(pendingTasks);
    if (!completer.isCompleted) completer.complete(foundDevices);
  });

  sock.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = sock.receive();
    if (datagram == null) return;

    final ip = datagram.address.address;

    try {
      final data = datagram.data;

      if (data.length >= _discoveryMinResponseLength) {
        int deviceId = 0;
        Map<String, dynamic>? device;

        if (_bytesEqual(data.sublist(0, 2), [0x5A, 0x5A])) {
          // Protocol 2
          (deviceId, device) = _parseProtocol23(data, ip, security, 2);
        } else if (_bytesEqual(data.sublist(0, 2), [0x83, 0x70]) &&
            _bytesEqual(data.sublist(8, 10), [0x5A, 0x5A])) {
          // Protocol 3: strip 8370 wrapper (first 8 bytes + last 16 bytes)
          final inner = data.sublist(8, data.length - 16);
          (deviceId, device) = _parseProtocol23(inner, ip, security, 3);
        }

        if (device != null &&
            !foundDevices.containsKey(deviceId) &&
            (discoverType!.isEmpty || discoverType.contains(device['type']))) {
          foundDevices[deviceId] = device;
        }
      } else if (_isXmlResponse(data)) {
        // Protocol 1: async TCP fetch required for device ID
        pendingTasks.add(_handleProtocol1(data, ip, foundDevices, discoverType!));
      }
    } catch (e) {
      stderr.writeln('Error parsing response from $ip: $e');
    }
  });

  return completer.future;
}

/// Parse a protocol V2 or V3 binary UDP response (after any 8370 unwrapping).
(int, Map<String, dynamic>?) _parseProtocol23(
  Uint8List data,
  String ip,
  LocalSecurity security,
  int protocol,
) {
  final deviceId = _bytesToIntLE(data.sublist(20, 26));

  final encryptData = data.sublist(40, data.length - 16);
  final reply = security.aesDecrypt(encryptData);
  if (reply.isEmpty) return (0, null);

  final ssidLen = reply[40];
  final ssid = String.fromCharCodes(reply.sublist(41, 41 + ssidLen));
  final parts = ssid.split('_');
  if (parts.length < 2) return (0, null);

  final port = bytes2port(reply.sublist(4, 8));
  final model = String.fromCharCodes(reply.sublist(17, 25));
  final sn = String.fromCharCodes(reply.sublist(8, 40));

  return (
    deviceId,
    {
      'device_id': deviceId,
      'type': int.parse(parts[1], radix: 16),
      'ip_address': ip,
      'port': port,
      'model': model,
      'sn': sn,
      'protocol': protocol,
    },
  );
}

/// Handle a protocol V1 XML UDP response asynchronously (needs TCP for ID).
Future<void> _handleProtocol1(
  Uint8List data,
  String ip,
  Map<int, Map<String, dynamic>> foundDevices,
  List<int> discoverType,
) async {
  try {
    final xmlStr = String.fromCharCodes(data);

    final deviceTagContent = RegExp(
      r'<body\b[^>]*>.*?<device\b([^>]*)',
      dotAll: true,
    ).firstMatch(xmlStr)?.group(1);
    if (deviceTagContent == null) throw ElementMissing();

    final portStr = _xmlAttr(deviceTagContent, 'port');
    final apcSn = _xmlAttr(deviceTagContent, 'apc_sn');
    final apcTypeStr = _xmlAttr(deviceTagContent, 'apc_type');
    if (portStr == null || apcSn == null || apcTypeStr == null) {
      throw ElementMissing();
    }

    final port = int.parse(portStr);
    final deviceType = int.parse(apcTypeStr);
    final sn = apcSn;

    final response = await getDeviceInfo(ip, port);
    final deviceId = getIdFromResponse(response);

    String model;
    if (sn.length == _serialType1Length) {
      model = sn.substring(9, 17);
    } else if (sn.length == _serialType2Length) {
      model = sn.substring(3, 11);
    } else {
      model = '';
    }

    if (!foundDevices.containsKey(deviceId) &&
        (discoverType.isEmpty || discoverType.contains(deviceType))) {
      foundDevices[deviceId] = {
        'device_id': deviceId,
        'type': deviceType,
        'ip_address': ip,
        'port': port,
        'model': model,
        'sn': sn,
        'protocol': 1,
      };
    }
  } on ElementMissing {
    stderr.writeln('Missing element in XML response from $ip');
  } catch (e) {
    stderr.writeln('Error handling protocol 1 device at $ip: $e');
  }
}

/// Extract device ID from a TCP device-info response (protocol 1).
/// Matches get_id_from_response() in discover.py.
int getIdFromResponse(Uint8List response) {
  if (response.length < 80) return 0;
  final xmlSlice = response.sublist(64, response.length - 16);
  if (!_isXmlResponse(xmlSlice)) return 0;

  final xmlStr = String.fromCharCodes(xmlSlice);
  final tagContent =
      RegExp(r'<smartDevice\b([^>]*)').firstMatch(xmlStr)?.group(1);
  if (tagContent == null) throw ElementMissing();

  final devId = _xmlAttr(tagContent, 'devId');
  if (devId == null) throw ElementMissing();

  return _bytesToIntLE(_hexToBytes(devId));
}

/// Connect to a device via TCP and request device info.
/// Matches get_device_info() in discover.py.
Future<Uint8List> getDeviceInfo(String deviceIp, int devicePort) async {
  try {
    final sock = await Socket.connect(
      deviceIp,
      devicePort,
      timeout: const Duration(seconds: 8),
    );
    sock.add(deviceInfoMsg);
    await sock.flush();

    final chunks = <int>[];
    await sock
        .listen((d) => chunks.addAll(d))
        .asFuture<void>()
        .timeout(const Duration(milliseconds: 500), onTimeout: () {});
    await sock.close();
    return Uint8List.fromList(chunks);
  } catch (_) {
    return Uint8List(0);
  }
}

/// Enumerate all LAN broadcast addresses for private networks.
/// Matches enum_all_broadcast() in discover.py.
Future<List<String>> enumAllBroadcast() async {
  final nets = <String>[];

  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
    includeLoopback: false,
  );

  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      if (addr.type != InternetAddressType.IPv4) continue;
      if (addr.isLoopback || addr.isLinkLocal) continue;

      final broadcast = _broadcastFromIp(addr.address);
      if (broadcast != null && !nets.contains(broadcast)) {
        nets.add(broadcast);
      }
    }
  }

  return nets;
}

/// Convert little-endian port bytes to int.
/// Matches bytes2port() in discover.py.
int bytes2port(Uint8List valueBytes) {
  var result = 0;
  for (var b = 0; b < _bytes2PortLength; b++) {
    final b1 = b < valueBytes.length ? valueBytes[b] & 0xFF : 0;
    result |= b1 << (b * 8);
  }
  return result;
}

// ── private helpers ───────────────────────────────────────────────────────────

bool _isXmlResponse(Uint8List data) {
  if (data.length < 6) return false;
  // "<?xml " = 0x3c 0x3f 0x78 0x6d 0x6c 0x20
  return _bytesEqual(
    data.sublist(0, 6),
    [0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20],
  );
}

/// Compute broadcast address from an IPv4 address.
/// Assumes /24 for 192.168.x.x and 172.16-31.x.x; /8 for 10.x.x.x.
String? _broadcastFromIp(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  final a = int.tryParse(parts[0]);
  final b = int.tryParse(parts[1]);
  if (a == null || b == null) return null;

  if (a == 10) return '10.255.255.255';
  if (a == 172 && b >= 16 && b <= 31) {
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
  if (a == 192 && b == 168) {
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
  return null;
}

int _bytesToIntLE(Uint8List bytes) {
  var result = 0;
  for (var i = 0; i < bytes.length; i++) {
    result |= bytes[i] << (i * 8);
  }
  return result;
}

bool _bytesEqual(Uint8List a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String? _xmlAttr(String tagContent, String attrName) {
  return RegExp('$attrName="([^"]*)"').firstMatch(tagContent)?.group(1);
}

Uint8List _hexToBytes(String hex) {
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}
