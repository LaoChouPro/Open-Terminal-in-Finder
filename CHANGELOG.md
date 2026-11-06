# 更新日志

本文件记录 FinderTerminal 的重要变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## 未发布

### 变更

- 整理为标准开源项目结构，补充社区文档、GitHub 模板和 macOS 构建工作流。
- 将构建与安装分离；仅构建不再修改 `/Applications`、重启访达或更改扩展设置。
- 编译产物移出版本控制，并增加 macOS、Xcode 和 Python 忽略规则。
- 构建脚本支持通过 `ARCH=arm64` 或 `ARCH=x86_64` 指定本机编译架构。

## 1.0.0 - 2026-11-06

### 新增

- 基于 FinderSync 的文件、文件夹和空白处右键菜单。
- 通过菜单栏宿主 App 和 URL Scheme 在对应目录打开终端。
- 扩展状态检查、系统扩展设置入口和重启访达功能。
- 可选开机自启动。
- 自定义 App 图标及源码构建、签名和安装流程。
