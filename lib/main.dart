import 'dart:io';

import 'midealocal/discover.dart';

void main(List<String> args) async {
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

  exit(0);
}

