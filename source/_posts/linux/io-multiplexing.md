---
title: I/O 多路复用
date: 2021-07-23 21:57:04
tags: "Linux"
id: io-multiplexing
no_word_count: true
no_toc: false
categories: Linux
---

## I/O 多路复用

### 简介

I/O 多路复用是指-允许程序员检查和阻止多个 I/O 流(或其他“同步”事件)，每当任何一个流处于活动状态时都会收到通知，以便它可以处理该流上的数据。

在 Linux 系统中存在以下三种实现方式：

- select
- poll
- epoll

### select

函数概览：

```text
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
```

样例实现方式：

```text
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <wait.h>
#include <signal.h>
#include <errno.h>
#include <sys/select.h>
#include <sys/time.h>
#include <unistd.h>
 
#define MAXBUF 256
 
void child_process(void)
{
  sleep(2);
  char msg[MAXBUF];
  struct sockaddr_in addr = {0};
  int n, sockfd,num=1;
  srandom(getpid());
  /* Create socket and connect to server */
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  addr.sin_family = AF_INET;
  addr.sin_port = htons(2000);
  addr.sin_addr.s_addr = inet_addr("127.0.0.1");
 
  connect(sockfd, (struct sockaddr*)&addr, sizeof(addr));
 
  printf("child {%d} connected \n", getpid());
  while(1){
        int sl = (random() % 10 ) +  1;
        num++;
     	sleep(sl);
  	sprintf (msg, "Test message %d from client %d", num, getpid());
  	n = write(sockfd, msg, strlen(msg));	/* Send message */
  }
 
}
 
int main()
{
  char buffer[MAXBUF];
  int fds[5];
  struct sockaddr_in addr;
  struct sockaddr_in client;
  int addrlen, n,i,max=0;;
  int sockfd, commfd;
  fd_set rset;
  for(i=0;i<5;i++)
  {
  	if(fork() == 0)
  	{
  		child_process();
  		exit(0);
  	}
  }
 
 
  /*
     创建 socket 客户端
     创建文件描述符，并放入数组
  */
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  memset(&addr, 0, sizeof (addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(2000);
  addr.sin_addr.s_addr = INADDR_ANY;
  bind(sockfd,(struct sockaddr*)&addr ,sizeof(addr));
  listen (sockfd, 5); 
 
  for (i=0;i<5;i++) 
  {
    memset(&client, 0, sizeof (client));
    addrlen = sizeof(client);
    fds[i] = accept(sockfd,(struct sockaddr*)&client, &addrlen);
    if(fds[i] > max)
    	max = fds[i];
  }
  
  /*
     读取文件描述符集合，写文件描述符集合，异常描述符集合，超时时间
     标记启用的文件描述符
  */
  while(1){
	FD_ZERO(&rset);
  	for (i = 0; i< 5; i++ ) {
  		FD_SET(fds[i],&rset);
  	}
 
   	puts("round again");
	select(max+1, &rset, NULL, NULL, NULL);
 
	for(i=0;i<5;i++) {
		if (FD_ISSET(fds[i], &rset)){
			memset(buffer,0,MAXBUF);
			read(fds[i], buffer, MAXBUF);
			puts(buffer);
		}
	}	
  }
  return 0;
}
```

函数的执行流程：

1. select 是一个阻塞函数，当没有数据时会阻塞在当前行。
2. 当有数据时会将 rset 中对应的位置置为 1。
3. select 函数返回不再阻塞。
4. 遍历文件描述符数组，判断为 1 的描述符。
5. 读取数据进行处理。

函数缺点：

1. rset 采用了 bitmap 的形式默认大小为 1024。
2. rset 每次循环都必须重新置位，不可重复使用
3. 尽管将 rset 的判断是从内核态进行的，但是仍然有拷贝的开销
4. select 并不知道哪一个文件描述符下有数据，需要遍历。

函数特性：

- 我们需要在每次调用之前构建每个集合
- 该函数检查任何位 - O(n)
- 我们需要遍历文件描述符以检查它是否存在于 select 返回的集合中
- select 的主要优点是它非常普遍 - 在每一个 unix 系统中都存在

### poll

函数概览:

