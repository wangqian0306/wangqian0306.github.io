---
title: three.js
date: 2023-10-26 21:41:32
tags:
- "nodejs"
id: three-js
no_word_count: true
no_toc: false
categories:
- "前端"
---

## three.js

### 简介

three.js 是一款 JavaScript 的 3D 库，目的在于可以便捷、轻量化、跨浏览器的展示 3D 内容。

### 安装和使用

#### 基本使用

对于 React 项目来说使用 react-three-fiber 作为渲染器可以更方便的集成 three.js 具体操作逻辑如下：

安装依赖：

```bash
npm install three @types/three @react-three/fiber @react-three/drei
```

根据如下样例编写页面即可：

```typescript
import * as THREE from 'three'
import React, { useRef, useState } from 'react'
import { Canvas, useFrame, ThreeElements } from '@react-three/fiber'
import {Inter} from 'next/font/google'

const inter = Inter({subsets: ['latin']})

function Box(props: ThreeElements['mesh']) {
  const meshRef = useRef<THREE.Mesh>(null!)
  const [hovered, setHover] = useState(false)
  const [active, setActive] = useState(false)
  useFrame((state, delta) => (meshRef.current.rotation.x += delta))
  return (
      <mesh
          {...props}
          ref={meshRef}
          scale={active ? 1.5 : 1}
          onClick={(event) => setActive(!active)}
          onPointerOver={(event) => setHover(true)}
          onPointerOut={(event) => setHover(false)}>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color={hovered ? 'hotpink' : 'orange'} />
      </mesh>
  )
}

export default function Home() {
    return (
        <main
            className={`flex min-h-screen flex-col items-center justify-between p-24 ${inter.className}`}
        >
            <Canvas>
                <ambientLight/>
                <pointLight position={[10, 10, 10]}/>
                <Box position={[-1.2, 0, 0]}/>
                <Box position={[1.2, 0, 0]}/>
            </Canvas>
        </main>
    )
}
```

#### 载入模型

可以从互联网上下载 `glb` 格式的模型，然后将其放置在项目 `public` 文件夹内。

> 注：如果是 Windows 电脑则可以使用自带的 3D Builder 快速建模。

通过将模型上传至 [https://gltf.pmnd.rs/](https://gltf.pmnd.rs/) 工具页即可获得模型的展示效果与文档。


代码样例如下：

`/src/compoment/demo.tsx`

```typescript
import * as THREE from "three";
import React, { useRef } from "react";
import { useGLTF } from "@react-three/drei";
import { GLTF } from "three-stdlib";

type GLTFResult = GLTF & {
    nodes: {
        mesh_0: THREE.Mesh;
    };
    materials: {
        Turquoise: THREE.MeshStandardMaterial;
    };
};

export function Model(props: JSX.IntrinsicElements["group"]) {
    const { nodes, materials } = useGLTF("/demo.glb") as GLTFResult;
    return (
        <group {...props} dispose={null}>
            <mesh
                castShadow
                receiveShadow
                geometry={nodes.mesh_0.geometry}
                material={materials.Turquoise}
                position={[-0.007, 0, 0]}
                rotation={[-1.571, 0, 0]}
                scale={1.429}
            />
        </group>
    );
}

useGLTF.preload("/demo.glb");
```

`/src/pages/index.tsx`

```typescript
import React, {Suspense} from 'react'
import {Canvas} from '@react-three/fiber'
import {Inter} from 'next/font/google'
import {OrbitControls, Stage} from "@react-three/drei";
import {Model} from "@/compoment/demo";

const inter = Inter({subsets: ['latin']})

export default function Home() {
    return (
        <main
            className={`flex min-h-screen flex-col items-center justify-between p-24 ${inter.className}`}
        >
            <Canvas shadows dpr={[1, 2]} camera={{fov: 50}}>
                <Suspense fallback={null}>
                    <Stage preset="rembrandt" intensity={1} environment="city">
                        false
                        <Model/>
                        false
                    </Stage>
                </Suspense>
                <OrbitControls autoRotate/>
            </Canvas>
        </main>
    )
}
```

之后正常运行项目即可。

> 注：在载入 Canvas 时需要访问 ` https://raw.githubusercontent.com` 中读取 `potsdamer_platz_1k.hdr` 文件，如果网络链接不通则会报错。

### 参考资料

[官方网站](https://threejs.org/)

[官方项目](https://github.com/mrdoob/three.js)

[react-three-fiber 文档](https://docs.pmnd.rs/react-three-fiber)

[react-three-fiber 项目](https://github.com/pmndrs/react-three-fiber)

[drei 项目](https://github.com/pmndrs/drei)
