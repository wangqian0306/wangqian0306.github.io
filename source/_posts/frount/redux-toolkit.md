---
title: Redux Toolkit
date: 2023-03-17 21:41:32
tags:
- "Node.js"
- "Next.js"
- "React"
id: redux-toolkit
no_word_count: true
no_toc: false
categories:
- "前端"
---

## Redux Toolkit

### 简介

Redux 是一款针对于 javascript 的可预测状态的容器，而 Redux Toolkit 是为了便于使用而构建的工具包。

### 使用方式

#### 样例模板

可以使用如下命令创建一个样例模板：

```bash
npx create-next-app --example with-redux my-app
```

> 注：默认采用了 Next.js 的 APP Router 但是它和 redux-persist 有兼容性上的问题，所以仅建议作为参考。

#### 手动配置

首先需要安装依赖包：

```bash
npm install @reduxjs/toolkit react-redux redux-persist
```

然后需要创建 `lib/redux/rootReducer.ts`，并填入如下样例内容：

```typescript
import { combineReducers } from 'redux';

const reducer = combineReducers({
});

export default reducer;
```

创建 `lib/redux/store.ts`，并填入如下样例内容：

```typescript
/* Core */
import { configureStore, type ThunkAction, type Action } from '@reduxjs/toolkit'
import {
    useSelector as useReduxSelector,
    useDispatch as useReduxDispatch,
    type TypedUseSelectorHook,
} from 'react-redux'

/* Instruments */
import { reducer } from './rootReducer'


import {persistStore, persistReducer, FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER} from 'redux-persist'
import createWebStorage from 'redux-persist/lib/storage/createWebStorage';
const createNoopStorage = () => {
    return {
        getItem(_key: any) {
            return Promise.resolve(null);
        },
        setItem(_key: any, value: any) {
            return Promise.resolve(value);
        },
        removeItem(_key: any) {
            return Promise.resolve();
        },
    };
};
const storage = typeof window !== 'undefined' ? createWebStorage('local') : createNoopStorage();

const persistConfig = {
    key: 'root',
    storage: storage
}

const persistedReducer = persistReducer(persistConfig, reducer)

function makeStore() {
    return configureStore({
        reducer: persistedReducer,
        devTools: process.env.NODE_ENV !== "production"
    });
}

export const reduxStore = configureStore({
    reducer: persistedReducer,
    middleware: (getDefaultMiddleware) =>
        getDefaultMiddleware({
            serializableCheck: {
                ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
            },
        }),
})

export const persist = persistStore(reduxStore);
export const useDispatch = () => useReduxDispatch<ReduxDispatch>()
export const useSelector: TypedUseSelectorHook<ReduxState> = useReduxSelector

/* Types */
export type ReduxStore = typeof reduxStore
export type ReduxState = ReturnType<typeof reduxStore.getState>
export type ReduxDispatch = typeof reduxStore.dispatch
export type ReduxThunkAction<ReturnType = void> = ThunkAction<
    ReturnType,
    ReduxState,
    unknown,
    Action
>
```

创建空白的 `lib/redux/slices/index.ts` 文件：


创建 `lib/redux/index.ts`，并填入如下样例内容：

```typescript
export * from './store'
export * from './slices'
```

之后需要编辑 `lib/providers.tsx` 文件，引入相关配置：

```typescript jsx
'use client'

/* Core */
import { Provider } from 'react-redux'

/* Instruments */
import {persist, reduxStore} from '@/lib/redux'
import {PersistGate} from "redux-persist/integration/react";

export const Providers = (props: React.PropsWithChildren) => {
  return (
      <Provider store={reduxStore}>
          <PersistGate persistor={persist} loading={null}>
              {props.children}
          </PersistGate>
      </Provider>
  );
}
```

还需要将 Provider 注入到 `_app.tsx` 文件中：

```typescript jsx
import '@/styles/globals.css'
import type { AppProps } from 'next/app'
import {Providers} from "@/lib/providers";

export default function App({ Component, pageProps }: AppProps) {
  return (
      <Providers>
          <Component {...pageProps} />
      </Providers>
  )
}
```

如果还需要样例可以使用下面的代码：

创建 `lib/redux/slices/demoSlice` 文件:

```typescript
import {createSlice} from '@reduxjs/toolkit'

/* Types */
export interface DemoSliceState {
  value: number
}

// Define the initial state using that type
const initialState: DemoSliceState = {
  value: 0,
}

export const demoSlice = createSlice({
  name: 'demo',
  // `createSlice` will infer the state type from the `initialState` argument
  initialState,
  reducers: {
    increment: (state: DemoSliceState) => {
      state.value += 1
    },
    decrement: (state: DemoSliceState) => {
      state.value -= 1
    },
  },
})
```

创建 `lib/redux/demoSlice/selector.ts` 文件：

```typescript
import type { ReduxState } from '@/lib/redux'

export const selectDemo = (state: ReduxState) => state.demo.value
```

创建 `lib/redux/demoSlice/index.ts` 文件

```typescript
export * from './demoSlice'
export * from './selectors'
```

修改 `lib/redux/slices/index.ts` 文件：

```typescript
export * from './demoSlice'
```

修改 `lib/redux/rootReducer.ts` 文件：

```typescript
import {demoSlice} from './slices'
import {combineReducers} from "redux";

export const reducer = combineReducers({
    demo: demoSlice.reducer
});
```

创建 `pages/counter/index.tsx` 页面：

