## Clash Meta

### 本地部署

本地可以使用图形化工具 `Clash Verge`

### 容器部署

官方提供了容器，可以编写如下 `docker-compose.yaml`:

```yaml
version: '3'

services:
  metacubexd:
    container_name: metacubexd
    image: ghcr.io/metacubex/metacubexd
    restart: always
    ports:
      - '80:80'
  meta:
    container_name: meta
    image: docker.io/metacubex/clash-meta:Alpha
    restart: always
    network_mode: host
    cap_add:
      - NET_ADMIN
    volumes:
      - ./config.yaml:/root/.config/clash
```

### 参考资料

[项目](https://github.com/MetaCubeX/Clash.Meta/tree/Alpha)

[面板](https://github.com/MetaCubeX/metacubexd/tree/main)
