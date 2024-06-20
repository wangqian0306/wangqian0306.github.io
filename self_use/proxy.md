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

### 配置 Docker 代理

修改 `/usr/lib/systemd/system/docker.service`

```text
[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
Environment="HTTP_PROXY=http://192.168.1.170:7890"
Environment="HTTPS_PROXY=http://192.168.1.170:7890"
Environment="NO_PROXY=localhost,127.0.0.1"
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

然后运行如下命令：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
docker info
```

若出现 `HTTP_PROXY` 等字样则证明配置完成