```typescript jsx
'use client'

/* Mui */
import {Box, Button, Typography} from "@mui/material";

/* redux */
import {
    demoSlice,
    useSelector,
    useDispatch,
    selectDemo,
} from '@/lib/redux'

export default function Test() {
    const dispatch = useDispatch();
    const count = useSelector(selectDemo);

    return (
        <div>
            <Box>
                <Typography>Counter: {count}</Typography>
                <Button onClick={() => dispatch(demoSlice.actions.increment())}>
                    Increment
                </Button>
                <Button onClick={() => dispatch(demoSlice.actions.decrement())}>
                    Decrement
                </Button>
            </Box>
        </div>
    )
}
```

### 根据 OpenAPI 生成代码


使用如下命令安装相关依赖：

```bash
npm install -D @rtk-query/codegen-openapi esbuild-runner ts-node
```

然后需要初始化 `lib/redux/emptyApi.ts` 文件，填入如下内容：

```typescript
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'

export const emptySplitApi = createApi({
  baseQuery: fetchBaseQuery({ baseUrl: '/' }),
  endpoints: () => ({}),
})
```

在项目根目录编写 `openapi-config.ts` 文件，填入如下内容：

```typescript
import type { ConfigFile } from '@rtk-query/codegen-openapi'

const config: ConfigFile = {
    schemaFile: 'http://localhost:8080/v3/api-docs',
    apiFile: './lib/redux/emptyApi.ts',
    apiImport: 'emptySplitApi',
    outputFile: './lib/redux/api.ts',
    exportName: 'api',
    hooks: true,
}

export default config
```

之后可以使用如下命令生成代码了：

```bash
npx @rtk-query/codegen-openapi openapi-config.ts
```

#### JWT 验证

如果说项目使用了 JWT 等验证方式则需要进一步进行配置，具体样例如下：

编写 `lib/redux/slices/authSlice/authSlice.ts` 文件并填入如下内容：

```typescript
import {createSlice, PayloadAction} from '@reduxjs/toolkit';
import {User} from "@/lib/redux/api";

export interface AuthSliceState {
    token: string | null;
    user: User | null;
}

const initialState: AuthSliceState = {
    token: null,
    user: null
};

export const authSlice = createSlice({
    name: 'auth',
    initialState,
    reducers: {
        setToken: (state: AuthSliceState, action: PayloadAction<string | null>) => {
            state.token = action.payload;
            if (!action.payload) {
                state.user = null
            }
        },
        setUser: (state: AuthSliceState, action: PayloadAction<User | null>) => {
            state.user = action.payload
        }
    }
});
```

编写 `lib/redux/slices/authSlice/selector.ts` :

```typescript
/* Instruments */
import type { ReduxState } from '@/lib/redux'

export const selectAuth = (state: ReduxState) => state.auth
```

> 注：此处因为还没有引入 reducer 所以会暂时报错，无需关注

编写 `lib/redux/slices/authSlice/index.ts`

```typescript
export * from './authSlice'
export * from './selectors'
```

修改 `lib/redux/slices/index.ts` :

```typescript
export * from './authSlice'
```

在 `lib/redux/rootReducer.ts` 中引入 `authReducer`:

```typescript
/* Instruments */
import {authSlice} from './slices'
import {combineReducers} from "redux";
import {api} from '@/lib/redux/api'

export const reducer = combineReducers({
    auth: authSlice.reducer,
    [api.reducerPath]: api.reducer
});
```

在 'store' 配置中也需要引入中间件：

```typescript
export const reduxStore = configureStore({
    reducer: persistedReducer,
    middleware: (getDefaultMiddleware) =>
        getDefaultMiddleware({
            serializableCheck: {
                ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
            },
        }).contact(api.middleware),
})
```

在 `lib/redux/emptyApi.ts` 修改请求地址位置并放置 `Token`:

```typescript
import {BaseQueryFn, createApi, FetchArgs, fetchBaseQuery, FetchBaseQueryError} from '@reduxjs/toolkit/query/react'
import {ReduxState} from "@/lib/redux/store";
import {authSlice} from '@/lib/redux/slices/authSlice';

export interface MessageData {
    message: string;
}

const customBaseQuery = fetchBaseQuery({
    baseUrl: process.env.NODE_ENV === "development" ? 'http://localhost:8080' : '/',
    prepareHeaders: (headers, api) => addDefaultHeaders(headers, api),
});

function addDefaultHeaders(headers: Headers, api: { getState: () => unknown }) {
    headers.set('Accept', 'application/json');
    headers.set('Content-Type', 'application/json');
    const token: any = (api.getState() as ReduxState).auth.token;
    if (token !== null) {
        headers.set('Authorization', `Bearer ${token}`);
    }
    return headers;
}

const BaseQueryWithAuth: BaseQueryFn<
    string | FetchArgs,
    unknown,
    FetchBaseQueryError
> = async (args, api, extraOptions) => {
    let result = await customBaseQuery(args, api, extraOptions);
    if (result.error && result.error.status === 401) {
        api.dispatch(authSlice.actions.setToken(null));
    }
    if (result.error !== undefined) {
        let message: string = (result.error.data as MessageData).message;
        console.error(message);
    }
    return result;
};

export const emptySplitApi = createApi({
    baseQuery: BaseQueryWithAuth,
    endpoints: () => ({}),
})
```

之后即可编写页面进行测试。

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

[Redux 官方文档](https://redux.js.org/tutorials/fundamentals/part-1-overview)

[使用 OpenAPI 接口生成代码](https://redux-toolkit.js.org/rtk-query/usage/code-generation#openapi)

[App Router 配置说明](https://redux-toolkit.js.org/usage/nextjs#the-app-router-architecture-and-redux)
