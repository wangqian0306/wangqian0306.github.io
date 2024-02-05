---
title: IDS 和 IPS
date: 2024-02-04 21:57:04
tags:
- "Linux"
- "IDS"
id: ids_ips
no_word_count: true
no_toc: false
categories: Linux
---

## IDS 和 IPS

### 简介

IDS 是英文“Intrusion Detection Systems”的缩写，中文意思是“入侵检测系统”。专业上讲就是依照一定的安全策略，对网络、系统的运行状况进行监视，尽可能发现各种攻击企图、攻击行为或者攻击结果，以保证网络系统资源的机密性、完整性和可用性。

IPS 是英文“Intrusion Prevention System”的缩写,中文意思为“入侵防御系统”，IPS 可以说是 IDS 的新一代产品。IPS 位于防火墙和网络的设备之间。这样，如果检测到攻击，IPS 会在这种攻击扩散到网络的其它地方之前阻止这个恶意的通信。IDS 是存在于网络之外起到报警的作用，而不是在你的网络前面起到防御的作用。目前有很多种 IPS 系统，它们使用的技术都不相同。但是，一般来说，IPS 系统都依靠对数据包的检测。IPS 将检查入网的数据包，确定这种数据包的真正用途，然后决定是否允许这种数据包进入你的网络。

### Suricata

#### 安装和使用

> 注：此处以 Rocky Linux 样例。

```bash
sudo dnf install epel-release -y
sudo dnf install suricata -y
sudo suricata-update update-sources
sudo suricata-update enable-source et/open
sudo suricata-update
systemctl enable suricata.service --now
```

### 参考资料

[常见网络安全设备：IDS（入侵检测系统）](https://cloud.tencent.com/developer/article/2233375?areaSource=102001.2&traceId=wbhOfyE7lyavhB-ay1uBK)

[使用 Azure 网络观察程序和开源工具执行网络入侵检测](https://learn.microsoft.com/zh-cn/azure/network-watcher/network-watcher-intrusion-detection-open-source-tools)

[基于网络的入侵检测系统的几种？常用开源NIDS，让我们来了解一下](https://www.ruijie.com.cn/jszl/90432/)

[Suricata](https://suricata.io/)

[Snort](https://www.snort.org/)

[Security Onion](https://securityonionsolutions.com/)
