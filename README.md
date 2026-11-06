# 访达右键终端 (FinderTerminal)

极简、稳定的 macOS 原生小工具：在访达（Finder）任意位置右键，即可在上下文菜单中点击 **“在终端中打开这里”**，并在当前目录下开启一个全新的 macOS 终端窗口。

## 功能特性

- **纯原生体验**：基于 Apple 官方 `FinderSync` 扩展框架深度定制，无需辅助功能权限（Accessibility）或复杂的 AppleScript 模拟点击。
- **全场景支持**：
  - 右键任意文件夹：在该文件夹下打开终端。
  - 右键任意文件：在该文件所在目录打开终端。
  - 右键窗口空白处：在当前浏览目录打开终端。
  - 右键桌面背景：在桌面目录（`~/Desktop`）打开终端。
- **不在 Dock 栏驻留**：`LSUIElement = true`，不占用 Dock 栏或应用切换器空间，仅在顶部菜单栏显示精致的小终端图标。
- **状态栏菜单管理**：
  - **开机自启动**：支持一键勾选/取消开机自动启动（采用现代 `SMAppService` 与用户级 `LaunchAgent` 双重可靠机制）。
  - **扩展状态检测**：实时显示访达扩展的激活状态。
  - **一键跳转扩展设置**：直接打开系统设置中的扩展管理面板。
  - **重启访达**：一键刷新访达进程，使扩展立即生效。
  - **退出应用**：随时完全退出。
- **独立专属应用图标**：附带精美暗色微光终端 Squircle App 图标及 Retina 适配。

---

## 项目结构

```
.
├── FinderTerminal/                  # 主程序（菜单栏 Agent）
│   ├── main.swift                   # 入口文件
│   ├── AppDelegate.swift            # 状态栏菜单与 URL Scheme 事件处理
│   ├── LaunchAtLogin.swift          # 开机自启动管理
│   └── Info.plist                   # 主应用配置 (LSUIElement=true, URL Schemes)
├── FinderTerminalExtension/         # 访达右键扩展 (FIFinderSync)
│   ├── FinderSync.swift             # 右键菜单注入与目录解析
│   ├── Info.plist                   # 扩展配置 (com.apple.FinderSync)
│   └── FinderTerminalExtension.entitlements # 沙盒与文件权限配置
├── Resources/
│   ├── generate_icons.py            # 高分辨率 AppIcon.icns 生成脚本
│   └── AppIcon.icns                 # macOS 原生图标
├── build_and_install.sh             # 自动化构建、代码签名与安装脚本
└── README.md
```

---

## 安装与构建

项目已自带一键编译安装脚本，终端运行：

```bash
chmod +x build_and_install.sh
./build_and_install.sh
```

脚本将自动完成：
1. 编译 App Extension 与主程序
2. 注入专属沙盒授权并进行签名
3. 安装至 `/Applications/FinderTerminal.app`
4. 注册并启用访达扩展
5. 重启访达并启动菜单栏应用

---

## 系统设置说明

在 macOS 14 / 15+ 中，若首次使用右键未出现菜单项：
1. 点击顶部菜单栏的终端小图标。
2. 点击 **“打开系统扩展设置...”**（或进入 **系统设置 -> 登录项与扩展 -> 访达扩展**）。
3. 确保勾选 **FinderTerminalExtension**（在终端中打开这里）。
4. 点击菜单中的 **“重启访达以刷新扩展”** 即可。
