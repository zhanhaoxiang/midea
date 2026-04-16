# Midea Device Scanner — Dart Port Design

## Problem Statement

Port the Python Midea LAN device scanning logic (`midealocal/discover.py` + `security.py`) to Dart, maintaining an identical directory structure and one class per file. Run both Python and Dart implementations to confirm real device discovery.

## Scope

- Port only the **scan** path (no cloud login, no device control)
- Entry point: `lib/main.dart` — CLI output like the Python script
- Execution: `dart run lib/main.dart`

## Architecture

Mirror Python's `midealocal/` as `lib/midealocal/`:

```
lib/
  main.dart                    # scan entry point (mirrors main/main.py)
  midealocal/
    const.dart                 # DeviceType enum, ProtocolVersion enum
    exceptions.dart            # exception hierarchy
    security.dart              # LocalSecurity class (AES-ECB)
    discover.dart              # discover() + all helper functions
```

## Components

### `const.dart`
- `DeviceType` enum with all device type int values (A0–X00)
- `ProtocolVersion` enum (V1, V2, V3)
- Constants: `maxByteValue`, `maxDoubleByteValue`

### `exceptions.dart`
- `MideaLocalError` base exception
- Subclasses: `CannotAuthenticate`, `CannotConnect`, `DataUnexpectedLength`, `DataSignDoesntMatch`, `DataSignWrongType`, `ElementMissing`, `MessageWrongFormat`, `SocketException`, `ValueWrongType`

### `security.dart` — `LocalSecurity`
- AES-ECB decrypt (`aesDecrypt`) using `pointycastle`
- AES key: `141661095494369103254425781617665632877` formatted as hex bytes (16 bytes)
- PKCS7 unpadding after decrypt
- Returns `Uint8List` (equivalent to Python's `bytearray`)

### `discover.dart`
- Constants: `broadcastMsg`, `deviceInfoMsg`, `discoveryMinResponseLength`
- `enumAllBroadcast()` — uses `dart:io NetworkInterface.list()` to find all private non-loopback IPv4 broadcast addresses
- `bytes2port(Uint8List)` — little-endian 4-byte to int
- `getDeviceInfo(String ip, int port)` — TCP connect, send `deviceInfoMsg`, receive response
- `getIdFromResponse(Uint8List)` — parse Protocol V1 XML for device ID
- `parseDiscoverResponse(...)` — parses raw UDP datagram:
  - Protocol 2: header `5a5a`, AES-ECB decrypt encrypted payload
  - Protocol 3: header `8370`, strip outer wrapper then same as Protocol 2
  - Protocol 1: XML response `3c3f786d6c20`, TCP follow-up for device ID
- `discover({List<int>? discoverType, List<String>? ipAddress})` — UDP broadcast on ports 6445 and 20086, collect responses with 5s timeout

### `main.dart`
- `scanDevices()` — calls `discover()`, prints each found device's ID/IP/port/type/model/SN
- `main()` — calls `scanDevices()`

## Data Flow

```
main() 
  → scanDevices() 
    → discover()
      → enumAllBroadcast()          # find subnet broadcast addresses
      → UDP sendto(broadcastMsg)    # ports 6445 and 20086
      → loop: parseDiscoverResponse()
          → LocalSecurity.aesDecrypt()   # for protocol 2/3
          → XML parse                    # for protocol 1
          → getDeviceInfo() [TCP]        # for protocol 1 only
      → return Map<int, DeviceInfo>
    → print each device
```

## Dependencies

Add to `pubspec.yaml`:
- `pointycastle: ^3.9.1` — AES ECB/CBC cipher operations
- `xml: ^6.5.0` — XML parsing for Protocol V1 device responses

## Error Handling

- UDP send failure: catch `SocketException`, warn and continue
- Parse failure: return `null` for that datagram, skip and continue  
- TCP timeout (getDeviceInfo): catch, return empty `Uint8List`
- AES decrypt error: return empty `Uint8List`

## Testing Plan

1. Run Python scanner: `cd midea-local && source venv/bin/activate && python main/main.py`
2. Confirm Python finds devices and prints results
3. Run Dart scanner: `dart run lib/main.dart`
4. Confirm Dart prints identical device information (same device IDs, IPs, types)
