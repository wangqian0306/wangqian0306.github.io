## V2ray

### 部署

```bash
docker run -d --name v2ray -v /path/to/config.json:/etc/v2ray/config.json -p 10086:10086 v2fly/v2fly-core run -c /etc/v2ray/config.json
```

### 参考资料

[项目官网](https://www.v2fly.org/)

[容器页](https://github.com/v2fly/docker)

[Windows 客户端](https://github.com/2dust/v2rayN)

[Android 客户端](https://github.com/2dust/v2rayNG)

[博客指南](https://guide.v2fly.org/)
