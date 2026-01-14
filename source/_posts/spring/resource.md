---
title: Spring Resource
date: 2026-01-13 21:32:58
tags:
- "Java"
- "Spring"
id: spring-resource
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring Resource

### 简介

在开发中可以使用多种不同的方式来引入外部资源，并将这些资源引入 Spring 中完成对应的业务逻辑。

现针对引用方式进行一些整理，通常的引入方式如下：

- 引入 `classpath` 目录中的文件
- 引入 URL
- 引入宿主机中的文件

### 使用方式

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Example 1: Loading Resources with @Value and Resource
 *
 * Spring's Resource interface provides a powerful abstraction for accessing low-level resources.
 * When combined with @Value, Spring automatically creates the appropriate Resource implementation
 * based on the prefix you use in the resource path.
 *
 */
@RestController
public class ResourceController {

    // ==================== CLASSPATH RESOURCE ====================
    // Use "classpath:" to load files from src/main/resources
    // Spring creates a ClassPathResource instance
    // This is the most common way to load application resources
    @Value("classpath:myFile.txt")
    private Resource classpathResource;

    // ==================== URL RESOURCE ====================
    // Use "https://" (or "http://") to load resources from the web
    // Spring creates a UrlResource instance
    // Useful for loading remote configuration, data files, or documentation
    @Value("https://raw.githubusercontent.com/danvega/danvega/refs/heads/master/README.md")
    private Resource urlResource;

    // ==================== FILE SYSTEM RESOURCE ====================
    // Use "file:" with "./" for paths relative to the working directory
    // Spring creates a FileUrlResource instance
    // The working directory is typically where you run the application from
    // Note: For absolute paths, use "file:/absolute/path/to/file.txt"
    @Value("file:./data/config.txt")
    private Resource fileResource;

    /**
     * GET /
     * Demonstrates loading a text file from the classpath.
     * The file myFile.txt is located in src/main/resources/
     */
    @GetMapping
    public String getClasspathResource() throws IOException {
        return new String(classpathResource.getContentAsByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * GET /classpath
     * Demonstrates using ClassPathResource directly instead of @Value injection.
     *
     * You can instantiate Resource implementations directly when:
     * - You need to create resources programmatically (e.g., in a loop or based on logic)
     * - You're in a non-Spring-managed class (no @Value available)
     * - You prefer explicit control over the resource type
     *
     * Available implementations: ClassPathResource, FileSystemResource, UrlResource, etc.
     */
    @GetMapping("/classpath")
    public String getClasspathResource2() throws IOException {
        Resource resource = new ClassPathResource("myFile.txt");
        return new String(resource.getContentAsByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * GET /readme
     * Demonstrates loading a resource from a remote URL.
     * Fetches the README.md from a GitHub repository.
     */
    @GetMapping("/readme")
    public String getUrlResource() throws IOException {
        return new String(urlResource.getContentAsByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * GET /file
     * Demonstrates loading a file from the filesystem.
     * The file is loaded relative to the application's working directory.
     */
    @GetMapping("/file")
    public String getFileResource() throws IOException {
        return new String(fileResource.getContentAsByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * GET /info
     * Demonstrates the metadata methods available on the Resource interface.
     * Shows filename, existence check, readability, and description.
     */
    @GetMapping("/info")
    public String getResourceInfo() throws IOException {
        StringBuilder info = new StringBuilder();

        info.append("=== Classpath Resource (myFile.txt) ===\n");
        info.append("Filename: ").append(classpathResource.getFilename()).append("\n");
        info.append("Exists: ").append(classpathResource.exists()).append("\n");
        info.append("Readable: ").append(classpathResource.isReadable()).append("\n");
        info.append("Description: ").append(classpathResource.getDescription()).append("\n");
        info.append("Class: ").append(classpathResource.getClass().getSimpleName()).append("\n\n");

        info.append("=== File Resource (data/config.txt) ===\n");
        info.append("Filename: ").append(fileResource.getFilename()).append("\n");
        info.append("Exists: ").append(fileResource.exists()).append("\n");
        info.append("Readable: ").append(fileResource.isReadable()).append("\n");
        info.append("Description: ").append(fileResource.getDescription()).append("\n");
        info.append("Class: ").append(fileResource.getClass().getSimpleName()).append("\n\n");

        info.append("=== URL Resource (GitHub README) ===\n");
        info.append("Filename: ").append(urlResource.getFilename()).append("\n");
        info.append("Exists: ").append(urlResource.exists()).append("\n");
        info.append("Readable: ").append(urlResource.isReadable()).append("\n");
        info.append("Description: ").append(urlResource.getDescription()).append("\n");
        info.append("Class: ").append(urlResource.getClass().getSimpleName()).append("\n");

        return info.toString();
    }

}
```

### 参考资料

[]()
