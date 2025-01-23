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

在工作中遇到了云台控制和视频接入的相关需求，此处针对相关内容进行了初步的整理。

### 读取视频流

可以通过如下方式读取摄像头的 RTSP 协议视频信号，需要注意的是登录摄像头的配置网站明确端口和认证方式。

####  OpenCV

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

### 控制云台

可以通过如下方式控制云台，需要注意的是登录摄像头的配置网站明确端口和认证方式。

基本的控制逻辑是采用 ONVIF 协议，在海康威视摄像头上需要摄像机启用集成协议，具体文档如下：

[摄像机开启ONVIF协议](https://knowbot.hikvision.com/webchatbot-pc/#/sharingPath?params=379537&sysNum=1693447044565&type=0)

简单说就是：

- 开启开放型网络视频接口
    - 认证方式为 digest/wsse 或 Digest&ws-username token 
- 创建独立用户
    - 选择权限为管理员

#### onviz-zeep

使用如下命令安装相关依赖库：

```bash
pip install zeep
pip install onvif_zeep
```

然后使用如下代码即可：

```python
import time

from onvif import ONVIFCamera

# 摄像头的IP地址、端口、用户名和密码
ip_address = 'xxx.xxx.xxx.xxx'
port = 80
username = 'xxx'
password = 'xxx'

# 创建ONVIFCamera实例
mycam = ONVIFCamera(ip_address, port, username, password)

# 获取PTZ服务对象
ptz = mycam.create_ptz_service()

# 获取 Media service 对象并得到配置文件
media = mycam.create_media_service()

# 获取配置信息
media_profile = media.GetProfiles()[0]

# 构建请求对象
request = ptz.create_type('GetConfigurationOptions')
request.ConfigurationToken = media_profile.PTZConfiguration.token
ptz_configuration_options = ptz.GetConfigurationOptions(request)
request = ptz.create_type('ContinuousMove')
request.ProfileToken = media_profile.token

# 发送转动停止信号
ptz.Stop({'ProfileToken': media_profile.token})

# 转动请求配置，x 和 y 都是 0-1.0 的数字
request.Velocity = {
    'PanTilt': {
        'x': 0.5,
        'y': 0
    }
}

# 发送转动请求
ptz.ContinuousMove(request)
# 延迟等待云台转动
time.sleep(1)
# 发送转动停止信号
ptz.Stop({'ProfileToken': media_profile.token})
```
