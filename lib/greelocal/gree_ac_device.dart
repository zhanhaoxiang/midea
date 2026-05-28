import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'gree_crypto.dart';

const String GENERIC_KEY = 'a3K8Bx%2r8Y7#xDh';
String ENCRYPTION_TYPE = 'ECB';
const String GENERIC_GCM_KEY = '{yxAHAY_Lm6pbC/<';
const List<int> GCM_IV = <int>[
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
const List<int> GCM_ADD = <int>[
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
const int GREE_PORT = 7000;

class ScanResult {
  ScanResult(
    this.ip,
    this.port,
    this.id, [
    this.name = '<unknown>',
    this.encryption_type = 'ECB',
  ]);

  String ip = '';
  int port = 0;
  String id = '';
  String name = '<unknown>';
  String encryption_type = 'ECB';
}

String add_pkcs7_padding(String data) {
  final pad_length = 16 - (data.length % 16);
  return data + String.fromCharCode(pad_length) * pad_length;
}

String decrypt(String pack_encoded, String key) =>
    GreeCrypto.decryptEcb(pack_encoded, key);

String decrypt_generic(String pack_encoded) =>
    GreeCrypto.decryptGenericEcb(pack_encoded);

String encrypt(String pack, String key) => GreeCrypto.encryptEcb(pack, key);

String encrypt_generic(String pack) => GreeCrypto.encryptGenericEcb(pack);

String decrypt_GCM(String pack_encoded, String tag_encoded, String key) =>
    GreeCrypto.decryptGcm(pack_encoded, tag_encoded, key);

String decrypt_GCM_generic(String pack_encoded, String tag_encoded) =>
    GreeCrypto.decryptGenericGcm(pack_encoded, tag_encoded);

Map<String, String> encrypt_GCM(String pack, String key) {
  final encrypted = GreeCrypto.encryptGcm(pack, key);
  return <String, String>{
    'pack': encrypted.pack,
    'tag': encrypted.tag,
  };
}

Map<String, String> encrypt_GCM_generic(String pack) {
  final encrypted = GreeCrypto.encryptGenericGcm(pack);
  return <String, String>{
    'pack': encrypted.pack,
    'tag': encrypted.tag,
  };
}

Future<Uint8List> send_data(String ip, int port, List<int> data) async {
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

String create_request(String tcid, dynamic pack_encrypted, [int i = 0]) {
  var request = '{"cid":"app","i":$i,"t":"pack","uid":0,"tcid":"$tcid",';
  if (pack_encrypted is Map<String, String>) {
    request +=
        '"tag":"${pack_encrypted["tag"]}","pack":"${pack_encrypted["pack"]}"}';
  } else {
    request += '"pack":"$pack_encrypted"}';
  }
  return request;
}

String create_status_request_pack(String tcid) =>
    '{"cols":["Pow","Mod","SetTem","WdSpd","Air","Blo","Health","SwhSlp","Lig","SwingLfRig","SwUpDn","Quiet","Tur","StHt","TemUn","HeatCoolType","TemRec","SvSt"],"mac":"$tcid","t":"status"}';

ScanResult? parse_scan_response(String address, int port, Uint8List data) {
  try {
    final response = _decode_json(data);
    if (response == null) {
      return null;
    }

    var encryption_type = response.containsKey('tag') ? 'GCM' : 'ECB';
    final decrypted_pack = _decrypt_generic_pack(response, encryption_type);
    final pack = jsonDecode(decrypted_pack) as Map<String, dynamic>;

    final pack_cid = pack['cid'] as String?;
    final response_cid = response['cid'] as String?;
    final cid = pack_cid != null && pack_cid.isNotEmpty
        ? pack_cid
        : response_cid ?? '<unknown-cid>';

    if (encryption_type != 'GCM' && pack.containsKey('ver')) {
      final match = RegExp(r'V(\d+)').firstMatch(pack['ver'] as String);
      if (match != null && int.parse(match.group(1)!) >= 2) {
        encryption_type = 'GCM';
      }
    }

    return ScanResult(
      address,
      port,
      cid,
      pack['name'] as String? ?? '<unknown>',
      encryption_type,
    );
  } catch (_) {
    return null;
  }
}

Future<List<ScanResult>> search_devices({
  required String broadcast,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  socket.send(
    Uint8List.fromList(utf8.encode('{"t":"scan"}')),
    InternetAddress(broadcast),
    GREE_PORT,
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
      final result = parse_scan_response(
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
    await bind_device(result);
  }
  return results;
}

Future<String?> bind_device(ScanResult search_result) async {
  final pack = '{"mac":"${search_result.id}","t":"bind","uid":0}';
  final pack_encrypted = search_result.encryption_type == 'GCM'
      ? encrypt_GCM_generic(pack)
      : encrypt_generic(pack);
  final request = create_request(search_result.id, pack_encrypted, 1);

  try {
    final result = await send_data(
      search_result.ip,
      GREE_PORT,
      utf8.encode(request),
    );
    final response = _decode_json(result);
    if (response == null || response['t'] != 'pack') {
      return null;
    }

    final decrypted_pack = _decrypt_generic_pack(
      response,
      search_result.encryption_type,
    );
    final bind_response = jsonDecode(decrypted_pack) as Map<String, dynamic>;
    if ((bind_response['t'] as String?)?.toLowerCase() == 'bindok') {
      return bind_response['key'] as String;
    }
  } on TimeoutException {
    if (search_result.encryption_type != 'GCM') {
      search_result.encryption_type = 'GCM';
      return bind_device(search_result);
    }
  } catch (_) {}

  return null;
}

Future<Map<String, dynamic>?> get_param({
  required String client,
  required String id,
  required String key,
  required List<String> params,
}) async {
  final cols = params.map((value) => '"$value"').join(',');
  final pack = '{"cols":[$cols],"mac":"$id","t":"status"}';
  final pack_encrypted = ENCRYPTION_TYPE == 'GCM'
      ? encrypt_GCM(pack, key)
      : encrypt(pack, key);
  final request = create_request(id, pack_encrypted);

  final result = await send_data(client, GREE_PORT, utf8.encode(request));
  final response = _decode_json(result);
  if (response == null || response['t'] != 'pack') {
    return null;
  }

  final pack_text = _decrypt_device_pack(response, key);
  final pack_json = jsonDecode(pack_text) as Map<String, dynamic>;
  final cols_list = (pack_json['cols'] as List).cast<String>();
  final dat_list = (pack_json['dat'] as List).cast<dynamic>();
  return Map<String, dynamic>.fromIterables(cols_list, dat_list);
}

Future<void> set_param({
  required String client,
  required String id,
  required String key,
  required List<String> params,
}) async {
  final kv_list = params.map((value) => value.split('=')).toList();
  final errors = kv_list.where((pair) => pair.length != 2).toList();
  if (errors.isNotEmpty) {
    throw ArgumentError('Invalid parameters detected: $errors');
  }

  final opts = kv_list.map((pair) => '"${pair[0]}"').join(',');
  final ps = kv_list.map((pair) => pair[1]).join(',');
  final pack = '{"opt":[$opts],"p":[$ps],"t":"cmd"}';
  final pack_encrypted = ENCRYPTION_TYPE == 'GCM'
      ? encrypt_GCM(pack, key)
      : encrypt(pack, key);
  final request = create_request(id, pack_encrypted);

  final result = await send_data(client, GREE_PORT, utf8.encode(request));
  final response = _decode_json(result);
  if (response == null || response['t'] != 'pack') {
    throw StateError('Unexpected response type: ${response?["t"]}');
  }

  final pack_text = _decrypt_device_pack(response, key);
  final pack_json = jsonDecode(pack_text) as Map<String, dynamic>;
  if (pack_json['r'] != 200) {
    throw StateError('Failed to set parameter');
  }
}

Uint8List? _trim_json(Uint8List data) {
  for (var i = data.length - 1; i >= 0; i--) {
    if (data[i] == 0x7d) {
      return data.sublist(0, i + 1);
    }
  }
  return null;
}

Map<String, dynamic>? _decode_json(Uint8List data) {
  final trimmed = _trim_json(data);
  if (trimmed == null) {
    return null;
  }
  return jsonDecode(utf8.decode(trimmed)) as Map<String, dynamic>;
}

String _decrypt_generic_pack(
  Map<String, dynamic> response,
  String encryption_type,
) {
  if (encryption_type == 'GCM') {
    return GreeCrypto.decryptGenericGcm(
      response['pack'] as String,
      response['tag'] as String,
    );
  }
  return GreeCrypto.decryptGenericEcb(response['pack'] as String);
}

String _decrypt_device_pack(Map<String, dynamic> response, String key) {
  if (ENCRYPTION_TYPE == 'GCM') {
    return GreeCrypto.decryptGcm(
      response['pack'] as String,
      response['tag'] as String,
      key,
    );
  }
  return GreeCrypto.decryptEcb(response['pack'] as String, key);
}
