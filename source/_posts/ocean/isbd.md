---
title: Iridium Short Burst Data
date: 2024-04-01 21:32:58
tags:
- "JAVA"
id: isbd
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## Iridium Short Burst Data

### 简介

Iridium Short Burst Data 是铱星的一种短报文，报文可以通过 DirectIP 方式或邮件的方式推送到客户侧。由于提供方并没有说明

### 使用方式

如果需要使用 java 解析报文可以使用如下代码：

```java
import lombok.Data;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

@Data
public class Isbdmsg {

    private String imei;
    private String payload;
    private Double lat;
    private Double lon;
    private Long cepRadius;
    private Long timeOfSession;

    private Long cdrRef;
    private Integer momsn;
    private Integer mtmsn;

    private Boolean finish;
    private Integer readBytes = 0;

    public Isbdmsg(byte[] data) {
        decodeFull(data);
        while (readBytes < data.length) {
            int iei = data[readBytes];
            if (iei == 1) {
                decodeHeader(Arrays.copyOfRange(data, readBytes + 1, readBytes + 31));
            } else if (iei == 2) {
                decodePayload(data);
            } else if (iei == 3) {
                decodeLocation(Arrays.copyOfRange(data, readBytes + 1, readBytes + 14));
            } else {
                return;
            }
        }
    }

    public void decodeFull(byte[] data) {
        int protocolVersion = data[0];
        if (protocolVersion != 1) {
            throw new IllegalArgumentException("not a valid protocol version");
        }
        int overallMessageLen = ((data[1] & 0xFF) << 8) | (data[2] & 0xFF);
        if (data.length != overallMessageLen + 3) {
            throw new IllegalArgumentException("message incomplete");
        }
        this.readBytes = this.readBytes + 3;
    }

    public void decodeHeader(byte[] data) {
        int moHeaderLen = ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
        if (moHeaderLen != 28) {
            throw new IllegalArgumentException("not a valid moHeaderLen");
        }
        this.cdrRef = ((long) (data[2] & 0xFF) << 24) |
                ((long) (data[3] & 0xFF) << 16) |
                ((long) (data[4] & 0xFF) << 8) |
                ((long) (data[5] & 0xFF));
        this.imei = new String(Arrays.copyOfRange(data, 6, 21), StandardCharsets.UTF_8);
        this.momsn = ((data[22] & 0xFF) << 8) | (data[23] & 0xFF);
        this.mtmsn = ((data[24] & 0xFF) << 8) | (data[25] & 0xFF);
        this.timeOfSession = ((long) (data[26] & 0xFF) << 24) |
                ((long) (data[27] & 0xFF) << 16) |
                ((long) (data[28] & 0xFF) << 8) |
                ((long) (data[29] & 0xFF));
        this.readBytes = this.readBytes + 31;
    }

    public void decodeLocation(byte[] data) {
        int moLocationLen = ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
        if (moLocationLen != 11) {
            throw new IllegalArgumentException("not a valid moHeaderLen");
        }
        int nsi = getValueAtIndex(data[2], 1);
        int ewi = getValueAtIndex(data[2], 0);
        int latitudeDegrees = data[3];
        double latitudeMinute = convertToDecimal(data[4], data[5]);
        int longitudeDegrees = data[6];
        double longitudeMinute = convertToDecimal(data[7], data[8]);
        this.lat = withSigns(ewi, latitudeDegrees + convertToDegrees(latitudeMinute));
        this.lon = withSigns(nsi, longitudeDegrees + convertToDegrees(longitudeMinute));
        this.cepRadius = ((long) (data[9] & 0xFF) << 24) |
                ((long) (data[10] & 0xFF) << 16) |
                ((long) (data[11] & 0xFF) << 8) |
                ((long) (data[12] & 0xFF));
        this.readBytes = this.readBytes + 14;
    }

    private double convertToDecimal(byte msByte, byte lsByte) {
        int thousandths = (msByte << 8) | lsByte;
        return thousandths / 1000.0;
    }

    private double convertToDegrees(double decimal) {
        return decimal / 60.0;
    }

    private int getValueAtIndex(byte b, int index) {
        if (index < 0 || index >= 8) {
            throw new IllegalArgumentException("Index out of range");
        }
        return (b >> index) & 1;
    }

    private double withSigns(int i, double number) {
        if (i == 0) {
            return number;
        } else {
            return 0 - number;
        }
    }

    public void decodePayload(byte[] data) {
        int moPayloadLen = ((data[readBytes + 1] & 0xFF) << 8) | (data[readBytes + 2] & 0xFF);
        this.payload = new String(Arrays.copyOfRange(data, readBytes + 3, readBytes + 3 + moPayloadLen));
        this.finish = true;
        this.readBytes = readBytes + 3 + moPayloadLen;
    }
}
```

并如下改动 netty 接收代码：

```java
import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@ChannelHandler.Sharable
@Component
public class DiscardServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf buf = (ByteBuf) msg;
        try {
            byte[] receivedData = new byte[buf.readableBytes()];
            buf.readBytes(receivedData);
            Isbdmsg isbdmsg = new Isbdmsg(receivedData);
            log.info(isbdmsg.getImei() + ": " + isbdmsg.getPayload());
        } finally {
            if (buf != null) {
                buf.release();
            }
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("server error: " + cause.getMessage());
        ctx.close();
    }
}
```

### 参考资料

[DIRECTIP SBD INFORMATION](https://apollosat.com/docs/directip-sbd-information/)