```text
int poll (struct pollfd *fds, unsigned int nfds, int timeout);
```

poll 模型的数据结构如下：

```text
struct pollfd {
      int fd;
      short events; 
      short revents;
};
```

样例如下：

```text
  for (i=0;i<5;i++) 
  {
    memset(&client, 0, sizeof (client));
    addrlen = sizeof(client);
    pollfds[i].fd = accept(sockfd,(struct sockaddr*)&client, &addrlen);
    pollfds[i].events = POLLIN;
  }
  sleep(1);
  while(1){
  	puts("round again");
	poll(pollfds, 5, 50000);
 
	for(i=0;i<5;i++) {
		if (pollfds[i].revents & POLLIN){
			pollfds[i].revents = 0;
			memset(buffer,0,MAXBUF);
			read(pollfds[i].fd, buffer, MAXBUF);
			puts(buffer);
		}
	}
  }
```

函数的执行流程：

1. 将描述符从用户态转到内核态
2. poll 是一个阻塞函数，当没有数据时会阻塞在当前行，如果有数据则标识 fd 的 revents 为 POLLIN。
3. poll 方法返回
4. 遍历 fd，定位文件描述符
5. 重置对象
6. 读取和处理

函数缺点：

1. 有拷贝的开销
2. poll 并不知道哪一个文件描述符下有数据，需要遍历。

函数特性：

- poll() 不要求用户计算最高编号的文件描述符的值+1
- poll() 对于大值文件描述符更有效。想象一下，通过 select() 观察一个值为 900 的文件描述符——内核必须检查每个传入集合的每一位，直到第 900 位。
- select() 的文件描述符集是静态大小的。
- 使用 select()，文件描述符集在返回时被重建，因此每个后续调用都必须重新初始化它们。 poll() 系统调用将输入（events 字段）与输出（revents 字段）分开，允许数组无需更改即可重用。
- select() 的超时参数在返回时未定义。需要独立是实现。
- select() 更普遍，因为一些 Unix 系统不支持 poll()

### epoll

在使用 select 和 poll 时，我们管理用户空间上的所有内容，并在每次调用时发送集合并进行等待。 要添加另一个套接字，我们需要将其添加到集合中并再次调用 select/poll。

Epoll 系统调用可以帮助我们在内核中创建和管理上下文。

我们将任务分为 3 个步骤：

- 使用 epoll_create 在内核中创建上下文
- 使用 epoll_ctl 在上下文中添加和删除文件描述符
- 使用 epoll_wait 在上下文中等待事件

样例实现：

```
  struct epoll_event events[5];
  int epfd = epoll_create(10);
  ...
  ...
  for (i=0;i<5;i++) 
  {
    static struct epoll_event ev;
    memset(&client, 0, sizeof (client));
    addrlen = sizeof(client);
    ev.data.fd = accept(sockfd,(struct sockaddr*)&client, &addrlen);
    ev.events = EPOLLIN;
    epoll_ctl(epfd, EPOLL_CTL_ADD, ev.data.fd, &ev); 
  }
  
  while(1){
  	puts("round again");
  	nfds = epoll_wait(epfd, events, 5, 10000);
	
	for(i=0;i<nfds;i++) {
			memset(buffer,0,MAXBUF);
			read(events[i].data.fd, buffer, MAXBUF);
			puts(buffer);
	}
  }
```

函数的执行流程：

1. 有数据时会将文件描述符放在队首。
2. epoll 会返回有数据的文件描述符的个数
3. 根据返回的个数读取文件描述符即可
4. 读取处理

函数特性：

- 我们可以在等待时添加和删除文件描述符
- epoll_wait 只返回文件描述符就绪的对象
- epoll 有更好的性能——O(1) 而不是 O(n)
- epoll 可以表现为级别触发或边缘触发
- epoll 是 Linux 特定的，因此不可移植

### 参考资料

https://www.bilibili.com/video/BV1qJ411w7du?from=search&seid=14828976220028495409

https://devarea.com/linux-io-multiplexing-select-vs-poll-vs-epoll/#.XYD0TygzaUl

https://notes.shichao.io/unp/ch6/

https://www.ulduzsoft.com/2014/01/select-poll-epoll-practical-difference-for-system-architects/
