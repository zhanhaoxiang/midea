"""Get token for Midea washing machine from NetHome Plus cloud."""

import asyncio
import ssl
from aiohttp import ClientSession, TCPConnector

from midealocal.cloud import get_midea_cloud, get_preset_account_cloud


async def main():
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    connector = TCPConnector(ssl=ssl_context)

    account = get_preset_account_cloud()
    print(f"使用内置账号登录 NetHome Plus...")

    async with ClientSession(connector=connector) as session:
        cloud = get_midea_cloud(
            cloud_name="NetHome Plus",
            session=session,
            account=account["username"],
            password=account["password"],
        )

        if await cloud.login():
            print("NetHome Plus 云端登录成功！")
            appliance_id = 210006722801783
            print(f"获取设备 token (appliance_id: {appliance_id})...")
            keys = await cloud.get_cloud_keys(appliance_id)
            if keys:
                for method, key_info in keys.items():
                    print(f"\n方法 {method} 的 token:")
                    print(f"  Token: {key_info['token']}")
                    print(f"  Key: {key_info['key']}")
            else:
                print("无法获取 token")
        else:
            print("云端登录失败")


if __name__ == "__main__":
    asyncio.run(main())
