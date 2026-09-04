# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概况

GXU 研课表（`watermeter`）——面向广西大学研究生的非官方校园信息查询应用，多平台 Flutter 客户端（Android / iOS / Linux / Windows）。基于上游开源项目 `Traintime PDA / XDYou` 的 GXU 独立维护线。上游 XDU 逻辑仍在代码中，但本仓库按“GXU 单校 fork”处理：凡是用户可见的 XDU 默认行为，直接替换为 GXU 行为，不保留双校分支或兼容层。

**必读：`AGENTS.md` 的 "Current Project Notes" 部分包含大量已确认的行为约束（登录流、各页面交互细节、构建陷阱、发布流程），改动前先查阅对应条目；完成代码改动后按其 "Session Handoff" 约定回写 AGENTS.md。**

## 常用命令

统一使用仓库内固定 Flutter SDK（`.flutter/` 是 git submodule）：

```bash
git submodule update --init --recursive
.flutter/bin/flutter pub get
.flutter/bin/flutter analyze
.flutter/bin/flutter test                                   # 全部测试
.flutter/bin/flutter test test/gxu_score_model_test.dart    # 单个测试文件
.flutter/bin/dart run tool/security_audit.dart              # 安全相关改动后的回归检查
dart run build_runner build --delete-conflicting-outputs     # 生成代码（lib/generated、*.g.dart）
.flutter/bin/flutter run -d windows                         # 或 android/ios/linux
```

构建：

```bash
.flutter/bin/flutter build apk --release --split-per-abi     # Android 发布包（尺寸比较必须用 release 产物）
.flutter/bin/flutter build linux --release
# flutter build windows 当前失败（缺 Visual Studio 工具链），不要浪费时间重试
```

本机环境约定：Android SDK 在 `D:\Android\Sdk`；仓库必须使用真实 ASCII 路径 `D:\c++\cliProxyApi\CLIProxyAPI_6.6.58_windows_amd64\course_schedule\traintime_pda`；app 改动默认重新构建 debug APK 并装到手机 `3B1F56E9B8L7YW34`（用 `D:\Android\Sdk\platform-tools\adb.exe`），迭代 UI 调试优先用持久 `flutter run` 会话走热重载。

## 架构

分层为 `page`（UI）→ `controller`（状态/交互）→ `repository`（会话+数据）→ `model`（类型），按 feature 组织：

- **`lib/repository/gxu_ids/`**：GXU 研究生系统（`yjsxt.gxu.edu.cn`）全部会话与解析器。核心是 `GxuCASession`（统一认证登录：账号密码/短信验证码，Cookie 持久化），其余会话（课表 `GxuClasstableSession`、成绩 `GxuScoreSession`、选课、空闲教室、评教、校园网 `GxuNetworkSession`）复用其登录态。HTML 页面解析与 session 分文件（如 `gxu_classtable_parser.dart` vs `gxu_classtable_session.dart`），解析回归测试在 `test/gxu_*_parser_test.dart`。
- **`lib/repository/`**（非 gxu）：`preference.dart`（SharedPreferences 封装，敏感串走 flutter_secure_storage）、`fork_info.dart`（品牌/仓库/更新签名公钥的唯一来源）、`pda_service_session.dart`（检查更新，读 DigitalOcean Spaces 清单并做 RSA-SHA256 签名校验）、`security/`（加密文件存储 `secure_file_store.dart`、`SecureCookieStorage`）。
- **`lib/page/<feature>/`**：每个功能一个目录；旧 XDU 版本与 GXU 版本常并存（如 `score.dart` vs `gxu_score.dart`），GXU 模式（启动时强制 `Preference.isGxuMode = true`）只路由到 GXU 版本。
- **状态管理**：Get（`Get.put` 控制器）+ Provider 混用；主页课表状态在 `ClassTableController`（`lib/controller/`，拆成多个 mixin）。
- **生成代码勿手改**：`lib/generated/`、`lib/bridge/*.g.dart`、`*.g.dart`。自定义 build_runner 生成器在 `tool/generators/`（i18n、成绩哈希）；Python 工具生成更新清单 `generate_update_manifest.py` 与启动图 `generate_gxu_launcher_icon.py`。
- **`website/`**：官网 `gxu.app` 早期静态页（`public/`）、Node 计数服务（`service/`）、部署模板（`deploy/`）。**注意：官网当前唯一权威来源是 GitHub `GaleBird/gxu-app` 仓库，本仓库 `website/` 已落后多个提交（缺深色几何风重设计与新截图）；要改线上官网请改上游仓库并重新部署，不要直接部署本仓库的 `website/`。**
- **`pigeon_bridge/`**：Dart/原生平台桥（iOS 桌面小组件等）。
- **Android split versionCode 归一化**：更新版本比较前对 split APK versionCode 除以 10 还原真实 build 的逻辑在 `lib/repository/update_build_number.dart`（测试 `test/update_build_number_test.dart`）；改版本比较/更新判断时必须连这两个文件一起改。

i18n：UI 文案在 `assets/flutter_i18n/*.yaml`；非 UI 文案由生成器从 `assets/non_ui_i18n/` 生成。

## 关键约定

- **缓存写入**：GXU 成绩/选课/校园网/课表缓存一律通过 `secure_file_store.dart` 加密写入，不得退回明文 `writeAsString*`；Cookie 一律用 `SecureCookieStorage`，不得重新引入 `cookie_jar` 的 `FileStorage`。
- **错误处理**：远端页面结构变化（标签/节点缺失）要显式报错，不得静默伪造空结果；损坏缓存要删除并回退远端，不能卡死页面；`DioException` 技术长文不直接展示给用户（用 `describeGxuServiceError()`）。
- **版本号**：`pubspec.yaml` 的 `+build` 发布时必须单调递增；发布 tag 格式 `v1.0.1+41`（带 build 号），push `v*` tag 自动触发 `.github/workflows/release_for_android.yaml` 构建、签名并上传 APK 到 GitHub Release 和 DigitalOcean Spaces。
- **提交风格**：`feat:` / `fix:` / `chore:`，主题行简短，中英文均可；提交前 `dart format lib test tool`（格式化用任意可用 dart，或 `.flutter/bin/dart format`）。
- **设计方向**（详见 `.impeccable.md`）：Material 3 “校园自然系”——西大绿主色、米白底、金色小面积点缀；信息优先，避免渐变/玻璃/重阴影。GXU 字标统一用 `lib/page/public_widget/gxu_wordmark.dart`。
- 本机没有 `gh` 命令；发版走 push tag 触发 GitHub Actions。
