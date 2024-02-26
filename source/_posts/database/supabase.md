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

```typescirpt
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

```typescirpt
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
