import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'gree_crypto.dart';

const int _greePort = 7000;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum GreeEncryptionType { ecb, gcm }

enum GreeMode {
  auto(0),
  cool(1),
  dry(2),
  fan(3),
  heat(4);

  const GreeMode(this.value);
  final int value;

  static GreeMode fromValue(int v) =>
      GreeMode.values.firstWhere((e) => e.value == v, orElse: () => GreeMode.auto);
}

enum GreeFanSpeed {
  auto(0),
  low(1),
  medLow(2),
  medium(3),
  medHigh(4),
  high(5);

  const GreeFanSpeed(this.value);
  final int value;

  static GreeFanSpeed fromValue(int v) =>
      GreeFanSpeed.values.firstWhere((e) => e.value == v, orElse: () => GreeFanSpeed.auto);
}

enum GreeTemperatureUnit {
  celsius(0),
  fahrenheit(1);

  const GreeTemperatureUnit(this.value);
  final int value;
}

// ---------------------------------------------------------------------------
// GreeParameter – device protocol key constants
// ---------------------------------------------------------------------------

class GreeParameter {
  static const String power = 'Pow';
  static const String mode = 'Mod';
  static const String temperature = 'SetTem';
  static const String fanSpeed = 'WdSpd';
  static const String freshAir = 'Air';
  static const String xfan = 'Blo';
  static const String health = 'Health';
  static const String sleep = 'SwhSlp';
  static const String light = 'Lig';
  static const String horizontalSwing = 'SwingLfRig';
  static const String verticalSwing = 'SwUpDn';
  static const String quiet = 'Quiet';
  static const String turbo = 'Tur';
  static const String antiFreeze = 'StHt';
  static const String temperatureUnit = 'TemUn';
  static const String heatCoolType = 'HeatCoolType';
  static const String temperatureCorrection = 'TemRec';
  static const String energySaving = 'SvSt';

  static const List<String> all = [
    power, mode, temperature, fanSpeed, freshAir, xfan, health, sleep,
    light, horizontalSwing, verticalSwing, quiet, turbo, antiFreeze,
    temperatureUnit, heatCoolType, temperatureCorrection, energySaving,
  ];
}

// ---------------------------------------------------------------------------
// GreeDeviceStatus – typed snapshot of device state
// ---------------------------------------------------------------------------

class GreeDeviceStatus {
  const GreeDeviceStatus({
    required this.power,
    required this.mode,
    required this.temperature,
    required this.fanSpeed,
    required this.freshAir,
    required this.xfan,
    required this.health,
    required this.sleep,
    required this.light,
    required this.horizontalSwing,
    required this.verticalSwing,
    required this.quiet,
    required this.turbo,
    required this.antiFreeze,
    required this.temperatureUnit,
    required this.energySaving,
  });

  final bool power;
  final GreeMode mode;
  final int temperature;
  final GreeFanSpeed fanSpeed;
  final bool freshAir;
  final bool xfan;
  final bool health;
  final bool sleep;
  final bool light;
  final int horizontalSwing;
  final int verticalSwing;
  final bool quiet;
  final bool turbo;
  final bool antiFreeze;
  final GreeTemperatureUnit temperatureUnit;
  final bool energySaving;

  factory GreeDeviceStatus.fromRaw(Map<String, dynamic> raw) {
    int getInt(String key, [int def = 0]) => (raw[key] as int?) ?? def;
    bool getBool(String key) => getInt(key) != 0;

    return GreeDeviceStatus(
      power: getBool(GreeParameter.power),
      mode: GreeMode.fromValue(getInt(GreeParameter.mode)),
      temperature: getInt(GreeParameter.temperature, 24),
      fanSpeed: GreeFanSpeed.fromValue(getInt(GreeParameter.fanSpeed)),
      freshAir: getBool(GreeParameter.freshAir),
      xfan: getBool(GreeParameter.xfan),
      health: getBool(GreeParameter.health),
      sleep: getBool(GreeParameter.sleep),
      light: getBool(GreeParameter.light),
      horizontalSwing: getInt(GreeParameter.horizontalSwing),
      verticalSwing: getInt(GreeParameter.verticalSwing),
      quiet: getBool(GreeParameter.quiet),
      turbo: getBool(GreeParameter.turbo),
      antiFreeze: getBool(GreeParameter.antiFreeze),
      temperatureUnit: getInt(GreeParameter.temperatureUnit) == 1
          ? GreeTemperatureUnit.fahrenheit
          : GreeTemperatureUnit.celsius,
      energySaving: getBool(GreeParameter.energySaving),
    );
  }

  @override
  String toString() =>
      'GreeDeviceStatus(power=$power, mode=$mode, temp=${temperature}°, '
      'fan=$fanSpeed, health=$health, sleep=$sleep, turbo=$turbo, quiet=$quiet)';
}

// ---------------------------------------------------------------------------
// GreeAcDevice
// ---------------------------------------------------------------------------

