---
title: PySide
date: 2025-06-26 21:32:58
tags:
- "Python"
- "PySide"
id: pyside
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## PySide

### 简介

PySide 是 Qt 框架的官方 Python 绑定库，由 Qt Company 和 PySide 团队维护。它允许开发者使用 Python 编写跨平台的图形用户界面（GUI）应用程序。

QFluentWidgets 是一个基于 C++ Qt/PyQt/PySide 的 Fluent Design 风格组件库。

### 安装和样例

```bash
pip install PySide6
pip install "PySide6-Fluent-Widgets[full]" -i https://pypi.org/simple/
```

可以克隆仓库看看样例：

```bash
git clone --branch PySide6 --single-branch https://github.com/zhiyiYo/PyQt-Fluent-Widgets.git
cd PyQt-Fluent-Widgets/examples/gallery
python demo.py
```

### 接入网页并接收消息

```python
import sys
import json
from PySide6.QtWidgets import (
    QApplication,
    QMainWindow,
    QVBoxLayout,
    QWidget,
    QPushButton,
    QHBoxLayout,
)
from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtCore import QUrl, QObject, Slot, Signal
from PySide6.QtWebChannel import QWebChannel


# 用于 JavaScript 调用 Python 的桥接类
class Bridge(QObject):
    # 自定义信号，用于发送坐标数据到 Python
    coordinatesReceived = Signal(str)

    # 新增：用于向JavaScript发送消息的信号
    sendMessage = Signal(str)

    @Slot(str)
    def receiveCoordinates(self, data):
        """
        接收来自 JavaScript 的坐标数据
        data: JSON 字符串
        """
        print("接收到了数据:", data)  # 增加调试输出
        try:
            points = json.loads(data)
            print("✅ 从网页获取的坐标：")
            for i, point in enumerate(points):
                print(f"  点 {i+1}: 纬度={point['lat']}, 经度={point['lng']}")
            # 发送确认消息回JavaScript
            self.sendMessage.emit("坐标已成功接收！")
        except Exception as e:
            print("❌ 解析坐标数据失败:", e)
            self.sendMessage.emit("坐标接收失败！")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Leaflet 地图嵌入 PySide6")
        self.resize(1200, 800)

        # 创建布局
        layout = QVBoxLayout()

        # 创建 QWebEngineView
        self.web_view = QWebEngineView()
        layout.addWidget(self.web_view)

        # 按钮布局
        btn_layout = QHBoxLayout()
        self.btn_upload = QPushButton("上传坐标")
        self.btn_upload.clicked.connect(self.upload_coordinates)
        self.btn_sample = QPushButton("添加示例点")
        self.btn_sample.clicked.connect(self.add_sample_points)
        self.btn_clear = QPushButton("清除所有")
        self.btn_clear.clicked.connect(self.clear_all)

        btn_layout.addWidget(self.btn_upload)
        btn_layout.addWidget(self.btn_sample)
        btn_layout.addWidget(self.btn_clear)

        layout.addLayout(btn_layout)

        # 设置中央部件
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        # 创建桥接对象
        self.bridge = Bridge()
        self.bridge.coordinatesReceived.connect(self.on_coordinates_received)
        # 连接发送消息的信号
        self.bridge.sendMessage.connect(self.send_message_to_js)

        # 设置 WebChannel
        self.channel = QWebChannel()
        # 修正：使用"pybridge"作为对象名（与HTML中一致）
        self.channel.registerObject("pybridge", self.bridge)
        self.web_view.page().setWebChannel(self.channel)

        # 加载 HTML 内容
        self.load_html()

    def load_html(self):
        """加载内嵌的 HTML"""
        html_content = """
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Leaflet 地图示例</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
          crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
            integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
            crossorigin=""></script>
    <script src="qrc:///qtwebchannel/qwebchannel.js"></script>
    <style>
        html, body { margin: 0; padding: 0; height: 100%; font-family: Arial, sans-serif; }
        .container { display: flex; height: 100vh; }
        #map { width: 70%; height: 100%; }
        #sidebar { width: 30%; height: 100%; padding: 20px; background-color: #f7f9fc; box-shadow: -2px 0 5px rgba(0,0,0,0.1); overflow-y: auto; }
        #sidebar h3 { margin-top: 0; color: #333; }
        .point-item { padding: 10px; margin-bottom: 8px; background-color: #fff; border: 1px solid #ddd; border-radius: 6px; display: flex; justify-content: space-between; align-items: center; font-size: 14px; }
        .point-coords { flex: 1; }
        .delete-btn { background-color: #e74c3c; color: white; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer; font-size: 12px; }
        .delete-btn:hover { background-color: #c0392b; }
        #messages { margin-top: 20px; padding: 10px; background-color: #e8f4f8; border-radius: 5px; }
    </style>
</head>
<body>
<div class="container">
    <div id="map"></div>
    <div id="sidebar">
        <h3>标记点列表</h3>
        <div id="points-list"></div>
        <div id="messages">
            <h4>消息:</h4>
            <div id="message-content"></div>
        </div>
    </div>
</div>

<script>
  var pybridge;
  new QWebChannel(qt.webChannelTransport, function(channel) {
    pybridge = channel.objects.pybridge;
     
    // 连接来自Python的信号
    pybridge.sendMessage.connect(function(message) {
        document.getElementById("message-content").innerHTML += "<p style='color: green;'>Python: " + message + "</p>";
        console.log("Received from Python:", message);
    });
  });

  var map = L.map('map').setView([39.9042, 116.4074], 10);
  const tiles = L.tileLayer('https://webrd02.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}', {
    attribution: '高德地图',
    tileSize: 256,
    detectRetina: true
  }).addTo(map);

  setTimeout(() => map.invalidateSize(), 100);

  var markers = [];
  var polyline = null;

  var customIcon = L.icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/9131/9131546.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  });

  map.on('click', function (e) { addMarker(e.latlng.lat, e.latlng.lng); });

  function addMarker(lat, lng) {
    var marker = L.marker([lat, lng], {icon: customIcon}).addTo(map);
    var markerId = Date.now() + Math.random();
    markers.push({ marker: marker, lat: lat, lng: lng, id: markerId });
    marker.bindPopup(createPopupContent(markerId));
    marker.openPopup();
    updatePointsList();
    updateRoute();
  }

  function createPopupContent(markerId) {
    const index = markers.findIndex(m => m.id === markerId) + 1;
    return `
      <div class="marker-popup">
        <b>标记点 #${index}</b><br/>
        纬度: ${markers.find(m => m.id === markerId).lat.toFixed(6)}<br/>
        经度: ${markers.find(m => m.id === markerId).lng.toFixed(6)}<br/>
        <button onclick="removeThisMarker(${markerId})" style="margin-top: 5px;">删除此标记</button>
      </div>
    `;
  }

  window.removeThisMarker = function (markerId) {
    const markerObj = markers.find(m => m.id === markerId);
    if (markerObj) map.removeLayer(markerObj.marker);
    markers = markers.filter(m => m.id !== markerId);
    updatePointsList();
    updateRoute();
  };

  function updatePointsList() {
    const listContainer = document.getElementById('points-list');
    listContainer.innerHTML = '';
    if (markers.length === 0) {
      listContainer.innerHTML = '<p style="color: #999;">暂无标记点</p>';
      return;
    }
    markers.forEach((markerObj, index) => {
      const item = document.createElement('div');
      item.className = 'point-item';
      item.innerHTML = `
        <div class="point-coords">
          <strong>点 #${index + 1}</strong><br/>
          纬度: ${markerObj.lat.toFixed(6)}<br/>
          经度: ${markerObj.lng.toFixed(6)}
        </div>
        <button class="delete-btn" onclick="removeThisMarker(${markerObj.id})">删除</button>
      `;
      listContainer.appendChild(item);
    });
  }

  function updateRoute() {
    if (polyline) { map.removeLayer(polyline); polyline = null; }
    if (markers.length < 2) return;
    var latlngs = markers.map(m => [m.lat, m.lng]);
    polyline = L.polyline(latlngs, { color: '#FF0000', weight: 4, opacity: 0.8 }).addTo(map);
    map.fitBounds(polyline.getBounds(), { padding: [50, 50] });
  }

  function clearAll() {
    markers.forEach(m => map.removeLayer(m.marker));
    markers = [];
    updatePointsList();
    updateRoute();
  }

  function addSampleMarkers() {
    const samplePoints = [
      [39.9042, 116.4074],
      [39.9163, 116.3972],
      [39.8971, 116.4039],
      [39.9300, 116.3900]
    ];
    samplePoints.forEach(point => addMarker(point[0], point[1]));
  }

  // 新增：获取所有坐标并发送给 Python
  function getCoordinatesFromJS() {
    const data = markers.map(m => ({ lat: m.lat, lng: m.lng }));
    // 通过 WebChannel 发送给 Python
    pybridge.receiveCoordinates(JSON.stringify(data));
  }

  // 暴露函数给 Python 调用
  window.addMarker = addMarker;
  window.removeThisMarker = removeThisMarker;
  window.updateRoute = updateRoute;
  window.clearAll = clearAll;
  window.addSampleMarkers = addSampleMarkers;
  window.getCoordinatesFromJS = getCoordinatesFromJS; // 暴露获取坐标的函数

  updatePointsList();
</script>
</body>
</html>
        """
        self.web_view.setHtml(html_content)

    def upload_coordinates(self):
        """点击上传按钮，调用网页中的 JS 函数获取坐标"""
        self.web_view.page().runJavaScript("getCoordinatesFromJS();")

    def add_sample_points(self):
        """添加示例点"""
        self.web_view.page().runJavaScript("addSampleMarkers();")

    def clear_all(self):
        """清除所有标记"""
        self.web_view.page().runJavaScript("clearAll();")

    def on_coordinates_received(self, data):
        """接收到坐标时的处理（可扩展为保存文件等）"""
        print("📌 坐标已上传到 Python 端：", data)

    def send_message_to_js(self, message):
        """发送消息到JavaScript（这个方法会被信号自动调用）"""
        # 消息通过信号发送，在JavaScript中处理
        pass


# 启动应用
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
```

### 参考资料

[官方文档](https://wiki.qt.io/Qt_for_Python)

[qfluentwidgets 官方网站](https://qfluentwidgets.com/)
