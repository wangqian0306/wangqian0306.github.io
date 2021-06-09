---
title: OpenShift 相关内容整理
date: 2020-04-07 20:52:13
tags:
- "Container"
- "OpenShift"
id: openshift
no_word_count: true
no_toc: false
categories: Kubernetes
---

## 简介

OpenShift 是红帽“加强”过的 Kubernetes。

[官方文档(v3.11.0)](https://docs.okd.io/3.11/welcome/index.html)

## Yaml 模板

### DeploymentConfig
```yaml
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  name: demo
  labels:
    app: demo
spec:
  template:
    metadata:
      labels:
        app: demo
    spec:
      hostname: demo
      containers:
        - env:
            - name: SPRING_PROFILES_ACTIVE
              valueFrom:
                configMapKeyRef:
                  key: DEFAULT
                  name: profile
            - name: PORT
              value: "8080"
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /actuator/health
              port: 5273
              scheme: HTTP
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /actuator/health
              port: 5273
              scheme: HTTP
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          image: docker.io/wqnice/demo:0.1.0
          imagePullPolicy: Always
          name: demo
          ports:
            - containerPort: 8080
              protocol: TCP
  replicas: 1
  strategy:
    type: Rolling
  paused: false
  revisionHistoryLimit: 2
  minReadySeconds: 0
```

### Service
```yaml
kind: Service
apiVersion: v1
metadata:
  labels:
    app: demo
  name: demo
spec:
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
  selector:
    app: demo
```

### Route
```yaml
kind: Route
apiVersion: v1
metadata:
  labels:
    app: demo
  name: demo
spec:
  host: demo.apps.<hostname>
  path: "/"
  port:
    targetPort: http
  to:
    kind: Service
    name: demo
    weight: 100
  wildcardPolicy: None
```

### Template
```yaml
apiVersion: v1
kind: Template
metadata:
  name: redis-template
  annotations:
    description: "Description"
    iconClass: "icon-redis"
    tags: "database,nosql"
parameters:
- description: Password used for Redis authentication
  from: '[A-Z0-9]{8}'
  generate: expression
  name: REDIS_PASSWORD
message: 'demo description'
labels:
  redis: master
objects:
- apiVersion: apps.openshift.io/v1
  kind: DeploymentConfig
  metadata:
    name: redis
  spec:
    template:
    metadata:
      labels:
        app: redis
    spec:
      hostname: redis
      containers: 
        - image: docker.io/wqnice/demo:0.1.0
          imagePullPolicy: Always
          name: demo
          ports:
            - containerPort: 8080
              protocol: TCP
    replicas: 1
    strategy:
    type: Rolling
    paused: false
    revisionHistoryLimit: 2
    minReadySeconds: 0
```

### ConfigMap
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: example-config
  namespace: default
data: 
  example.property.1: hello
  example.property.2: world
  example.property.file: |-
    property.1=value-1
    property.2=value-2
    property.3=value-3
```

### PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  name: demo-pv
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: demo-pvc
  nfs:
    path: /demo
    server: 172.25.2.1
  persistentVolumeReclaimPolicy: Retain
  storageClassName: demo
```

### PersistentVolumeCliam
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  finalizers:
    - kubernetes.io/pvc-protection
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: demo-pv
```

### CronJobs
```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: demo
spec:
  schedule: "*/1 * * * *"  
  jobTemplate:             
    spec:
      template:
        metadata:
          labels:          
            parent: "cronjobpi"
        spec:
          containers:
          - name: pi
            image: perl
            command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
          restartPolicy: OnFailure 
```

### DaemonSet
```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: demo
spec:
  selector:
      matchLabels:
        name: demo
  template:
    metadata:
      labels:
        name: demo
    spec:
      containers:
      - image: docker.io/wqnice/demo:0.1.0
        imagePullPolicy: Always
        name: demo
        ports:
          - containerPort: 8080
            protocol: TCP
      serviceAccount: default
      terminationGracePeriodSeconds: 10
```

## Robot 账户配置

创建账户
```bash
oc create sa robot
```
获取令牌
```bash
oc serviceaccounts get-token robot
```

授予机器人账户全部权限
```bash
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:<namespace>:<robot name>
```