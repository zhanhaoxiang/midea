/// Midea local constants. Mirrors midealocal/const.py.

enum DeviceType {
  a0(0xA0),
  a1(0xA1),
  ac(0xAC),
  ad(0xAD),
  b0(0xB0),
  b1(0xB1),
  b3(0xB3),
  b4(0xB4),
  b6(0xB6),
  b8(0xB8),
  bf(0xBF),
  c2(0xC2),
  c3(0xC3),
  ca(0xCA),
  cc(0xCC),
  cd(0xCD),
  ce(0xCE),
  cf(0xCF),
  da(0xDA),
  db(0xDB),
  dc(0xDC),
  e1(0xE1),
  e2(0xE2),
  e3(0xE3),
  e6(0xE6),
  e8(0xE8),
  ea(0xEA),
  ec(0xEC),
  ed(0xED),
  fa(0xFA),
  fb(0xFB),
  fc(0xFC),
  fd(0xFD),
  x13(0x13),
  x26(0x26),
  x34(0x34),
  x40(0x40),
  x00(0x00);

  const DeviceType(this.value);
  final int value;

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
