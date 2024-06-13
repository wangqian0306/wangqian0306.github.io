---
title: NextAuth.js
date: 2024-05-24 21:41:32
tags:
- "Next.js"
- "OAuth"
- "OIDC"
id: next-auth
no_word_count: true
no_toc: false
categories: 
- "前端"
---

## NextAuth.js

### 简介

NextAuth.js 是 Next.js 应用程序的完整开源身份验证解决方案。

### 使用方式

首先需要安装依赖包：

```bash
npm install next-auth@beta
```

> 注：此处由于 5.0 还没发布所以采用 beta 版本。在部署的时候有一些缓存 bug 可以降级 next.js 版本至 14.1.4 。

然后使用如下命令生成 `AUTH_SECRET`

```bash
npx auth secret
```

编写 `.env.local` 文件：

```text
AUTH_SECRET=<auth_secret>
AUTH_<OAuth_Provider>_ID=<oauth_client_id>
AUTH_<OAuth_Provider>_SECRET=<oauth_secret>
```

> 注：测试服务使用 GitHub 作为服务提供端，服务创建请访问 [示例文档](https://next-auth.js.org/providers/github) 并填写好 .env.local 文件。

编写 `auth/index.ts` 文件：

```typescript
import NextAuth, {NextAuthConfig} from "next-auth"

import GitHub from "@auth/core/providers/github";

export const BASE_PATH = "/api/auth"

const authOptions:NextAuthConfig = {
  providers: [
    GitHub,
  ],
  basePath: BASE_PATH,
  secret: process.env.AUTH_SECRET,
  debug: process.env.NODE_ENV !== "production"}

export const {handlers, auth, signIn, signOut} = NextAuth(authOptions);
```

编写 `middleware.ts` :

```typescript
import { NextResponse } from "next/server";
import { auth, BASE_PATH } from "@/auth";

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};

export default auth((req) => {
  const reqUrl = new URL(req.url);
  if (!req.auth && reqUrl?.pathname !== "/") {
    return NextResponse.redirect(
      new URL(
        `${BASE_PATH}/signin?callbackUrl=${encodeURIComponent(
          reqUrl?.pathname
        )}`,
        req.url
      )
    );
  }
});
```

> 注：此处可以编写若未登录之后的重定向和路由保存逻辑。

编写 `api/auth/[...nextauth]/route.ts` ：

```typescript
import { handlers } from "@/auth";

export const { GET, POST } = handlers;
```

### 常用方式

#### 自定义 OAuth 服务器

在 `auth.ts` 中修改

```typescript
import {OAuthConfig} from "@auth/core/providers";

const customProvider: OAuthConfig<any> = {
  id: 'demo',
  name: 'demo',
  type: 'oauth',
  authorization: {
    url: "http://<host>/oauth2/authorize",
    params: { scope: "profile" },
  },
  issuer: "http://<host>",
  token: 'http://<host>/oauth2/token',
  userinfo: 'http://<host>/oauth2/userinfo',
  clientId: process.env.CUSTOM_CLIENT_ID,
  clientSecret: process.env.CUSTOM_SECRET,
  profile(profile) {
    return {
      id: profile.sub,
      name: profile.name
    };
  },
}
```

#### 自定义 OIDC 服务器

```typescript
import {OIDCConfig} from "@auth/core/providers";

const customProvider: OIDCConfig<any> = {
  id: 'oidc-client',
  name: 'oidc-client',
  type: 'oidc',
  authorization: {
    url: "http://<host>/oauth2/authorize",
    params: { scope: "openid" },
  },
  issuer: "http://<host>",
  token: 'http://<host>/oauth2/token',
  userinfo: 'http://<host>/oauth2/userinfo',
  clientId: process.env.CUSTOM_CLIENT_ID,
  clientSecret: process.env.CUSTOM_SECRET,
}
```

#### 独立服务简单实现

```typescript
const config = {
  providers: [
    Credentials({
      name: "Credentials",
      credentials: {
        username: {
          label: "Username:",
          type: "text",
          placeholder: "your-cool-username"
        },
        password: {
          label: "Password:",
          type: "password",
          placeholder: "your-awesome-password"
        }
      },
      async authorize(credentials) {
        // This is where you need to retrieve user data 
        // to verify with credentials
        // Docs: https://next-auth.js.org/configuration/providers/credentials
        const user = { id: "42", name: "Dave", password: "nextauth" }
        if (credentials?.username === user.name && credentials?.password === user.password) {
          return user
        } else {
          return null
        }
      }
    })
  ],
} satisfies NextAuthConfig
```

#### 无页面跳转登录

编写 `auth/helpers.ts` 文件

```typescript
"use server";
import {signIn as naSignIn, signOut as naSignOut} from ".";

export async function signIn(prop:any) {
  await naSignIn(prop);
}

export async function signOut() {
  await naSignOut();
}
```

> 注：此处可以传入提供方ID，实现快速登录，跳过登录页。之后如果是 oauth2 登录还需要在 oauth2 处登出。

编写 `app/AuthButton.client.tsx` 文件：

```typescript jsx
"use client"

import {useSession} from "next-auth/react";

import {Button} from "@mui/material"

import {signIn, signOut} from "@/auth/helpers";

export default function AuthButton() {
  const session = useSession();
  return session?.data?.user? (
    <Button onClick={async ()=> await signOut()}>
      {session.data?.user?.name}: Sign Out
    </Button>
  ) : (
    <Button onClick={async ()=> await signIn('oidc-client')}>
      Sign In
    </Button>
  );
}
```

编写 `app/AuthButton.server.tsx` 文件

```typescript jsx
import {SessionProvider} from "next-auth/react";
import {BASE_PATH, auth} from "@/auth";

import AuthButtonClient from "@/app/AuthButton.client";

export default async function AuthButton() {
  const session = await auth();
  if (session && session.user) {
    session.user = {
      name: session.user.name,
      email: session.user.email
    };
  }

  return (
    <SessionProvider basePath={BASE_PATH} session={session}>
      <AuthButtonClient/>
    </SessionProvider>
  )
}
```

修改 `app/page.tsx` 文件

```typescript jsx
import {auth} from "@/auth";
import AuthButton from "@/app/AuthButton.server";

export default async function Home() {
  const session = await auth();
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <h1 className="text-3xl font-bold underline">
        Hello world!
      </h1>
      <pre>{JSON.stringify(session, null, 2)}</pre>
      <AuthButton/>
    </main>
  );
}
```

#### 服务端和客户端获取用户信息

编写 `WhoAmIServerAction.tsx` ：

```typescript jsx
"use client";

import {useEffect, useState} from "react";

export default function WhoAmIServerAction({
                                             onGetUserAction,
                                           }: {
  onGetUserAction: () => Promise<string | null>;
}) {
  const [user, setUser] = useState<string | null>();

  useEffect(() => {
    onGetUserAction().then((user) => setUser(user));
  }, []);
  return <div>Who Am I (server action): {user}</div>;
}
```

编写 `page.tsx` ：

```typescript jsx
import {auth} from "@/auth";

import WhoAmIServerAction from "./WhoAmIServerAction";

export default async function TestRoute() {
  const session = await auth();

  async function onGetUserAction() {
    "use server";
    const session = await auth();
    return session?.user?.name ?? null;
  }

  return (
    <main>
      <h1>Test Route</h1>
      <div>User: {session?.user?.name}</div>
      <WhoAmIServerAction onGetUserAction={onGetUserAction}/>
    </main>
  )
}
```

### 参考资料

[官方文档](https://next-auth.js.org/getting-started/typescript)

[示例项目](https://github.com/nextauthjs/next-auth-example)

[视频教程](https://www.youtube.com/watch?v=z2A9P1Zg1WM)