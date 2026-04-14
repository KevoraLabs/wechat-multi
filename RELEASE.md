# Release Guide

`wechat-multi` 的发版自动化放在当前仓库，通过推送 `v*` tag 触发。

## 一次性准备

先把自动化代码提交到主仓库：

```bash
git status
git add .github/workflows/release.yml scripts/package-app.sh scripts/update-homebrew-cask.sh README.md RELEASE.md
git commit -m "Add tag-driven release automation"
git push origin main
```

如果要让 release 自动同步 Homebrew tap，需要先配置 Actions secret：

1. 打开 `KevoraLabs/wechat-multi`
2. 进入 `Settings > Secrets and variables > Actions`
3. 新建 secret：`HOMEBREW_TAP_TOKEN`
4. 这个 token 需要能访问 `KevoraLabs/homebrew-tap`，并具备提交代码和创建 PR 的权限

现在 workflow 会在 secret 存在时自动更新 `KevoraLabs/homebrew-tap`。

## 每次发版

### 1. 更新版本号

修改 [project.yml](/Users/kevin/Developer/Code/wechat-multi/project.yml:1) 里的：

- `MARKETING_VERSION`
- 如有需要，更新 `CURRENT_PROJECT_VERSION`

例如：

```yml
MARKETING_VERSION: 0.1.1
CURRENT_PROJECT_VERSION: 2
```

### 2. 提交并推送代码

```bash
git add project.yml
git commit -m "Bump version to 0.1.1"
git push origin main
```

### 3. 打 tag 并推送

```bash
git tag v0.1.1
git push origin v0.1.1
```

注意：

- tag 去掉前缀 `v` 后，必须和 `MARKETING_VERSION` 完全一致
- 例如 `MARKETING_VERSION: 0.1.1` 对应 `git tag v0.1.1`
- 如果不一致，GitHub Actions 会直接失败

## Workflow 会自动做什么

推送 tag 后，`/.github/workflows/release.yml` 会自动执行：

1. checkout 当前仓库
2. 安装 `xcodegen`
3. 构建 Release 版 `.app`
4. 打包为 `wechat-multi-版本号.dmg`
5. 计算安装包 `sha256`
6. 创建 GitHub Release 并上传 DMG
7. 在 workflow Summary 输出可用于 Homebrew cask 的版本号、下载地址和 `sha256`
8. 如果配置了 `HOMEBREW_TAP_TOKEN`，自动更新 `KevoraLabs/homebrew-tap/Casks/wechat-multi.rb`

## 两种发布模式

### 半自动

不配置 `HOMEBREW_TAP_TOKEN` 时：

- GitHub Release 自动完成
- 你手动更新 `homebrew-tap` 的 cask
- workflow Summary 里会直接给出 `version`、下载地址和 `sha256`

### 全自动

配置 `HOMEBREW_TAP_TOKEN` 后，workflow 会：

- checkout `KevoraLabs/homebrew-tap`
- 更新 `Casks/wechat-multi.rb`
- 直接提交并推送到 `main`

## 手动更新 Homebrew tap

如果当前是半自动模式，可以从 release 产物里拿到：

- version
- 下载地址
- sha256

然后手动更新 `KevoraLabs/homebrew-tap` 里的 `Casks/wechat-multi.rb`。

仓库里也提供了本地辅助脚本：

```bash
./scripts/update-homebrew-cask.sh \
  --cask-file /path/to/homebrew-tap/Casks/wechat-multi.rb \
  --version 0.1.1 \
  --sha256 <sha256> \
  --url https://github.com/KevoraLabs/wechat-multi/releases/download/v0.1.1/wechat-multi-0.1.1.dmg
```
