# 安全政策

## 支持范围

安全修复优先应用于默认分支中的最新源码。旧版本和自行修改的构建不保证获得修复。

## 私密报告漏洞

请不要通过公开 Issue、Pull Request 或讨论区披露尚未修复的漏洞。请使用 GitHub 的私密漏洞报告：

[提交私密安全报告](https://github.com/LaoChouPro/Open-Terminal-in-Finder/security/advisories/new)

如果该功能不可用，请先创建一个不包含漏洞细节的 Issue，请求维护者提供私密联系方式。

报告请尽量包含：

- 受影响的版本或提交 SHA。
- macOS 版本和 CPU 架构。
- 复现步骤及实际影响。
- 建议的修复方式（如果有）。
- 是否已公开或正在被利用。

请使用测试环境验证，不要访问、修改或删除他人的数据，也不要对真实用户实施拒绝服务。维护者会尽快确认报告，并在修复期间与你协调披露时间。

## 安全边界

FinderTerminal 在本地处理目录路径，并调用系统“终端”App。正常构建不需要网络服务或第三方运行时依赖。FinderSync 扩展使用沙盒和只读的用户选择文件权限。

构建脚本使用临时签名，不提供 Developer ID 身份验证或 Apple 公证。请只运行你信任的源码和脚本；分发预编译 App 时，发布者应使用自己的 Developer ID 签名并完成公证。

## 安装脚本注意事项

`Scripts/install.sh` 会替换 `/Applications/FinderTerminal.app`、终止正在运行的 FinderTerminal、修改当前用户的 Finder 扩展注册并重启访达。仅在理解这些操作后运行；CI 和仅构建场景使用 `Scripts/build.sh`。
