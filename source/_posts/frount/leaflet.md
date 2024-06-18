---
title: Leaflet
date: 2024-06-14 21:41:32
tags:
- "Next.js"
- "Leaflet"
- "React Leaflet"
id: leaflet
no_word_count: true
no_toc: false
categories: 
- "前端"
---

## Leaflet

### 简介

Leaflet 是一个交互式的地图库。为了将其对接进入 Next.js 还需要额外安装 React Leaflet 库。

### 安装和使用

安装依赖库：

```bash
npm install leaflet react-leaflet leaflet-defaulticon-compatibility
npm install -D @types/leaflet
```

编写 `components/Map.tsx` ：

```typescript tsx
"use client";

// IMPORTANT: the order matters!
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css";
import "leaflet-defaulticon-compatibility";

import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import {LatLngExpression} from "leaflet";

export default function Map() {
  const position:LatLngExpression = [51.505, -0.09]

  return (
    <MapContainer
      center={position}
      zoom={11}
      scrollWheelZoom={true}
      style={{ height: "400px", width: "600px" }}
      attributionControl={false}
    >
      <TileLayer
        attribution=' '
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Marker position={position}>
        <Popup>
          This Marker icon is displayed correctly with <i>leaflet-defaulticon-compatibility</i>.
        </Popup>
      </Marker>
    </MapContainer>
  );
}
```

编写 `test/page.tsx` ：

```typescript tsx
"use client";

import dynamic from "next/dynamic";

const LazyMap = dynamic(() => import("@/components/Map"), {
  ssr: false,
  loading: () => <p>Loading...</p>,
});

export default function Home() {
  return (
    <main>
      <LazyMap />
    </main>
  );
}
```

### 自定义插件

```typescript tsx
import L from "leaflet";
import {createLayerComponent, LayerProps } from "@react-leaflet/core";
import { ReactNode } from "react";

interface KittenProps extends LayerProps {
  userId: string,
  children?: ReactNode // PropsWithChildren is not exported by @react-leaflet/core
}

class Kitten extends L.TileLayer {
  // 
  getTileUrl(coords: L.Coords) {
    var i = Math.ceil( Math.random() * 4 );
    return "https://placekitten.com/256/256?image=" + i;
  }

  getAttribution() {
    return "<a href='https://placekitten.com/attribution.html'>PlaceKitten</a>"
  }

}

const createKittenLayer = (props: KittenProps, context:any) => {
  const instance = new Kitten("placeholder", {...props});
  return {instance, context};
}

const updateKittenLayer = (instance: any, props: KittenProps, prevProps: KittenProps) => {
  if (prevProps.userId !== props.userId) {
    if (instance.setUserId) instance.setUserId(props.userId)
  }

}

const KittenLayer = createLayerComponent(createKittenLayer, updateKittenLayer);
export default KittenLayer;
```

> 注：在使用这种方式之后 IDEA 会报错，但是程序是可以正常运行的，是 leaflet 源码的问题。

[参考文件](https://github.com/sakitam-fdd/wind-layer/blob/master/packages/leaflet/src/layer/Base.ts)

### 参考资料

[Leaflet](https://leafletjs.com/)

[React Leaflet](https://react-leaflet.js.org/)

[Nextjs with react-leaflet](https://stackoverflow.com/questions/77978480/nextjs-with-react-leaflet-ssr-webpack-window-not-defined-icon-not-found)

[How to extend TileLayer component in react-leaflet v3?](https://stackoverflow.com/questions/65663826/how-to-extend-tilelayer-component-in-react-leaflet-v3/65713838#65713838)
