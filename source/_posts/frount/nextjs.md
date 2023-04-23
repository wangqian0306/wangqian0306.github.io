---
title: ncu
date: 2023-03-17 21:41:32
tags:
- "Node.js"
- "Next.js"
- "React"
- "Redux"
id: nextjs
no_word_count: true
no_toc: false
categories: 前端
---

## Next.js

### 简介

Next.js 是一个用于生产环境的 React 应用框架。Redux 则是一种模式和库，用于管理和更新应用程序状态，使用称为“操作”的事件。它是需要在整个应用程序中使用的状态的集中存储，规则确保状态只能以可预测的方式更新。

### 创建项目

在安装完 Node 之后就可以使用如下命令快速生成项目

```bash
npx create-next-app@latest --typescript
```

### chakra-ui 插件

使用如下命令安装即可：

```bash
npm i @chakra-ui/react @emotion/react @emotion/styled framer-motion
```

在安装完成后需要修改 `src/pages/_app.tsx` 文件，引入 ui 插件：

```typescript
import '@/styles/globals.css'
import type { AppProps } from 'next/app'
import { ChakraProvider } from "@chakra-ui/react";

export default function App({ Component, pageProps }: AppProps) {
  return (
    <ChakraProvider>
      <Component {...pageProps} />
    </ChakraProvider>
  )
}
```

### 配置 Redux

首先需要安装依赖包：

```bash
npm install @reduxjs/toolkit react-redux redux-persist
```

然后需要创建 `src/store/reducer.ts`，并填入如下样例内容：

```typescript
import { combineReducers } from 'redux';

const rootReducer = combineReducers({
});

export default rootReducer;
```

创建 `src/store/store.ts`，并填入如下样例内容：

```typescript
import {configureStore} from '@reduxjs/toolkit';
import rootReducer from "@/store/reducer";
import {FLUSH, PAUSE, PERSIST, persistReducer, persistStore, PURGE, REGISTER, REHYDRATE} from "redux-persist";
import storage from "redux-persist/lib/storage";

const persistConfig = {
  key: 'root',
  storage
}

const persistedReducer = persistReducer(persistConfig, rootReducer)

export const store = configureStore({
  reducer: persistedReducer,
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
      },
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export const persist = persistStore(store);
export type AppDispatch = typeof store.dispatch
```

创建 `src/store/hook.ts`，并填入如下样例内容：

```typescript
import { useDispatch, useSelector } from 'react-redux'
import type { TypedUseSelectorHook } from 'react-redux'
import type { RootState, AppDispatch } from './store'

export const useAppDispatch: () => AppDispatch = useDispatch
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector
```

之后需要编辑 `src/pages/_app.tsx` 文件，引入相关配置：

```typescript
import '@/styles/globals.css'
import type { AppProps } from 'next/app'
import { Provider } from 'react-redux';
import { store } from '@/store/store';
import { persist} from "@/store/store";
import { PersistGate } from 'redux-persist/integration/react'
import { ChakraProvider } from "@chakra-ui/react";

export default function App({ Component, pageProps }: AppProps) {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persist}>
        <ChakraProvider>
          <Component {...pageProps} />
        </ChakraProvider>
      </PersistGate>
    </Provider>
  )
}
```

如果还需要样例可以使用下面的代码：

创建 `features/counter/counterSlice.ts` 文件:

```typescript
import {createSlice} from '@reduxjs/toolkit'

interface CounterState {
  value: number
}

// Define the initial state using that type
const initialState: CounterState = {
  value: 0,
}

export const counterSlice = createSlice({
  name: 'counter',
  // `createSlice` will infer the state type from the `initialState` argument
  initialState,
  reducers: {
    increment: (state: CounterState) => {
      state.value += 1
    },
    decrement: (state: CounterState) => {
      state.value -= 1
    },
    // Use the PayloadAction type to declare the contents of `action.payload`
  },
})

export const {increment, decrement} = counterSlice.actions

export default counterSlice.reducer
```

创建 `test.tsx` 页面：

```typescript
import {Box, Button, Flex, Text} from "@chakra-ui/react";
import {decrement, increment} from "@/features/counter/counterSlice";
import Head from "next/head";
import {useAppDispatch, useAppSelector} from "@/store/hooks";

export default function Test() {
  const dispatch = useAppDispatch();
  const counterState = useAppSelector((state) => state["counter"]);

  return (
    <>
      <Head>
        <title>Test</title>
        <link rel="icon" href="/favicon.ico"/>
      </Head>
      <Flex>
        <Box>
          <Text>Counter: {counterState.value}</Text>
          <Button onClick={() => dispatch(increment(counterState))}>
            Increment
          </Button>
          <Button onClick={() => dispatch(decrement(counterState))}>
            Decrement
          </Button>
        </Box>
      </Flex>
    </>
  )
}
```

在 `store/reducer.ts` 中引入 `counterReducer`:

```typescript
import { combineReducers } from 'redux';
import counterReducer from '@/features/counter/counterSlice'

const rootReducer = combineReducers({
  counter: counterReducer,
});

export default rootReducer;
```

### 根据 OpenAPI 生成代码

然后需要初始化 `src/store/emptyApi.ts` 文件，填入如下内容：

```typescript
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'

export const emptySplitApi = createApi({
  baseQuery: fetchBaseQuery({ baseUrl: '/' }),
  endpoints: () => ({}),
})
```

然后需要初始化如下配置 `openapi-config.json` 文件，填入如下内容:

```json
{
  "schemaFile": "https://petstore3.swagger.io/api/v3/openapi.json",
  "apiFile": "./src/store/emptyApi.ts",
  "apiImport": "emptySplitApi",
  "outputFile": "./src/store/petApi.ts",
  "exportName": "petApi",
  "hooks": true
}
```

之后可以使用如下命令生成代码了：

```bash
npx @rtk-query/codegen-openapi openapi-config.ts
```

### 修改内容后自动刷新页面

在 `api.ts` 中可以定义 `tagTypes` 属性，标识缓存内容的类型。此外还可以在获取数据的 API 上标识请求返回的数据为 `providesTags: ['xxx'],`，在更新数据的 API 上标识 `invalidatesTags: ['Post'],` 即可完成自动更新逻辑。

```typescript
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query'
import type { Post, User } from './types'

const api = createApi({
  baseQuery: fetchBaseQuery({
    baseUrl: '/',
  }),
  tagTypes: ['Post', 'User'],
  endpoints: (build) => ({
    getPosts: build.query<Post[], void>({
      query: () => '/posts',
      providesTags: ['Post'],
    }),
    getUsers: build.query<User[], void>({
      query: () => '/users',
      providesTags: ['User'],
    }),
    addPost: build.mutation<Post, Omit<Post, 'id'>>({
      query: (body) => ({
        url: 'post',
        method: 'POST',
        body,
      }),
      invalidatesTags: ['Post'],
    }),
    editPost: build.mutation<Post, Partial<Post> & Pick<Post, 'id'>>({
      query: (body) => ({
        url: `post/${body.id}`,
        method: 'POST',
        body,
      }),
      invalidatesTags: ['Post'],
    }),
  }),
})
```

### 参考资料

[Next.js 官方文档](https://nextjs.org/docs/getting-started)

[Redux 官方文档](https://redux.js.org/tutorials/fundamentals/part-1-overview)

[使用 OpenAPI 接口生成代码](https://redux-toolkit.js.org/rtk-query/usage/code-generation#openapi)