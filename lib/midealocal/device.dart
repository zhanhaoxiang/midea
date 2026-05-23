/// Midea local device. Mirrors midealocal/device.py.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'const.dart';
import 'exceptions.dart' as midea_exc;
import 'message.dart';
import 'packet_builder.dart';
import 'security.dart';

const int minAuthResponse = 20;
const int minMsgLength = 56;
const int minV2FactualMsgLength = 6;
const int responseTimeout = 12;
const int socketTimeoutSeconds = 10;
const int queryTimeoutSeconds = 20;

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class AuthException implements Exception {}

class ResponseException implements Exception {}

class NoSupportedProtocol implements Exception {}

// ---------------------------------------------------------------------------
// MessageResult
// ---------------------------------------------------------------------------

enum MessageResult {
  padding(0),
  success(1),
  unknown(96),
  unexpected(97),
  timeout(98),
  error(99);

  const MessageResult(this.value);
  final int value;
}

// ---------------------------------------------------------------------------
// MideaDevice
// ---------------------------------------------------------------------------

abstract class MideaDevice {
  MideaDevice({
    required String name,
    required int deviceId,
    required DeviceType deviceType,
    required String ipAddress,
    required int port,
    required String token,
    required String key,
    required ProtocolVersion deviceProtocol,
    required String model,
    required int subtype,
    required Map<String, dynamic> attributes,
  }) : _deviceId = deviceId,
       _deviceType = deviceType,
       _ipAddress = ipAddress,
       _port = port,
       _token = _hexToBytes(token),
       _key = _hexToBytes(key),
       _deviceProtocolVersion = deviceProtocol,
       _model = model,
       _subtype = subtype,
       _attributes = attributes;

  final int _deviceId;
  final DeviceType _deviceType;
  String _ipAddress;
  final int _port;
  final Uint8List _token;
  final Uint8List _key;
  final ProtocolVersion _deviceProtocolVersion;
  final String _model;
  final int _subtype;
  final Map<String, dynamic> _attributes;

  final LocalSecurity _security = LocalSecurity();
  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSub;

  // Persistent incoming data buffer + notification controller
  final _incomingBuffer = <int>[];
  final _dataAvailable = StreamController<void>.broadcast();

  Uint8List _parseBuffer = Uint8List(0);
  int messageProtocolVersion = 0;
  bool applianceQuery = true;
  final List<String> _unsupportedProtocol = [];
  final List<void Function(Map<String, dynamic>)> _updates = [];
  bool _available = false;

  int get deviceId => _deviceId;
  DeviceType get deviceType => _deviceType;
  String get model => _model;
  int get subtype => _subtype;
  bool get available => _available;

  Map<String, dynamic> get attributes {
    final ret = <String, dynamic>{};
    for (final k in _attributes.keys) {
      ret[k] = _attributes[k];
    }
    return ret;
  }

  /// Mutable attribute map accessible to subclasses.
  Map<String, dynamic> get attrs => _attributes;

  // ── Connection ────────────────────────────────────────────────────────────

  Future<bool> connect({bool checkProtocol = false}) async {
    try {
      _socket = await Socket.connect(
        _ipAddress,
        _port,
        timeout: const Duration(seconds: socketTimeoutSeconds),
      );
      _attachSocket(_socket!);

      if (_deviceProtocolVersion == ProtocolVersion.v3) {
        await authenticate();
      }
      if (checkProtocol) {
        await refreshStatus(checkProtocol: true);
        setAvailable(true);
      }
      return true;
    } on SocketException {
      _socket = null;
    } on AuthException catch (e) {
      // authentication failed
      print("auth exception: ${e.toString()}");
    } on midea_exc.SocketException {
      _socket = null;
    } on NoSupportedProtocol {
      // no supported query
      print("no supported");
    } catch (e) {
      _socket = null;
      print(e.toString());
    }
    if (checkProtocol) setAvailable(false);
    return false;
  }

  void _attachSocket(Socket socket) {
    _incomingBuffer.clear();
    _socketSub?.cancel();
    _socketSub = socket.listen(
      (data) {
        _incomingBuffer.addAll(data);
        if (!_dataAvailable.isClosed) _dataAvailable.add(null);
      },
      onError: (e) {},
      onDone: () {},
    );
  }

