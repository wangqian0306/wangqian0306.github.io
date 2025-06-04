---
title: pySerial 
date: 2025-06-04 23:09:32
tags:
- "pySerial"
- "Python"
id: pyserial
no_word_count: true
no_toc: false
categories: "Ocean"
---

## pySerial

### 简介

pySerial 可以让 Python 程序读取串口。

### 使用方式

```powershell
pip install pyserial
```

编写如下程序即可获取当前开放的 `COM` 口

```python
import serial
import serial.tools.list_ports

def list_serial_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    return [port.device for port in ports]

def check_opened_ports():
    """尝试打开每个串口，判断是否已被占用"""
    available_ports = list_serial_ports()
    opened_ports = []

    for port in available_ports:
        try:
            ser = serial.Serial(port)
            ser.close()
            # 如果能成功打开并关闭，说明未被占用
            print(f"{port} 是可用的")
        except serial.SerialException:
            print(f"{port} 可能已被占用或无法访问")
            opened_ports.append(port)

    return opened_ports

# 使用示例
if __name__ == '__main__':
    print("当前可能被占用的串口：")
    busy_ports = check_opened_ports()
    print(busy_ports)
```

简要的读取程序如下：

```python
import serial
import time

# 配置串口参数
port = 'COM3'         # Windows 下可能是 COM3、COM4 等；Linux 下可能是 /dev/ttyUSB0 或 /dev/ttyS0
baud_rate = 9600      # 波特率，根据设备实际设置修改
timeout = 1           # 读取超时时间（秒）

# 打开串口
try:
    ser = serial.Serial(port, baud_rate, timeout=timeout)
    
    if ser.is_open:
        print(f"串口 {port} 已打开，波特率: {baud_rate}")
        
    while True:
        if ser.in_waiting > 0:       # 如果有数据可读
            data = ser.readline()    # 按行读取
            try:
                print("收到数据:", data.decode('utf-8').strip())
            except UnicodeDecodeError:
                print("收到非UTF-8数据:", data)

        time.sleep(0.1)              # 小延时避免CPU占用过高

except serial.SerialException as e:
    print(f"无法打开或读取串口: {e}")

finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()
        print("串口已关闭")
```

### 参考资料

[官方文档](https://pythonhosted.org/pyserial/)
