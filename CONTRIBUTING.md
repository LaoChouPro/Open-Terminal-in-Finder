# 贡献指南

感谢你为 FinderTerminal 做出贡献！无论是报告问题、改进文档，还是提交代码，都欢迎参与。

## 开始之前

- 使用 macOS 14.0 或更高版本，并安装 Xcode Command Line Tools。
- 搜索已有 Issue 和 Pull Request，避免重复工作。
- 对较大的功能或行为变更，先创建 Issue 讨论方案。
- 一个 Pull Request 只处理一个主题，避免混入无关格式化或重构。

## 本地开发

```bash
git clone https://github.com/LaoChouPro/Open-Terminal-in-Finder.git
cd Open-Terminal-in-Finder
./Scripts/build.sh
```

构建产物位于 `build/FinderTerminal.app`。`build/` 已被 Git 忽略，不要提交编译产物、签名文件或本地 IDE 配置。

需要验证 Finder 集成时，再运行：

```bash
./Scripts/install.sh
```

该命令会替换 `/Applications/FinderTerminal.app`、关闭正在运行的 FinderTerminal 并重启访达。不要在运行测试或 CI 时使用安装脚本。

## 提交前检查

```bash
bash -n Scripts/build.sh Scripts/install.sh
plutil -lint FinderTerminal/Info.plist \
  FinderTerminalExtension/Info.plist \
  FinderTerminalExtension/FinderTerminalExtension.entitlements
./Scripts/build.sh
codesign --verify --deep --strict --verbose=2 build/FinderTerminal.app
git diff --check
```

如果修改了扩展菜单、目录解析、URL Scheme、开机自启动或安装逻辑，还请人工验证对应场景，并在 Pull Request 中说明：

- 测试的 macOS 版本和 CPU 架构。
- 文件、文件夹、空白处和桌面等已测试场景。
- 未能验证的场景。

## 代码风格

- 遵循现有 Swift、Shell 和 plist 文件的命名与缩进。
- Swift 使用 4 个空格缩进；YAML 使用 2 个空格缩进。
- 保持实现简单，优先使用 Apple 官方 API。
- 不引入与功能无关的依赖。
- 注释解释“为什么”，避免复述代码。
- 不在日志、Issue 或提交中包含用户路径、令牌或其他敏感信息。

## 提交与 Pull Request

1. 从最新默认分支创建主题分支。
2. 使用清晰、聚焦的提交；推荐使用 Conventional Commits，例如 `fix: handle file selections correctly`。
3. 更新受影响的 README、CHANGELOG 或其他文档。
4. 完成上述检查并填写 Pull Request 模板。
5. 关联相关 Issue，说明行为变化和验证结果。

项目采用 MIT 许可证。提交贡献即表示你同意贡献内容按同一许可证发布。

## 安全问题

请勿通过公开 Issue 报告未公开的安全漏洞，改用 [SECURITY.md](SECURITY.md) 中的私密渠道。
