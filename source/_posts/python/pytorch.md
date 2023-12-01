---
title: PyTorch
date: 2023-12-01 21:41:32
tags: 
- "Python"
id: torch
no_word_count: true
no_toc: false
---

## PyTorch

### 简介

PyTorch 是一个开源的机器学习库，由 Facebook 的人工智能研究实验室 (FAIR)开发。它提供了一个动态计算图，并建立在 Python 之上。PyTorch 主要用于构建深度神经网络，但也可用于其他类型的机器学习模型。

### 安装

> 注：建议使用带 GPU 的设备，本文以 Linux 系统 CUDA 12.0 Python 3.9.18 做为样例。

```bash
pip3 install torch torchvision torchaudio opencv-python
```

### 常见用例

#### 目标识别(Object Detection)

> 注：PyTorch 官方提供了很多的预训练模型，由于想最快的显示标注结果所以选择 FasterRCNN_MobileNet 作为样例，其余 [预训练模型](https://pytorch.org/vision/stable/models.html) 可以在这里找到。

识别图像(使用 CPU)

```python
from torchvision.io.image import read_image
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn,FasterRCNN_MobileNet_V3_Large_FPN_Weights
from torchvision.utils import draw_bounding_boxes
from torchvision.transforms.functional import to_pil_image


def main():
    # Step 0: Set input and output file paths
    input_path = "input.jpg"
    output_path = "output.jpg"

    # Step 1: Read the input image
    img = read_image(input_path)

    # Step 2: Initialize model with the best available weights
    weights = FasterRCNN_MobileNet_V3_Large_FPN_Weights.DEFAULT
    model = fasterrcnn_mobilenet_v3_large_fpn(weights=weights, box_score_thresh=0.9)
    model.eval()

    # Step 3: Initialize the inference transforms
    preprocess = weights.transforms()

    # Step 4: Apply inference preprocessing transforms
    batch = [preprocess(img)]

    # Step 5: Use the model and visualize the prediction
    prediction = model(batch)[0]
    labels = [weights.meta["categories"][i] for i in prediction["labels"]]
    boxed_img = draw_bounding_boxes(img,
                                    boxes=prediction["boxes"],
                                    labels=labels,
                                    colors="red",
                                    width=4,
                                    font="LiberationSans-Regular")

    # Step 6: Save the output image
    im = to_pil_image(boxed_img.detach())
    im.save(output_path)


if __name__ == "__main__":
    main()
```

识别视频(使用 GPU)：

```bash
from torchvision.models.detection import FasterRCNN_MobileNet_V3_Large_FPN_Weights, fasterrcnn_mobilenet_v3_large_fpn
import torch
import torchvision.transforms as T
import cv2
import datetime


def main():
    # Step 0: Set input and output file paths
    input_path = "input.mp4"
    output_path = "output.mp4"

    weights = FasterRCNN_MobileNet_V3_Large_FPN_Weights.DEFAULT
    model = fasterrcnn_mobilenet_v3_large_fpn(weights=weights, box_score_thresh=0.9)
    model = model.cuda()
    model.eval()
    cap = cv2.VideoCapture(input_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    # Define the codec and create VideoWriter object for output video
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    start = datetime.datetime.now()
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Perform inference on the frame here
        transform = T.Compose([T.ToTensor()])
        img_tensor = transform(frame).unsqueeze(0)
        img_tensor = img_tensor.cuda()

        with torch.no_grad():
            prediction = model(img_tensor)


        boxes = prediction[0]['boxes'].cpu().numpy()
        labels = [weights.meta["categories"][i] for i in prediction[0]["labels"]]

        for box, label in zip(boxes, labels):
            box = list(map(int, box))
            frame = cv2.rectangle(frame, (box[0], box[1]), (box[2], box[3]), (0, 255, 0), 2)
            frame = cv2.putText(frame, f'Label: {label}', (box[0], box[1] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

        # Display or save the marked frame
        out.write(frame)
        cv2.imshow('Object Detection', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    end = datetime.datetime.now()
    print(end-start)
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
```

> 注：在 model 和 img_tensor 处使用 `cuda()` 方法即可。

### 参考资料

[项目官网](https://pytorch.org)

[预训练模型](https://pytorch.org/vision/stable/models.html)
