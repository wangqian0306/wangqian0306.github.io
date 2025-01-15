---
title: qrcode
date: 2025-01-15 22:26:13
tags:
- "QR Code"
id: qrcode
no_word_count: true
no_toc: false
---

## qrcode

### 简介

使用 python-qrcode 库可以生成二维码。

### 使用方式

使用如下命令安装依赖：

```bash
pip install "qrcode[pil]"
```

使用如下代码即可生成基本的二维码：

```python
def text_to_qr(text, filename):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(text)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(filename)
```

> 注：其它用例参照官方项目。

### 参考资料

[官方项目](https://github.com/lincolnloop/python-qrcode)

[PyPI qrcode](https://pypi.org/project/qrcode/)
