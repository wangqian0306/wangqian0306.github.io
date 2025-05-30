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

##### 持续移动

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

# 转动和缩放请求配置，x 和 y 都是 0-1.0 的数字
request.Velocity = {
    'PanTilt': {
        'x': 0.5,
        'y': 0
    },
    'Zoom': {
        'x': 0.8
    }
}

# 发送转动请求
ptz.ContinuousMove(request)
# 延迟等待云台转动
time.sleep(1)
# 发送转动停止信号
ptz.Stop({'ProfileToken': media_profile.token})
```

##### 角度移动

```python
from onvif import ONVIFCamera


class HikvisionPTZControl:
    def __init__(self, ip, port, user, password):
        self.mycam = ONVIFCamera(ip, port, user, password)
        self.media = self.mycam.create_media_service()
        self.ptz = self.mycam.create_ptz_service()

        # 获取所有 Profiles
        self.profiles = self.media.GetProfiles()
        if not self.profiles:
            raise ValueError("No ONVIF profile found.")
        self.profile = self.profiles[0]  # 默认使用第一个 Profile
        self.profile_token = self.profile.token

    def move_to_position(self, x, y, zoom=0):
        """
        将摄像头移动到指定的 x (水平), y (垂直) 位置，并设置 zoom 缩放等级。
        - x, y 的取值范围为 [-1, 1]。
        - zoom 的取值范围为 [0, 1]。
        """
        request = self.ptz.create_type('AbsoluteMove')
        request.ProfileToken = self.profile_token
        request.Position = {
            'PanTilt': {'x': x, 'y': y},
            'Zoom': {'x': zoom}
        }
        request.Speed = {
            'PanTilt': {'x': 0.1, 'y': 0.1}
        }
        self.ptz.AbsoluteMove(request)
    
    def get_ptz_configuration_options(self):
        """
        获取 PTZ 配置参数清单
        """
        request = self.ptz.create_type('GetConfigurationOptions')
        request.ConfigurationToken = self.profile_token
        ptz_configuration_options = self.ptz.GetConfigurationOptions(request)
        print(ptz_configuration_options)

    def get_ptz_config(self):
        """
        获取硬件 PTZ 配置
        """
        request_configuration = self.ptz.create_type('GetConfiguration')
        request_configuration.PTZConfigurationToken = self.profile_token
        ptz_configuration = self.ptz.GetConfiguration(request_configuration)
        print(ptz_configuration)
    
    def get_ptz_status(self):
        """
        获取硬件 PTZ 状态
        """
        print(self.ptz.GetStatus({'ProfileToken': self.profile_token}))

    def set_zoom(self, zoom):
        """
        设置摄像头的缩放等级，保持当前云台位置不变。
        - zoom 的取值范围为 [0, 1]。
        """
        status = self.ptz.GetStatus({'ProfileToken': self.profile_token})
        current_pan = status.Position.PanTilt.x
        current_tilt = status.Position.PanTilt.y
        self.move_to_position(current_pan, current_tilt, zoom)


# 使用示例
if __name__ == "__main__":
    # 替换为你的摄像头 IP、端口、用户名和密码
    ip = "xxx.xxx.xxx.xxx"
    port = 80
    username = "xxxxx"
    password = "xxxxx"

    try:
        ptz_ctrl = HikvisionPTZControl(ip, port, username, password)
        ptz_ctrl.move_to_position(1, 1, 0)
    except Exception as e:
        print(f"Error occurred: {e}")
```

#### 定位到记忆点

```python
from onvif import ONVIFCamera

ip_address = 'xxx.xxx.xxx.xxx'
port = 80
username = 'xxxx'
password = 'xxxx'

# 创建 ONVIF 摄像头对象
mycam = ONVIFCamera(ip_address, port, username, password)

# 创建媒体服务和 PTZ 服务
media_service = mycam.create_media_service()
ptz_service = mycam.create_ptz_service()

