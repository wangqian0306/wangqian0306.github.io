## 代理配置

### 启动代理

```bash
export http_proxy=http://host:port
export https_proxy=$http_proxy
```

### 关闭代理

```bash
unset http_proxy
unset https_proxy
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
