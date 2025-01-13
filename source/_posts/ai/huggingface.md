---
title: Hugging Face
date: 2023-08-04 22:26:13
tags:
- "Hugging Face"
- "AI"
id: hugging-face
no_word_count: true
no_toc: false
---

## Hugging Face

### 简介

Hugging Face 是一个专注于机器学习，数据集和 AI 应用的社区。

### 外部项目

[Meta Llama 2](https://huggingface.co/meta-llama)

[Code Llama](https://huggingface.co/codellama)

### 常用内容

#### Chat

[https://huggingface.co/chat/](https://huggingface.co/chat/)

可以访问上面的网站来调用一些开源的大语言模型。

#### BigCode

BigCode 是一个专注于 编码类 LLM 的开源项目，模型清单如下：

[BigCode](https://huggingface.co/bigcode)

### Transformers.js

Hugging Face 提供的 Transformers.js 可以直接再浏览器中运行 Transformers 。

在 Next.js 中可以按照如下方式使用：

- 安装依赖

```bash
npm i @xenova/transformers
```

- 设置 `next.config.mjs` 配置

```text
/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
    experimental: {
        serverComponentsExternalPackages: ['sharp', 'onnxruntime-node'],
    },
};

export default nextConfig;
```

- 编写 `app/test/pipeline.ts` 

```typescript
import {PipelineType} from "@xenova/transformers/types/pipelines";
import {pipeline} from "@xenova/transformers";

const P = () => class PipelineSingleton {
  static task: PipelineType = 'text-classification';
  static model = 'Xenova/distilbert-base-uncased-finetuned-sst-2-english';
  static instance:any = null;

  static async getInstance(progress_callback:any = null) {
    if (this.instance === null) {
      this.instance = pipeline(this.task, this.model, { progress_callback });
    }
    return this.instance;
  }
}

declare const global: {
  PipelineSingleton?: any;
};

let PipelineSingleton:any;
if (process.env.NODE_ENV !== 'production') {
  if (!global.PipelineSingleton) {
    global.PipelineSingleton = P();
  }
  PipelineSingleton = global.PipelineSingleton;
} else {
  PipelineSingleton = P();
}
export default PipelineSingleton;
```

- 编写 `app/test/route.ts` 

```typescript
import {NextRequest, NextResponse} from 'next/server'
import PipelineSingleton from "./pipeline";

export async function GET(request:NextRequest) {
  const text = request.nextUrl.searchParams.get('text');
  if (!text) {
    return NextResponse.json({
      error: 'Missing text parameter',
    }, { status: 400 });
  }
  // Get the classification pipeline. When called for the first time,
  // this will load the pipeline and cache it for future use.
  const classifier = await PipelineSingleton.getInstance();

  // Actually perform the classification
  const result = await classifier(text);

  return NextResponse.json(result);
}
```

- 编写程序入口

```typescript jsx
'use client';

import {useState} from 'react'

export default function Home() {
  const [value,setValue] = useState<string>("");
  const [result, setResult] = useState<string>();
  const [ready, setReady] = useState<boolean>();

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    // Update the input value state whenever the input changes
    setValue(event.target.value);
  };

  const classify = async (text: string) => {
    if (!text)
      return;
    if (ready === null)
      setReady(false);
    const result = await fetch(`/test?text=${encodeURIComponent(text)}`);
    if (!ready)
      setReady(true);
    const json = await result.json();
    setResult(json);
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-12">
      <h1 className="text-5xl font-bold mb-2 text-center">Transformers.js</h1>
      <h2 className="text-2xl mb-4 text-center">Next.js template (server-side)</h2>
      <input
        type="text"
        value={value}
        className="w-full max-w-xs p-2 border border-gray-300 rounded mb-4"
        placeholder="Enter text here"
        onChange={handleInputChange}
      />
      <button onClick={() => classify(value)}> Transformers </button>
      {ready !== null && (
        <pre className="bg-gray-100 p-2 rounded">
          {(!ready || !result) ? 'Loading...' : JSON.stringify(result, null, 2)}
        </pre>
      )}
    </main>
  )
}
```

### 参考资料

[Hugging Face Hub 和开源生态介绍](https://www.bilibili.com/video/BV1mm4y1x72Q)

[Hugging Face 主页](https://huggingface.co/)

[Transformers.js](https://huggingface.co/docs/transformers.js/index)