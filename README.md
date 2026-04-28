**简体中文** | [English](README.en.md)

# Snoopy for macOS

一个将 Apple TV / tvOS 上的 Snoopy 屏幕保护移植到 macOS 的项目。

这个项目的目标很简单：在 macOS 上尽可能还原 tvOS 版本的 Snoopy 屏保播放效果，包括背景图、透明视频图层、片段切换和随机播放体验。

## 项目目的

- 将 tvOS 上的 Snoopy 屏幕保护迁移为可在 macOS 上安装的 `.saver` 屏保插件
- 保留原始素材的视觉风格与播放节奏
- 在 macOS 的屏保运行机制下，重建片段编排、循环播放与背景切换逻辑
- 提供一个可继续维护和调试的开源工程

## 技术栈

- `Objective-C`
- `ScreenSaver.framework`
- `SpriteKit`
- `AVFoundation`
- `AVKit`
- `Xcode`

## 技术实现概览

项目当前主要由以下几部分组成：

- [`snoopyView`](/Users/yichen/Documents/git/Snoopy/snoopy/snoopyView.h) / [`snoopyView.m`](/Users/yichen/Documents/git/Snoopy/snoopy/snoopyView.m)
  - 屏保入口类
  - 负责初始化 `ScreenSaverView`、`SKView`、`SKScene`
  - 管理视频播放、背景切换和屏保生命周期
- [`Clip.h`](/Users/yichen/Documents/git/Snoopy/snoopy/Clip.h) / [`Clip.m`](/Users/yichen/Documents/git/Snoopy/snoopy/Clip.m)
  - 负责扫描已打包进屏保 bundle 的 `.mov` 文件
  - 按 clip 分组素材
  - 生成每个 clip 的播放顺序与随机编排结果

## 播放方案

这个项目不是简单把视频连续播出来，而是在 macOS 屏保环境里重新搭了一层播放逻辑：

- 使用 `SKVideoNode` 在 `SpriteKit` 场景中播放带 alpha 的视频
- 使用 `AVQueuePlayer` 维护 clip 内部的连续播放队列
- 使用 `Clip` 模型组织 `Intro / Loop / Outro / Others` 这类素材结构
- 使用背景色和背景图节点来模拟 tvOS 屏保的底层视觉
- 在 clip 边界上单独处理切换，减少闪烁和残影

## 构建方式

可以直接用 Xcode 打开工程：

- 打开 [`snoopy.xcodeproj`](/Users/yichen/Documents/git/Snoopy/snoopy.xcodeproj)
- 选择 `snoopy` Scheme
- 以 `Release` 配置构建

也可以使用命令行：

```bash
xcodebuild -project snoopy.xcodeproj -scheme snoopy -configuration Release build
```

构建产物为一个 macOS 屏保 bundle：

- `snoopy.saver`

## 素材说明

- 仓库不包含完整视频素材
- 相关视频文件未上传到 GitHub，主要原因是版权限制和文件体积较大
- 项目中的播放逻辑仍然保留了对这些素材的支持

## 项目定位

这是一个面向 macOS 的 Snoopy 屏保移植项目，重点在于：

- 还原 tvOS 版本的视觉体验
- 解决 macOS 屏保环境下的视频播放问题
- 为后续继续优化 clip 切换、资源组织和稳定性留出清晰的工程结构

## 历史版本说明

### v0.2.1

拖了好久，终于有时间搞一搞，解决了，都解决了。

这个版本解决了 `legacyScreenSaver` 的内存问题。原来 macOS 在关闭屏保时并不会调用 `stopAnimation()`，而是会发出 `com.apple.screensaver.willstop` 通知。

### v0.1.1

这个版本还有一些问题，有时会黑屏，运行久了也会卡顿。当时判断大概率和 `AVQueuePlayer` 的队列管理有关。

同时由于 macOS 的屏保机制，安装新版本之后有时需要重启系统才能生效。

这一版改用了 `SpriteKit` 播放视频，并支持 HEVC alpha 通道来显示背景。

## English Version

See [README.en.md](README.en.md).
