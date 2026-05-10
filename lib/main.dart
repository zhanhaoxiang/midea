/// Control Midea drum washing machine via LAN. Mirrors main/main.py.

import 'dart:io';

import 'midealocal/const.dart';
import 'midealocal/devices/db/midea_db_device.dart';

Future<void> main() async {
  // 1：扫描局域网的设备, 把打印的信息中想要控制的设备的信息copy到localInfo中
  // 注意，家用空调的类型是0xAC
  // scanDevices();

  var localInfo = {
    "device_id": 210006722801783,
    "type": 219,
    "ip_address": "192.168.31.50",
    "port": 6444,
    "model": "38125196",
    "sn": "0000DB5133812519632225A0084904FX",
    "protocol": 3,
  };

  // 2. 使用device_id 生成token和key, 这一步会生成两对token和key, 把结果复制和替换下面的tokenList
  // await getCloudKey(localInfo['device_id'] as int);
  List<Map<String, String>> tokenList = [
    {
      "token":
          "6f558f5767c97cd7a6f07d45f42e2e3f056960a04aee9b1476515ea67ac120e1084b76dda13540f6ea60150abdd71c229919ec0075cca227f3cbfe278d46bfb9",
      "key": "9c55e12e2ef044d788e42c50343740f1ecc08fe21b654e85a484859465913c41",
    },
    {
      "token":
          "8278a0431691859fddb18f7955d218a044e9c6b11e59ea313a3280ff861d291390afe973d120f276e6f8be9abc121807c246ebe3cf8d21f3d8f9b8e46b5dab69",
      "key": "4b2c3efccf634638b541106fae6f8782f6dc15391f0f445a8e04bd428f0186c3",
    },
  ];

  // Step 2: create device
  final protocol = ProtocolVersion.values.firstWhere(
    (p) => p.value == localInfo['protocol'],
    orElse: () => ProtocolVersion.v2,
  );
  int index = 0;
  for (Map<String, String> tk in tokenList) {
    // 开始尝试连接设备
    print('使用第 ${index + 1} 套 token/key 尝试连接设备...');

    String token = tk['token']!;
    String key = tk['key']!;

    final device = MideaDBDevice(
      name: DeviceType.fromInt(localInfo['type'] as int)?.name ?? '未知设备',
      deviceId: localInfo['device_id'] as int,
      ipAddress: localInfo['ip_address'] as String,
      port: localInfo['port'] as int,
      token: token,
      key: key,
      deviceProtocol: protocol,
      model: (localInfo['model'] as String?) ?? '',
      subtype: 0,
    );

    final connected = await device.connect(checkProtocol: true);
    if (!connected) {
      print('  连接失败');
      exit(1);
    }
    print('  连接成功！');

    // Step 3: read status (already populated by connect checkProtocol)
    print('\n[3] 读取设备状态...');
    final attrs = device.attributes;
    print('  当前属性:');
    for (final e in attrs.entries) {
      print('    ${e.key}: ${e.value}');
    }

    // Step 4: power on
    print('\n[4] 尝试控制：开机...');
    try {
      device.setAttribute(DeviceAttributes.power, true);
      print('  已发送开机指令');
      await Future<void>.delayed(const Duration(seconds: 2));
      // device.setAttribute(DeviceAttributes.start, true);
      await device.refreshStatus(checkProtocol: true);
      print(' 当前状态： ${device.attributes}');
      print('  开机后 power 状态: ${device.attributes[DeviceAttributes.power]}');
    } catch (e) {
      print('  控制失败: $e');
    }
    device.closeSocket();

    print('\n\n----------------------------------------\n');
  }

  exit(0);
}