  /// Read at most [maxBytes] from the persistent socket buffer.
  Future<Uint8List> _recvBytes(
    int maxBytes, {
    Duration timeout = const Duration(seconds: socketTimeoutSeconds),
  }) async {
    if (_incomingBuffer.isNotEmpty) {
      final take = _incomingBuffer.length.clamp(1, maxBytes);
      final data = _incomingBuffer.sublist(0, take);
      _incomingBuffer.removeRange(0, take);
      return Uint8List.fromList(data);
    }
    // Wait for data
    await _dataAvailable.stream.first.timeout(timeout);
    final take = _incomingBuffer.length.clamp(1, maxBytes);
    final data = _incomingBuffer.sublist(0, take);
    _incomingBuffer.removeRange(0, take);
    return Uint8List.fromList(data);
  }

  // ── Authentication (V3) ───────────────────────────────────────────────────

  Future<void> authenticate() async {
    if (_socket == null) throw midea_exc.SocketException();
    final request = _security.encode8370(_token, msgtypeHandshakeRequest);
    _socket!.add(request);
    await _socket!.flush();

    final response = await _recvBytes(
      512,
      timeout: const Duration(seconds: socketTimeoutSeconds),
    );
    if (response.length < minAuthResponse) throw AuthException();

    final tcpResponse = response.sublist(8, 72);
    _security.tcpKey(tcpResponse, _key);
  }

  // ── Message sending ───────────────────────────────────────────────────────

  void sendMessage(Uint8List data, {bool query = false}) {
    if (_deviceProtocolVersion == ProtocolVersion.v3) {
      sendMessageV3(data, msgType: msgtypeEncryptedRequest, query: query);
    } else {
      sendMessageV2(data, query: query);
    }
  }

  void sendMessageV2(Uint8List data, {bool query = false}) {
    if (_socket == null) throw midea_exc.SocketException();
    _socket!.add(data);
  }

  void sendMessageV3(
    Uint8List data, {
    int msgType = msgtypeEncryptedRequest,
    bool query = false,
  }) {
    final encoded = _security.encode8370(data, msgType);
    sendMessageV2(encoded, query: query);
  }

  void buildSend(MessageRequest cmd, {bool query = false}) {
    final data = cmd.serialize();
    final msg = PacketBuilder(_deviceId, data).finalize();
    print("$deviceId Sending: $cmd, query is $query");
    sendMessage(msg, query: query);
  }

  // ── Status polling ────────────────────────────────────────────────────────

  Future<void> refreshStatus({bool checkProtocol = false}) async {
    if (applianceQuery) {
      buildSend(MessageQueryAppliance(_deviceType), query: true);
      if (checkProtocol) {
        await _waitForQueryResponse();
      } else {
        await drainIncomingMessages(
          idleTimeout: const Duration(milliseconds: 500),
          maxDuration: const Duration(seconds: 3),
        );
      }
    }

    final cmds = <MessageRequest>[];
    cmds.addAll(buildQuery());

    var errorCount = 0;
    for (final cmd in cmds) {
      final cmdName = cmd.runtimeType.toString();
      if (_unsupportedProtocol.contains(cmdName)) {
        errorCount++;
        continue;
      }
      buildSend(cmd, query: true);

      if (checkProtocol) {
        try {
          await _waitForQueryResponse();
        } on TimeoutException {
          errorCount++;
          _unsupportedProtocol.add(cmdName);
        } on ResponseException {
          errorCount++;
        }
      }
    }

    if (!checkProtocol) {
      await drainIncomingMessages(
        idleTimeout: const Duration(seconds: 2),
        maxDuration: const Duration(seconds: 8),
      );
    }

    if (cmds.isNotEmpty && errorCount == cmds.length) {
      throw NoSupportedProtocol();
    }
  }

  Future<void> _waitForQueryResponse() async {
    while (true) {
      if (_socket == null) throw midea_exc.SocketException();
      final msg = await _recvBytes(
        512,
        timeout: const Duration(seconds: queryTimeoutSeconds),
      );
      if (msg.isEmpty) throw ResponseException();
      final result = parseMessage(msg);
      if (result == MessageResult.success) break;
      if (result == MessageResult.padding) continue;
      throw ResponseException();
    }
  }

