# CLAUDE.md - Midea Dart改写指南

## 概述

本文档记录将midea-local Python代码改写为Dart的注意事项和约定。

## 目录结构

```
midea/
├── lib/midealocal/devices/
│   ├── ac/
│   │   ├── message.dart      # AC消息类
│   │   └── midea_ac_device.dart  # AC设备类
│   └── db/
│       ├── message.dart        # DB消息类
│       └── midea_db_device.dart  # DB设备类
└── test/midealocal/devices/
    ├── ac/
    │   ├── message_ac_test.dart
    │   └── device_ac_test.dart
    └── db/
        ├── message_db_test.dart
        └── device_db_test.dart
```

## 文件命名约定

- **文件名**: 使用snake_case风格，格式为`midea_xx_device.dart`
  - AC设备: `midea_ac_device.dart`
  - DB设备: `midea_db_device.dart`

- **类名**: 使用`MideaXXDevice`格式
  - `MideaACDevice`
  - `MideaDBDevice`

## 属性命名约定

- 使用Dart常见的camelCase风格（驼峰命名）
- 例如: `promptTone`, `targetTemperature`, `fanSpeed`, `swingVertical`

## 常量映射表

在Python中使用字典或列表定义的静态映射，在Dart中保持为`static const Map`或`static const List`。

```dart
// Python
_mode: ClassVar[dict[int, str]] = {0: "normal", ...}

// Dart
static const Map<int, String> _modeMap = {0: 'normal', ...};
```

## 消息类实现

### 继承结构

```dart
// Dart
abstract class MessageXXBase extends MessageRequest {
  MessageXXBase({
    required int protocolVersion,
    required MessageType messageType,
    required int bodyType,
  }) : super(...);
}
```

### 序列化

- Python: 使用`bytearray`，重写`body`属性
- Dart: 重写`buildBody()`方法，返回`Uint8List`

### 响应解析

- Python: 使用`MessageBody`子类解析响应字节
- Dart: 创建响应类，解析`body`属性到对应字段

## 设备类实现

### 基类继承

```dart
class MideaXXDevice extends MideaDevice {
  // 属性映射表（static const）
  // 构造函数
  // buildQuery() - 返回消息列表
  // processMessage() - 处理响应
  // setAttribute() - 设置属性
}
```

### 属性默认值的Map

Dart不支持在`static const` Map中使用非常量值（如`Uint8List(0)`），应使用`static final`:

```dart
static final Map<String, dynamic> _defaultAttributes = {
  DeviceAttributes.power: false,
  DeviceAttributes.washingData: Uint8List(0),  // 非const值
  ...
};
```

## 测试注意事项

1. **无设备测试**: 由于没有真实设备，测试应验证消息序列化结构，而非端到端通信
2. **Mock测试**: 可使用mock测试设备属性处理
3. **消息体测试**: 验证消息字节结构的关键字段

```dart
test('test query body', () {
  final msg = MessageQuery(ProtocolVersion.v1.value);
  final body = msg.body;
  expect(body[0], 0x41);  // 验证bodyType
});
```

## 常用类型转换

| Python | Dart |
|--------|------|
| `bytearray` | `Uint8List` |
| `bytes` | `Uint8List` |
| `List[int]` | `List<int>` 或 `Int32List` |
| `dict[str, Any]` | `Map<String, dynamic>` |
| `int?` | `int?` (可空int) |
| `bool | int` | `dynamic` |

## 依赖导入

```dart
import 'dart:typed_data';
import '../../const.dart';
import '../../device.dart';
import '../../message.dart';
import 'message.dart';
```

## 常见问题

### 1. 重复定义
同一测试文件中避免重复定义`group`。

### 2. const Map初始化
带有非const值的Map使用`static final`而非`static const`。

### 3. 继承方法标记
如父类方法签名变化，使用`@override`标记可能产生warning��可删除该标记。

### 4. 消息序列号
AC消息需要维护消息序列号，使用类变量:

```dart
static int _messageSerial = 0;
```

## 运行测试

```bash
flutter test test/midealocal/devices/ac/
flutter test test/midealocal/devices/db/
```

## 代码分析

```bash
dart analyze lib/midealocal/devices/
```