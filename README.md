# GXU研课表

面向广西大学研究生的非官方开源校园信息查询应用。

当前版本由 `KIKO` 持续维护，围绕广西大学研究生的使用场景进行功能裁剪、品牌调整与体验优化；项目基于上游开源项目 `Traintime PDA / XDYou` 继续维护。

感谢原开发团队与历届贡献者提供的功能基础、历史积累与开源代码。

## 项目定位

- 当前版本面向：广西大学研究生
- 当前维护者：KIKO
- 当前维护仓库：`GaleBird/traintime_pda`
- 上游项目：Traintime PDA / XDYou
- 上游仓库：`BenderBlog/traintime_pda`

## 当前功能

- GXU 原生日程表 / 课程表
- GXU 成绩查询
- GXU 选课情况查询
- GXU 校园网用量查询
- 工具箱与常用校园入口
- 上课提醒与基础通知能力
- Android / iOS / Linux / Windows 多平台 Flutter 客户端

## 构建方式

优先使用仓库内固定的 Flutter SDK：

```bash
git submodule update --init --recursive
.flutter/bin/flutter pub get
.flutter/bin/flutter analyze
.flutter/bin/flutter test
.flutter/bin/flutter run -d windows
```

Android 构建示例：

```bash
.flutter/bin/flutter build apk --release --split-per-abi
```

## 版本与发布

- `pubspec.yaml` 中的 `version` 用于显示版本名
- `+build` 用于平台构建号，发布新版本时必须单调递增
- 软件内“检查更新”当前采用远端版本清单加外部下载链接的方式

## 开源与来源说明

- 当前 GXU 版本是独立维护线，不代表广西大学官方立场
- 项目继续保留上游开源来源说明
- 仓库保留 `LICENSE` 与源码文件中的版权头说明

## 授权

本项目源代码以 `MPL-2.0` 为主，部分文件带有 `MIT` 或 `Apache-2.0` 授权；具体以文件头部的 `SPDX-License-Identifier` 为准。
