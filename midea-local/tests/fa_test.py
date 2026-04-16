# -*- coding: utf-8 -*-
"""FA device mock test."""

from unittest.mock import MagicMock, patch

from midealocal.cloud import DEFAULT_KEYS
from midealocal.const import ProtocolVersion
from midealocal.devices.fa import MideaFADevice
from midealocal.devices.fa.message import MessageSet, MessageQuery


def test_fa_message_serialization():
    msg = MessageSet(protocol_version=3, subtype=0)
    msg.power = True
    msg.fan_speed = 3
    msg.oscillate = True
    
    body = msg._body
    print("Message body: " + body.hex())
    
    assert body[3] == 1, "Power bit should be 1"
    assert body[4] == 3, "Fan speed should be 3"
    assert body[7] & 0x01, "Oscillate bit should be 1"


def test_fa_message_power_off():
    msg = MessageSet(protocol_version=3, subtype=0)
    msg.power = False
    
    body = msg._body
    print("Power off body: " + body.hex())
    
    assert body[3] == 0, "Power bit should be 0"


def test_fa_device_attributes():
    device = MideaFADevice(
        name="Test Fan",
        device_id=0x56011CF4,
        ip_address="192.168.1.100",
        port=6445,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="FGD24SJX",
        subtype=0,
        customize='{"speed_count": 3}',
    )
    
    assert device.attributes["power"] is False
    assert device.attributes["fan_speed"] == 0
    assert device.speed_count == 3


def test_fa_device_set_attribute():
    device = MideaFADevice(
        name="Test Fan",
        device_id=0x56011CF4,
        ip_address="192.168.1.100",
        port=6445,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="FGD24SJX",
        subtype=0,
        customize='{"speed_count": 3}',
    )
    
    with patch.object(device, "build_send") as mock_send:
        device.set_attribute("power", True)
        mock_send.assert_called_once()
        
        call_args = mock_send.call_args[0][0]
        assert call_args.power is True
        print("Set power=True: " + call_args._body.hex())
        
    with patch.object(device, "build_send") as mock_send:
        device.set_attribute("fan_speed", 5)
        call_args = mock_send.call_args[0][0]
        assert call_args.fan_speed == 5
        print("Set fan_speed=5: " + call_args._body.hex())


def test_fa_device_oscillation():
    device = MideaFADevice(
        name="Test Fan",
        device_id=0x56011CF4,
        ip_address="192.168.1.100",
        port=6445,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="FGD24SJX",
        subtype=0,
        customize='{"speed_count": 3}',
    )
    
    with patch.object(device, "build_send") as mock_send:
        device.set_attribute("oscillate", True)
        call_args = mock_send.call_args[0][0]
        assert call_args.oscillate is True
        print("Set oscillate=True: " + call_args._body.hex())
        
    with patch.object(device, "build_send") as mock_send:
        device.set_attribute("oscillation_angle", "90")
        call_args = mock_send.call_args[0][0]
        print("Set oscillation_angle=90: " + call_args._body.hex())


def test_fa_process_message():
    device = MideaFADevice(
        name="Test Fan",
        device_id=0x56011CF4,
        ip_address="192.168.1.100",
        port=6445,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="FGD24SJX",
        subtype=0,
        customize='{"speed_count": 3}',
    )
    
    mock_response = bytes([
        0x00, 0x00, 0x00, 0x00,
        0x00,
        0x01,
        0x03,
        0x00, 0x00, 0x00, 0x00,
        0x01,
    ]) + bytes(50)
    
    with patch("midealocal.devices.fa.message.MessageResponse.__init__", return_value=None):
        from midealocal.devices.fa.message import FAGeneralMessageBody
        body = FAGeneralMessageBody(bytearray(mock_response[4:30]))
        
        print("child_lock: " + str(body.child_lock))
        print("power: " + str(body.power))
        print("mode: " + str(body.mode))
        print("fan_speed: " + str(body.fan_speed))
        print("oscillate: " + str(body.oscillate))
        print("oscillation_angle: " + str(body.oscillation_angle))
        print("oscillation_mode: " + str(body.oscillation_mode))


if __name__ == "__main__":
    print("=== Test FA Message Serialization ===")
    test_fa_message_serialization()
    
    print("\n=== Test FA Power Off ===")
    test_fa_message_power_off()
    
    print("\n=== Test FA Device Attributes ===")
    test_fa_device_attributes()
    
    print("\n=== Test FA Set Attribute ===")
    test_fa_device_set_attribute()
    
    print("\n=== Test FA Oscillation ===")
    test_fa_device_oscillation()
    
    print("\n=== Test FA Process Message ===")
    test_fa_process_message()
    
    print("\n=== All tests passed! ===")