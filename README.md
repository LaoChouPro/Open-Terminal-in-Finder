# FinderTerminal — 访达右键终端

[![Build](https://github.com/LaoChouPro/Open-Terminal-in-Finder/actions/workflows/build.yml/badge.svg)](https://github.com/LaoChouPro/Open-Terminal-in-Finder/actions/workflows/build.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black)](https://www.apple.com/macos/)
[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一个轻量的 macOS 原生工具：在访达中右键文件、文件夹或空白处，选择 **“在终端中打开这里”**，即可在对应目录打开新的终端窗口。

FinderTerminal 使用 Apple 的 `FinderSync` 扩展框架，不需要辅助功能权限，也不模拟鼠标或键盘操作。菜单栏宿主 App 负责打开终端、管理开机自启动和检查扩展状态。

## 功能

- 右键文件夹：在该文件夹中打开终端。
- 右键文件：在文件所在目录打开终端。
- 右键文件夹空白处或桌面：在当前目录打开终端。
- 菜单栏图标：查看扩展状态、打开扩展设置或重启访达。
- 可选开机自启动。
- 不占用 Dock 和应用切换器。
- 支持 Apple Silicon 和 Intel Mac（按当前机器架构从源码构建）。

## 系统要求

- macOS 14.0 或更高版本
- Xcode Command Line Tools
- macOS 自带的“终端” App

检查编译工具是否已安装：

```bash
xcode-select -p
```

如果未安装，运行 `xcode-select --install`。

## 安装

```bash
git clone https://github.com/LaoChouPro/Open-Terminal-in-Finder.git
cd Open-Terminal-in-Finder
./Scripts/install.sh
```

安装脚本会：

1. 从源码编译主 App 和 FinderSync 扩展。
2. 使用临时签名（ad-hoc signature）签名。
3. 替换 `/Applications/FinderTerminal.app`。
4. 注册并启用扩展，重启访达，然后启动菜单栏 App。

**注意：** 安装会关闭正在运行的 FinderTerminal，并重启访达。请先保存访达中正在进行的文件操作。

如果右键菜单没有出现：

1. 点击菜单栏中的终端图标。
2. 选择“打开系统扩展设置...”。
3. 在“登录项与扩展 → 访达扩展”中启用 **FinderTerminalExtension**。
4. 回到菜单栏菜单，选择“重启访达以刷新扩展”。

## 仅构建

构建不会安装 App、重启访达或修改系统扩展设置：

```bash
./Scripts/build.sh
```

产物位于：

```text
build/FinderTerminal.app
```

默认构建当前机器的架构。也可以显式指定：

```bash
ARCH=arm64 ./Scripts/build.sh
ARCH=x86_64 ./Scripts/build.sh
```

## 使用

安装并启用扩展后，在访达中右键并选择 **“在终端中打开这里”**。菜单栏 App 会收到扩展传来的目录，并调用系统“终端”打开它。

## 项目结构

```text
.
├── FinderTerminal/                 # 菜单栏宿主 App
│   ├── AppDelegate.swift            # 菜单、URL Scheme 和终端调用
│   ├── LaunchAtLogin.swift          # 开机自启动
│   ├── main.swift                   # App 入口
│   └── Info.plist
├── FinderTerminalExtension/         # FinderSync 扩展
│   ├── FinderSync.swift             # 右键菜单和目录解析
│   ├── FinderTerminalExtension.entitlements
│   └── Info.plist
├── Resources/                       # App 图标及可选生成脚本
├── Scripts/
│   ├── build.sh                     # 仅编译、打包和签名
│   └── install.sh                   # 构建并安装到 /Applications
├── .github/                         # CI 与社区模板
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
└── SECURITY.md
```

## 开发与验证

```bash
# 检查脚本和 plist
bash -n Scripts/build.sh Scripts/install.sh
plutil -lint FinderTerminal/Info.plist \
  FinderTerminalExtension/Info.plist \
  FinderTerminalExtension/FinderTerminalExtension.entitlements

# 完整构建并验证签名
./Scripts/build.sh
codesign --verify --deep --strict --verbose=2 build/FinderTerminal.app
```

贡献代码前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。当前自动化验证覆盖脚本、plist、编译、Bundle 结构和签名；Finder 右键菜单仍需在真实 macOS 桌面中人工确认。

### 重新生成图标（可选）

正常构建不需要 Python。只有重新生成图标时才需要 Python 3 和 Pillow：

```bash
python3 -m pip install Pillow
python3 Resources/generate_icons.py
```

## 签名与分发

构建脚本使用临时签名，适合本地构建和使用，不等同于 Developer ID 签名或公证。如果要向其他用户分发预编译 App，请使用自己的 Developer ID 证书签名并按 Apple 要求公证。

## 卸载

1. 从菜单栏菜单退出 FinderTerminal。
2. 在“系统设置 → 登录项与扩展 → 访达扩展”中停用 FinderTerminalExtension。
3. 删除 `/Applications/FinderTerminal.app`。
4. 如果曾启用开机自启动，先在菜单栏菜单中取消“开机自启动”。

## 社区与安全

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全政策](SECURITY.md)
- [更新日志](CHANGELOG.md)

## 许可证

本项目采用 [MIT License](LICENSE)。