  Future<void> drainIncomingMessages({
    Duration idleTimeout = const Duration(milliseconds: 500),
    Duration maxDuration = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(maxDuration);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final msg = await _recvBytes(512, timeout: idleTimeout);
        if (msg.isEmpty) return;
        parseMessage(msg);
      } on TimeoutException {
        return;
      }
    }
  }

  // ── Message parsing ───────────────────────────────────────────────────────

  bool preProcessMessage(Uint8List msg) {
    if (msg[9] == MessageType.queryAppliance.value) {
      final message = MessageApplianceResponse(msg);
      applianceQuery = false;
      messageProtocolVersion = message.protocolVersion;
      print(
        '$deviceId Appliance query received: '
        'protocol_version=$messageProtocolVersion',
      );
      return false;
    }
    return true;
  }

  MessageResult parseMessage(Uint8List msg) {
    List<Uint8List> messages;
    if (_deviceProtocolVersion == ProtocolVersion.v3) {
      final (decoded, remaining) = _security.decode8370(
        Uint8List.fromList([..._parseBuffer, ...msg]),
      );
      messages = decoded;
      _parseBuffer = remaining;
    } else {
      final (fetched, remaining) = _fetchV2Message(
        Uint8List.fromList([..._parseBuffer, ...msg]),
      );
      messages = fetched;
      _parseBuffer = remaining;
    }

    if (messages.isEmpty) return MessageResult.padding;

    for (final message in messages) {
      if (message.length == 5 && String.fromCharCodes(message) == 'ERROR') {
        return MessageResult.error;
      }

      if (message.length > 5) {
        final payloadLen = message[4] + (message[5] << 8) - 56;
        final payloadType = message[2] + (message[3] << 8);

        if (payloadType == 0x1001 || payloadType == 0x0001) continue;

        if (message.length > minMsgLength) {
          final cryptographic = message.sublist(40, message.length - 16);
          if (payloadLen % 16 == 0) {
            final decrypted = _security.aesDecrypt(cryptographic);
            try {
              var cont = true;
              if (applianceQuery) {
                cont = preProcessMessage(decrypted);
              }
              if (cont) {
                final status = processMessage(decrypted);
                if (status.isNotEmpty) updateAll(status);
              }
            } catch (e) {
              print('$deviceId Parse ignored: $e');
            }
          }
        }
      }
    }
    return MessageResult.success;
  }

  static (List<Uint8List>, Uint8List) _fetchV2Message(Uint8List msg) {
    final result = <Uint8List>[];
    while (msg.length >= minV2FactualMsgLength) {
      if (msg.length < 6) break;
      final alleged = msg[4] + (msg[5] << 8);
      if (alleged == 0) break;
      if (msg.length >= alleged) {
        result.add(msg.sublist(0, alleged));
        msg = msg.sublist(alleged);
      } else {
        break;
      }
    }
    return (result, msg);
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────────

  void sendHeartbeat() {
    final msg = PacketBuilder(
      _deviceId,
      Uint8List.fromList([0x00]),
    ).finalize(msgType: 0);
    sendMessage(msg);
  }

  // ── Updates ───────────────────────────────────────────────────────────────

  void registerUpdate(void Function(Map<String, dynamic>) update) {
    _updates.add(update);
  }

  void updateAll(Map<String, dynamic> status) {
    for (final update in _updates) {
      update(status);
    }
  }

  void setAvailable(bool available) {
    _available = available;
    updateAll({'available': available});
  }

  // ── Socket cleanup ────────────────────────────────────────────────────────

  void closeSocket() {
    _unsupportedProtocol.clear();
    _parseBuffer = Uint8List(0);
    _incomingBuffer.clear();
    _socketSub?.cancel();
    _socketSub = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
  }

  void setIpAddress(String ip) {
    if (_ipAddress != ip) {
      _ipAddress = ip;
      closeSocket();
    }
  }

  // ── Abstract API ──────────────────────────────────────────────────────────

  List<MessageRequest> buildQuery();

  Map<String, dynamic> processMessage(Uint8List msg);

  void setAttribute(String attr, dynamic value);

  dynamic getAttribute(String attr) => _attributes[attr];

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
