## V2ray

### V2rayN

> 注：需要安装 .Net core 

- 添加订阅分组
- 更新当前订阅
- 测试全部
- 选择服务器

### V2rayNG

> 注：直接访问 Play 商店即可

- 点击设置
    - 订阅分组设置
        - 添加
- 点击选项
    - 更新订阅
    - 测试全部
- 选择服务器
- 点击 V 图标

### 容器部署

```yaml
services:
  v2ray:
    image: v2fly/v2fly-core
    ports:
      - "10086:10086"
    volumes:
      - /path/to/config.json:/etc/v2ray/config.json
    command: run -c /etc/v2ray/config.json
```

### 参考资料

[项目官网](https://www.v2fly.org/)

[容器页](https://github.com/v2fly/docker)

[Windows 客户端](https://github.com/2dust/v2rayN)

[Android 客户端](https://github.com/2dust/v2rayNG)

[博客指南](https://guide.v2fly.org/)
