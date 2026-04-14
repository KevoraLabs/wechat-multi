# WeChatMulti

一个只驻留在菜单栏的 macOS 小工具，用来生成并启动额外的微信实例。

## 当前版本能力

- 菜单栏常驻，无主窗口，不出现在 Dock
- 自动检测主微信安装位置
- 一键复制到 `~/Applications/WeChat-2.app`
- 自动修改副本的 `CFBundleIdentifier`
- 自动重签名副本
- 单独启动主微信 / 微信副本 / 同时启动两个实例
- 删除副本
- 打开日志文件

## 设计取舍

第一版不写入 `/Applications`，而是固定写入用户目录下的 `~/Applications`：

- 不需要 `sudo`
- 不需要特权 helper
- 更适合状态栏工具的轻量使用方式

## 打开应用

当前 GitHub Release 提供的安装包还没有做 Apple notarization。第一次打开如果看到“Apple 无法验证 `WeChatMulti.app` 是否包含恶意软件”之类的提示，在确认安装包来源可信后，可以手动移除隔离属性：

```bash
xattr -dr com.apple.quarantine /Applications/WeChatMulti.app
```

如果你把应用放在别的位置，把路径替换成实际的 `.app` 路径即可，例如：

```bash
xattr -dr com.apple.quarantine ~/Downloads/WeChatMulti.app
```

## 本地运行

```bash
cd /Users/kevin/Developer/Code/side-project/apps/macos/WeChatMulti
xcodegen generate
open WeChatMulti.xcodeproj
```

然后在 Xcode 里直接 `Run`。

## 打包发布包

```bash
./scripts/package-app.sh
```

脚本会：

- 在缺少工程文件时自动执行 `xcodegen generate`
- 构建 `Release` 版本
- 输出 `dist/WeChatMulti-版本号-构建号.dmg`
- 打印对应的 SHA256，后续可直接填到 Homebrew cask

## GitHub Actions 发版

自动化放在 `wechat-multi` 仓库本身，通过推 tag 发版：

完整步骤见 [RELEASE.md](/Users/kevin/Developer/Code/wechat-multi/RELEASE.md:1)。

```bash
git tag v0.1.0
git push origin v0.1.0
```

这里的 tag 去掉前缀 `v` 后，必须和 `project.yml` 里的 `MARKETING_VERSION` 一致；workflow 会做这个校验，不一致就直接失败。

`/.github/workflows/release.yml` 会自动执行这条链路：

- 构建 `.app`
- 打包成 GitHub Release 资产 `wechat-multi-版本号.dmg`
- 创建 GitHub Release 并上传 DMG
- 计算 SHA256
- 如果配置了 `HOMEBREW_TAP_TOKEN`，自动更新 `KevoraLabs/homebrew-tap` 的 `Casks/wechat-multi.rb`

### 半自动

没有配置 `HOMEBREW_TAP_TOKEN` 时：

- release 会自动生成
- Homebrew tap 不会自动改
- 你可以从 workflow Summary 里直接拿到 `version`、DMG 地址和 `sha256`，手动更新 tap

### 全自动

配置了 `HOMEBREW_TAP_TOKEN` 后：

- release 会自动生成
- workflow 会自动提交 `KevoraLabs/homebrew-tap/Casks/wechat-multi.rb`
- cask 会自动同步新的 `version`、下载地址和 `sha256`
