---
title: Spring 模板页面
date: 2025-08-05 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-template
no_word_count: true
no_toc: false
categories: Spring
---

## Spring 模板页面

### 简介

在遇到简单需求的时候，无需使用复杂的前端框架，用 HTML + CSS 方式就可以实现页面了。

### 使用方式

在 Spring 依赖中添加如下项目：

- Spring Web
- Thymeleaf
- htmx
- Lombok

之后编写数据模型：

`UserSettings.java`

```java
import lombok.Data;

@Data
public class UserSettings {
    private String username;
    private String email;
    private String password; // 注意：实际项目中密码处理更复杂
    private boolean darkMode;
    private boolean notificationsEnabled;
    private boolean autoSave;
}
```

`Report.java`

```java
import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDate;

@Data
@AllArgsConstructor
public class Report {
    private String name;
    private String status;
    private LocalDate createdAt;
}
```

`DashboardController.java`

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class DashboardController {
    
    @GetMapping("/dashboard/content")
    public String getDashboardContent(Model model) {
        model.addAttribute("totalUsers", 12345);
        model.addAttribute("activeUsers", 8765);
        model.addAttribute("revenue", 45678.0);
        model.addAttribute("userGrowth", 12.0); // %
        model.addAttribute("activeGrowth", 8.0);
        model.addAttribute("revenueGrowth", 15.0);
        return "dashboard/content :: content";
    }
}
```

`ReportController.java`

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

@Controller
public class ReportController {

    @GetMapping("/reports/content")
    public String getReportsContent(Model model) {
        List<Report> reports = Arrays.asList(
                new Report("月度销售报告", "COMPLETED", LocalDate.of(2025, 7, 1)),
                new Report("用户行为分析", "PROCESSING", LocalDate.of(2025, 7, 15)),
                new Report("市场趋势预测", "PENDING", LocalDate.of(2025, 8, 1))
        );
        model.addAttribute("reports", reports);
        return "reports/content :: content";
    }

}
```

`SettingsController.java`

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class SettingsController {

    @GetMapping("/settings/content")
    public String getSettingsContent(Model model) {
        UserSettings settings = new UserSettings();
        settings.setUsername("john_doe");
        settings.setEmail("john@example.com");
        settings.setDarkMode(false);
        settings.setNotificationsEnabled(true);
        settings.setAutoSave(true);
        model.addAttribute("userSettings", settings);
        return "settings/content :: content";
    }
    
    @PostMapping("/settings/update")
    public String updateSettings(@ModelAttribute UserSettings userSettings) {
        System.out.println("更新设置: " + userSettings);
        return "redirect:/settings/content?success=true";
    }

}
```

`MainController.java`

```java
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class MainController {
    
    @GetMapping("/")
    public String showMainPage() {
        return "main";
    }

}
```

之后还需要编辑前端页面：

`resource/template/dashboard/content.html`

```html
<div th:fragment="content" id="dashboard-content" class="space-y-6">
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <!-- Metric Cards -->
        <div class="bg-white p-4 rounded-lg shadow-md flex items-center space-x-4">
            <span class="text-green-500 text-3xl">
                <i class="fas fa-users"></i>
            </span>
            <div>
                <p class="text-gray-500">总用户数</p>
                <h3 class="text-2xl font-bold" th:text="${totalUsers}">12,345</h3>
            </div>
        </div>
        <div class="bg-white p-4 rounded-lg shadow-md flex items-center space-x-4">
            <span class="text-blue-500 text-3xl">
                <i class="fas fa-chart-line"></i>
            </span>
            <div>
                <p class="text-gray-500">活跃用户</p>
                <h3 class="text-2xl font-bold" th:text="${activeUsers}">8,765</h3>
            </div>
        </div>
        <div class="bg-white p-4 rounded-lg shadow-md flex items-center space-x-4">
            <span class="text-yellow-500 text-3xl">
                <i class="fas fa-dollar-sign"></i>
            </span>
            <div>
                <p class="text-gray-500">收入</p>
                <h3 class="text-2xl font-bold" th:text="'$' + ${revenue}">$45,678.00</h3>
            </div>
        </div>
        <div class="bg-white p-4 rounded-lg shadow-md flex items-center space-x-4">
            <span class="text-red-500 text-3xl">
                <i class="fas fa-percentage"></i>
            </span>
            <div>
                <p class="text-gray-500">增长</p>
                <h3 class="text-2xl font-bold" th:text="${userGrowth} + '%'">12%</h3>
            </div>
        </div>
    </div>
</div>
```

`resource/template/reports/content.html`

```html
<div th:fragment="content" id="reports-content" class="space-y-6">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
        <tr>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                报告名称
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                状态
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                创建日期
            </th>
        </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200" th:each="report : ${reports}">
        <tr>
            <td class="px-6 py-4 whitespace-nowrap" th:text="${report.name}">月度销售报告</td>
            <td class="px-6 py-4 whitespace-nowrap" th:classappend="${report.status == 'COMPLETED'} ? 'text-green-500' : (${report.status == 'PROCESSING'} ? 'text-yellow-500' : 'text-red-500')" th:text="${report.status}">已完成</td>
            <td class="px-6 py-4 whitespace-nowrap" th:text="${report.createdAt}">2025-07-01</td>
        </tr>
        </tbody>
    </table>
