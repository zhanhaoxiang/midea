/// Midea local message. Mirrors midealocal/message.py.

import 'dart:typed_data';
import 'const.dart';

// ---------------------------------------------------------------------------
// MessageType
// ---------------------------------------------------------------------------

enum MessageType {
  defaultType(0x00),
  set(0x02),
  query(0x03),
  notify1(0x04),
  notify2(0x05),
  exception(0x06),
  exception2(0x0A),
  queryAppliance(0xA0);

  const MessageType(this.value);
  final int value;

  static MessageType? fromInt(int v) {
    for (final t in MessageType.values) {
      if (t.value == v) return t;
    }
    return null;
  }

  static String getKeyFromValue(int v) {
    for (final t in MessageType.values) {
      if (t.value == v) return t.name;
    }
    return 'Unknown';
  }
}

// ---------------------------------------------------------------------------
// ListTypes  (mirrors ListTypes IntEnum in message.py)
// The values we actually use are X02, X03, X04, B5, B1
// We store them as plain int constants.
// ---------------------------------------------------------------------------

class ListTypes {
  static const int x00 = 0x00;
  static const int x01 = 0x01;
  static const int x02 = 0x02;
  static const int x03 = 0x03;
  static const int x04 = 0x04;
  static const int x06 = 0x06;
  static const int x08 = 0x08;
  static const int x14 = 0x14;
  static const int x16 = 0x16;
  static const int x31 = 0x31;
  static const int x3D = 0x3D;
  static const int x52 = 0x52;
  static const int x81 = 0x81;
  static const int x83 = 0x83;
  static const int b1 = 0xB1;
  static const int b5 = 0xB5;
  static const int x21 = 0x21;
  static const int x24 = 0x24;
  static const int x41 = 0x41;
  static const int x48 = 0x48;
  static const int xa0 = 0xA0;
  static const int xa4 = 0xA4;
  static const int x80 = 0x80;
  static const int c3 = 0xC3;
  static const int c8 = 0xC8;
  static const int aa = 0xAA;
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class MessageLenError implements Exception {}

class MessageBodyError implements Exception {}

class MessageCheckSumError implements Exception {}

// ---------------------------------------------------------------------------
// MessageBase
// ---------------------------------------------------------------------------

abstract class MessageBase {
  static const int headerLength = 10;

  DeviceType deviceType = DeviceType.x00;
  MessageType messageType = MessageType.defaultType;
  int bodyType = ListTypes.x00;
  int protocolVersion = 0;

  static int checksum(List<int> data) =>
      (~data.reduce((a, b) => a + b) + 1) & 0xFF;

  Uint8List get header;
  Uint8List get body;
}

// ---------------------------------------------------------------------------
// MessageRequest
// ---------------------------------------------------------------------------

abstract class MessageRequest extends MessageBase {
  MessageRequest({
    required DeviceType deviceType,
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) {
    this.deviceType = deviceType;
    this.protocolVersion = protocolVersion;
    this.messageType = messageType;
    this.bodyType = bodyType;
  }

  @override
  Uint8List get header {
    final length = MessageBase.headerLength + body.length;
    return Uint8List.fromList([
      0xAA,
      length,
      deviceType.value,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      protocolVersion,
      messageType.value,
    ]);
  }

  /// Subclasses return the payload bytes (without the bodyType prefix byte).
  Uint8List buildBody();

  @override
  Uint8List get body {
    final result = <int>[];
    result.add(bodyType);
    result.addAll(buildBody());
    return Uint8List.fromList(result);
  }

  Uint8List serialize() {
    final stream = <int>[];
    stream.addAll(header);
    stream.addAll(body);
    stream.add(MessageBase.checksum(stream.sublist(1)));
    return Uint8List.fromList(stream);
  }
}

// ---------------------------------------------------------------------------
// MessageQueryAppliance
// ---------------------------------------------------------------------------

class MessageQueryAppliance extends MessageRequest {
  MessageQueryAppliance(DeviceType deviceType)
    : super(
        deviceType: deviceType,
        protocolVersion: 0,
        messageType: MessageType.queryAppliance,
        bodyType: ListTypes.x00,
      );

  @override
  Uint8List buildBody() => Uint8List(0);

  @override
  Uint8List get body => Uint8List(19);
}

// ---------------------------------------------------------------------------
// MessageQuestCustom
// ---------------------------------------------------------------------------

class MessageQuestCustom extends MessageRequest {
  MessageQuestCustom({
    required DeviceType deviceType,
    required int protocolVersion,
    required MessageType cmdType,
    required Uint8List cmdBody,
  }) : _cmdBody = cmdBody,
       super(
         deviceType: deviceType,
         protocolVersion: protocolVersion,
         messageType: cmdType,
         bodyType: ListTypes.x00,
       );

  final Uint8List _cmdBody;

  @override
  Uint8List buildBody() => Uint8List(0);

  @override
  Uint8List get body => _cmdBody;
}

// ---------------------------------------------------------------------------
// MessageBody
// ---------------------------------------------------------------------------

class MessageBody {
  MessageBody(this._data);

  final Uint8List _data;

  Uint8List get data => _data;

  int get bodyType => _data[0];

  static int readByte(Uint8List body, int byte, {int defaultValue = 0}) =>
      body.length > byte ? body[byte] : defaultValue;
}

// ---------------------------------------------------------------------------
// MessageResponse
// ---------------------------------------------------------------------------

class MessageResponse extends MessageBase {
  MessageResponse(Uint8List message) {
    if (message.length < MessageBase.headerLength + 1) throw MessageLenError();
    _header = Uint8List.fromList(message.sublist(0, MessageBase.headerLength));
    protocolVersion = _header[MessageBase.headerLength - 2];
    messageType =
        MessageType.fromInt(_header[MessageBase.headerLength - 1]) ??
        MessageType.defaultType;
    deviceType = DeviceType.fromInt(_header[2]) ?? DeviceType.x00;
    final bodyData = Uint8List.fromList(
      message.sublist(MessageBase.headerLength, message.length - 1),
    );
    _messageBody = MessageBody(bodyData);
    bodyType = bodyData.isNotEmpty ? bodyData[0] : 0;
  }

  late Uint8List _header;
  late MessageBody _messageBody;

  @override
  Uint8List get header => _header;

  @override
  Uint8List get body => _messageBody.data;

  void setBody(MessageBody body) => _messageBody = body;

  /// Copy all non-_data fields from MessageBody subclass to this response.
  void setAttr() {
    // Implemented in subclasses via explicit field copying.
  }
}

class MessageApplianceResponse extends MessageResponse {
  MessageApplianceResponse(Uint8List message) : super(message);
}
