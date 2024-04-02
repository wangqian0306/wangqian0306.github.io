---
title: Netty
date: 2024-04-02 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Netty"
id: netty
no_word_count: true
no_toc: false
categories: Spring
---

## Netty

### 简介

Netty 是一个 NIO 客户端服务器框架，可以快速轻松地开发协议服务器和客户端等网络应用程序。它极大地简化和简化了网络编程，例如 TCP 和 UDP Socket 服务器开发。

### 使用方式

#### Socket Server

首先需要引入依赖：

```groovy
dependencies {
    implementation 'io.netty:netty-all:4.1.108.Final'
}
```

然后需要编写数据接收类：

```java
import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.util.ReferenceCountUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DiscardServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        try {
            while (in.isReadable()) {
                log.error(String.valueOf((char) in.readByte()));
            }
        } finally {
            ReferenceCountUtil.release(msg);
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }

}
```

然后编写服务：

```java
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class NettyServerRunner implements ApplicationRunner {

    private final DiscardServerHandler discardServerHandler;

    public NettyServerRunner(DiscardServerHandler discardServerHandler) {
        this.discardServerHandler = discardServerHandler;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        EventLoopGroup bossGroup = new NioEventLoopGroup();
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap b = new ServerBootstrap();
            b.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        public void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(discardServerHandler);
                        }
                    })
                    .option(ChannelOption.SO_BACKLOG, 128)
                    .childOption(ChannelOption.SO_KEEPALIVE, true);

            ChannelFuture f = b.bind(8888).sync();
            f.channel().closeFuture().sync();
        } finally {
            workerGroup.shutdownGracefully();
            bossGroup.shutdownGracefully();
        }
    }
}
```

之后即可运行如下命令测试服务状态：

```bash
telnet localhost 8888
```

> 注：进入命令后可以输入任意内容查看日志。

### 参考资料

[官方网站](https://netty.io/)
