## 代理配置

### 启动代理

```bash
export HTTP_PROXY=http://xxx.xxx.xxx.xxx:xxxx
export HTTPS_PROXY=$HTTP_PROXY
```

### 关闭代理

```bash
unset HTTP_PROXY
unset HTTPS_PROXY
```

### 配置 git 代理

```bash
git config --global http.proxy http://host:port
git config --global https.proxy http://host:port
```

### 取消 git 代理

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```