class GreeAcDevice {
  GreeAcDevice({
    required this.ip,
    required this.port,
    required this.deviceId,
    this.name = '',
    this.encryptionType = GreeEncryptionType.ecb,
    this.deviceKey,
  });

  final String ip;
  final int port;
  final String deviceId;
  String name;
  GreeEncryptionType encryptionType;
  String? deviceKey;

  bool get isBound => deviceKey != null;

  // ---- Scan ---------------------------------------------------------------

  /// Broadcasts a scan packet and collects responding devices for [timeout].
  static Future<List<GreeAcDevice>> scan({
    required String broadcastAddress,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(
      Uint8List.fromList(utf8.encode('{"t":"scan"}')),
      InternetAddress(broadcastAddress),
      _greePort,
    );

    final results = <GreeAcDevice>[];
    final completer = Completer<void>();

    Timer(timeout, () => socket.close());

    socket.listen(
      (event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null) {
            final device = parseScanResponse(dg.address.address, dg.port, dg.data);
            if (device != null) results.add(device);
          }
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    return results;
  }

  /// Parses a raw scan datagram into a [GreeAcDevice]. Returns null on error.
  static GreeAcDevice? parseScanResponse(String address, int port, Uint8List data) {
    try {
      final trimmed = _trimJson(data);
      if (trimmed == null) return null;

      final resp = jsonDecode(utf8.decode(trimmed)) as Map<String, dynamic>;
      var encType = resp.containsKey('tag') ? GreeEncryptionType.gcm : GreeEncryptionType.ecb;

      final packDecrypted = encType == GreeEncryptionType.gcm
          ? GreeCrypto.decryptGenericGcm(resp['pack'] as String, resp['tag'] as String)
          : GreeCrypto.decryptGenericEcb(resp['pack'] as String);

      final pack = jsonDecode(packDecrypted) as Map<String, dynamic>;

      // Upgrade to GCM if firmware version is v2+.
      if (encType == GreeEncryptionType.ecb && pack.containsKey('ver')) {
        final verMatch = RegExp(r'V(\d+)').firstMatch(pack['ver'] as String);
        if (verMatch != null && int.parse(verMatch.group(1)!) >= 2) {
          encType = GreeEncryptionType.gcm;
        }
      }

      final cid = _resolveDeviceId(pack, resp);
      return GreeAcDevice(
        ip: address,
        port: port,
        deviceId: cid,
        name: pack['name'] as String? ?? '',
        encryptionType: encType,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- Bind ---------------------------------------------------------------

  /// Exchanges a bind request to obtain the device encryption key.
  /// Automatically retries with GCM if ECB fails.
  Future<bool> bind() async {
    final pack = '{"mac":"$deviceId","t":"bind","uid":0}';
    final request = _buildRequest(pack, useGenericKey: true, i: 1);
    try {
      final response = await _sendData(ip, port, utf8.encode(request));
      final json = _parseJson(response);
      if (json == null || json['t'] != 'pack') return false;

      final packDecrypted = _decryptGeneric(json);
      final bindResp = jsonDecode(packDecrypted) as Map<String, dynamic>;
      if ((bindResp['t'] as String?)?.toLowerCase() == 'bindok') {
        deviceKey = bindResp['key'] as String;
        return true;
      }
    } catch (_) {}

    if (encryptionType == GreeEncryptionType.ecb) {
      encryptionType = GreeEncryptionType.gcm;
      final retried = await bind();
      if (!retried) encryptionType = GreeEncryptionType.ecb;
      return retried;
    }
    return false;
  }

  // ---- Get status ---------------------------------------------------------

  /// Returns a raw key→value map for the requested [params] (defaults to all).
  Future<Map<String, dynamic>?> getRawStatus([List<String>? params]) async {
    if (deviceKey == null) return null;
    final cols = params ?? GreeParameter.all;
    final colsJson = cols.map((c) => '"$c"').join(',');
    final pack = '{"cols":[$colsJson],"mac":"$deviceId","t":"status"}';
    final request = _buildRequest(pack, useGenericKey: false);
    try {
      final response = await _sendData(ip, port, utf8.encode(request));
      final json = _parseJson(response);
      if (json == null || json['t'] != 'pack') return null;

      final pack2 = jsonDecode(_decryptDevice(json)) as Map<String, dynamic>;
      final keys = (pack2['cols'] as List).cast<String>();
      final values = (pack2['dat'] as List).cast<int>();
      return Map.fromIterables(keys, values);
    } catch (_) {}
    return null;
  }

  /// Returns a typed [GreeDeviceStatus], or null on failure.
  Future<GreeDeviceStatus?> getStatus() async {
    final raw = await getRawStatus();
    return raw != null ? GreeDeviceStatus.fromRaw(raw) : null;
  }

  // ---- Set parameters -----------------------------------------------------

  /// Sends key=value pairs as a CMD packet. Returns true if device responds r=200.
  Future<bool> setParameters(Map<String, dynamic> params) async {
    if (deviceKey == null) return false;
    final opts = params.keys.map((k) => '"$k"').join(',');
    final ps = params.values.map((v) => v.toString()).join(',');
    final pack = '{"opt":[$opts],"p":[$ps],"t":"cmd"}';
    final request = _buildRequest(pack, useGenericKey: false);
    try {
      final response = await _sendData(ip, port, utf8.encode(request));
      final json = _parseJson(response);
      if (json == null || json['t'] != 'pack') return false;
      final pack2 = jsonDecode(_decryptDevice(json)) as Map<String, dynamic>;
      return (pack2['r'] as int?) == 200;
    } catch (_) {}
    return false;
  }

  // ---- Convenience setters ------------------------------------------------

  Future<bool> setPower(bool on) =>
      setParameters({GreeParameter.power: on ? 1 : 0});

  Future<bool> setMode(GreeMode mode) =>
      setParameters({GreeParameter.mode: mode.value});

  Future<bool> setTemperature(int celsius) =>
      setParameters({GreeParameter.temperature: celsius});

  Future<bool> setFanSpeed(GreeFanSpeed speed) =>
      setParameters({GreeParameter.fanSpeed: speed.value});

  Future<bool> setHealth(bool on) =>
      setParameters({GreeParameter.health: on ? 1 : 0});

  Future<bool> setSleep(bool on) =>
      setParameters({GreeParameter.sleep: on ? 1 : 0});

  Future<bool> setLight(bool on) =>
      setParameters({GreeParameter.light: on ? 1 : 0});

  Future<bool> setQuiet(bool on) =>
      setParameters({GreeParameter.quiet: on ? 1 : 0});

  Future<bool> setTurbo(bool on) =>
      setParameters({GreeParameter.turbo: on ? 1 : 0});

  Future<bool> setXfan(bool on) =>
      setParameters({GreeParameter.xfan: on ? 1 : 0});

  Future<bool> setEnergySaving(bool on) =>
      setParameters({GreeParameter.energySaving: on ? 1 : 0});

  Future<bool> setVerticalSwing(int mode) =>
      setParameters({GreeParameter.verticalSwing: mode});

  Future<bool> setHorizontalSwing(int mode) =>
      setParameters({GreeParameter.horizontalSwing: mode});

  // ---- Private: request building ------------------------------------------

  String _buildRequest(String pack, {required bool useGenericKey, int i = 0}) {
    final prefix = '{"cid":"app","i":$i,"t":"pack","uid":0,"tcid":"$deviceId",';
    if (encryptionType == GreeEncryptionType.gcm) {
      final enc = useGenericKey
          ? GreeCrypto.encryptGenericGcm(pack)
          : GreeCrypto.encryptGcm(pack, deviceKey!);
      return '${prefix}"tag":"${enc.tag}","pack":"${enc.pack}"}';
    } else {
      final enc = useGenericKey
          ? GreeCrypto.encryptGenericEcb(pack)
          : GreeCrypto.encryptEcb(pack, deviceKey!);
      return '${prefix}"pack":"$enc"}';
    }
  }

  String _decryptGeneric(Map<String, dynamic> json) {
    if (encryptionType == GreeEncryptionType.gcm) {
      return GreeCrypto.decryptGenericGcm(
          json['pack'] as String, json['tag'] as String);
    }
    return GreeCrypto.decryptGenericEcb(json['pack'] as String);
  }

  String _decryptDevice(Map<String, dynamic> json) {
    if (encryptionType == GreeEncryptionType.gcm) {
      return GreeCrypto.decryptGcm(
          json['pack'] as String, json['tag'] as String, deviceKey!);
    }
    return GreeCrypto.decryptEcb(json['pack'] as String, deviceKey!);
  }

  // ---- Private: network ---------------------------------------------------

  static Future<Uint8List> _sendData(String ip, int port, List<int> data) async {
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
      if (event == RawSocketEvent.read) {
        final dg = socket.receive();
        if (dg != null && !completer.isCompleted) {
          socket.close();
          completer.complete(dg.data);
        }
      }
    });
    return completer.future;
  }

  // ---- Private: JSON helpers ----------------------------------------------

  static Map<String, dynamic>? _parseJson(Uint8List data) {
    final trimmed = _trimJson(data);
    if (trimmed == null) return null;
    try {
      return jsonDecode(utf8.decode(trimmed)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Uint8List? _trimJson(Uint8List data) {
    for (var i = data.length - 1; i >= 0; i--) {
      if (data[i] == 0x7D) return data.sublist(0, i + 1);
    }
    return null;
  }

  static String _resolveDeviceId(
      Map<String, dynamic> pack, Map<String, dynamic> resp) {
    final packCid = pack['cid'] as String?;
    if (packCid != null && packCid.isNotEmpty) return packCid;
    final respCid = resp['cid'] as String?;
    if (respCid != null) return respCid;
    return '<unknown>';
  }

  @override
  String toString() =>
      'GreeAcDevice(ip=$ip, id=$deviceId, name=$name, '
      'encryption=$encryptionType, bound=$isBound)';
}
