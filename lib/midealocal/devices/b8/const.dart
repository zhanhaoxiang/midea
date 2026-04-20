/// Midea local B8 device const. Mirrors midealocal/devices/b8/const.dart.

class B8DeviceAttributes {
  static const String workStatus = 'work_status';
  static const String functionType = 'function_type';
  static const String controlType = 'control_type';
  static const String moveDirection = 'move_direction';
  static const String cleanMode = 'clean_mode';
  static const String fanLevel = 'fan_level';
  static const String area = 'area';
  static const String waterLevel = 'water_level';
  static const String voiceVolume = 'voice_volume';
  static const String mop = 'mop';
  static const String carpetSwitch = 'carpet_switch';
  static const String speed = 'speed';
  static const String haveReserveTask = 'have_reserve_task';
  static const String batteryPercent = 'battery_percent';
  static const String workTime = 'work_time';
  static const String uvSwitch = 'uv_switch';
  static const String wifiSwitch = 'wifi_switch';
  static const String voiceSwitch = 'voice_switch';
  static const String commandSource = 'command_source';
  static const String errorType = 'error_type';
  static const String errorDesc = 'error_desc';
  static const String deviceError = 'device_error';
  static const String boardCommunicationError = 'board_communication_error';
  static const String laserSensorShelter = 'laser_sensor_shelter';
  static const String laserSensorError = 'laser_sensor_error';
}

enum B8WorkMode {
  charge(0x01),
  work(0x02),
  stop(0x03),
  pause(0x1b);

  const B8WorkMode(this.value);
  final int value;
}

enum B8WorkStatus {
  none(0x00),
  charge(0x01),
  work(0x02),
  stop(0x03),
  chargingOnDock(0x04),
  reserveTaskFinished(0x05),
  chargeFinish(0x06),
  chargingWithWire(0x07),
  pause(0x08),
  updating(0x09),
  savingMap(0x0a),
  error(0x0b),
  sleep(0x0c),
  chargePause(0x0d),
  relocate(0x0e),
  electrolysedWaterMaking(0x0f),
  dustCollecting(0x10),
  backDustCollecting(0x11),
  sleepInStation(0x12);

  const B8WorkStatus(this.value);
  final int value;
}

enum B8FunctionType {
  none(0x00),
  dustBoxCleaning(0x01),
  waterTankCleaning(0x02);

  const B8FunctionType(this.value);
  final int value;
}

enum B8ControlType {
  none(0x0),
  manual(0x1),
  auto(0x2);

  const B8ControlType(this.value);
  final int value;
}

enum B8Moviment {
  none(0x0),
  forward(0x1),
  back(0x2),
  left(0x3),
  right(0x4);

  const B8Moviment(this.value);
  final int value;
}

enum B8CleanMode {
  none(0x00),
  random(0x01),
  arc(0x02),
  edge(0x03),
  emphases(0x04),
  screw(0x05),
  bed(0x06),
  wideScrew(0x07),
  auto(0x08),
  area(0x09),
  zoneIndex(0x0a),
  zoneRect(0x0b),
  path(0x0c);

  const B8CleanMode(this.value);
  final int value;
}

enum B8FanLevel {
  off(0x0),
  soft(0x1),
  normal(0x2),
  high(0x3),
  low(0x4);

  const B8FanLevel(this.value);
  final int value;
}

enum B8WaterLevel {
  off(0x0),
  low(0x1),
  normal(0x2),
  high(0x3);

  const B8WaterLevel(this.value);
  final int value;
}

enum B8MopState {
  off(0x0),
  on(0x1),
  lackWater(0x2);

  const B8MopState(this.value);
  final int value;
}

enum B8Speed {
  low(0x1),
  high(0x0);

  const B8Speed(this.value);
  final int value;
}

enum B8ErrorType {
  no(0x00),
  canFix(0x01),
  reboot(0x02),
  warning(0x03);

  const B8ErrorType(this.value);
  final int value;
}

enum B8ErrorCanFixDescription {
  no(0x0),
  fixDust(0x01),
  fixWheelHang(0x02),
  fixWheelOverload(0x03),
  fixSideBrushOverload(0x04),
  fixRollBrushOverload(0x05),
  fixDustEngine(0x06),
  fixFrontPanel(0x07),
  fixRadarMask(0x08),
  fixDropSensor(0x09),
  fixLowBattery(0x0a),
  fixAbnormalPosture(0x0b),
  fixLaserSensor(0x0c),
  fixEdgeSensor(0x0d),
  fixStartInForbidArea(0x0e),
  fixStartInStrongMagnetic(0x0f),
  fixLaserSensorBlocked(0x10);

  const B8ErrorCanFixDescription(this.value);
  final int value;
}

enum B8ErrorRebootDescription {
  no(0x00),
  rebootLaserCommFail(0x01),
  rebootRobotCommFail(0x02),
  rebootInnerFail(0x03);

  const B8ErrorRebootDescription(this.value);
  final int value;
}

enum B8ErrorWarningDescription {
  no(0x00),
  warnLocationFail(0x01),
  warnLowBattery(0x02),
  warnFullDust(0x03),
  warnLowWater(0x04);

  const B8ErrorWarningDescription(this.value);
  final int value;
}

enum B8StatusType {
  x01(0x01);

  const B8StatusType(this.value);
  final int value;
}
