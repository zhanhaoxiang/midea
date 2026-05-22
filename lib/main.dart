/// Control Midea drum washing machine via LAN. Mirrors main/main.py.

import 'dart:io';

import 'package:midea/function.dart';

import 'midealocal/const.dart';
import 'midealocal/device.dart';
import 'midealocal/devices/db/midea_db_device.dart';
import 'midealocal/devices/device_selector.dart';

Future<void> main() async {
  // 1：扫描局域网的设备, 把打印的信息中想要控制的设备的信息copy到localInfo中
  // 注意，家用空调的类型是0xAC
  final targetIp = Platform.environment['MIDEA_TARGET_IP'] ?? '192.168.31.30';
  print('目标空调 IP: $targetIp');
  final airConditioner = (await scanDevices()).entries.lastWhere((e) {
    final type = DeviceType.fromInt(e.value['type']);
    return type == DeviceType.ac && e.value['ip_address'] == targetIp;
  });

  final airConditionDeviceId = airConditioner.key;
  final airConditionInfo = airConditioner.value;

  var localInfo = {
    "device_id": airConditionDeviceId,
    "type": airConditionInfo['type'],
    "ip_address": airConditionInfo['ip_address'],
    "port": airConditionInfo['port'],
    "model": airConditionInfo['model'],
    "sn": airConditionInfo['sn'],
    "protocol": airConditionInfo['protocol'],
  };

  print(localInfo);

  // 2. 使用device_id 生成token和key, 这一步会生成两对token和key, 把结果复制和替换下面的tokenList
  List<Map<String, String>> tokenList = await getCloudKey(
    localInfo['device_id'] as int,
  );
  // List<Map<String, String>> tokenList = [
  // {
  //   "token":
  //       "40cfeee4f7d53a8243228909db8f084c201d550c016a6419d232388d3f96793fa733cced0c8354b0ac89a20c865a0417e33c2df5242ea4f587c2406f0e505e02",
  //   "key": "c842f7ff7e38443fbe1ddb579b4d664f2f129e21c63447709a109e0928d2bffa",
  // },
  // {
  //   "token":
  //       "8278a0431691859fddb18f7955d218a044e9c6b11e59ea313a3280ff861d291390afe973d120f276e6f8be9abc121807c246ebe3cf8d21f3d8f9b8e46b5dab69",
  //   "key": "4b2c3efccf634638b541106fae6f8782f6dc15391f0f445a8e04bd428f0186c3",
  // },
  // ];
  print(tokenList);

  // Step 2: create device
  final protocol = ProtocolVersion.values.firstWhere(
    (p) => p.value == localInfo['protocol'],
    orElse: () => ProtocolVersion.v2,
  );
  int index = 0;
  try {
    for (Map<String, String> tk in tokenList) {
      // 开始尝试连接设备
      print('使用第 ${index + 1} 套 token/key 尝试连接设备...');

      String token = tk['token']!;
      String key = tk['key']!;

      MideaDevice? device = selectDevice(
        deviceType:
            DeviceType.fromInt(localInfo['type'] as int) ?? DeviceType.x00,
        name: "AC",
        deviceId: localInfo['device_id'] as int,
        ipAddress: localInfo['ip_address'] as String,
        port: localInfo['port'] as int,
        token: token,
        key: key,
        deviceProtocol: protocol,
        model: (localInfo['model'] as String?) ?? '',
        subtype: 0,
      );
      if (device == null) {
        print('  无法创建设备实例');
        continue;
      }

      final connected = await device.connect(checkProtocol: false);
      if (!connected) {
        print('  连接失败');
        // exit(1);
        index += 1;
        continue;
      }
      print('  连接成功！');

      await device.refreshStatus(checkProtocol: false);

      // Step 3: read status
      print('\n[3] 读取设备状态...');
      final attrs = device.attributes;
      print('  当前属性:');
      for (final e in attrs.entries) {
        print('    ${e.key}: ${e.value}');
      }

      // Step 4: power on
      print('\n[4] 尝试控制：开机...');

      device.setAttribute(DbDeviceAttributes.power, true);
      print('  已发送开机指令');
      await device.drainIncomingMessages(
        idleTimeout: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 5),
      );
      await Future<void>.delayed(const Duration(seconds: 5));
      // device.setAttribute(DeviceAttributes.start, true);
      try {
        await device.refreshStatus(checkProtocol: false);
        await device.drainIncomingMessages(
          idleTimeout: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 3),
        );
        print(' 当前状态： ${device.attributes}');
        print('  开机后 power 状态: ${device.attributes[DbDeviceAttributes.power]}');
      } on NoSupportedProtocol {
        print('  开机指令已发送，但状态查询没有匹配到可用协议');
      }

      device.closeSocket();

      print('\n\n----------------------------------------\n');
      index += 1;
    }
  } catch (e) {
    print('  控制失败: $e');
  }

  exit(0);
}
