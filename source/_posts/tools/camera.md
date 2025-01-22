---
title: 摄像头视频流
date: 2025-01-22 21:32:58
tags:
- "Python"
- "OpenCV"
id: camera
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## 摄像头视频流

### 简介

可以通过如下方式读取摄像头的 RTSP 协议视频信号：

### OpenCV

使用如下命令安装依赖：

```bash
pip install opencv-python
```

使用如下代码即可读取视频流：

```python
import cv2

# RTSP URL ，请替换为你的实际 URL ，默认可以使用 1 作为 channel
rtsp_url = "rtsp://<username>:<password>@<ip_address>:<port>/Streaming/Channels/<channel>"

# 创建一个VideoCapture对象
cap = cv2.VideoCapture(rtsp_url)

# 检查是否成功打开视频流
if not cap.isOpened():
    print("无法打开RTSP流")
    exit()

# 循环读取视频帧
while True:
    # 获取一帧
    ret, frame = cap.read()
    
    # 如果读取失败，跳出循环
    if not ret:
        print("无法接收帧 (流结束?). 退出.")
        break
    
    # 显示结果帧
    cv2.imshow('Frame', frame)
    
    # 按'q'键退出循环
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# 完成后释放捕捉器和关闭所有窗口
cap.release()
cv2.destroyAllWindows()
```
