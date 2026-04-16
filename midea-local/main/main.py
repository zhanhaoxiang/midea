"""List Midea devices from Meiju Cloud."""

import asyncio
import ssl
from aiohttp import ClientSession, TCPConnector

from midealocal.cloud import get_midea_cloud


async def main():
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    connector = TCPConnector(ssl=ssl_context)

    async with ClientSession(connector=connector) as session:
        cloud = get_midea_cloud(
            cloud_name="美的美居",
            session=session,
            account="18028061491",
            password="Aa.123456",
        )

        if await cloud.login():
            print("云端登录成功！")
            appliances = await cloud.list_appliances(None)
            print(f"\n共发现 {len(appliances)} 个设备：\n")
            for device_id, app in appliances.items():
                print(f"  设备 ID: {device_id}")
                print(f"  设备名称: {app.get('name', '未知')}")
                print(f"  类型: {hex(app.get('type', 0))} ({app.get('type', 0)})")
                print(f"  型号: {app.get('model', '未知')}")
                print(f"  SN: {app.get('sn', '未知')}")
                print(f"  在线状态: {'在线' if app.get('online') else '离线'}")
                print("-" * 40)
        else:
            print("云端登录失败")


if __name__ == "__main__":
    asyncio.run(main())
