/// Control Midea drum washing machine via LAN. Mirrors main/main.py.

import 'dart:io';

import '../lib/midealocal/const.dart';
import '../lib/midealocal/discover.dart';
import '../lib/midealocal/devices/db/midea_db_device.dart';

const int washingMachineId = 210006722801783;
const String token =
    '7269369097c64f4315b276dffcc5eca8b96bfc3f6e1e5c3c80af0323ed4775003f7aa2554f5c25805f4086f43e5f5026136cc2aa8a6d5c3cedc2674c981c11e9';
const String key =
    'b5c5b6cc787a4ce7ae8835f8b34051d2b2a8b27883ec4f71839f851227d32210';

Future<Map<String, dynamic>?> scanLocalDevice() async {
  print('\n[1] 扫描本地局域网设备...');
  final found = await discover(discoverType: [0xDB]);

  if (found.isEmpty) {
    print('  未发现 DB 设备，尝试全类型扫描...');
    final allFound = await discover();
    if (allFound.isEmpty) {
      print('  本地未发现任何设备');
      return null;
    }
    found.addAll(allFound);
  }

  for (final entry in found.entries) {
    final id = entry.key;
    final info = entry.value;
    print(
        '  发现: id=$id  ip=${info['ip_address']}  type=0x${(info['type'] as int).toRadixString(16)}  protocol=${info['protocol']}');
    if (id == washingMachineId) {
      print('  ✓ 匹配到滚筒洗衣机！');
      return info;
    }
  }

  // fallback: use the only DB device if one exists
  final dbDevices = Map.fromEntries(
    found.entries.where((e) => e.value['type'] == 0xDB),
  );
  if (dbDevices.length == 1) {
    final info = dbDevices.values.first;
    print('  使用唯一的 DB 设备 (id=${dbDevices.keys.first})');
    return info;
  }

  print('  本地扫描中未找到 id=$washingMachineId 的设备');
  return null;
}

Future<void> main() async {
  // Step 1: scan
  final localInfo = await scanLocalDevice();
  if (localInfo == null) {
    print('\n无法在本地网络中找到洗衣机，无法控制');
    exit(1);
  }

  // Step 2: create device
  final protocol = ProtocolVersion.values.firstWhere(
    (p) => p.value == localInfo['protocol'],
    orElse: () => ProtocolVersion.v2,
  );

  print('\n[2] 连接洗衣机 ${localInfo['ip_address']}:${localInfo['port']}...');
  final device = MideaDBDevice(
    name: '滚筒洗衣机',
    deviceId: washingMachineId,
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
    device.setAttribute(DeviceAttributes.power, false);
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
  exit(0);
}
