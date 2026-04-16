import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class LocalSecurity {
  LocalSecurity() {
    _aesKey = _parseHexBigInt(
      BigInt.parse('141661095494369103254425781617665632877'),
    );
    _salt = _parseHexBigInt(
      BigInt.parse(
        '233912452794221312800602098970898185176935770387238278451789080441632479840061417076563',
      ),
    );
    _iv = Uint8List(16);
  }

  late Uint8List _aesKey;
  late Uint8List _salt;
  late Uint8List _iv;

  Uint8List _parseHexBigInt(BigInt value) {
    final hex = value.toRadixString(16);
    final paddedHex = hex.length % 2 == 0 ? hex : '0$hex';
    return _hexToBytes(paddedHex);
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Uint8List aesDecrypt(Uint8List raw) {
    try {
      final key = encrypt.Key(_aesKey);
      final iv = encrypt.IV(_iv);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb),
      );
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(raw), iv: iv);
      return Uint8List.fromList(_unpad(decrypted));
    } catch (e) {
      return Uint8List(0);
    }
  }

  List<int> _unpad(List<int> data) {
    if (data.isEmpty) return data;
    final padLength = data.last;
    if (padLength > 16 || padLength > data.length) return data;
    return data.sublist(0, data.length - padLength);
  }
}

class DiscoveredDevice {
  DiscoveredDevice({
    required this.deviceId,
    required this.type,
    required this.ipAddress,
    required this.port,
    required this.model,
    required this.sn,
    required this.protocol,
  });

  final int deviceId;
  final int type;
  final String ipAddress;
  final int port;
  final String model;
  final String sn;
  final int protocol;
}

class Discover {
  static const int _bytes2PortLength = 4;
  static const int _discoveryMinResponseLength = 104;

  static final Uint8List _broadcastMsg = Uint8List.fromList([
    0x5A,
    0x5A,
    0x01,
    0x11,
    0x48,
    0x00,
    0x92,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7F,
    0x75,
    0xBD,
    0x6B,
    0x3E,
    0x4F,
    0x8B,
    0x76,
    0x2E,
    0x84,
    0x9C,
    0x6E,
    0x57,
    0x8D,
    0x65,
    0x90,
    0x03,
    0x6E,
    0x9D,
    0x43,
    0x42,
    0xA5,
    0x0F,
    0x1F,
    0x56,
    0x9E,
    0xB8,
    0xEC,
    0x91,
    0x8E,
    0x92,
    0xE5,
  ]);

  static Future<List<DiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final foundDevices = <DiscoveredDevice>[];
    final security = LocalSecurity();
    final foundIds = <int>{};
    final completer = Completer<List<DiscoveredDevice>>();
    RawDatagramSocket? socket;

