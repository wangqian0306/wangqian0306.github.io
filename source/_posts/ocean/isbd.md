---
title: Iridium Short Burst Data
date: 2024-04-01 21:32:58
tags:
- "Python"
id: isbd
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## Iridium Short Burst Data

### 简介

Iridium Short Burst Data 是铱星的一种短报文，报文可以通过 DirectIP 方式或邮件的方式推送到客户侧。按照本文进行编码即可获得一个测试服务器。

### 使用方式

如果需要使用 java 解析报文可以使用如下代码：

```java
import lombok.Data;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

@Data
public class Isbdmsg {

    private String msgProtocolVer;
    private Integer totalMsgLen;
    private String moHeaderIei;
    private Integer moHeaderLen;
    private Long cdrRef;
    private String imei;
    private String status;
    private Integer moMsn;
    private Integer mtMsn;
    private Long msgTimestamp;
    private String payloadHeaderIei;
    private Integer payloadHeaderLen;
    private String locOrient;
    private Integer locLatDeg;
    private Integer locLatMin;
    private Integer locLonDeg;
    private Integer locLonMin;
    private Long cepRadius;
    private String payloadIei;
    private Integer payloadLen;
    private String payload;

    public Isbdmsg(byte[] data) {
        this.msgProtocolVer = byteToHex(data[0]);
        this.totalMsgLen = ((data[1] & 0xFF) << 8) | (data[2] & 0xFF);
        this.moHeaderIei = byteToHex(data[3]);
        this.moHeaderLen = ((data[4] & 0xFF) << 8) | (data[5] & 0xFF);
        this.cdrRef = ((long)(data[6] & 0xFF) << 24) |
                ((long)(data[7] & 0xFF) << 16) |
                ((long)(data[8] & 0xFF) << 8) |
                ((long)(data[9] & 0xFF));
        this.imei = new String(Arrays.copyOfRange(data,10,25), StandardCharsets.UTF_8);
        this.status = byteToHex(data[25]);
        this.moMsn = ((data[26] & 0xFF) << 8) | (data[27] & 0xFF);
        this.mtMsn = ((data[28] & 0xFF) << 8) | (data[29] & 0xFF);
        this.msgTimestamp = ((long)(data[30] & 0xFF) << 24) |
                ((long)(data[31] & 0xFF) << 16) |
                ((long)(data[32] & 0xFF) << 8) |
                ((long)(data[33] & 0xFF));
        this.payloadHeaderIei = byteToHex(data[34]);
        this.payloadHeaderLen = ((data[35] & 0xFF) << 8) | (data[36] & 0xFF);
        this.locOrient = String.valueOf(data[37]);
        this.locLatDeg = Integer.valueOf(String.valueOf(data[38]));
        this.locLatMin = ((data[39] & 0xFF) << 8) | (data[40] & 0xFF);
        this.locLonDeg = Integer.valueOf(String.valueOf(data[41]));
        this.locLonMin = ((data[42] & 0xFF) << 8) | (data[43] & 0xFF);
        this.cepRadius = ((long)(data[44] & 0xFF) << 24) |
                ((long)(data[45] & 0xFF) << 16) |
                ((long)(data[46] & 0xFF) << 8) |
                ((long)(data[47] & 0xFF));
        this.payloadIei = byteToHex(data[48]);
        this.payloadLen = ((data[49] & 0xFF) << 8) | (data[50] & 0xFF);
        this.payload = new String(Arrays.copyOfRange(data,51,data.length), StandardCharsets.UTF_8);
    }

    public static String byteToHex(byte b) {
        return String.format("%02X", b);
    }
}
```

并如下改动 netty 接收代码：

```
import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DiscardServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }

}
```

### 参考资料

[DIRECTIP SBD INFORMATION](https://apollosat.com/docs/directip-sbd-information/)
