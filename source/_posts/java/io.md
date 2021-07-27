---
title: JAVA 当中的 I/O 模式
date: 2021-07-27 21:57:04
tags: "JAVA"
id: io
no_word_count: true
no_toc: false
categories: JAVA
---

## JAVA 当中的 I/O 模式

### 简介

在 Java 当中的 I/O 可以大致分为以下三类：

- BIO(同步阻塞)
- NIO(同步非阻塞)
- AIO(异步非阻塞)

### BIO

同步阻塞I/O模式，数据的读取写入必须阻塞在一个线程内等待其完成。

#### 传统 BIO

![BIO 通信模型图](https://i.loli.net/2021/07/27/M3FVUosLxGqJATl.png)

采用 **BIO 通信模型** 的服务端，通常由一个独立的 Acceptor 线程负责监听客户端的连接。
我们一般通过在`while(true)` 循环中服务端会调用 `accept()` 方法等待接收客户端的连接的方式监听请求。
一旦接收到一个连接请求，就可以建立通信套接字在这个通信套接字上进行读写操作。
此时不能再接收其他客户端连接请求，只能等待同当前连接的客户端的操作执行完成，不过可以通过多线程来支持多个客户端的连接，如上图所示。

如果要让 **BIO 通信模型** 能够同时处理多个客户端请求，就必须使用多线程。
(主要的原因是`socket.accept()`、`socket.read()`、`socket.write()` 涉及的三个主要函数都是同步阻塞的)
也就是说它在接收到客户端连接请求之后为每个客户端创建一个新的线程进行链路处理，处理完成之后，通过输出流返回应答给客户端，然后销毁线程。
这就是典型的 **一请求/应答通信模型** 。
我们可以设想一下如果这个连接不做任何事情的话就会造成不必要的线程开销，不过可以通过 **线程池机制** 改善，线程池还可以让线程的创建和回收成本相对较低。
使用 `FixedThreadPool` 可以有效的控制了线程的最大数量，保证了系统有限的资源的控制，实现了 N(客户端请求数量): M(处理客户端请求的线程数量) 的伪异步I/O模型
(N 可以远远大于 M)，下面一节"伪异步 BIO"中会详细介绍到。

#### 伪异步 IO

为了解决同步阻塞 I/O 面临的一个链路需要一个线程处理的问题，后来有人对它的线程模型进行了优化——后端通过一个线程池来处理多个客户端的请求接入。
我们可以把客户端的数量设置为 M，线程池的最大数量设置为 N，其中 M 可以远远大于 N。
我们可以通过线程池灵活地调配线程资源，限制线程池的大小防止由于海量并发接入导致线程耗尽。

![bio-2.png](https://i.loli.net/2021/07/27/Io8RDzUJmb43dr9.png)

采用线程池和任务队列可以实现一种叫做伪异步的 I/O 通信框架，它的模型图如上图所示。
当有新的客户端接入时，将客户端的 Socket 封装成一个 Task (该任务实现 java.lang.Runnable 接口) 传递到后端的线程池中进行处理。
JDK 的线程池维护一个消息队列和 N 个活跃线程，对消息队列中的任务进行处理。
由于线程池可以设置缓冲队列的大小和最大线程数，因此，它的资源占用是可控的，无论多少个客户端并发访问，都不会导致资源的耗尽和宕机。

伪异步 I/O 通信框架采用了线程池实现，因此避免了为每个请求都创建一个独立线程造成的线程资源耗尽问题。
不过因为它的底层仍然是同步阻塞的 BIO 模型，因此无法从根本上解决问题。

### NIO

NIO 是一种同步非阻塞的 I/O 模型，在 Java 1.4 中引入了 NIO 框架，对应 java.nio 包，提供了 Channel , Selector，Buffer 等抽象。

它支持面向缓冲的，基于通道的I/O操作方法。
NIO 提供了与传统 BIO 模型中的 `Socket` 和 `ServerSocket` 相对应的 `SocketChannel` 和 `ServerSocketChannel`
两种不同的套接字通道实现，两种通道都支持阻塞和非阻塞两种模式。
阻塞模式使用就像传统中的支持一样，比较简单，但是性能和可靠性都不好；非阻塞模式正好与之相反。
对于低负载、低并发的应用程序，可以使用同步阻塞 I/O 来提升开发速率和更好的维护性；对于高负载、高并发的（网络）应用，应使用 NIO 的非阻塞模式来开发。

NIO 一个重要的特点是：socket 主要的读、写、注册和接收函数，在等待就绪阶段都是非阻塞的，真正的 I/O 操作是同步阻塞的(消耗 CPU 但性能非常高)。

NIO 的读写函数可以立刻返回，这就给了我们不开线程利用 CPU 的最好机会：如果一个连接不能读写(socket.read() 返回 0 或者 socket.write() 返回 0 )，
我们可以把这件事记下来，记录的方式通常是在 Selector 上注册标记位，然后切换到其它就绪的连接(channel)继续进行读写。

NIO的主要事件有几个：读就绪、写就绪、有新连接到来。

我们首先需要注册当这几个事件到来的时候所对应的处理器。
然后在合适的时机告诉事件选择器：我对这个事件感兴趣。
对于写操作，就是写不出去的时候对写事件感兴趣；
对于读操作，就是完成连接和系统没有办法承载新读入的数据的时；
对于 accept，一般是服务器刚启动的时候；
而对于 connect，一般是 connect 失败需要重连或者直接异步调用 connect 的时候。

其次，用一个死循环选择就绪的事件，会执行系统调用(Linux 2.6 之前是 select、poll，2.6 之后是 epoll，Windows 是 IOCP)，还会阻塞的等待新事件的到来。
新事件到来的时候，会在 selector 上注册标记位，标示可读、可写或者有连接到来。

注意，select是阻塞的，无论是通过操作系统的通知(epoll)还是不停的轮询(select，poll)，这个函数是阻塞的。
所以你可以放心大胆地在一个 while(true) 里面调用这个函数而不用担心 CPU 空转。

样例程序如下：

```java
interface ChannelHandler {
    void channelReadable(Channel channel);

    void channelWritable(Channel channel);
}

class Channel {
    Socket socket;
    Event event;//读，写或者连接
}

//IO线程主循环:
class IoThread extends Thread {
    public void run() {
        Channel channel;
        while (channel = Selector.select()) {//选择就绪的事件和对应的连接
            if (channel.event == accept) {
                registerNewChannelHandler(channel);//如果是新连接，则注册一个新的读写处理器
            }
            if (channel.event == write) {
                getChannelHandler(channel).channelWritable(channel);//如果可以写，则执行写事件
            }
            if (channel.event == read) {
                getChannelHandler(channel).channelReadable(channel);//如果可以读，则执行读事件
            }
        }
    }

    Map<Channel, ChannelHandler> handlerMap;//所有channel的对应事件处理器
}
```

### AIO

本文所说的 AIO 特指 Java 环境下的 AIO。
AIO 是 java 中 IO 模型的一种，作为 NIO 的改进和增强随 Java 1.7 版本更新被集成在 JDK 的 nio 包中，因此 AIO 也被称作是 NIO 2.0。
区别于传统的 BIO(Blocking IO,同步阻塞式模型,Java 1.4 之前就存在于 JDK 中，NIO 于 Java 1.4 版本发布更新)的阻塞式读写，
AIO 提供了从建立连接到读、写的全异步操作。
AIO 可用于异步的文件读写和网络通信。

样例服务端：

```java
public class SimpleAIOServer {

    public static void main(String[] args) {
        try {
            final int port = 5555;
            //首先打开一个 ServerSocket 通道并获取 AsynchronousServerSocketChannel 实例：
            AsynchronousServerSocketChannel serverSocketChannel = AsynchronousServerSocketChannel.open();
            //绑定需要监听的端口到 serverSocketChannel:  
            serverSocketChannel.bind(new InetSocketAddress(port));
            //实现一个 CompletionHandler 回调接口 handler，
            //之后需要在 handler 的实现中处理连接请求和监听下一个连接、数据收发，以及通信异常。
            CompletionHandler<AsynchronousSocketChannel, Object> handler = new CompletionHandler<AsynchronousSocketChannel,
                    Object>() {
                @Override
                public void completed(final AsynchronousSocketChannel result, final Object attachment) {
                    // 继续监听下一个连接请求  
                    serverSocketChannel.accept(attachment, this);
                    try {
                        System.out.println("接受了一个连接：" + result.getRemoteAddress()
                                .toString());
                        // 给客户端发送数据并等待发送完成
                        result.write(ByteBuffer.wrap("From Server:Hello i am server".getBytes()))
                                .get();
                        ByteBuffer readBuffer = ByteBuffer.allocate(128);
                        // 阻塞等待客户端接收数据
                        result.read(readBuffer)
                                .get();
                        System.out.println(new String(readBuffer.array()));

                    } catch (IOException | InterruptedException | ExecutionException e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void failed(final Throwable exc, final Object attachment) {
                    System.out.println("出错了：" + exc.getMessage());
                }
            };
            serverSocketChannel.accept(null, handler);
            // 由于 serverSocketChannel.accept(null, handler); 是一个异步方法，调用会直接返回，
            // 为了让子线程能够有时间处理监听客户端的连接会话，
            // 这里通过让主线程休眠一段时间(当然实际开发一般不会这么做)以确保应用程序不会立即退出。
            TimeUnit.MINUTES.sleep(Integer.MAX_VALUE);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

样例客户端：

```java
public class SimpleAIOClient {

    public static void main(String[] args) {
        try {
            // 打开一个 SocketChannel 通道并获取 AsynchronousSocketChannel 实例
            AsynchronousSocketChannel client = AsynchronousSocketChannel.open();
            // 连接到服务器并处理连接结果
            client.connect(new InetSocketAddress("127.0.0.1", 5555), null, new CompletionHandler<Void, Void>() {
                @Override
                public void completed(final Void result, final Void attachment) {
                    System.out.println("成功连接到服务器!");
                    try {
                        // 给服务器发送信息并等待发送完成
                        client.write(ByteBuffer.wrap("From client:Hello i am client".getBytes()))
                                .get();
                        ByteBuffer readBuffer = ByteBuffer.allocate(128);
                        // 阻塞等待接收服务端数据
                        client.read(readBuffer)
                                .get();
                        System.out.println(new String(readBuffer.array()));
                    } catch (InterruptedException | ExecutionException e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void failed(final Throwable exc, final Void attachment) {
                    exc.printStackTrace();
                }
            });
            TimeUnit.MINUTES.sleep(Integer.MAX_VALUE);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

### 参考资料

https://github.com/Snailclimb/JavaGuide/blob/master/docs/java/basis/BIO%2CNIO%2CAIO%E6%80%BB%E7%BB%93.md

https://zhuanlan.zhihu.com/p/111816019

https://zhuanlan.zhihu.com/p/23488863

https://segmentfault.com/a/1190000020364149