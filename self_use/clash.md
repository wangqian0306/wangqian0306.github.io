## Clash

### 本地部署

首先需要下载二进制文件到本地，并进行重命名。

```bash
wget https://github.com/Dreamacro/clash/releases/download/v1.13.0/clash-linux-amd64-v1.13.0.gz
gzip -d clash-linux-amd64-v1.13.0.gz
mv clash-linux-amd64-v1.13.0 /usr/local/bin/clash
chmod a+x /usr/local/bin/clash
```

编辑配置文件 `custom.yaml` (参照提供方)，注意以下配置项:

```text
# 允许局域网访问
allow-lan: true
# 外部控制器接口
external-controller: '0.0.0.0:9090'
```

然后使用如下命令开启服务：

```bash
clash -f demo.yaml
```

如需页面还需以下操作：

```bash
git clone https://github.com/Dreamacro/clash-dashboard.git
cd clash-dashboard
git checkout gh-pages
```

在配置文件中修改页面显示地址：

```text
external-ui: <path>
```

> 注: 默认的路径是 `~/.config/clash/<path>` 此处可以配置绝对路径。 

之后启动服务，访问 [http://localhost:9090/ui](http://localhost:9090/ui) 即可。

### 容器部署

运行以下命令：

```bash
mkdir clash
cd clash
touch docker-compose.yaml
git clone https://github.com/Dreamacro/clash-dashboard.git
cd clash-dashboard
git checkout gh-pages
cd ..
```

编辑配置文件 `custom.yaml` (参照提供方)

官方提供了容器，可以编写如下 `docker-compose.yaml`:

```yaml
version: "3.8"
services:
  clash:
    image: dreamacro/clash
    container_name: clash
    volumes:
      - ./config.yaml:/root/.config/clash/config.yaml
       - ./clash-dashboard:/ui
    ports:
      - "7890:7890"
      - "7891:7891"
      - "9090:9090"
    restart: unless-stopped
    network_mode: "bridge"
```

### 参考资料

[官方项目](https://github.com/Dreamacro/clash)

[官方文档](https://github.com/Dreamacro/clash/wiki#welcome)

[官方前端页面](https://github.com/Dreamacro/clash-dashboard)

[第三方前端页面 yacd](https://github.com/haishanh/yacd)
