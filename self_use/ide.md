## Ide

[server](https://github.com/NotoChen/Jetbrains-Help)

```bash
services:
  jetbrains-help:
    build: .
    image: jetbrains-help:latest
    container_name: jetbrains-help
    ports:
      - 10768:10768
```

```text
--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED
--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED

-javaagent:<path>\ja-netfilter.jar=jetbrains
```