    try {
      final addrs = await _enumAllBroadcast();
      if (addrs.isEmpty) {
        print('No broadcast addresses found');
        completer.complete(foundDevices);
        return completer.future;
      }

      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      for (final addr in addrs) {
        try {
          final broadcastAddr = InternetAddress(addr);
          socket.send(_broadcastMsg, broadcastAddr, 6445);
          print('Broadcast sent to $addr:6445');
        } catch (e) {
          print("Can't send to $addr:6445: $e");
        }
      }

      for (final addr in addrs) {
        try {
          final broadcastAddr = InternetAddress(addr);
          socket.send(_broadcastMsg, broadcastAddr, 20086);
          print('Broadcast sent to $addr:20086');
        } catch (e) {
          print("Can't send to $addr:20086: $e");
        }
      }

      print('Waiting for responses...');

      Timer(timeout, () {
        socket?.close();
        completer.complete(foundDevices);
      });

      socket.listen((event) {
        print('Socket event: $event');
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            print(
              'Received ${datagram.data.length} bytes from ${datagram.address.address}:${datagram.port}',
            );
            final result = _parseDiscoverResponse(
              datagram.data,
              datagram.address.address,
              security,
              foundIds,
            );
            if (result != null) {
              print('Device found: ${result.ipAddress}');
              foundDevices.add(result);
            }
          }
        }
      });
    } catch (e) {
      print('Discovery error: $e');
      socket?.close();
      completer.complete(foundDevices);
    }

    return completer.future;
  }

  static DiscoveredDevice? _parseDiscoverResponse(
    Uint8List data,
    String ip,
    LocalSecurity security,
    Set<int> foundIds,
  ) {
    if (data.length >= _discoveryMinResponseLength) {
      if (_bytesEqual(data.sublist(0, 2), [0x5A, 0x5A])) {
        return _parseProtocol2(data, ip, security, foundIds);
      } else if (_bytesEqual(data.sublist(8, 10), [0x5A, 0x5A])) {
        return _parseProtocol3(data, ip, security, foundIds);
      }
    }
    return null;
  }

  static DiscoveredDevice? _parseProtocol2(
    Uint8List data,
    String ip,
    LocalSecurity security,
    Set<int> foundIds,
  ) {
    final protocol = 2;
    final deviceIdBytes = data.sublist(20, 26);
    final deviceId = _bytesToInt(deviceIdBytes, Endian.little);

    if (foundIds.contains(deviceId)) return null;
    foundIds.add(deviceId);

    final encryptData = data.sublist(40, data.length - 16);
    final reply = security.aesDecrypt(encryptData);
    if (reply.isEmpty) return null;

    final ssidLength = reply[40];
    final ssidBytes = reply.sublist(41, 41 + ssidLength);
    final ssid = String.fromCharCodes(ssidBytes);
    final deviceTypeStr = ssid.split('_')[1];
    final port = _bytes2Port(reply.sublist(4, 8));
    final model = String.fromCharCodes(reply.sublist(17, 25));
    final sn = String.fromCharCodes(reply.sublist(8, 40));

    return DiscoveredDevice(
      deviceId: deviceId,
      type: int.parse(deviceTypeStr, radix: 16),
      ipAddress: ip,
      port: port,
      model: model,
      sn: sn,
      protocol: protocol,
    );
  }

  static DiscoveredDevice? _parseProtocol3(
    Uint8List data,
    String ip,
    LocalSecurity security,
    Set<int> foundIds,
  ) {
    final protocol = 3;
    final actualData = data.sublist(8, data.length - 16);
    final deviceIdBytes = actualData.sublist(20, 26);
    final deviceId = _bytesToInt(deviceIdBytes, Endian.little);

    if (foundIds.contains(deviceId)) return null;
    foundIds.add(deviceId);

    final encryptData = actualData.sublist(40, actualData.length - 16);
    final reply = security.aesDecrypt(encryptData);
    if (reply.isEmpty) return null;

    final ssidLength = reply[40];
    final ssidBytes = reply.sublist(41, 41 + ssidLength);
    final ssid = String.fromCharCodes(ssidBytes);
    final deviceTypeStr = ssid.split('_')[1];
    final port = _bytes2Port(reply.sublist(4, 8));
    final model = String.fromCharCodes(reply.sublist(17, 25));
    final sn = String.fromCharCodes(reply.sublist(8, 40));

    return DiscoveredDevice(
      deviceId: deviceId,
      type: int.parse(deviceTypeStr, radix: 16),
      ipAddress: ip,
      port: port,
      model: model,
      sn: sn,
      protocol: protocol,
    );
  }

  static int _bytes2Port(Uint8List valueBytes) {
    var result = 0;
    for (var b = 0; b < _bytes2PortLength; b++) {
      final b1 = b < valueBytes.length ? valueBytes[b] & 0xFF : 0;
      result |= b1 << (b * 8);
    }
    return result;
  }

  static Future<List<String>> _enumAllBroadcast() async {
    final nets = <String>[];

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            final broadcast = _calculateBroadcastFromIp(ip);
            if (broadcast.isNotEmpty && !nets.contains(broadcast)) {
              nets.add(broadcast);
            }
          }
        }
      }
    } catch (e) {
      nets.add('192.168.1.255');
      nets.add('192.168.0.255');
    }

    return nets;
  }

  static String _calculateBroadcastFromIp(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length != 4) return '';
      final firstOctet = int.tryParse(parts[0]) ?? 0;
      final secondOctet = int.tryParse(parts[1]) ?? 0;

      if (firstOctet == 10) return '10.255.255.255';
      if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31)
        return '172.$secondOctet.255.255';
      return '${parts[0]}.${parts[1]}.${parts[2]}.255';
    } catch (e) {
      return '';
    }
  }

  static bool _bytesEqual(Uint8List a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _bytesToInt(Uint8List bytes, Endian endian) {
    var result = 0;
    for (var i = 0; i < bytes.length; i++) {
      if (endian == Endian.big) {
        result = (result << 8) | bytes[i];
      } else {
        result |= bytes[i] << (i * 8);
      }
    }
    return result;
  }
}

void main(List<String> args) async {
  print('Starting Midea device scan...');
  print('');

  final result = await Discover.discover(timeout: const Duration(seconds: 10));

  print('');
  print('Found ${result.length} device(s)');
  print('');

  for (final device in result) {
    print('=' * 40);
    print('Device ID: ${device.deviceId}');
    print('  IP: ${device.ipAddress}');
    print('  Port: ${device.port}');
    print('  Type: 0x${device.type.toRadixString(16).toUpperCase()}');
    print('  Model: ${device.model}');
    print('  SN: ${device.sn}');
    print('  Protocol: ${device.protocol}');
  }

  exit(0);
}
