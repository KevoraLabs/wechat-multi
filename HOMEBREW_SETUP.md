# Homebrew Setup

这份文档用于把 `wechat-multi` 接入自定义 Homebrew tap。

目标效果：

- 用户可以执行 `brew install --cask KevoraLabs/tap/wechat-multi`
- 安装来源是 `KevoraLabs/wechat-multi` 的 GitHub Release
- cask 文件维护在 `KevoraLabs/homebrew-tap`

## 一、tap 仓库结构

目标仓库：

- `KevoraLabs/homebrew-tap`

目录结构至少需要这样：

```text
homebrew-tap/
  Casks/
    wechat-multi.rb
```

说明：

- 仓库名使用 `homebrew-tap`，用户执行 `brew tap KevoraLabs/tap` 时会自动映射到这个仓库
- cask 文件放在 `Casks/` 目录里

参考文档：

- [Homebrew Taps](https://docs.brew.sh/Taps)
- [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)

## 二、cask 文件

在 `KevoraLabs/homebrew-tap/Casks/wechat-multi.rb` 写入：

```ruby
cask "wechat-multi" do
  version "0.1.3"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/KevoraLabs/wechat-multi/releases/download/v#{version}/wechat-multi-#{version}.dmg",
      verified: "github.com/KevoraLabs/wechat-multi/"
  name "WeChatMulti"
  desc "Launch multiple WeChat instances on macOS"
  homepage "https://github.com/KevoraLabs/wechat-multi"

  app "WeChatMulti.app"
end
```

## 三、Release 产物要求

为了让 Homebrew 配置最简单，`wechat-multi` 仓库发布时建议满足这两个条件：

1. Git tag 形式固定为：

```bash
v0.1.3
```

2. GitHub Release 资产名固定为：

```bash
wechat-multi-0.1.3.dmg
```

也就是：

```text
https://github.com/KevoraLabs/wechat-multi/releases/download/v0.1.3/wechat-multi-0.1.3.dmg
```

不要把内部 build number 放进 Homebrew 下载 URL。  
Homebrew 只关心用户可安装的发布版本，不关心你的内部构建号。

## 四、用户安装方式

用户可以这样安装：

```bash
brew tap KevoraLabs/tap
brew install --cask wechat-multi
```

或者一步完成：

```bash
brew install --cask KevoraLabs/tap/wechat-multi
```

升级：

```bash
brew upgrade --cask wechat-multi
```

卸载：

```bash
brew uninstall --cask wechat-multi
```

## 五、每次发版如何更新

每次 `wechat-multi` 发布新版本后，需要同步更新 `homebrew-tap` 里的 cask：

1. 确认 GitHub Release 已经生成
2. 拿到新版本号，例如 `0.1.4`
3. 拿到新的 DMG 下载地址
4. 计算 DMG 的 `sha256`
5. 更新 `Casks/wechat-multi.rb` 里的：

- `version`
- `sha256`
- `url`

例如：

```ruby
cask "wechat-multi" do
  version "0.1.4"
  sha256 "NEW_SHA256"

  url "https://github.com/KevoraLabs/wechat-multi/releases/download/v#{version}/wechat-multi-#{version}.dmg",
      verified: "github.com/KevoraLabs/wechat-multi/"
  name "WeChatMulti"
  desc "Launch multiple WeChat instances on macOS"
  homepage "https://github.com/KevoraLabs/wechat-multi"

  app "WeChatMulti.app"
end
```

然后提交到 `homebrew-tap`：

```bash
git add Casks/wechat-multi.rb
git commit -m "Update wechat-multi to 0.1.4"
git push origin main
```

## 六、本地验证

改完 cask 后，本地可以这样验证：

```bash
brew tap KevoraLabs/tap /path/to/homebrew-tap
brew install --cask --verbose wechat-multi
```

或者直接审核：

```bash
brew audit --cask --tap KevoraLabs/tap wechat-multi
```

## 七、注意事项

1. Homebrew 安装不等于绕过 macOS 安全校验。  
   如果应用没有经过 Apple notarization，用户第一次打开仍可能遇到 Gatekeeper 提示。

2. `sha256` 必须和 Release 里的 `.dmg` 完全一致。  
   只要 DMG 内容变了，就必须重新计算。

3. 版本号、tag、下载文件名最好保持一一对应。  
   推荐固定规则：

```text
tag: v0.1.3
version: 0.1.3
asset: wechat-multi-0.1.3.dmg
```

4. 如果已经配置了 `HOMEBREW_TAP_TOKEN`，可以在 `wechat-multi` 的 GitHub Actions 里：

- checkout `KevoraLabs/homebrew-tap`
- 更新 `Casks/wechat-multi.rb`
- 直接提交回 `main`，或按需改成自动创建 PR

当前仓库已经可以按这个方向配置；如果不提供 secret，则继续走手动维护。
