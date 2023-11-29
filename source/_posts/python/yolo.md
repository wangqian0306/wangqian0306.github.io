---
title: YOLO
date: 2023-11-23 21:41:32
tags: 
- "Python"
id: yolo
no_word_count: true
no_toc: false
---

## YOLO 

### 简介

YOLO(You Only Look Once) 是一款目标检测和图像分割模型。

> 注：AGPL-3.0 协议，可以付费商用。

### 使用场景

#### 车辆跟踪识别

此样例严格限制 Python 版本 >=3.7,<3.11

> 注：在测试中采用的系统版本是 Rocky Linux 9.3 Python 版本是 3.9.18 ，在训练和使用模型时使用显卡可以显著的减少训练时常。

在使用前可以访问 [PyTorch](https://pytorch.org/get-started/locally/) 官网根据实际情况获取安装命令然后进行安装。

使用如下命令安装依赖：

```bash
pip3 install ultralytics
```

使用如下 Python 程序进行测试：

```python
import ultralytics
ultralytics.checks()
```

使用如下命令安装 C 环境：

```bash
yum install gcc gcc-c++ cmake -y
```

使用如下命令安装 `ByteTrack` :

```bash
git clone https://github.com/ifzhang/ByteTrack.git
cd ByteTrack
```

然后编辑 `requirements.txt`：

```txt
# overwrite protobuf version
protobuf==3.19.6

# TODO: Update with exact module version
numpy==1.23.4
torch>=1.7
opencv_python
loguru
scikit-image
tqdm
torchvision>=0.10.0
Pillow
thop
ninja
tabulate
tensorboard
lapx
motmetrics
filterpy
h5py

# verified versions
onnx==1.9.0
onnxruntime
onnx-simplifier==0.3.5
```

```bash
pip3 install -r requirements.txt
python3 setup.py develop
pip3 install cython; pip3 install 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'
pip3 install cython_bbox
pip3 install -q onemetric
pip3 install -q loguru lap thop
```

使用如下 Python 程序进行测试：

```python
import sys
sys.path.append(f"{HOME}/ByteTrack")


import yolox
print("yolox.__version__:", yolox.__version__)
```

使用如下命令安装 `Roboflow Supervision` ：

```bash
pip3 install supervision==0.1.0
```

使用如下 Python 程序进行测试：

```python
import supervision
print("supervision.__version__:", supervision.__version__)
```

下载演示视频流：

```bash
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1pz68D1Gsx80MoPg-_q-IbEdESEmyVLm-' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1pz68D1Gsx80MoPg-_q-IbEdESEmyVLm-" -O vehicle-counting.mp4 && rm -rf /tmp/cookies.txt
```

编写示例程序：

```python
SOURCE_VIDEO_PATH = "<VIDEO_PATH>"
TARGET_VIDEO_PATH = "<PATH>/vehicle-counting-result.mp4"
import sys
sys.path.append("<PATH>/ByteTrack")

import yolox
from yolox.tracker.byte_tracker import BYTETracker, STrack
from onemetric.cv.utils.iou import box_iou_batch
from dataclasses import dataclass

@dataclass(frozen=True)
class BYTETrackerArgs:
    track_thresh: float = 0.25
    track_buffer: int = 30
    match_thresh: float = 0.8
    aspect_ratio_thresh: float = 3.0
    min_box_area: float = 1.0
    mot20: bool = False

import supervision
from supervision.draw.color import ColorPalette
from supervision.geometry.dataclasses import Point
from supervision.video.dataclasses import VideoInfo
from supervision.video.source import get_video_frames_generator
from supervision.video.sink import VideoSink
from supervision.notebook.utils import show_frame_in_notebook
from supervision.tools.detections import Detections, BoxAnnotator
from supervision.tools.line_counter import LineCounter, LineCounterAnnotator

from typing import List

import numpy as np


# converts Detections into format that can be consumed by match_detections_with_tracks function
def detections2boxes(detections: Detections) -> np.ndarray:
    return np.hstack((
        detections.xyxy,
        detections.confidence[:, np.newaxis]
    ))


# converts List[STrack] into format that can be consumed by match_detections_with_tracks function
def tracks2boxes(tracks: List[STrack]) -> np.ndarray:
    return np.array([
        track.tlbr
        for track
        in tracks
    ], dtype=float)


# matches our bounding boxes with predictions
def match_detections_with_tracks(
        detections: Detections,
        tracks: List[STrack]
) -> Detections:
    if not np.any(detections.xyxy) or len(tracks) == 0:
        return np.empty((0,))

    tracks_boxes = tracks2boxes(tracks=tracks)
    iou = box_iou_batch(tracks_boxes, detections.xyxy)
    track2detection = np.argmax(iou, axis=1)

    tracker_ids = [None] * len(detections)

    for tracker_index, detection_index in enumerate(track2detection):
        if iou[tracker_index, detection_index] != 0:
            tracker_ids[detection_index] = tracks[tracker_index].track_id

    return tracker_ids

MODEL = "yolov8x.pt"
from ultralytics import YOLO

model = YOLO(MODEL)
model.fuse()

CLASS_NAMES_DICT = model.model.names
# class_ids of interest - car, motorcycle, bus and truck
CLASS_ID = [2, 3, 5, 7]

# create frame generator
generator = get_video_frames_generator(SOURCE_VIDEO_PATH)
# create instance of BoxAnnotator
box_annotator = BoxAnnotator(color=ColorPalette(), thickness=4, text_thickness=4, text_scale=2)
# acquire first video frame
iterator = iter(generator)
frame = next(iterator)
# model prediction on single frame and conversion to supervision Detections
results = model(frame)
detections = Detections(
    xyxy=results[0].boxes.xyxy.cpu().numpy(),
    confidence=results[0].boxes.conf.cpu().numpy(),
    class_id=results[0].boxes.cls.cpu().numpy().astype(int)
)
# format custom labels
labels = [
    f"{CLASS_NAMES_DICT[class_id]} {confidence:0.2f}"
    for _, confidence, class_id, tracker_id
    in detections
]
# annotate and display frame
#frame = box_annotator.annotate(frame=frame, detections=detections, labels=labels)

# show_frame_in_notebook(frame, (16, 16))

LINE_START = Point(50, 1500)
LINE_END = Point(3840-50, 1500)

VideoInfo.from_video_path(SOURCE_VIDEO_PATH)
# from tqdm.notebook import tqdm


# create BYTETracker instance
byte_tracker = BYTETracker(BYTETrackerArgs())
# create VideoInfo instance
video_info = VideoInfo.from_video_path(SOURCE_VIDEO_PATH)
# create frame generator
generator = get_video_frames_generator(SOURCE_VIDEO_PATH)
# create LineCounter instance
line_counter = LineCounter(start=LINE_START, end=LINE_END)
# create instance of BoxAnnotator and LineCounterAnnotator
box_annotator = BoxAnnotator(color=ColorPalette(), thickness=4, text_thickness=4, text_scale=2)
line_annotator = LineCounterAnnotator(thickness=4, text_thickness=4, text_scale=2)

# open target video file
with VideoSink(TARGET_VIDEO_PATH, video_info) as sink:
    # loop over video frames
    for frame in generator:
        # model prediction on single frame and conversion to supervision Detections
        results = model(frame)
        detections = Detections(
            xyxy=results[0].boxes.xyxy.cpu().numpy(),
            confidence=results[0].boxes.conf.cpu().numpy(),
            class_id=results[0].boxes.cls.cpu().numpy().astype(int)
        )
        # filtering out detections with unwanted classes
        mask = np.array([class_id in CLASS_ID for class_id in detections.class_id], dtype=bool)
        detections.filter(mask=mask, inplace=True)
        # tracking detections
        tracks = byte_tracker.update(
            output_results=detections2boxes(detections=detections),
            img_info=frame.shape,
            img_size=frame.shape
        )
        tracker_id = match_detections_with_tracks(detections=detections, tracks=tracks)
        detections.tracker_id = np.array(tracker_id)
        # filtering out detections without trackers
        mask = np.array([tracker_id is not None for tracker_id in detections.tracker_id], dtype=bool)
        detections.filter(mask=mask, inplace=True)
        # format custom labels
        labels = [
            f"#{tracker_id} {CLASS_NAMES_DICT[class_id]} {confidence:0.2f}"
            for _, confidence, class_id, tracker_id
            in detections
        ]
        # updating line counter
        line_counter.update(detections=detections)
        # annotate and display frame
        frame = box_annotator.annotate(frame=frame, detections=detections, labels=labels)
        line_annotator.annotate(frame=frame, line_counter=line_counter)
        sink.write_frame(frame)
```

运行程序即可在设定目录找到渲染视频。

### 参考资料

[官方项目](https://github.com/ultralytics/ultralytics)

[官方手册](https://docs.ultralytics.com/)

[车辆跟踪识别](https://github.com/roboflow/notebooks/blob/main/notebooks/how-to-track-and-count-vehicles-with-yolov8.ipynb)