# 获取第一个配置项
configs = media_service.GetProfiles()
profile_token = configs[0].token

# 获取所有预设点
presets = ptz_service.GetPresets(ProfileToken=profile_token)

print("PTZ Presets:")
for idx, preset in enumerate(presets):
    print(f"{idx}: {preset.token} - {preset.Name}")

# 选择一个预设点编号
selected_index = int(input("请输入要跳转的预设点编号: "))

# 移动到选定的预设点
ptz_service.GotoPreset(ProfileToken=profile_token,
                       PresetToken=presets[selected_index].token)

print("已跳转至预设点:", presets[selected_index].Name)
```

### 控制灯光和雨刷

#### 调试

打开灯

```bash
curl -X PUT "http://xxx.xxx.xxx.xxx/ISAPI/PTZCtrl/channels/1/auxcontrols/1" \
     -u xxx:xxxx \
     --digest \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0" encoding="UTF-8"?><PTZAux><id>1</id><type>LIGHT</type><status>on</status></PTZAux>'
```

关闭灯

```bash
curl -X PUT "http://xxx.xxx.xxx.xxx/ISAPI/PTZCtrl/channels/1/auxcontrols/1" \
     -u xxx:xxxx \
     --digest \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0" encoding="UTF-8"?><PTZAux><id>1</id><type>LIGHT</type><status>off</status></PTZAux>'
```

打开雨刷

```bash
curl -X PUT "http://xxx.xxx.xxx.xxx/ISAPI/PTZCtrl/channels/1/auxcontrols/1" \
     -u xxx:xxxx \
     --digest \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0" encoding="UTF-8"?><PTZAux><id>1</id><type>WIPER</type><status>on</status></PTZAux>'
```

关闭雨刷

```bash
curl -X PUT "http://xxx.xxx.xxx.xxx/ISAPI/PTZCtrl/channels/1/auxcontrols/1" \
     -u xxx:xxxx \
     --digest \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0" encoding="UTF-8"?><PTZAux><id>1</id><type>WIPER</type><status>off</status></PTZAux>'
```

#### 控制代码

```python
import requests
from requests.auth import HTTPDigestAuth


class PlugInController:
    def __init__(self, host, username, password):
        """
        初始化控制器

        :param host:  
        :param username: 登录用户名
        :param password: 登录密码
        """
        self.base_url = f'http://{host}/ISAPI/PTZCtrl/channels/1/auxcontrols/1'
        self.username = username
        self.password = password
        self.headers = {
            "Content-Type": "application/xml"
        }

    def _send_command(self, action_type, status):
        """
        内部方法：发送控制命令

        :param action_type: 设备类型，如 LIGHT 或 WIPER
        :param status: 状态 on 或 off
        :return: 响应对象
        """
        xml_data = f'''<?xml version="1.0" encoding="UTF-8"?>
<PTZAux>
  <id>1</id>
  <type>{action_type}</type>
  <status>{status}</status>
</PTZAux>'''

        try:
            response = requests.put(
                self.base_url,
                auth=HTTPDigestAuth(self.username, self.password),
                headers=self.headers,
                data=xml_data,
                timeout=5  # 设置超时时间
            )
            return response
        except requests.exceptions.RequestException as e:
            print("请求失败:", e)
            return None

    def turn_light_on(self):
        """打开灯光"""
        return self._send_command("LIGHT", "on")

    def turn_light_off(self):
        """关闭灯光"""
        return self._send_command("LIGHT", "off")

    def turn_wiper_on(self):
        """启动雨刷"""
        return self._send_command("WIPER", "on")

    def turn_wiper_off(self):
        """停止雨刷"""
        return self._send_command("WIPER", "off")
```

### 参考资料

[海康威视 ISAPI 文档](https://download.isecj.jp/catalog/misc/isapi.pdf)

[Control the white ColorVU LED on Hikvision cameras](https://community.home-assistant.io/t/control-the-white-colorvu-led-on-hikvision-cameras/245092/13)
