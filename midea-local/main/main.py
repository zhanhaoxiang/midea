"""Control Midea drum washing machine via LAN using cloud credentials."""

import asyncio
import logging
import ssl

from aiohttp import ClientSession, TCPConnector

from midealocal.cloud import get_midea_cloud, get_preset_account_cloud
from midealocal.const import ProtocolVersion
from midealocal.devices import device_selector
from midealocal.discover import discover

logging.basicConfig(level=logging.WARNING)

WASHING_MACHINE_ID = 210006722801783
MEIJU_CLOUD = "美的美居"
MEIJU_ACCOUNT = "18028061491"
MEIJU_PASSWORD = "Aa.123456"


async def get_cloud_info(session: ClientSession) -> dict | None:
    """Step 1: Get washing machine info from MeijuCloud (美的美居)."""
    print(f"\n[1] 登录 {MEIJU_CLOUD} 获取设备信息...")
    cloud = get_midea_cloud(
        cloud_name=MEIJU_CLOUD,
        session=session,
        account=MEIJU_ACCOUNT,
        password=MEIJU_PASSWORD,
    )
    if not await cloud.login():
        print(f"  {MEIJU_CLOUD} 登录失败")
        return None
    print(f"  {MEIJU_CLOUD} 登录成功")

    devices = await cloud.list_appliances(None)
    if not devices or WASHING_MACHINE_ID not in devices:
        print(f"  未找到洗衣机 (id={WASHING_MACHINE_ID})")
        return None

    d = devices[WASHING_MACHINE_ID]
    print(f"  找到设备: {d['name']}  type=0x{d['type']:02x}  model={d['model']}  online={d['online']}")
    return d


async def get_token_and_key(session: ClientSession) -> tuple[str, str] | tuple[None, None]:
    """Step 2: Get token/key from NetHome Plus (preset account)."""
    preset = get_preset_account_cloud()
    print(f"\n[2] 使用内置账号登录 NetHome Plus 获取 token...")
    cloud = get_midea_cloud(
        cloud_name="NetHome Plus",
        session=session,
        account=preset["username"],
        password=preset["password"],
    )
    if not await cloud.login():
        print("  NetHome Plus 登录失败")
        return None, None
    print("  NetHome Plus 登录成功")

    keys = await cloud.get_cloud_keys(WASHING_MACHINE_ID)
    if not keys:
        print("  无法获取 token/key")
        return None, None

    # Try method 1 first, fall back to method 2
    key_info = keys.get(1) or keys.get(2) or next(iter(keys.values()))
    token = key_info["token"]
    key = key_info["key"]
    print(f"  Token: {token[:16]}...")
    print(f"  Key:   {key[:16]}...")
    return token, key


def scan_local_device() -> dict | None:
    """Step 3: Discover the washing machine on LAN."""
    print(f"\n[3] 扫描本地局域网设备...")
    found = discover(discover_type=[0xDB])
    if not found:
        print("  未发现任何设备，尝试全类型扫描...")
        found = discover()

    if not found:
        print("  本地未发现任何设备")
        return None

    for device_id, info in found.items():
        print(f"  发现: id={device_id}  ip={info['ip_address']}  type=0x{info['type']:02x}  protocol={info['protocol']}")
        if device_id == WASHING_MACHINE_ID:
            print(f"  ✓ 匹配到滚筒洗衣机！")
            return info

    print(f"  本地扫描中未找到 id={WASHING_MACHINE_ID} 的设备")
    # Return first found device as fallback if only one DB device exists
    db_devices = {k: v for k, v in found.items() if v["type"] == 0xDB}
    if len(db_devices) == 1:
        device_id, info = next(iter(db_devices.items()))
        print(f"  使用唯一的 DB 设备 (id={device_id})")
        return info
    return None


async def main():
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE
    connector = TCPConnector(ssl=ssl_context)

    async with ClientSession(connector=connector) as session:
        # Step 1: Get device info from MeijuCloud
        # cloud_info = await get_cloud_info(session)
        # if cloud_info is None:
        #     return
        cloud_info = {
            "name": "滚筒洗衣机",
            "type": 219,
            "sn": "0000DB5133812519632225A0084904FX",
            "sn8": "38125196",
            "model_number": 13124,
            "manufacturer_code": "0000",
            "model": "38125196",
            "online": True
        }

        # Step 2: Get token/key from NetHome Plus
        token, key = await get_token_and_key(session)
        if token is None:
            return

    # Step 3: Discover local device
    local_info = scan_local_device()
    if local_info is None:
        print("\n无法在本地网络中找到洗衣机，无法控制")
        return

    # Step 4: Create device and connect
    print(f"\n[4] 连接洗衣机 {local_info['ip_address']}:{local_info['port']}...")
    protocol = ProtocolVersion(local_info["protocol"])
    device = device_selector(
        name="滚筒洗衣机",
        device_id=WASHING_MACHINE_ID,
        device_type=0xDB,
        ip_address=local_info["ip_address"],
        port=local_info["port"],
        token=token,
        key=key,
        device_protocol=protocol,
        model=cloud_info.get("model", ""),
        subtype=0,
        customize="",
    )

    if not device.connect():
        print("  连接失败")
        return
    print("  连接成功！")

    # Step 5: Read current attributes
    print("\n[5] 读取设备状态...")
    device.refresh_status()
    attrs = device.attributes
    print("  当前属性:")
    for k, v in attrs.items():
        print(f"    {k}: {v}")

    # Step 6: Try to control — power on
    print("\n[6] 尝试控制：开机...")
    try:
        device.set_attribute("power", True)
        print("  已发送开机指令")
        import time
        time.sleep(1)
        device.refresh_status()
        print(f"  开机后 power 状态: {device.attributes.get('power')}")
    except Exception as e:
        print(f"  控制失败: {e}")


if __name__ == "__main__":
    asyncio.run(main())
