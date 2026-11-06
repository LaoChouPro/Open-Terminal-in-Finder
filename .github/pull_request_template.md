## 说明

<!-- 简要说明这个 PR 解决了什么问题，以及为什么采用这个方案。 -->

关联 Issue：<!-- 例如 Fixes #123；没有可删除此行。 -->

## 变更

-
-

## 验证

<!-- 填写实际执行过的命令和人工测试；不要勾选未执行的项目。 -->

- [ ] `bash -n Scripts/build.sh Scripts/install.sh`
- [ ] `plutil -lint` 检查所有 plist 和 entitlements
- [ ] `./Scripts/build.sh`
- [ ] `codesign --verify --deep --strict --verbose=2 build/FinderTerminal.app`
- [ ] 已在 Finder 中人工验证受影响的功能

测试环境：<!-- macOS 版本、CPU 架构 -->

## 文档与兼容性

- [ ] 已更新受影响的文档和 CHANGELOG
- [ ] 未提交 build/、签名文件或本地配置
- [ ] 已说明行为变更、迁移步骤或未验证的风险

## 补充信息

<!-- 截图、日志摘要、已知限制或后续工作。请勿包含私人路径或敏感信息。 -->
