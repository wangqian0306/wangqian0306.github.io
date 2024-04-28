---
title: Supabase
date: 2021-08-04 22:12:59
tags: 
- "Supabase"
- "Next.js"
id: supabase
no_word_count: true
no_toc: false
categories: "前端"
---

## Supabase

### 简介

Supabase 是一个应用开发平台，可以实现如下功能：

- Postgres 数据库托管
- 身份验证和授权
- 自动生成的 API
  - REST
  - 实时订阅
  - GraphQL（测试版）
-  函数
  - 数据库函数
  - 边缘函数
- 文件存储
- 仪表盘

> 注：此项目当前还处于 Public Beta 测试阶段，适合于大多数非企业使用场景。

### 使用

#### 创建数据库

登录 [https://supabase.com/](https://supabase.com/) 官方网站，然后注册登录，并按照如下流程进行初始化：

- 创建组织
- 创建项目
- 选择 `SQL editor` 然后输入如下 SQL

```sql
 -- Create the table
 create table notes (
   id serial primary key,
   title text
 );

 -- Insert some sample data
 insert into notes (title)
 values
   ('Today I created a Supabase project.'),
   ('I added some data and queried it from Next.js.'),
   ('It was awesome!');
```

#### 使用模板(Next.js + Supabase)

使用如下命令即可初始化一个样例项目，访问项目即可看到配置方式：

```bash
npx create-next-app -e with-supabase
```

然后需要编辑 `.env.example` 文件，并将其重命名为 `.env.local`:

```text
NEXT_PUBLIC_SUPABASE_URL=<SUBSTITUTE_SUPABASE_URL>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<SUBSTITUTE_SUPABASE_ANON_KEY>
```

> 注: 此处的地址需要访问创建的 Supabase 仪表板中的项目详情中查看。

最后可以编写如下页面进行测试：

```typescript
'use client'

import { createClient } from '@/utils/supabase/client'
import { useEffect, useState } from 'react'

export default function Page() {
    const [notes, setNotes] = useState<any[] | null>(null)
    const supabase = createClient()

    useEffect(() => {
        const getData = async () => {
            const { data } = await supabase.from('notes').select()
            setNotes(data)
        }
        getData()
    }, [])

    return <pre>{JSON.stringify(notes, null, 2)}</pre>
}
```

#### 修改现有项目

可以使用如下命令安装依赖：

```bash
npm install @supabase/ssr @supabase/supabase-js
```

编写 `lib/supabase/client.ts` :

```typescript
import { createBrowserClient } from "@supabase/ssr";

export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
```

编写 `lib/supabase/middleware.ts` :

```typescript
import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";

export const updateSession = async (request: NextRequest) => {
  // This `try/catch` block is only here for the interactive tutorial.
  // Feel free to remove once you have Supabase connected.
  try {
    // Create an unmodified response
    let response = NextResponse.next({
      request: {
        headers: request.headers,
      },
    });

    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            return request.cookies.get(name)?.value;
          },
          set(name: string, value: string, options: CookieOptions) {
            // If the cookie is updated, update the cookies for the request and response
            request.cookies.set({
              name,
              value,
              ...options,
            });
            response = NextResponse.next({
              request: {
                headers: request.headers,
              },
            });
            response.cookies.set({
              name,
              value,
              ...options,
            });
          },
          remove(name: string, options: CookieOptions) {
            // If the cookie is removed, update the cookies for the request and response
            request.cookies.set({
              name,
              value: "",
              ...options,
            });
            response = NextResponse.next({
              request: {
                headers: request.headers,
              },
            });
            response.cookies.set({
              name,
              value: "",
              ...options,
            });
          },
        },
      },
    );

    // This will refresh session if expired - required for Server Components
    // https://supabase.com/docs/guides/auth/server-side/nextjs
    await supabase.auth.getUser();

    return response;
  } catch (e) {
    // If you are here, a Supabase client could not be created!
    // This is likely because you have not set up environment variables.
    // Check out http://localhost:3000 for Next Steps.
    return NextResponse.next({
      request: {
        headers: request.headers,
      },
    });
  }
};
```

编写 `lib/supabase/server.ts` :

```typescript
import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { cookies } from "next/headers";

export const createClient = () => {
  const cookieStore = cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch (error) {
            // The `set` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: "", ...options });
          } catch (error) {
            // The `delete` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    },
  );
};
```

#### Vector 插件

运行以下 sql 可以引入 vector 插件

```sql
create extension vector
with
  schema extensions;
```

然后使用如下 sql 即可创建一个表：

```sql
create table documents (
  id serial primary key,
  content text not null,
  embedding vector(384)
);
```

使用如下 sql 建立一个语义检索函数：

```sql
create or replace function match_documents (
  query_embedding vector(384),
  match_threshold float,
  match_count int
)
returns setof documents
language sql
as $$
  select *
  from documents
  where documents.embedding <#> query_embedding < -match_threshold
  order by documents.embedding <#> query_embedding asc
  limit least(match_count, 200);
$$;
```

修改 `types.d.ts`:

```typescript
type Message = {
    content: string
}
type Embedding = {
    embedding: []
}
type SelectDocument = {
    id: number,
    content: string,
    embedding: []
}
```

安装 `transformers.js` :

```bash
npm i @xenova/transformers
```

修改 `next.config.mjs` 配置：

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

编写 `/app/api/transformers/pipeline.ts`：

```typescript
import {PipelineType} from "@xenova/transformers/types/pipelines";
import {pipeline} from "@xenova/transformers";

const P = () => class PipelineSingleton {
  static task: PipelineType = 'feature-extraction';
  static model = 'Supabase/gte-small';
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

编写 `/app/api/transformers/route.ts` ：

```typescript
import {NextResponse,NextRequest} from "next/server";
import PipelineSingleton from "@/app/api/transformers/pipeline";

export async function POST(request:NextRequest) {
  const {content}: Partial<Message> = await request.json()
  if (!content) {
    return NextResponse.json({
      error: 'Missing content',
    }, { status: 400 });
  }
  const classifier = await PipelineSingleton.getInstance();
  const result = await classifier(content, {
    pooling: 'mean',
    normalize: true,
  });
  const embedding = Array.from(result.data)
  return NextResponse.json({"embedding": embedding})
}
```

编写 `/app/api/document/route.ts`

```typescript
import {NextResponse,NextRequest} from "next/server";
import PipelineSingleton from "@/app/api/transformers/pipeline";
import { createClient } from "@/app/lib/supabase/client";

const supabase = createClient()

export async function POST(request:NextRequest) {
  const {content}: Partial<Message> = await request.json()
  if (!content) {
    return NextResponse.json({
      error: 'Missing content',
    }, { status: 400 });
  }
  const classifier = await PipelineSingleton.getInstance();
  const result = await classifier(content, {
    pooling: 'mean',
    normalize: true,
  });
  const embedding = Array.from(result.data)
  const { data, error } = await supabase.from('documents').insert({
    content,
    embedding,
  })
  if (error) {
    throw error;
  } else {
    return NextResponse.json(data);
  }
}
```

修改 `/app/page.tsx` 代码即可进行检索：

```typescript jsx
'use client';

import {createClient} from "@/app/lib/supabase/client";
import {useState} from 'react'

export default function Test() {
  const [value, setValue] = useState<string>("");
  const [documents, setDocuments] = useState<SelectDocument[]>([]);
  const [ready, setReady] = useState<boolean>();
  const supabase = createClient()

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValue(event.target.value);
  };

  const insert = async (text: string) => {
    if (!text)
      return;
    if (ready === null)
      setReady(false);
    try {
      const response = await fetch("/api/document", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: text
        })
      });
      if (!ready)
        setReady(true);
    } catch (error) {
      console.error('There was a problem with the fetch operation:', error);
    }
  };

  const search = async (text: string) => {
    if (!text)
      return;
    try {
      const response = await fetch("/api/transformers", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: text
        })
      });
      const emb:Embedding = await response.json();
      const {data} = await supabase.rpc('match_documents', {
        query_embedding: emb.embedding,
        match_threshold: 0.78,
        match_count: 10,
      })
      const documents: SelectDocument[] = data.map((item: any) => ({
        id: item.id,
        content: item.content,
        embedding: item.embedding
      }));
      setDocuments(documents)
    } catch (error) {
      console.error('There was a problem with the fetch operation:', error);
    }
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
      <button onClick={() => insert(value)}>Insert</button>
      <button onClick={() => search(value)}>Transformers</button>
      <ul>
        {documents.map(document => (
          <li key={document.id}>
            <p>{document.content}</p>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

还可使用如下 sql 进行内容检索：

```sql
select *
from match_documents(
  '[...]'::vector(384),
  0.78,
  10
);
```

#### 本地部署(Docker)

使用如下命令即可在本地部署一套 Supabase 服务：

```bash
# Get the code
git clone --depth 1 https://github.com/supabase/supabase

# Go to the docker folder
cd supabase/docker

# Copy the fake env vars
cp .env.example .env

# Pull the latest images
docker compose pull

# Start the services (in detached mode)
docker compose up -d
```

待程序启动后即可访问 [http://localhost:8000](http://localhost:8000) 进入服务

### 参考资料

[官方项目](https://github.com/supabase/supabase)

[官方网站](https://supabase.com/)

[Next.js 样例文档](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)
