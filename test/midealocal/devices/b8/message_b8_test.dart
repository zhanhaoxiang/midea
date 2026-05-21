import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:midea/midealocal/const.dart';
import 'package:midea/midealocal/devices/b8/const.dart';
import 'package:midea/midealocal/devices/b8/message.dart';
import 'package:midea/midealocal/devices/b8/midea_b8_device.dart';
import 'package:midea/midealocal/message.dart' show MessageType;

// Build a full message: 10-byte header + body.
// The Python test body arrays include a trailing CRC byte, so the body
// passed here is the full body including that last byte (which MessageResponse
// strips as the checksum).
Uint8List _msg(int messageType, List<int> body) => Uint8List.fromList([
  0xAA, 0x00, 0xB8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, messageType,
  ...body,
]);

// Build the standard 22-byte query response body used in several tests.
List<int> _queryBody({
  int workStatus = 0x07,    // B8WorkStatus.chargingWithWire
  int functionType = 0x00,  // B8FunctionType.none
  int controlType = 0x02,   // B8ControlType.auto
  int moveDirection = 0x00, // B8Moviment.none
  int cleanMode = 0x08,     // B8CleanMode.auto
  int fanLevel = 0x02,      // B8FanLevel.normal
  int area = 0,
  int waterLevel = 0x02,    // B8WaterLevel.normal
  int voiceVolume = 40,
  int haveReserveTask = 0,
  int batteryPercent = 80,
  int workTime = 20,
  int flags = 0xC7,         // uv|wifi|voice|commandSource|deviceError all set
  int errorType = 0x01,     // B8ErrorType.canFix
  int errorDesc = 0x01,     // B8ErrorCanFixDescription.fixDust
  int mop = 0x01,           // B8MopState.on
  int carpetByte = 0x01,
  int sensorByte = 0x07,    // laserError|laserShelter|boardCommError
  int speed = 0x00,         // B8Speed.high
}) => [
  0x32, 0x01,                 // bodyType=0x32, version=0x01
  workStatus, functionType, controlType, moveDirection, cleanMode, fanLevel,
  area, waterLevel, voiceVolume, haveReserveTask, batteryPercent, workTime,
  flags, errorType, errorDesc, mop, carpetByte, sensorByte, speed,
  0x00,                       // CRC
];

MideaB8Device _makeDevice() => MideaB8Device(
  name: 'Test',
  deviceId: 1,
  ipAddress: '192.168.1.1',
  port: 12345,
  token: 'AA',
  key: 'BB',
  deviceProtocol: ProtocolVersion.v1,
  model: 'test',
  subtype: 1,
);

