# Gree AC parity rewrite design

## Goal

Rewrite `lib/greelocal/gree_ac_device.dart` so the public surface, function names, parameter names, and call relationships mirror `gree-remote/PythonCLI/gree.py` as closely as Dart allows, making line-by-line review against the Python source straightforward.

## Scope

The rewrite covers the Dart Gree AC implementation and its tests.

In scope:
- Replace the current object-oriented API with a Python-shaped top-level API
- Preserve Python names such as `ScanResult`, `send_data`, `create_request`, `create_status_request_pack`, `search_devices`, `bind_device`, `get_param`, and `set_param`
- Preserve Python control flow and request-building order wherever Dart syntax permits
- Keep protocol behavior aligned with Python, including default values, encryption selection, timeout fallback, and `search_devices -> bind_device` flow
- Update tests to verify the Python-shaped API and parity-sensitive behaviors

Out of scope:
- Rewriting unrelated Gree crypto primitives beyond what the new API needs to call
- Preserving the current Dart-friendly `GreeAcDevice` convenience API
- Adding new abstraction layers not present in the Python source

## Target structure

`gree_ac_device.dart` will be reorganized around the same conceptual layout as `gree.py`:

1. Module-level constants for ports and encryption mode names
2. `ScanResult` data holder with Python-matching fields
3. Top-level request, scan, bind, get, and set functions
4. Small private Dart helpers only where required for async UDP and JSON trimming

The file should read in the same order as the Python source so review can happen with the two files side by side.

## Naming and API rules

- Use Python names directly, including snake_case function and parameter names
- Keep `ScanResult` field names aligned with Python (`ip`, `port`, `id`, `name`, `encryption_type`)
- Keep request-building helpers separated exactly like Python rather than folding them into a class
- Keep encryption mode values shaped like Python (`'ECB'`, `'GCM'`) where practical for parity-sensitive logic
- Allow only minimal Dart-specific additions when the language requires them, such as typed return values or private async socket helpers

## Behavioral parity rules

- `search_devices` sends the same scan payload to port `7000`
- Scan parsing uses the same `tag` and `ver` logic to determine encryption mode
- Missing values fall back the same way as Python, including `'<unknown-cid>'` and `'<unknown>'`
- `search_devices` automatically calls `bind_device` for discovered devices, matching Python flow
- `bind_device` always targets port `7000`
- ECB bind timeout switches the `ScanResult` to GCM and retries without rolling back
- Status and command requests follow the Python `ENCRYPTION_TYPE` decision path instead of the current split between scan encryption and command encryption

## Dart-specific adaptations

Two adaptations are allowed:

1. UDP I/O becomes `Future`-based because Dart does not use Python-style blocking sockets in this codebase
2. Python globals that depend on CLI args will be represented as explicit parameters or a small config object, but the outward function names and call graph remain Python-shaped

These adaptations must stay thin and must not obscure the original Python structure.

## Test strategy

Tests will be rewritten around parity behaviors rather than the current OO convenience methods.

Coverage will include:
- Scan response parsing for ECB, GCM, firmware-upgraded GCM, and missing fields
- `search_devices -> bind_device` orchestration
- Request payload generation for `create_request`, status, and command packets
- Bind timeout retry behavior
- Status and command decryption paths for both encryption modes

## Review goal

After the rewrite, a reviewer should be able to compare the Dart file to `gree.py` and see the same major symbols, the same request-building sequence, and the same control flow, with only unavoidable Dart async/type differences.
