"""Control Midea Air Circulator Fan (FA device)."""

import asyncio
import logging
from aiohttp import ClientSession

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.cloud import MideaCloud, get_midea_cloud, get_preset_account_cloud
from midealocal.discover import discover

logging.basicConfig(level=logging.DEBUG)


def scan_devices() -> dict:
    """扫描局域网内的美的设备。"""
    print("开始扫描设备...")
    found = discover()
    for device_id, info in found.items():
        print(f"设备 ID: {device_id}")
        print(f"  IP: {info.get('ip_address')}")
        print(f"  端口: {info.get('port')}")
        print(f"  类型: {info.get('type')}")
        print(f"  型号: {info.get('model')}")
        print(f"  SN: {info.get('sn')}")
        print("-" * 40)
    return found

DEVICE_INFO = {
    "name": "空气循环扇",
    "type": 0xFA,
    "sn": "0000FA51156011CF4A3283101661JX23",
    "sn8": "56011CF4",
    "model_number": 0,
    "manufacturer_code": "0000",
    "model": "FGD24SJX",
}

DEVICE_IP = "192.168.1.xxx"  # TODO: 替换为设备实际 IP 地址
DEVICE_PORT = 6445


async def get_token_from_cloud(cloud: MideaCloud, device_sn: str) -> dict | None:
    """从云端获取设备的 token 和 key。"""
    appliance_id = int(DEVICE_INFO["sn8"], 16)
    keys = await cloud.get_cloud_keys(appliance_id)
    if keys:
        return keys.get(1) or keys.get(2)
    return None


async def main():
    # 先扫描设备
    found = scan_devices()
    if not found:
        print("未发现任何设备")
        return

    return

    # 尝试从扫描结果中找到 FA 类型的设备
    fa_device = None
    for device_id, info in found.items():
        if info.get("type") == 0xFA:
            fa_device = info
            break

    if not fa_device:
        print("未发现空气循环扇 (FA 设备)")
        return

    print(f"找到空气循环扇: {fa_device}")

    async with ClientSession() as session:
        cloud = get_midea_cloud(
            cloud_name="美的美居",
            session=session,
            account="your_account",
            password="your_password",
        )

        token = ""
        key = ""

        if await cloud.login():
            token_key = await get_token_from_cloud(cloud, fa_device.get("sn", ""))
            if token_key:
                token = token_key["token"]
                key = token_key["key"]
                print(f"Token: {token}")
                print(f"Key: {key}")
            else:
                print("无法获取 token，使用默认 key")
        else:
            print("云端登录失败，使用默认 key")

        if not token or not key:
            keys = await MideaCloud.get_default_keys()
            default = keys.get(99, {})
            token = default.get("token", "")
            key = default.get("key", "")

        device = MideaFADevice(
            name=fa_device.get("model", "空气循环扇"),
            device_id=int(fa_device.get("sn8", "0"), 16),
            ip_address=fa_device.get("ip_address", ""),
            port=fa_device.get("port", 6445),
            token=token,
            key=key,
            device_protocol=ProtocolVersion.V3,
            model=fa_device.get("model", ""),
            subtype=0,
            customize='{"speed_count": 3}',
        )

        device.open()

        await asyncio.sleep(2)

        print("当前状态:", device.attributes)

        device.set_attribute("power", True)
        await asyncio.sleep(1)

        device.set_attribute("fan_speed", 3)
        await asyncio.sleep(1)

        device.set_attribute("oscillate", True)
        await asyncio.sleep(1)

        print("设置后状态:", device.attributes)

        await asyncio.sleep(5)

        device.set_attribute("power", False)
        await asyncio.sleep(1)

        device.close()
        print("完成")


if __name__ == "__main__":
    # 扫描设备
    scan_devices()

    # 可选：运行控制测试
    # asyncio.run(main())