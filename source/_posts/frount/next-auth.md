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
categories: 前端
---

## NextAuth.js

### 简介

NextAuth.js 是 Next.js 应用程序的完整开源身份验证解决方案。

### 使用方式

首先需要安装依赖包：

```bash
npm install next-auth
```

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

> 注：测试服务使用 GitHub 作为服务提供端，服务创建请访问 [示例文档](https://next-auth.js.org/providers/github)。

编写 `auth.ts` 文件：

```typescript
import NextAuth from "next-auth"
import "next-auth/jwt"

import GitHub from "next-auth/providers/github"
import { createStorage } from "unstorage"
import memoryDriver from "unstorage/drivers/memory"
import vercelKVDriver from "unstorage/drivers/vercel-kv"
import { UnstorageAdapter } from "@auth/unstorage-adapter"
import type { NextAuthConfig } from "next-auth"

const storage = createStorage({
  driver: process.env.VERCEL
    ? vercelKVDriver({
        url: process.env.AUTH_KV_REST_API_URL,
        token: process.env.AUTH_KV_REST_API_TOKEN,
        env: false,
      })
    : memoryDriver(),
})

const config = {
  theme: { logo: "https://authjs.dev/img/logo-sm.png" },
  adapter: UnstorageAdapter(storage),
  providers: [
    GitHub,
  ],
  basePath: "/auth",
  callbacks: {
    authorized({ request, auth }) {
      const { pathname } = request.nextUrl
      if (pathname === "/middleware-example") return !!auth
      return true
    },
    jwt({ token, trigger, session, account }) {
      if (trigger === "update") token.name = session.user.name
      if (account?.provider === "keycloak") {
        return { ...token, accessToken: account.access_token }
      }
      return token
    },
    async session({ session, token }) {
      if (token?.accessToken) {
        session.accessToken = token.accessToken
      }
      return session
    },
  },
  experimental: {
    enableWebAuthn: true,
  },
  debug: process.env.NODE_ENV !== "production" ? true : false,
} satisfies NextAuthConfig

export const { handlers, auth, signIn, signOut } = NextAuth(config)

declare module "next-auth" {
  interface Session {
    accessToken?: string
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    accessToken?: string
  }
}
```

编写 `middleware.ts` :

```typescript
export { auth as middleware } from "auth"

// Or like this if you need to do something here.
// export default auth((req) => {
//   console.log(req.auth) //  { session: { user: { ... } } }
// })

// Read more: https://nextjs.org/docs/app/building-your-application/routing/middleware#matcher
export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
}
```

编写 `api/auth/[...nextauth]/route.ts` ：

```typescript
import { handlers } from "auth"
export const { GET, POST } = handlers
```

### 常用方式

在 `auth.ts` 中修改  

#### 自定义 OAuth 服务器

> 注：此处可以使用

```typescript
import type {NextAuthConfig} from "next-auth";
import {OAuthConfig} from "@auth/core/providers";

const customProvider: OAuthConfig<any> = {
  id: 'demo',
  name: 'demo',
  type: 'oauth',
  authorization: {
    url: "http://<host>/oauth2/authorize",
    params: { scope: "profile" },
  },
  issuer: "http://<host><host>",
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

const config = {
  providers: [
    customProvider,
  ],
  basePath: "/auth",
  callbacks: {
    authorized({request, auth}) {
      const {pathname} = request.nextUrl
      if (pathname === "/middleware-example") return !!auth
      return true
    },
    jwt({token, trigger, session, account}) {
      if (trigger === "update") token.name = session.user.name
      if (account?.provider === "keycloak") {
        return {...token, accessToken: account.access_token}
      }
      return token
    },
    async session({session, token}) {
      if (token?.accessToken) {
        session.accessToken = token.accessToken
      }
      return session
    },
  },
  experimental: {
    enableWebAuthn: true,
  },
  debug: process.env.NODE_ENV !== "production",
} satisfies NextAuthConfig
```

#### 自定义 OIDC 服务器

```typescript
import type {NextAuthConfig} from "next-auth";
import {OIDCConfig} from "@auth/core/providers";

const customProvider: OIDCConfig<any> = {
  id: 'oidc-client',
  name: 'oidc-client',
  type: 'oidc',
  wellKnown: "http://<host>/.well-known/openid-configuration",
  authorization: {
    url: "http://<host>/oauth2/authorize",
    params: {scope: "openid"}
  },
  issuer: "http://<host>",
  userinfo: "http://<host>/userinfo",
  token: 'http://<host>/oauth2/token',
  clientId: "oidc-client",
  clientSecret: "secret",
  profile(profile) {
    return {
      id: profile.sub,
      name: profile.name
    }
  }
}

const config = {
  providers: [
    customProvider,
  ],
  basePath: "/auth",
  callbacks: {
    authorized({request, auth}) {
      const {pathname} = request.nextUrl
      if (pathname === "/middleware-example") return !!auth
      return true
    },
    jwt({token, trigger, session, account}) {
      if (trigger === "update") token.name = session.user.name
      if (account?.provider === "keycloak") {
        return {...token, accessToken: account.access_token}
      }
      return token
    },
    async session({session, token}) {
      if (token?.accessToken) {
        session.accessToken = token.accessToken
      }
      return session
    },
  },
  experimental: {
    enableWebAuthn: true,
  },
  debug: process.env.NODE_ENV !== "production",
} satisfies NextAuthConfig
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

### 参考资料

[官方文档](https://next-auth.js.org/getting-started/typescript)

[示例项目](https://github.com/nextauthjs/next-auth-example)
