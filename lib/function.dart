import 'dart:convert';
import 'dart:io';

import 'midealocal/cloud.dart';
import 'midealocal/const.dart';
import 'midealocal/discover.dart';

// 扫描所有设备
Future<Map<int, dynamic>> scanDevices() async {
  print('开始扫描设备...');

  final found = await discover();

  if (found.isEmpty) {
    print('未发现任何设备');
    exit(0);
  }

  Map<int, dynamic> devices = {};

  for (final entry in found.entries) {
    final deviceId = entry.key;
    final info = entry.value;
    final type = info['type'] as int;
    final deviceType = DeviceType.fromInt(type);
    print('设备 ID: $deviceId');
    print('  IP: ${info['ip_address']}');
    print('  端口: ${info['port']}');
    print('  类型: 0x${type.toRadixString(16).toUpperCase()} ($type) - ${deviceType?.name ?? '未知设备'}');
    print('  型号: ${info['model']}');
    print('  SN: ${info['sn']}');
    print('  Json格式化： ${jsonEncode(info)}');
    print('-' * 40);

    devices[deviceId] = info;
  }

  return found;
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
    final deviceType = DeviceType.fromInt(type);
    print('  设备 ID: $id');
    print('  设备名称: ${d['name']}');
    print('  类型: 0x${type.toRadixString(16).toUpperCase()} ($type) - ${deviceType?.name ?? '未知设备'}');
    print('  型号: ${d['model']}');
    print('  SN: ${d['sn']}');
    print('  在线状态: ${(d['online'] as bool) ? '在线' : '离线'}');
    print('----------------------------------------');
  }
}

Future<List<Map<String, String>>> getCloudKey(int deviceId) async {
  final preset = getPresetAccountCloud();
  final cloudName = preset['cloud_name']!;
  final account = preset['username']!;
  final password = preset['password']!;

  print('使用内置账号登录 $cloudName...');
  print('账号: $account');
  print('密码: $password');

  final cloud = getMideaCloud(cloudName, account, password);

  if (!await cloud.login()) {
    print('$cloudName 云端登录失败');
    exit(1);
  }
  print('$cloudName 云端登录成功！');

  print('获取设备 token (appliance_id: $deviceId)...');

  final keys = await cloud.getCloudKeys(deviceId);
  if (keys.isEmpty) {
    print('无法获取 token');
    exit(0);
  }
  print('获取到 ${keys.length} 个 token');
  List<Map<String, String>> tokenList = [];
  for (final entry in keys.entries) {
    tokenList.add({'token': entry.value['token']!, 'key': entry.value['key']!});
  }

  print('Token列表： ${jsonEncode(tokenList)}');
  return tokenList;
}
