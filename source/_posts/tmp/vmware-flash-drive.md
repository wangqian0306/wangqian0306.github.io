---
title: VMware 模拟 U 盘
date: 2023-07-11 21:41:32
tags: "VMware"
id: vmware-flash-drive
no_word_count: true
no_toc: false
---

## VMware 模拟 U 盘

### 简介

在 VMware 中可以轻松的创建新的硬盘，但是创建一个虚拟的 U 盘却需要一些神奇的操作。

### 使用方式

首先需要找到 VMware Workstation 软件的所在位置，然后运行如下命令生成一个虚拟磁盘。

```bash
vmware-vdiskmanager.exe -c -a buslogic -s <size> -t 0 "<path>"
```

样例如下：

```bash
vmware-vdiskmanager.exe -c -a buslogic -s 32GB -t 0 "D:\VMware VMs\vm-usb-key.vmdk"
```

然后即可将生成的虚拟磁盘移动到目标虚拟机中

> 注：目标虚拟机最好是个 Windows 因为新的虚拟磁盘需要进行初始化和分区。

编辑目标虚拟机的配置文件 `xxx.vmx`，确保以下参数在系统中存在。

```text
ehci.present = "TRUE"
ehci.pciSlotNumber = "xx"
```

在配置文件中添加如下内容：

```text
ehci:0.present = "TRUE"
ehci:0.deviceType = "disk"
ehci:0.fileName = "vm-usb-key.vmdk"
ehci:0.readonly = "FALSE"
```

启动虚拟机并进行初始化即可。

### 参考资料

[Create a Virtual USB Drive in VMware Workstation](https://onlinecomputertips.com/support-categories/software/vmware-workstation-virtual-usb/)
