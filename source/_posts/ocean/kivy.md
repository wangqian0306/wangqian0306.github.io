---
title: Kivy
date: 2024-10-08 21:32:58
tags:
- "Python"
- "Kivy"
id: kivy
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## Kivy 

### 简介

Kivy 是一个开源的 Python GUI 开发框架。

### 安装依赖

使用如下命令安装：

```bash
pip install kivy kivy-md materialyoucolor
```

示例：

```python
from kivymd.app import MDApp
from kivymd.uix.label import MDLabel


class MainApp(MDApp):
    def build(self):
        return MDLabel(text="Hello, World", halign="center")


MainApp().run()
```

除了使用这样的基本方式外还可以使用配置文件的方式创建页面，具体样例参见下文。

### 使用方式

#### 对接 matplotlib

安装依赖：

```bash
pip install kivy-matplotlib-widget
```

编写如下程序即可：

```python
from kivy.utils import platform

# avoid conflict between mouse provider and touch (very important with touch device)
# no need for android platform
if platform != 'android':
    from kivy.config import Config

    Config.set('input', 'mouse', 'mouse,disable_on_activity')

from kivy.lang import Builder
from kivy.app import App
import matplotlib.pyplot as plt
import kivy_matplotlib_widget

KV = '''
Screen
    figure_wgt:figure_wgt
    BoxLayout:
        orientation:'vertical'
        BoxLayout:
            size_hint_y:0.2
            Button:
                text:"home"
                on_release:app.home()
            ToggleButton:
                group:'touch_mode'
                state:'down'
                text:"pan" 
                on_release:
                    app.set_touch_mode('pan')
                    self.state='down'
            ToggleButton:
                group:'touch_mode'
                text:"zoom box"  
                on_release:
                    app.set_touch_mode('zoombox')
                    self.state='down'                
        MatplotFigure:
            id:figure_wgt
'''


class Test(App):
    lines = []

    def build(self):
        self.screen = Builder.load_string(KV)
        return self.screen

    def on_start(self, *args):
        fig, ax1 = plt.subplots(1, 1)

        ax1.plot([0, 1, 2, 3, 4], [1, 2, 8, 9, 4], label='line1')
        ax1.plot([2, 8, 10, 15], [15, 0, 2, 4], label='line2')

        self.screen.figure_wgt.figure = fig

    def set_touch_mode(self, mode):
        self.screen.figure_wgt.touch_mode = mode

    def home(self):
        self.screen.figure_wgt.home()


Test().run()
```

> 注：kivy_matplotlib_widget 包如果没有引入则会无法使用 MatplotFigure 组件，IDEA 可能因为代理的问题没能正确读取依赖。

#### 对接 OpenCV

安装依赖：

```bash
pip install opencv-python
```

编写如下程序即可：

```python
import cv2
from kivy.app import App
from kivy.clock import Clock
from kivy.graphics.texture import Texture
from kivy.uix.image import Image


class KivyCamera(Image):
    def __init__(self, capture, fps, **kwargs):
        super(KivyCamera, self).__init__(**kwargs)
        self.capture = capture
        Clock.schedule_interval(self.update, 1.0 / fps)

    def update(self, dt):
        ret, frame = self.capture.read()
        if ret:
            # convert it to texture
            buf1 = cv2.flip(frame, 0)
            buf = buf1.tostring()
            image_texture = Texture.create(size=(frame.shape[1], frame.shape[0]), colorfmt='bgr')
            image_texture.blit_buffer(buf, colorfmt='bgr', bufferfmt='ubyte')
            # display image from the texture
            self.texture = image_texture


class CamApp(App):
    def build(self):
        video_path = 'video.mp4'
        self.capture = cv2.VideoCapture(video_path)
        self.my_camera = KivyCamera(capture=self.capture, fps=30)
        return self.my_camera

    def on_stop(self):
        # without this, app will not exit even if the window is closed
        self.capture.release()


if __name__ == '__main__':
    CamApp().run()
```

### 参考资料

[Kivy 官网](https://kivy.org/)

[KivyMD 官网](https://kivymd.readthedocs.io/en/latest/)

[kivy-matplotlib-widget 官方项目](https://github.com/mp-007/kivy_matplotlib_widget)
