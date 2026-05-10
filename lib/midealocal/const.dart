/// Midea local constants. Mirrors midealocal/const.py.

enum DeviceType {
  a0(0xA0, '未知设备'),
  a1(0xA1, '除湿器'),
  ac(0xAC, '空调器'),
  ad(0xAD, '空气盒子'),
  b0(0xB0, '微波炉'),
  b1(0xB1, '电烤箱'),
  b3(0xB3, '消毒碗柜'),
  b4(0xB4, '小烤箱'),
  b6(0xB6, '油烟机'),
  b8(0xB8, '设备类型B8'),
  bf(0xBF, '微蒸烤一体机'),
  c2(0xC2, '智能马桶'),
  c3(0xC3, '热泵空调Wi-Fi线控器'),
  ca(0xCA, '冰箱'),
  cc(0xCC, '中央空调(风管机)Wi-Fi线控器'),
  cd(0xCD, '空气能热水器'),
  ce(0xCE, '新风设备'),
  cf(0xCF, '中央空调暖家(水机)'),
  da(0xDA, '波轮洗衣机'),
  db(0xDB, '滚筒洗衣机'),
  dc(0xDC, '干衣机'),
  e1(0xE1, '洗碗机'),
  e2(0xE2, '电热水器'),
  e3(0xE3, '燃气热水器'),
  e6(0xE6, '壁挂炉'),
  e8(0xE8, '慢炖锅'),
  ea(0xEA, '电饭煲'),
  ec(0xEC, '电压力锅'),
  ed(0xED, '饮用水设备'),
  fa(0xFA, '电风扇'),
  fb(0xFB, '电取暖器'),
  fc(0xFC, '空气净化器'),
  fd(0xFD, '加湿器'),
  x13(0x13, '灯'),
  x26(0x26, '浴霸'),
  x34(0x34, '水槽式洗碗机'),
  x40(0x40, '凉霸'),
  x00(0x00, '未知设备');

  const DeviceType(this.value, this.name);
  final int value;
  final String name;

  static DeviceType? fromInt(int v) {
    for (final t in DeviceType.values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

enum ProtocolVersion {
  v1(1),
  v2(2),
  v3(3);

  const ProtocolVersion(this.value);
  final int value;
}

const int maxByteValue = 0xFF;
