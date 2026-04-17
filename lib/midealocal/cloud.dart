/// Midea cloud client. Mirrors midealocal/cloud.py (MideaCloud / MeijuCloud).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'security.dart';

// ---------------------------------------------------------------------------
// Supported cloud definitions
// ---------------------------------------------------------------------------

const Map<String, Map<String, String>> supportedClouds = {
  '美的美居': {
    'class_name': 'MeijuCloud',
    'app_id': '900',
    'app_key': '46579c15',
    'login_key': 'ad0ee21d48a64bf49f4fb583ab76e799',
    // bytes.fromhex(format(9795516279659324117647275084689641883661667,"x")).decode()
    'iot_key': 'prod_secret123@muc',
    // bytes.fromhex(format(117390035944627627450677220413733956185864939010425,"x")).decode()
    'hmac_key': 'PROD_VnoClJI9aikS8dyy',
    'api_url': 'https://mp-prod.smartmidea.net/mas/v5/app/proxy?alias=',
  },
  'NetHome Plus': {
    'class_name': 'MideaAirCloud',
    'default': 'true',
    'app_id': '1017',
    'app_key': '3742e9e5842d4ad59c2db887e12449f9',
    'api_url': 'https://mapp.appsmb.com',
  },
  'Midea Air': {
    'class_name': 'MideaAirCloud',
    'app_id': '1117',
    'app_key': 'ff0cf6f5f0c3471de36341cab3f7a9af',
    'api_url': 'https://mapp.appsmb.com',
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _randomHex(int numBytes) {
  final rng = Random.secure();
  return List.generate(
    numBytes,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String _utcStamp() {
  final t = DateTime.now().toUtc();
  String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
  return '${p(t.year, 4)}${p(t.month)}${p(t.day)}${p(t.hour)}${p(t.minute)}${p(t.second)}';
}

// ---------------------------------------------------------------------------
// Abstract base
// ---------------------------------------------------------------------------

abstract class MideaCloud {
  MideaCloud({
    required CloudSecurity security,
    required String appId,
    required String appKey,
    required String account,
    required String password,
    required String apiUrl,
  })  : _security = security,
        _appId = appId,
        _appKey = appKey,
        _account = account,
        _password = password,
        _apiUrl = apiUrl,
        _deviceId = CloudSecurity.getDeviceId(account);

  final CloudSecurity _security;
  final String _appId;
  // ignore: unused_field
  final String _appKey;
  final String _account;
  final String _password;
  final String _apiUrl;
  final String _deviceId;
  String? _accessToken;
  String? _uid;
  String _loginId = '';

  /// Subclasses return cloud-specific base parameters for every request.
  Map<String, dynamic> makeGeneralData() => {};

  /// POST to [_apiUrl + endpoint] with JSON body and HMAC-signed header.
  /// Returns response["data"] on success (code == 0), null otherwise.
  Future<Map<String, dynamic>?> apiRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    if (!data.containsKey('reqId') || data['reqId'] == null) {
      data['reqId'] = _randomHex(16);
    }
    if (!data.containsKey('stamp') || data['stamp'] == null) {
      data['stamp'] = _utcStamp();
    }
    final random =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final url = _apiUrl + endpoint;
    final body = jsonEncode(data);
    final sign = _security.sign('', body, random) ?? '';

    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'secretVersion': '1',
      'sign': sign,
      'random': random,
    };
    if (_uid != null) headers['uid'] = _uid!;
    if (_accessToken != null) headers['accessToken'] = _accessToken!;

    for (var i = 0; i < 3; i++) {
      try {
        final resp = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 10));
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        if (int.parse(json['code'].toString()) == 0 &&
            json.containsKey('data')) {
          return json['data'] as Map<String, dynamic>;
        }
        return null;
      } catch (_) {
        // retry on timeout / network error
      }
    }
    return null;
  }

  Future<String?> _getLoginId() async {
    final data = makeGeneralData()..['loginAccount'] = _account;
    final resp = await apiRequest('/v1/user/login/id/get', data);
    return resp?['loginId'] as String?;
  }

  Future<bool> login();

  Future<Map<int, Map<String, dynamic>>?> listAppliances(String? homeId);

  /// Fetch token + key pairs for [applianceId] from the cloud.
  /// Returns {1: {token: ..., key: ...}, 2: {...}} mirroring get_cloud_keys().
  Future<Map<int, Map<String, String>>> getCloudKeys(int applianceId) async {
    final result = <int, Map<String, String>>{};
    for (final method in [1, 2]) {
      final udpId = CloudSecurity.getUdpId(applianceId, method);
      if (udpId == null) continue;
      final data = makeGeneralData()..['udpid'] = udpId;
      final resp = await apiRequest('/v1/iot/secure/getToken', data);
      if (resp != null && resp.containsKey('tokenlist')) {
        for (final token in resp['tokenlist'] as List) {
          final t = token as Map<String, dynamic>;
          if (t['udpId'] == udpId) {
            result[method] = {
              'token': (t['token'] as String).toLowerCase(),
              'key': (t['key'] as String).toLowerCase(),
            };
          }
        }
      }
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// MeijuCloud ("美的美居")
// ---------------------------------------------------------------------------

class MeijuCloud extends MideaCloud {
  MeijuCloud._({
    required super.security,
    required super.appId,
    required super.appKey,
    required super.account,
    required super.password,
    required super.apiUrl,
  });

  factory MeijuCloud(String cloudName, String account, String password) {
    final c = supportedClouds[cloudName]!;
    return MeijuCloud._(
      security: MeijuCloudSecurity(
        loginKey: c['login_key']!,
        iotKey: c['iot_key']!,
        hmacKey: c['hmac_key']!,
      ),
      appId: c['app_id']!,
      appKey: c['app_key']!,
      account: account,
      password: password,
      apiUrl: c['api_url']!,
    );
  }

  @override
  Map<String, dynamic> makeGeneralData() => {
        'src': _appId,
        'format': '2',
        'stamp': _utcStamp(),
        'platformId': '1',
        'deviceId': _deviceId,
        'reqId': _randomHex(16),
        'uid': _uid,
        'clientType': '1',
        'appId': _appId,
        'language': 'en_US',
      };

  @override
  Future<bool> login() async {
    final loginId = await _getLoginId();
    if (loginId == null) return false;
    _loginId = loginId;

    final stamp = _utcStamp();
    final data = <String, dynamic>{
      'iotData': {
        'clientType': 1,
        'deviceId': _deviceId,
        'iampwd': _security.encryptIamPassword(_loginId, _password),
        'iotAppId': _appId,
        'loginAccount': _account,
        'password': _security.encryptPassword(_loginId, _password),
        'reqId': _randomHex(16),
        'stamp': stamp,
      },
      'data': {
        'appKey': _appKey,
        'deviceId': _deviceId,
        'platform': 2,
      },
      'timestamp': stamp,
      'stamp': stamp,
    };

    final resp = await apiRequest('/mj/user/login', data);
    if (resp == null) return false;

    _accessToken =
        (resp['mdata'] as Map<String, dynamic>)['accessToken'] as String;
    final decryptedKey =
        _security.aesDecryptWithFixedKey(resp['key'] as String);
    // b"0" in Python == Uint8List([0x30]) — triggers ECB mode
    _security.setAesKeys(decryptedKey, Uint8List.fromList([0x30]));
    return true;
  }

  @override
  Future<Map<int, Map<String, dynamic>>?> listAppliances(
    String? homeId,
  ) async {
    final data = makeGeneralData()..['homegroupId'] = homeId;

    final resp = await apiRequest('/v1/appliance/home/list/get', data);
    if (resp == null) return null;

    final appliances = <int, Map<String, dynamic>>{};
    for (final home in (resp['homeList'] as List? ?? [])) {
      final homeMap = home as Map<String, dynamic>;
      for (final room in (homeMap['roomList'] as List? ?? [])) {
        final roomMap = room as Map<String, dynamic>;
        for (final appliance in (roomMap['applianceList'] as List? ?? [])) {
          final a = appliance as Map<String, dynamic>;

          int modelNumber = 0;
          try {
            modelNumber = int.parse(a['modelNumber']?.toString() ?? '0');
          } catch (_) {}

          String sn = '';
          final snRaw = a['sn'] as String?;
          if (snRaw != null && snRaw.isNotEmpty) {
            try {
              sn = _security.aesDecrypt(snRaw);
            } catch (_) {}
          }

          String sn8 = (a['sn8'] as String?) ?? '00000000';
          if (sn8.isEmpty) sn8 = '00000000';

          String? model = a['productModel'] as String?;
          if (model == null || model.isEmpty) model = sn8;

          final deviceInfo = <String, dynamic>{
            'name': a['name'] as String?,
            'type': int.parse(a['type'] as String),
            'sn': sn,
            'sn8': sn8,
            'model_number': modelNumber,
            'manufacturer_code': (a['enterpriseCode'] as String?) ?? '0000',
            'model': model,
            'online': a['onlineStatus'] == '1',
          };

          appliances[int.parse(a['applianceCode'].toString())] = deviceInfo;
        }
      }
    }
    return appliances;
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

MideaCloud getMideaCloud(String cloudName, String account, String password) {
  final cloudData = supportedClouds[cloudName];
  if (cloudData == null) throw ArgumentError('Unknown cloud: $cloudName');
  switch (cloudData['class_name']) {
    case 'MeijuCloud':
      return MeijuCloud(cloudName, account, password);
    case 'MideaAirCloud':
      return MideaAirCloud(cloudName, account, password);
    default:
      throw ArgumentError(
        'Unsupported cloud class: ${cloudData['class_name']}',
      );
  }
}

// ---------------------------------------------------------------------------
// Preset account (NetHome Plus built-in credentials)
// ---------------------------------------------------------------------------

/// Decode preset credentials using the same XOR scheme as Python's
/// get_preset_account_cloud(). Uses BigInt for 128-bit arithmetic.
Map<String, String> getPresetAccountCloud() {
  const raw = [
    '39182118275972017797890111985649342047468653967530949796945843010512',
    '39182118275980892824833804202177448991093361348247890162501600564413',
    '39182118275972017797890111985649342050088014265865102175083010656997',
  ];
  final a = BigInt.parse(raw[0]);
  final b = BigInt.parse(raw[1]);
  final c = BigInt.parse(raw[2]);

  String bigIntToString(BigInt n) {
    var hex = n.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    return String.fromCharCodes(List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ));
  }

  return {
    'username': bigIntToString(a ^ b),
    'password': bigIntToString(a ^ c),
    'cloud_name': 'NetHome Plus',
  };
}

// ---------------------------------------------------------------------------
// MideaAirCloud ("NetHome Plus" / "Midea Air")
// ---------------------------------------------------------------------------

class MideaAirCloud extends MideaCloud {
  MideaAirCloud._({
    required super.security,
    required super.appId,
    required super.appKey,
    required super.account,
    required super.password,
    required super.apiUrl,
  });

  factory MideaAirCloud(String cloudName, String account, String password) {
    final c = supportedClouds[cloudName]!;
    return MideaAirCloud._(
      security: MideaAirSecurity(loginKey: c['app_key']!),
      appId: c['app_id']!,
      appKey: c['app_key']!,
      account: account,
      password: password,
      apiUrl: c['api_url']!,
    );
  }

  String? _sessionId;

  @override
  Map<String, dynamic> makeGeneralData() {
    final data = <String, dynamic>{
      'src': _appId,
      'format': '2',
      'stamp': _utcStamp(),
      'deviceId': _deviceId,
      'reqId': _randomHex(16),
      'clientType': '1',
      'appId': _appId,
    };
    if (_sessionId != null) data['sessionId'] = _sessionId;
    return data;
  }

  /// MideaAirCloud uses form-encoded POST and signs by sorting data params.
  /// Response format: {"errorCode": 0, "result": {...}}
  @override
  Future<Map<String, dynamic>?> apiRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = _apiUrl + endpoint;
    // Sign is computed on the data map (before adding sign itself)
    final sign = _security.sign(url, data, '') ?? '';
    data['sign'] = sign;

    final headers = <String, String>{};
    if (_uid != null) headers['uid'] = _uid!;
    if (_accessToken != null) headers['accessToken'] = _accessToken!;

    // Convert all values to String for form encoding
    final formData = data.map((k, v) => MapEntry(k, v.toString()));

    for (var i = 0; i < 3; i++) {
      try {
        final resp = await http
            .post(Uri.parse(url), headers: headers, body: formData)
            .timeout(const Duration(seconds: 10));
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        if (int.parse(json['errorCode'].toString()) == 0 &&
            json.containsKey('result')) {
          return json['result'] as Map<String, dynamic>;
        }
        return null;
      } catch (_) {
        // retry
      }
    }
    return null;
  }

  @override
  Future<bool> login() async {
    final loginId = await _getLoginId();
    if (loginId == null) return false;
    _loginId = loginId;

    final data = makeGeneralData()
      ..['loginAccount'] = _account
      ..['password'] = _security.encryptPassword(_loginId, _password);

    final resp = await apiRequest('/v1/user/login', data);
    if (resp == null) return false;

    _accessToken = resp['accessToken'] as String;
    _uid = resp['userId'] as String?;
    _sessionId = resp['sessionId'] as String?;
    return true;
  }

  @override
  Future<Map<int, Map<String, dynamic>>?> listAppliances(String? homeId) async {
    final data = makeGeneralData();
    final resp = await apiRequest('/v1/appliance/user/list/get', data);
    if (resp == null) return null;

    const snMinLen = 17;
    final appliances = <int, Map<String, dynamic>>{};
    for (final appliance in resp['list'] as List) {
      final a = appliance as Map<String, dynamic>;
      int modelNumber = 0;
      try {
        modelNumber = int.parse(a['modelNumber']?.toString() ?? '0');
      } catch (_) {}
      final sn = a['sn'] as String? ?? '';
      final sn8 = (sn.length > snMinLen) ? sn.substring(9, 17) : '';
      appliances[int.parse(a['id'].toString())] = {
        'name': a['name'],
        'type': int.parse(a['type'] as String, radix: 16),
        'sn': sn,
        'sn8': sn8,
        'model_number': modelNumber,
        'manufacturer_code': a['enterpriseCode'] ?? '0000',
        'model': sn8,
        'online': a['onlineStatus'] == '1',
      };
    }
    return appliances;
  }
}
