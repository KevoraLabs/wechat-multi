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

## 本地运行

```bash
cd /Users/kevin/Developer/Code/side-project/apps/macos/WeChatMulti
xcodegen generate
open WeChatMulti.xcodeproj
```

然后在 Xcode 里直接 `Run`。