</div>
```

`resource/template/settings/content.html`

```html
<div th:fragment="content" id="settings-content" class="space-y-6">
    <form method="post" action="/settings/update" hx-post="/settings/update" hx-target="#settings-content" hx-swap="innerHTML" class="space-y-4">
        <div>
            <label for="username" class="block text-sm font-medium text-gray-700">用户名</label>
            <input type="text" name="username" id="username" th:value="${userSettings.username}" class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
        </div>
        <div>
            <label for="email" class="block text-sm font-medium text-gray-700">电子邮件</label>
            <input type="email" name="email" id="email" th:value="${userSettings.email}" class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
        </div>
        <div>
            <label for="password" class="block text-sm font-medium text-gray-700">密码</label>
            <input type="password" name="password" id="password" class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
        </div>
        <div class="flex items-center space-x-2">
            <input type="checkbox" name="darkMode" id="darkMode" th:checked="${userSettings.darkMode}" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
            <label for="darkMode" class="block text-sm font-medium text-gray-700">暗模式</label>
        </div>
        <div class="flex items-center space-x-2">
            <input type="checkbox" name="notificationsEnabled" id="notificationsEnabled" th:checked="${userSettings.notificationsEnabled}" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
            <label for="notificationsEnabled" class="block text-sm font-medium text-gray-700">启用通知</label>
        </div>
        <div class="flex items-center space-x-2">
            <input type="checkbox" name="autoSave" id="autoSave" th:checked="${userSettings.autoSave}" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
            <label for="autoSave" class="block text-sm font-medium text-gray-700">自动保存</label>
        </div>
        <button type="submit" class="w-full bg-indigo-600 border border-transparent rounded-md shadow-sm py-2 px-4 text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            更新设置
        </button>
    </form>
</div>
```

`resource/template/main.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>HTMX Tabs</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/htmx.org@1.9.6"></script>
    <style>
        /* 自定义类：接近全屏的高度和宽度，四周留边 */
        .h-95vh {
            height: 95vh;
        }
        .w-95vw {
            width: 95vw;
        }
    </style>
</head>
<body class="bg-gradient-to-br from-blue-50 to-indigo-100 min-h-screen flex items-center justify-center p-4">
<!-- 修改：使用 95vw 宽度，减少 p-4 改为外层留白 -->
<div class="w-95vw h-95vh bg-white rounded-2xl shadow-xl overflow-hidden flex flex-col">
    <div class="flex-1 p-6 sm:p-8">
        <h1 class="text-4xl font-bold text-center text-gray-800 mb-10">完全分离的 Tab 示例</h1>

        <!-- Tab 导航 -->
        <div class="flex space-x-1 bg-gray-100 p-1 rounded-xl mb-8">
            <button
                    class="tab-button flex-1 text-lg font-medium text-gray-700 rounded-lg py-3 px-6 transition-all duration-200 hover:bg-white hover:shadow focus:outline-none"
                    hx-get="/dashboard/content"
                    hx-target="#tab-content-area"
                    hx-swap="innerHTML"
                    aria-selected="true">
                📊 仪表盘
            </button>
            <button
                    class="tab-button flex-1 text-lg font-medium text-gray-700 rounded-lg py-3 px-6 transition-all duration-200 hover:bg-white hover:shadow focus:outline-none"
                    hx-get="/reports/content"
                    hx-target="#tab-content-area"
                    hx-swap="innerHTML">
                📝 报告
            </button>
            <button
                    class="tab-button flex-1 text-lg font-medium text-gray-700 rounded-lg py-3 px-6 transition-all duration-200 hover:bg-white hover:shadow focus:outline-none"
                    hx-get="/settings/content"
                    hx-target="#tab-content-area"
                    hx-swap="innerHTML">
                ⚙️ 设置
            </button>
        </div>

        <div id="tab-content-area" class="min-h-64 p-6 bg-gray-50 rounded-xl border border-gray-200">
            <div class="text-center text-gray-400">
                <svg class="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <p class="text-lg">选择一个标签页开始</p>
            </div>
        </div>
    </div>
</div>

<!-- 初始化和状态管理脚本 -->
<script th:fragment="scripts">
  document.addEventListener('DOMContentLoaded', function () {
    const firstButton = document.querySelector('.tab-button');
    if (firstButton) {
      firstButton.click();
      firstButton.classList.add('active');
    }
  });

  document.body.addEventListener('htmx:afterOnLoad', function (evt) {
    document.querySelectorAll('.tab-button').forEach(btn => {
      btn.classList.remove('active');
    });
    evt.detail.elt.classList.add('active');
  });
</script>
</body>
</html>
```

### 参考资料

[面向 Spring Boot 开发者的 Htmx 的简介](https://blog.jetbrains.com/zh-hans/idea/2024/10/introduction-to-htmx-for-spring-boot-developers/)

[Spring Boot and Thymeleaf library for htmx](https://github.com/wimdeblauwe/htmx-spring-boot)
