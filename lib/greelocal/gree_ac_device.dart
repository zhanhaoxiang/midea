import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'gree_crypto.dart';

const String genericKey = 'a3K8Bx%2r8Y7#xDh';
String encryptionType = 'ECB';
const String genericGcmKey = '{yxAHAY_Lm6pbC/<';
const List<int> gcmIv = <int>[
  0x54,
  0x40,
  0x78,
  0x44,
  0x49,
  0x67,
  0x5a,
  0x51,
  0x6c,
  0x5e,
  0x63,
  0x13,
];
const List<int> gcmAdd = <int>[
  0x71,
  0x75,
  0x61,
  0x6c,
  0x63,
  0x6f,
  0x6d,
  0x6d,
  0x2d,
  0x74,
  0x65,
  0x73,
  0x74,
];
const int greePort = 7000;

class ScanResult {
  ScanResult(
    this.ip,
    this.port,
    this.id, [
    this.name = '<unknown>',
    this.encryptionType = 'ECB',
  ]);

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        json['ip'] as String,
        json['port'] as int,
        json['id'] as String,
        json['name'] as String? ?? '<unknown>',
        json['encryptionType'] as String? ?? 'ECB',
      );

  String ip = '';
  int port = 0;
  String id = '';
  String name = '<unknown>';
  String encryptionType = 'ECB';

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'id': id,
        'name': name,
        'encryptionType': encryptionType,
      };
}

String addPkcs7Padding(String data) {
  final padLength = 16 - (data.length % 16);
  return data + String.fromCharCode(padLength) * padLength;
}

String decrypt(String packEncoded, String key) =>
    GreeCrypto.decryptEcb(packEncoded, key);

String decryptGeneric(String packEncoded) =>
    GreeCrypto.decryptGenericEcb(packEncoded);

String encrypt(String pack, String key) => GreeCrypto.encryptEcb(pack, key);

String encryptGeneric(String pack) => GreeCrypto.encryptGenericEcb(pack);

String decryptGcm(String packEncoded, String tagEncoded, String key) =>
    GreeCrypto.decryptGcm(packEncoded, tagEncoded, key);

String decryptGcmGeneric(String packEncoded, String tagEncoded) =>
    GreeCrypto.decryptGenericGcm(packEncoded, tagEncoded);

Map<String, String> encryptGcm(String pack, String key) {
  final encrypted = GreeCrypto.encryptGcm(pack, key);
  return <String, String>{
    'pack': encrypted.pack,
    'tag': encrypted.tag,
  };
}

Map<String, String> encryptGcmGeneric(String pack) {
  final encrypted = GreeCrypto.encryptGenericGcm(pack);
  return <String, String>{
    'pack': encrypted.pack,
    'tag': encrypted.tag,
  };
}

Future<Uint8List> sendData(String ip, int port, List<int> data) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.send(Uint8List.fromList(data), InternetAddress(ip), port);

  final completer = Completer<Uint8List>();
  Timer(const Duration(seconds: 5), () {
    socket.close();
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('No response from $ip:$port'));
    }
  });

  socket.listen((event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final datagram = socket.receive();
    if (datagram == null || completer.isCompleted) {
      return;
    }
    socket.close();
    completer.complete(datagram.data);
  });

  return completer.future;
}

String createRequest(String tcid, dynamic packEncrypted, [int i = 0]) {
  var request = '{"cid":"app","i":$i,"t":"pack","uid":0,"tcid":"$tcid",';
  if (packEncrypted is Map<String, String>) {
    request +=
        '"tag":"${packEncrypted["tag"]}","pack":"${packEncrypted["pack"]}"}';
  } else {
    request += '"pack":"$packEncrypted"}';
  }
  return request;
}

String createStatusRequestPack(String tcid) =>
    '{"cols":["Pow","Mod","SetTem","WdSpd","Air","Blo","Health","SwhSlp","Lig","SwingLfRig","SwUpDn","Quiet","Tur","StHt","TemUn","HeatCoolType","TemRec","SvSt"],"mac":"$tcid","t":"status"}';

ScanResult? parseScanResponse(String address, int port, Uint8List data) {
  try {
    final response = _decodeJson(data);
    if (response == null) {
      return null;
    }

    var encType = response.containsKey('tag') ? 'GCM' : 'ECB';
    final decryptedPack = _decryptGenericPack(response, encType);
    final pack = jsonDecode(decryptedPack) as Map<String, dynamic>;

    final packCid = pack['cid'] as String?;
    final responseCid = response['cid'] as String?;
    final cid = packCid != null && packCid.isNotEmpty
        ? packCid
        : responseCid ?? '<unknown-cid>';

    if (encType != 'GCM' && pack.containsKey('ver')) {
      final match = RegExp(r'V(\d+)').firstMatch(pack['ver'] as String);
      if (match != null && int.parse(match.group(1)!) >= 2) {
        encType = 'GCM';
      }
    }

    return ScanResult(
      address,
      port,
      cid,
      pack['name'] as String? ?? '<unknown>',
      encType,
    );
  } catch (_) {
    return null;
  }
}

