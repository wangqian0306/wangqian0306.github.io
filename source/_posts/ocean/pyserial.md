---
title: PySerial 
date: 2025-06-04 23:09:32
tags:
- "PySerial"
- "Python"
id: pyserial
no_word_count: true
no_toc: false
categories: "Ocean"
---

## PySerial

### 简介

PySerial 是一个 Python 第三方库，用于在 Python 程序中实现串行通信（Serial Communication）。它为用户提供了简单、统一的接口来访问和控制串口。

### 使用方式

安装:

```bash
pip install pyserial
```

读取:

```python
import serial

# 配置串口（请根据你的设备修改端口号和波特率）
# ser = serial.Serial('COM3', 9600, timeout=1)  # Windows 示例
ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)  # Linux/macOS 示例

try:
    while True:
        if ser.in_waiting > 0:
            data = ser.readline().decode('utf-8').rstrip()
            print(f"收到数据: {data}")
except KeyboardInterrupt:
    print("程序被用户中断")
finally:
    ser.close()
    print("串口已关闭")
```

写入：

```python
import serial

# 配置串口（请根据你的设备修改端口号和波特率）
# ser = serial.Serial('COM3', 9600, timeout=1)  # Windows 示例
ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)  # Linux/macOS 示例

try:
    while True:
        command = input("输入 'on' 打开LED，'off' 关闭LED，'quit' 退出: ").strip().lower()
        
        if command == 'quit':
            break
        elif command in ['on', 'off']:
            ser.write(f"{command}\n".encode('utf-8'))
            print(f"已发送: {command}")
        else:
            print("无效命令，请输入 'on', 'off' 或 'quit'")
            
except Exception as e:
    print(f"发生错误: {e}")
finally:
    ser.close()
    print("串口已关闭")
```

### 常见问题

#### 在串口重新链接时端口发生了变化

可以通过如下步骤自定义链接设备的软连接

- 检查设备的 ID

```bash
udevadm info -a -p $(udevadm info -q path -n /dev/ttyUSB0) | grep -i serial
```

输入如下，需要记录 `ATTRS{serial}` 值的内容：

```text
    SUBSYSTEMS=="usb-serial"
    ATTRS{product}=="USB2.0-Serial"
    ATTRS{serial}=="xhci-hcd.1"
```

- 编辑自定义配置文件

```bash
sudo vim /etc/udev/rules.d/99-usb-serial.rules
```

内容如下：

```text
SUBSYSTEM=="tty", ATTRS{serial}=="xhci-hcd.1", SYMLINK+="ttyDEMO0", NAME="ttyDEMO0"
```

- 刷新配置

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

- 检查设备

```bash
ls /dev/ttyDEMO0
```

### 参考资料

[官方文档](https://pythonhosted.org/pyserial/)
