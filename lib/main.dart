import 'dart:io';

import 'midealocal/cloud.dart';
import 'midealocal/discover.dart';

void scanDevices() async {
  print('开始扫描设备...');

  final found = await discover();

  if (found.isEmpty) {
    print('未发现任何设备');
    exit(0);
  }

  for (final entry in found.entries) {
    final deviceId = entry.key;
    final info = entry.value;
    print('设备 ID: $deviceId');
    print('  IP: ${info['ip_address']}');
    print('  端口: ${info['port']}');
    print('  类型: ${info['type']}');
    print('  型号: ${info['model']}');
    print('  SN: ${info['sn']}');
    print('-' * 40);
  }
}

Future<void> listDevices() async {
  const cloudName = '美的美居';
  const account = '18028061491';
  const password = 'Aa.123456';

  final cloud = getMideaCloud(cloudName, account, password);

  if (!await cloud.login()) {
    print('云端登录失败！');
    exit(1);
  }
  print('云端登录成功！\n');

  final appliances = await cloud.listAppliances(null);
  if (appliances == null || appliances.isEmpty) {
    print('未发现设备');
    exit(0);
  }

  print('共发现 ${appliances.length} 个设备：\n');
  for (final entry in appliances.entries) {
    final id = entry.key;
    final d = entry.value;
    final type = d['type'] as int;
    print('  设备 ID: $id');
    print('  设备名称: ${d['name']}');
    print('  类型: 0x${type.toRadixString(16)} ($type)');
    print('  型号: ${d['model']}');
    print('  SN: ${d['sn']}');
    print('  在线状态: ${(d['online'] as bool) ? '在线' : '离线'}');
    print('----------------------------------------');
  }
}

void main(List<String> args) async {
  await listDevices();
}