Future<List<ScanResult>> searchDevices({
  required String broadcast,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  socket.send(
    Uint8List.fromList(utf8.encode('{"t":"scan"}')),
    InternetAddress(broadcast),
    greePort,
  );

  final results = <ScanResult>[];
  final completer = Completer<void>();
  Timer(timeout, socket.close);

  socket.listen(
    (event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = socket.receive();
      if (datagram == null) {
        return;
      }
      final result = parseScanResponse(
        datagram.address.address,
        datagram.port,
        datagram.data,
      );
      if (result != null) {
        results.add(result);
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
  );

  await completer.future;
  for (final result in results) {
    await bindDevice(result);
  }
  return results;
}

Future<String?> bindDevice(ScanResult searchResult) async {
  final pack = '{"mac":"${searchResult.id}","t":"bind","uid":0}';
  final packEncrypted = searchResult.encryptionType == 'GCM'
      ? encryptGcmGeneric(pack)
      : encryptGeneric(pack);
  final request = createRequest(searchResult.id, packEncrypted, 1);

  try {
    final result = await sendData(
      searchResult.ip,
      greePort,
      utf8.encode(request),
    );
    final response = _decodeJson(result);
    if (response == null || response['t'] != 'pack') {
      return null;
    }

    final decryptedPack = _decryptGenericPack(
      response,
      searchResult.encryptionType,
    );
    final bindResponse = jsonDecode(decryptedPack) as Map<String, dynamic>;
    if ((bindResponse['t'] as String?)?.toLowerCase() == 'bindok') {
      return bindResponse['key'] as String;
    }
  } on TimeoutException {
    if (searchResult.encryptionType != 'GCM') {
      searchResult.encryptionType = 'GCM';
      return bindDevice(searchResult);
    }
  } catch (_) {}

  return null;
}

Future<Map<String, dynamic>?> getParam({
  required String client,
  required String id,
  required String key,
  required List<String> params,
}) async {
  final cols = params.map((value) => '"$value"').join(',');
  final pack = '{"cols":[$cols],"mac":"$id","t":"status"}';
  final packEncrypted = encryptionType == 'GCM'
      ? encryptGcm(pack, key)
      : encrypt(pack, key);
  final request = createRequest(id, packEncrypted);

  final result = await sendData(client, greePort, utf8.encode(request));
  final response = _decodeJson(result);
  if (response == null || response['t'] != 'pack') {
    return null;
  }

  final packText = _decryptDevicePack(response, key);
  final packJson = jsonDecode(packText) as Map<String, dynamic>;
  final colsList = (packJson['cols'] as List).cast<String>();
  final datList = (packJson['dat'] as List).cast<dynamic>();
  return Map<String, dynamic>.fromIterables(colsList, datList);
}

Future<void> setParam({
  required String client,
  required String id,
  required String key,
  required List<String> params,
}) async {
  final kvList = params.map((value) => value.split('=')).toList();
  final errors = kvList.where((pair) => pair.length != 2).toList();
  if (errors.isNotEmpty) {
    throw ArgumentError('Invalid parameters detected: $errors');
  }

  final opts = kvList.map((pair) => '"${pair[0]}"').join(',');
  final ps = kvList.map((pair) => pair[1]).join(',');
  final pack = '{"opt":[$opts],"p":[$ps],"t":"cmd"}';
  final packEncrypted = encryptionType == 'GCM'
      ? encryptGcm(pack, key)
      : encrypt(pack, key);
  final request = createRequest(id, packEncrypted);

  final result = await sendData(client, greePort, utf8.encode(request));
  final response = _decodeJson(result);
  if (response == null || response['t'] != 'pack') {
    throw StateError('Unexpected response type: ${response?["t"]}');
  }

  final packText = _decryptDevicePack(response, key);
  final packJson = jsonDecode(packText) as Map<String, dynamic>;
  if (packJson['r'] != 200) {
    throw StateError('Failed to set parameter');
  }
}

Uint8List? _trimJson(Uint8List data) {
  for (var i = data.length - 1; i >= 0; i--) {
    if (data[i] == 0x7d) {
      return data.sublist(0, i + 1);
    }
  }
  return null;
}

Map<String, dynamic>? _decodeJson(Uint8List data) {
  final trimmed = _trimJson(data);
  if (trimmed == null) {
    return null;
  }
  return jsonDecode(utf8.decode(trimmed)) as Map<String, dynamic>;
}

String _decryptGenericPack(
  Map<String, dynamic> response,
  String encType,
) {
  if (encType == 'GCM') {
    return GreeCrypto.decryptGenericGcm(
      response['pack'] as String,
      response['tag'] as String,
    );
  }
  return GreeCrypto.decryptGenericEcb(response['pack'] as String);
}

String _decryptDevicePack(Map<String, dynamic> response, String key) {
  if (encryptionType == 'GCM') {
    return GreeCrypto.decryptGcm(
      response['pack'] as String,
      response['tag'] as String,
      key,
    );
  }
  return GreeCrypto.decryptEcb(response['pack'] as String, key);
}
