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

对于 React 项目来说使用 react-three-fiber 作为渲染器可以更方便的集成 three.js 具体操作逻辑如下：

安装依赖：

```bash
npm install three @types/three @react-three/fiber
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

### 参考资料

[官方网站](https://threejs.org/)

[官方项目](https://github.com/mrdoob/three.js)

[react-three-fiber 文档](https://docs.pmnd.rs/react-three-fiber)

[react-three-fiber 项目](https://github.com/pmndrs/react-three-fiber)
