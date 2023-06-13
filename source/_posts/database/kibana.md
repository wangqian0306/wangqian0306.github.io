---
title: Kibana 
date: 2022-09-07 23:09:32
tags:
- "Kibana"
- "Elastic Stack"
id: kibana
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## Kibana

### 简介

Kibana 是一款检索分析和展示 Elastic Stack 的仪表板工具。

### 容器部署

可以通过如下 `docker-compose` 部署 Kibana

```yaml
version: '3'
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:8.4.1
    environment:
      SERVER_NAME: kibana.example.org
      ELASTICSEARCH_HOSTS: '["http://es01:9200","http://es02:9200","http://es03:9200"]'
    ports:
      - "5601:5601"
```

如与 Elastic Search 一同部署，则可以先编写 `.env` 文件然后再编写 `docker-compose.yaml` 即可：

```env
ELASTIC_PASSWORD=<ELASTIC_PASSWORD>
KIBANA_PASSWORD=<KIBANA_PASSWORD>
CLUSTER_NAME=<CLUSTER_NAME>
```

```yaml
version: '3.8'
services:
  setup:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.4.1
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ x${ELASTIC_PASSWORD} == x ]; then
          echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
          exit 1;
        elif [ x${KIBANA_PASSWORD} == x ]; then
          echo "Set the KIBANA_PASSWORD environment variable in the .env file";
          exit 1;
        fi;
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: elasticsearch\n"\
          "    dns:\n"\
          "      - elasticsearch\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          "      - <remote_host>\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://elasticsearch:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H "Content-Type: application/json" https://elasticsearch:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
    healthcheck:
      test: [ "CMD-SHELL", "[ -f config/certs/elasticsearch/elasticsearch.crt ]" ]
      interval: 1s
      timeout: 5s
      retries: 120

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.4.1
    environment:
      - discovery.type=single-node
      - node.name=elasticsearch
      - cluster.name=${CLUSTER_NAME}
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.http.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.transport.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    ports:
      - "9200:9200"
      - "9300:9300"
    depends_on:
      setup:
        condition: service_healthy
  kibana:
    image: docker.elastic.co/kibana/kibana:8.4.1
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=https://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    volumes:
      - certs:/usr/share/kibana/config/certs
volumes:
  certs:
    driver: local
```

> 注：容器启动之后需要等待 `startup` 服务完成配置。之后即可使用 `elastic` 账户和之前配置的密码访问 [kibana](http://localhost:5601)

### RPM 部署

使用如下命令配置依赖：

```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
vim /etc/yum.repos.d/kibana.repo
```

然后填入如下内容：

```text
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

使用如下命令进行安装：

```bash
sudo yum install kibana
```

使用如下命令启动服务：

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo systemctl start kibana.service
```

- 配置

软件配置在 `/etc/kibana` 目录中。

默认日志在 `/var/log/kibana` 目录中。

- 关闭服务

```bash
sudo systemctl stop kibana.service
```

### 参考资料

[官方文档](https://www.elastic.co/guide/en/kibana/current/introduction.html)

[容器说明](https://hub.docker.com/_/kibana)

[安装手册](https://www.elastic.co/guide/en/kibana/8.8/rpm.html)