void main() {
  // -------------------------------------------------------------------------
  // MessageQuery – body == [0x32, 0x01]
  // -------------------------------------------------------------------------
  group('MessageQuery', () {
    test('body == [0x32, 0x01]', () {
      expect(MessageQuery(ProtocolVersion.v1.value).body, [0x32, 0x01]);
    });
  });

  // -------------------------------------------------------------------------
  // MessageB8Response – query response with full attribute set
  // Mirrors TestMideaB8Device.test_query_response (via device layer).
  // -------------------------------------------------------------------------
  group('MessageB8Response – query', () {
    test('parses all attributes from query body', () {
      final r = MessageB8Response(_msg(MessageType.query.value, _queryBody()));
      expect(r.workStatus, B8WorkStatus.chargingWithWire);
      expect(r.functionType, B8FunctionType.none);
      expect(r.controlType, B8ControlType.auto);
      expect(r.moveDirection, B8Moviment.none);
      expect(r.cleanMode, B8CleanMode.auto);
      expect(r.fanLevel, B8FanLevel.normal);
      expect(r.area, 0);
      expect(r.waterLevel, B8WaterLevel.normal);
      expect(r.voiceVolume, 40);
      expect(r.haveReserveTask, false);
      expect(r.batteryPercent, 80);
      expect(r.workTime, 20);
      expect(r.uvSwitch, true);
      expect(r.wifiSwitch, true);
      expect(r.voiceSwitch, true);
      expect(r.commandSource, true);
      expect(r.deviceError, true);
      expect(r.errorType, B8ErrorType.canFix);
      expect(r.errorDesc, B8ErrorCanFixDescription.fixDust);
      expect(r.mop, B8MopState.on);
      expect(r.carpetSwitch, true);
      expect(r.laserSensorError, true);
      expect(r.laserSensorShelter, true);
      expect(r.boardCommunicationError, true);
      expect(r.speed, B8Speed.high);
    });
  });

  // -------------------------------------------------------------------------
  // MideaB8Device.processMessage – query response string attrs
  // Mirrors TestMideaB8Device.test_query_response.
  // Dart enum .name is camelCase ("chargingWithWire"), not Python's snake_case.
  // -------------------------------------------------------------------------
  group('MideaB8Device – processMessage query', () {
    test('attrs updated with correct string values', () {
      final device = _makeDevice();
      device.processMessage(_msg(MessageType.query.value, _queryBody()));

      expect(device.attrs[B8DeviceAttributes.workStatus], 'chargingWithWire');
      expect(device.attrs[B8DeviceAttributes.functionType], 'none');
      expect(device.attrs[B8DeviceAttributes.controlType], 'auto');
      expect(device.attrs[B8DeviceAttributes.moveDirection], 'none');
      expect(device.attrs[B8DeviceAttributes.cleanMode], 'auto');
      expect(device.attrs[B8DeviceAttributes.fanLevel], 'normal');
      expect(device.attrs[B8DeviceAttributes.area], 0);
      expect(device.attrs[B8DeviceAttributes.waterLevel], 'normal');
      expect(device.attrs[B8DeviceAttributes.voiceVolume], 40);
      expect(device.attrs[B8DeviceAttributes.haveReserveTask], false);
      expect(device.attrs[B8DeviceAttributes.batteryPercent], 80);
      expect(device.attrs[B8DeviceAttributes.workTime], 20);
      expect(device.attrs[B8DeviceAttributes.uvSwitch], true);
      expect(device.attrs[B8DeviceAttributes.wifiSwitch], true);
      expect(device.attrs[B8DeviceAttributes.voiceSwitch], true);
      expect(device.attrs[B8DeviceAttributes.commandSource], true);
      expect(device.attrs[B8DeviceAttributes.deviceError], true);
      expect(device.attrs[B8DeviceAttributes.errorType], 'canFix');
      expect(device.attrs[B8DeviceAttributes.errorDesc], 'fixDust');
      expect(device.attrs[B8DeviceAttributes.mop], 'on');
      expect(device.attrs[B8DeviceAttributes.carpetSwitch], true);
      expect(device.attrs[B8DeviceAttributes.laserSensorError], true);
      expect(device.attrs[B8DeviceAttributes.laserSensorShelter], true);
      expect(device.attrs[B8DeviceAttributes.boardCommunicationError], true);
      expect(device.attrs[B8DeviceAttributes.speed], 'high');
    });
  });

  // -------------------------------------------------------------------------
  // MideaB8Device.processMessage – notify1 response
  // Mirrors TestMideaB8Device.test_notify_response.
  // body starts with 0x42 (notify body type), all offsets shift by -1.
  // -------------------------------------------------------------------------
  group('MideaB8Device – processMessage notify1', () {
    test('attrs updated from notify1 body', () {
      final body = [
        0x42,                                      // bodyType (notify = 0x42)
        B8WorkStatus.work.value,                   // [1]
        B8FunctionType.dustBoxCleaning.value,      // [2]
        B8ControlType.manual.value,                // [3]
        B8Moviment.left.value,                     // [4]
        B8CleanMode.path.value,                    // [5]
        B8FanLevel.high.value,                     // [6]
        1,                                         // [7] area
        B8WaterLevel.low.value,                    // [8]
        90,                                        // [9] voiceVolume
        0x01,                                      // [10] haveReserveTask bit0
        40,                                        // [11] batteryPercent
        15,                                        // [12] workTime
        0x86,                                      // [13] wifi|voice|deviceError
        B8ErrorType.warning.value,                 // [14]
        B8ErrorWarningDescription.warnFullDust.value, // [15]
        B8MopState.lackWater.value,                // [16]
        0x00,                                      // [17] carpetSwitch=false
        0x06,                                      // [18] laserShelter|boardComm
        B8Speed.low.value,                         // [19]
        0x00,                                      // CRC
      ];
      final device = _makeDevice();
      device.processMessage(_msg(MessageType.notify1.value, body));

      expect(device.attrs[B8DeviceAttributes.workStatus], 'work');
      expect(device.attrs[B8DeviceAttributes.functionType], 'dustBoxCleaning');
      expect(device.attrs[B8DeviceAttributes.controlType], 'manual');
      expect(device.attrs[B8DeviceAttributes.moveDirection], 'left');
      expect(device.attrs[B8DeviceAttributes.cleanMode], 'path');
      expect(device.attrs[B8DeviceAttributes.fanLevel], 'high');
      expect(device.attrs[B8DeviceAttributes.area], 1);
      expect(device.attrs[B8DeviceAttributes.waterLevel], 'low');
      expect(device.attrs[B8DeviceAttributes.voiceVolume], 90);
      expect(device.attrs[B8DeviceAttributes.haveReserveTask], true);
      expect(device.attrs[B8DeviceAttributes.batteryPercent], 40);
      expect(device.attrs[B8DeviceAttributes.workTime], 15);
      expect(device.attrs[B8DeviceAttributes.uvSwitch], false);
      expect(device.attrs[B8DeviceAttributes.wifiSwitch], true);
      expect(device.attrs[B8DeviceAttributes.voiceSwitch], true);
      expect(device.attrs[B8DeviceAttributes.commandSource], false);
      expect(device.attrs[B8DeviceAttributes.deviceError], true);
      expect(device.attrs[B8DeviceAttributes.errorType], 'warning');
      expect(device.attrs[B8DeviceAttributes.errorDesc], 'warnFullDust');
      expect(device.attrs[B8DeviceAttributes.mop], 'lackWater');
      expect(device.attrs[B8DeviceAttributes.carpetSwitch], false);
      expect(device.attrs[B8DeviceAttributes.laserSensorError], false);
      expect(device.attrs[B8DeviceAttributes.laserSensorShelter], true);
      expect(device.attrs[B8DeviceAttributes.boardCommunicationError], true);
      expect(device.attrs[B8DeviceAttributes.speed], 'low');
    });
  });

  // -------------------------------------------------------------------------
  // MideaB8Device.processMessage – reboot error response
  // Mirrors TestMideaB8Device.test_query_response_reboot_error.
  // -------------------------------------------------------------------------
  group('MideaB8Device – processMessage reboot error', () {
    test('errorType=reboot, errorDesc=rebootLaserCommFail', () {
      final body = _queryBody(
        workStatus: B8WorkStatus.updating.value,
        functionType: B8FunctionType.waterTankCleaning.value,
        controlType: B8ControlType.none.value,
        moveDirection: B8Moviment.none.value,
        cleanMode: B8CleanMode.none.value,
        fanLevel: B8FanLevel.off.value,
        waterLevel: B8WaterLevel.off.value,
        flags: 0,
        errorType: B8ErrorType.reboot.value,
        errorDesc: B8ErrorRebootDescription.rebootLaserCommFail.value,
        mop: B8MopState.off.value,
        carpetByte: 0,
        sensorByte: 0,
        speed: B8Speed.low.value,
      );      final device = _makeDevice();
      device.processMessage(_msg(MessageType.query.value, body));

      expect(device.attrs[B8DeviceAttributes.workStatus], 'updating');
      expect(device.attrs[B8DeviceAttributes.errorType], 'reboot');
      expect(device.attrs[B8DeviceAttributes.errorDesc], 'rebootLaserCommFail');
      expect(device.attrs[B8DeviceAttributes.deviceError], false);
    });
  });

  // -------------------------------------------------------------------------
  // MideaB8Device.processMessage – no error response
  // Mirrors TestMideaB8Device.test_query_response_no_error.
  // -------------------------------------------------------------------------
  group('MideaB8Device – processMessage no error', () {
    test('errorType=no, errorDesc=no', () {
      final body = _queryBody(
        workStatus: B8WorkStatus.none.value,
        functionType: B8FunctionType.none.value,
        controlType: B8ControlType.none.value,
        moveDirection: B8Moviment.none.value,
        cleanMode: B8CleanMode.none.value,
        fanLevel: B8FanLevel.off.value,
        waterLevel: B8WaterLevel.off.value,
        flags: 0,
        errorType: B8ErrorType.no.value,
        errorDesc: B8ErrorCanFixDescription.no.value,
        mop: B8MopState.off.value,
        carpetByte: 0,
        sensorByte: 0,
        speed: B8Speed.low.value,
      );
      final device = _makeDevice();
      device.processMessage(_msg(MessageType.query.value, body));

      expect(device.attrs[B8DeviceAttributes.workStatus], 'none');
      expect(device.attrs[B8DeviceAttributes.errorType], 'no');
      expect(device.attrs[B8DeviceAttributes.errorDesc], 'no');
    });
  });

  // -------------------------------------------------------------------------
  // MideaB8Device.processMessage – unexpected response (wrong version byte)
  // Mirrors TestMideaB8Device.test_unexpected_response.
  // When body[1] != 0x01, MessageB8Response finds no matching body → no attrs.
  // -------------------------------------------------------------------------
  group('MideaB8Device – unexpected response', () {
    test('returns empty newStatus when version byte != 0x01', () {
      final body = [0x32, 0x02, ...List.filled(20, 0)];
      final device = _makeDevice();
      final newStatus = device.processMessage(
        _msg(MessageType.query.value, body),
      );
      expect(newStatus, isEmpty);
    });
  });
}
