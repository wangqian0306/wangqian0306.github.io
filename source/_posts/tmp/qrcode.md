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

将图片放在二维码中间：

```python
import qrcode
from PIL import Image

def generate_qr_with_logo(data, logo_path, output_path):
    """
    Generates a QR code with a custom logo in the center.

    Args:
        data: The data to encode in the QR code (string).
        logo_path: Path to the logo image (string).
        output_path: Path to save the generated QR code (string).
    """
    try:
        # Create QR code instance
        qr = qrcode.QRCode(
            version=1,  # Adjust version for more data
            error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction
            box_size=10,
            border=4,
        )
        qr.add_data(data)
        qr.make(fit=True)

        # Create an image from the QR code
        qr_image = qr.make_image(fill_color="black", back_color="white").convert("RGB")

        # Open the logo image
        logo = Image.open(logo_path).convert("RGB")

        # Calculate logo size (adjust as needed)
        logo_size = int(qr_image.size[0] * 0.2)  # 20% of QR code size

        # Resize the logo
        logo = logo.resize((logo_size, logo_size), Image.LANCZOS)

        # Calculate logo position
        position = ((qr_image.size[0] - logo.size[0]) // 2, (qr_image.size[1] - logo.size[1]) // 2)

        # Paste the logo onto the QR code
        qr_image.paste(logo, position)

        # Save the QR code
        qr_image.save(output_path)
        print(f"QR code with logo saved to {output_path}")

    except FileNotFoundError:
        print(f"Error: Logo file not found at {logo_path}")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    data_to_encode = "<data>"
    logo_file = "logo.png"
    output_file = "qrcode_with_logo.png"
    generate_qr_with_logo(data_to_encode, logo_file, output_file)
```

> 注：其它用例参照官方项目。

### 参考资料

[官方项目](https://github.com/lincolnloop/python-qrcode)

[PyPI qrcode](https://pypi.org/project/qrcode/)
