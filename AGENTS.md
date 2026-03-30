# Repository Guidelines

## Project Structure & Module Organization
This repository is a multi-platform Flutter app (Android, iOS, Linux, Windows) with feature-first organization.

- `lib/page/`: UI pages by feature (for example `classtable`, `score`, `library`, `setting`).
- `lib/repository/`: data/session layer for campus services and API integration.
- `lib/model/`: typed data models (`xidian_ids`, `xdu_planet`, etc.).
- `lib/controller/`: state and interaction controllers.
- `lib/generated/` and `lib/bridge/*.g.dart`: generated code; do not hand-edit.
- `assets/`: images, i18n YAML files, and ML model files (`*.tflite`).
- `tool/generators/`: custom `build_runner` generators.
- `test/`: Flutter tests.
- Platform folders: `android/`, `ios/`, `linux/`, `windows/`.

## Build, Test, and Development Commands
Prefer the repo-pinned Flutter SDK in `.flutter/` (initialized as a submodule):

```bash
git submodule update --init --recursive
.flutter/bin/flutter pub get
.flutter/bin/flutter analyze
.flutter/bin/flutter test
dart run build_runner build --delete-conflicting-outputs
.flutter/bin/flutter run -d windows   # or android/ios/linux
```

Build examples:

```bash
.flutter/bin/flutter build apk --split-per-abi
.flutter/bin/flutter build linux --release
.flutter/bin/flutter build windows --release
```

## Coding Style & Naming Conventions
- Lint baseline: `analysis_options.yaml` (`flutter_lints`).
- Use 2-space indentation and run `dart format lib test tool` before commit.
- File names: `snake_case.dart`; classes/types: `PascalCase`; members: `lowerCamelCase`.
- Keep feature logic close to its module (`page` + corresponding `repository`/`model`).

## Testing Guidelines
- Primary framework: `flutter_test`.
- Place tests in `test/` and name files `*_test.dart`.
- Prefer focused widget/unit tests for parsing, state transitions, and failure paths.
- Run locally with `.flutter/bin/flutter test` before opening a PR.

## Commit & Pull Request Guidelines
- Follow existing commit style seen in history: `feat:`, `fix:`, `chore:`.
- Keep subject lines short and specific (English or Chinese is acceptable).
- PRs should include:
  - clear change summary,
  - affected modules/paths,
  - screenshots or recordings for UI changes,
  - verification steps/commands executed.

## Security & Configuration Tips
- Never commit signing keys, `android/key.properties`, or any secrets.
- Use CI secrets/env vars for credentials and release tokens.
- If generated files are stale, regenerate with `build_runner` instead of manual edits.

## Session Handoff
- After each completed code change, update this `AGENTS.md` with durable behavior changes, local build/install caveats, and any project-specific routing decisions that a new Codex session must inherit.
- Do not write transient investigation notes here; only keep facts that affect future edits, builds, debugging, or user-visible behavior.

## Current Project Notes
- This repository is now treated as a GXU-only fork. When user-facing behavior still reflects XDU defaults, replace them with GXU behavior instead of keeping dual-school branches or XDU reference templates, unless the user explicitly asks to preserve XDU behavior for a specific path.
- Historical XDU logic may still exist in code, but future edits should prefer direct GXU replacement over compatibility layers. Earlier notes about keeping XDU reference entries or a shared dual-school login flow are obsolete.
- App startup now forces `Preference.isGxuMode = true`; do not reintroduce user-facing XDU/GXU mode switching unless the user explicitly asks for multi-school support again.
- `LoginWindow` is GXU-only again and should log in through `GxuCASession` directly; the temporary school-mode selector and XDU login branch have been removed.
- `LoginWindow` 现支持“账号密码 / 短信验证码”两种统一认证登录：短信发送与短信提交都必须在 `GxuCASession` 内部先清空旧 Cookie，再走新的统一认证会话；短信登录手机号只在登录成功后写入 `Preference.gxuCaPhone`，并会清理旧 `idsAccount` / `idsPassword`，当 Cookie 过期且缺少账号/密码时，`GxuCASession.ensureYjsxtLoggedIn` 会显式报错提示重新登录。
- `Preference.gxuCaPhone` 与 `Preference.schoolNetQueryAccount` 现按敏感字符串走 `flutter_secure_storage`，不要再放回普通 SharedPreferences。
- 短信登录里的短信验证码输入框默认明文显示，并保留可切换隐藏；不要再改回默认隐藏，避免一次性验证码输入时增加核对成本和输错率。
- 登录页“忘记密码”入口当前指向的官方链路会上游跳转到非加密页面；应用侧只允许在弹出安全提示后用系统浏览器继续打开，不要再恢复成一键静默直开。
- Login branding is GXU-only now: the login page header no longer shows the old app icon or text header, and instead uses the transparent SVG asset `assets/gxu_name.svg` derived from the repo-root `name.svg`. Keep the login page background plain and avoid reintroducing the rejected gradient/glow treatment.
- The login page should use a fixed non-scroll layout, keep the whole content block slightly higher on the screen instead of vertically centering it, and still subtract `viewInsets.bottom` from the portrait visible height so short screens keep the login button reachable above the keyboard. Password login uses explicit focus-node handoff from account to password so the keyboard `下一项` button does not dismiss the keyboard, password/SMS-code fields trigger login from the keyboard action button, and password login keeps the original GXU behavior of always persisting `idsAccount` and `idsPassword` after a successful login.
- The SMS login row should stay on one line with an approximately `2:1` width split between the verification-code field and the `获取短信` button; do not switch it back to a stacked layout unless the user asks again.
- App 启动首页入口现在走 `StartupGate`：有缓存账号密码时直接进首页；若仅缓存了短信登录手机号，则先校验 `GxuCASession.isYjsxtLoggedIn()` 再决定进首页还是登录页，避免会话仍有效时先闪出登录页。
- `ToolBoxPage` should keep the GXU `网络查询` entry first with the Wi-Fi icon. Remaining GXU-unadapted toolbox items should be shown as `（未完成）` placeholders that open the in-app unfinished page instead of any XDU website. The old XDU `网络查询`, `移动门户`, `物理计算`, and `睿思导航` toolbox entries are removed.
- GXU 工具箱现已接入原生 `空闲教室` 查询入口，位于 `网络查询` 之后。该功能必须继续复用 `GxuCASession` 的研究生系统登录态，通过 `GxuEmptyClassroomSession` 直接访问研究生系统 `cxkxjsIndex/js?item_id=up_033_006_003` 页面和其 AJAX 接口（`findAllJsxx / findJszyqk / getJszyqkByJsxxid`），不要退回外部浏览器或 WebView。
- GXU 空闲教室查询页是移动优先的原生筛选页：筛选项基于研究生系统真实字段（学期、起止周次、起止星期、起止节次、教学楼、教室、座位数、占用情况、占用类型），窄屏纵向排布、宽屏双列排布；“查看方式”属于查询条件本身，放在筛选区顶部，不要再塞回结果区；进入页面时只加载筛选表单，不要自动立刻发起空教室查询，未查询前结果区应明确提示用户先选条件再点查询；时间范围区应保持 6 个紧凑选择项（开始/结束周次、开始/结束星期、开始/结束节次）的两列排布，优先压缩首屏高度；筛选项选择走原生底部面板，本地搜索只过滤已加载结果、不触发远端请求；结果列表默认只先渲染前 40 间教室并通过“继续加载”逐批展开，避免一次性渲染研究生系统返回的上千间教室导致卡顿或闪退；最近一次 GXU 空教室筛选条件保存在 `Preference.gxuEmptyClassroomQuery`，教学楼选择继续同步到旧的 `emptyClassroomLastChoice` 兼容键。
- GXU 空闲教室结果必须始终与当前筛选条件一一对应：任一远端查询条件（含查看方式、周次/星期/节次、楼栋、教室、座位/占用筛选）变化后，要立刻作废旧结果、旧详情缓存和本地结果搜索词，并阻止旧请求回填；刷新失败时宁可只显示错误，也不能继续保留上一次空教室结果误导用户；若 `Preference.gxuEmptyClassroomQuery` 本地 JSON 损坏，应记录 warning、清掉坏偏好并回退到服务端默认表单，而不是让页面初始化直接报错。
- GXU 空闲教室筛选项判等必须按“trim 后去空字符串”的同一口径比较新旧值；依赖同步的单选字段（如教学楼）在表单态里可能保存为 `['']`，而选项面板会回传 `[]`，这种语义等价的“空选择”不能触发结果作废、本地搜索清空或旧请求失效。
- GXU 空闲教室多选筛选项（如教室/占用情况）判等与落库统一按 `trim + 去空 + 去重 + 排序` 规范化，避免仅因顺序变化误判“条件已变化”；查询前会校验座位数区间（最少座位 > 最多座位时直接报错并阻止请求）。
- GXU 空闲教室页的主滚动容器必须保持稳定：不要再因为 `result == null / != null` 切换而替换掉整棵 `ListView` 外层，筛选条件变化后应尽量保留当前滚动位置，尤其是修改周次/星期/节次这类筛选项时不能再把页面强行跳回顶部；下拉刷新在“已有结果”时才允许触发远端刷新。
- GXU 空闲教室查询的页面结构异常必须显式报错（如缺少 `.cxkxjs .toolbar`、必需筛选项、教室目录列表或占用结果 `data` 列表），不要为“跑起来”静默伪造空结果；解析回归优先补 `test/gxu_empty_classroom_parser_test.dart`。
- GXU 空闲教室结果统计对每个教室按 `viewType` 懒构建占用前缀缓存，缓存长度必须覆盖当前查询范围（不能假设固定 `20/7/13` 上限）；`GxuEmptyClassroomResult.buildRows()` 必须复用该缓存计算可用数、占用数和本地搜索标签，避免在大范围查询后重复扫描每个房间的 5 组占用 map。
- `ToolBoxPage` 的 `网络查询` 必须走原生 `NetworkCardWindow`，不要再用 WebView 打开 `self.gxu.edu.cn` 的 HTTP 页面，避免在 WebView 里暴露明文链路登录流程。
- GXU homepage bottom navigation keeps four tabs in order: 首页 / 工具箱 / 猪图鉴赏 / 设置. `PigPage` remains a real page backed by `pighub.top`; do not remove the pig tab again unless the user explicitly asks to drop it.
- The `订水系统` / `后勤报修` / `空间预约` unfinished toolbox placeholders now each have their own teaser copy instead of sharing the generic unfinished message; `缴费系统` keeps the generic unfinished copy.
- GXU mode now also exposes a native homepage schoolnet card and a native single-page network detail screen; do not hide the schoolnet card on the GXU homepage anymore.
- GXU native network query now uses dedicated `Preference.schoolNetQueryAccount` plus `Preference.schoolNetQueryPassword`; password login auto-syncs the current account into the schoolnet account field, while SMS login only reuses a manually confirmed schoolnet account for the same cached phone. Missing schoolnet account/password must open the native account-password dialog directly instead of only telling the user to re-login. Login flow must still try password-only submission first, and only fall back to captcha login when the server still rejects the session; captcha OCR should remain a fallback path instead of the default path.
- GXU network query is cache-first: app startup and homepage refresh must preload/show the last successful cached `GxuNetworkUsage` instead of auto-refreshing `self.gxu.edu.cn`, and users refresh manually from the GXU network detail page when they want live data.
- GXU homepage schoolnet card now summarizes used traffic in `GB` and shows relative cache age; the GXU detail page should keep showing cached data plus refresh-status hints even if a later refresh fails.
- GXU network detail refresh must release `gxuNetworkRefreshing` even on early exits such as missing query password or missing account, otherwise the refresh button stays disabled until app restart after the user fixes the input.
- GXU dashboard parsing is label-based around `下次结算 / 已用流量 / 免费流量 / 可用流量 / 消费保护 / 账户余额`; if those labels disappear, surface an explicit page-structure error instead of silently faking data.
- GXU 校园网详情页不再显示原来的注意提示卡或独立官网说明卡；操作区保持单行三按钮（刷新 / 账号 / 官网），按钮为“图标在左、文字在右”的横向样式，并紧贴在流量信息卡下方排布，其中“刷新”为蓝底白字主按钮，“账号 / 官网”保持白底；按钮下方使用浅橙色提示条承载更自然的缓存提示文案（如“默认显示缓存数据；需要最新结果时再点刷新，如需验证会提示输入验证码。”），并用系统浏览器跳转到 `http://self.gxu.edu.cn` 查看尚未接入的功能。注意 `ReloadWidget` 内含 `Expanded`，无缓存错误态不能直接放进滚动视图，需用有界高度（例如 `Column + Expanded`）承载。
- GXU 校园网详情页的 `Scaffold` 现关闭页面级键盘避让；账号密码输入继续在 `SchoolNetPasswordDialog` 内处理键盘与滚动。
- GXU 校园网详情页的底部操作区在无缓存、首次进入、首次刷新失败、缺少账号/密码等空状态下也必须继续显示；不要再把 `刷新 / 账号 / 官网` 入口只挂在“已有缓存内容”的分支里。
- GXU 校园网无缓存空态卡片应保持纯说明用途，不要再在卡片内部重复放一个“刷新”按钮；空态正文需要可滚动，避免固定底部操作区出现后在短屏/分屏/大字号下把说明卡挤出或裁掉。
- 设置页执行“清除缓存并重启”或“退出登录”时，除删除 `GxuNetworkUsage.json` 外，还要同步重置 `gxuNetworkInfo / gxuNetworkStatus / gxuNetworkRefreshing / gxuNetworkError`，避免重启前后或非重启路径短暂显示旧校园网缓存状态。
- 设置页执行“清除缓存并重启”或“退出登录”时，Cookie 清理失败不能静默吞掉，但也不能提前中断本地缓存/偏好清理；应先完成本地清理，再显式提示 Cookie 异常，并保证确认弹窗先关闭、进度框在 `finally` 里收起，避免桌面端/重启失败时留下叠层弹窗。
- GXU 课表日期行里“今天”的高亮底色应与顶部周次条当前选中周次使用同一套 `highlightColor` 背景，不要再单独使用另一种 `primaryContainer` 色块。
- GXU homepage current/next-course logic must not switch to "tomorrow" before 22:05, because GXU晚课会持续到第 13 节结束。
- GXU classtable top week row ("第x周") uses compact height (56) on tall screens to avoid squeezing period time labels.
- GXU classtable top week row responsive breakpoints must use the actual classtable body viewport height after the AppBar, not `MediaQuery` full-route height; common ~640dp body heights on mainstream phones should fall into the compact week-row tier.
- GXU classtable now uses a segmented block layout with `午休/晚休` separators; `晚休` maps to periods 9-10, and the evening section shows periods 11-13 after it.
- GXU classtable does not use vertical scrolling; the left period column shows start time on top and end time at bottom for each period.
- GXU classtable left period column adds subtle row dividers, with start time emphasized and end time deemphasized to improve boundary readability.
- GXU 日程表在小窗/矮屏下也必须无溢出：顶部周次条、日期行、左侧节次列会按可用高度切换到紧凑尺寸；节次时间与 `午休/晚休` 标签要可缩放适配，不能再出现 split-screen 下的 `RenderFlex overflow`。
- GXU 课表卡片在超窄列宽下要强制进入紧凑布局：隐藏老师行、压缩地点最小字号与内边距，优先保证课程名和上课地点可读。
- GXU 课表卡片里的 `AutoSizeText` 最小字号必须和步进粒度保持整倍数关系；当前课程名/地点统一使用 `0.5` 的步进粒度，避免真机小窗下触发 `MinFontSize must be a multiple of stepGranularity` 断言。
- GXU homepage pull-to-refresh is a user-requested remote sync: it must call `ClassTableController.updateClassTable(isForce: true)` instead of reusing the 2-day cache window, and the success toast may only appear when `ClassTableController.error == null`; cached fallback after a refresh failure must surface the failure message instead of pretending refresh succeeded.
- `Preference.classTableCacheMode` exists to prevent reuse of stale XDU cache while the codebase is still being cleaned into a GXU-only fork.
- When GXU class-table refresh falls back to same-mode cache after a login/refresh error, `ClassTableController.state` remains `fetched` but `error` preserves the refresh failure so startup flow can avoid showing a false "已加载" toast.
- GXU semester switching must read the real graduate-system `select[name="xqdm"]` options instead of synthesizing year/term wheels. `GxuClasstableSession.getClassTable()` must honor `Preference.currentSemester` whenever `Preference.isUserDefinedSemester` is true.
- Historical GXU semesters currently estimate `termStartDay` from the semester code only: autumn uses the first Monday of September in the start year, spring uses the first Monday of February in the end year. Course filtering is real, but historical date labels are approximate unless a future change finds an official term-start source.
- GXU class-table course loading must paginate `/yjs/py/xkgl/xkmdcx/findXkmdByXsPage`; the graduate system can split cross-semester course rows across multiple pages, so a single request is incomplete.
- GXU now has a native score page again. Keep `ScoreCard` visible on the GXU homepage, route `ScoreWindow` to the GXU-specific page in GXU mode, and use `GxuScoreSession.isCacheExist` for offline gating instead of XDU `ScoreSession`.
- GXU homepage `ScoreCard` must not block entry with the old XDU `offline` flag from `ids_session.dart`; GXU users should be allowed into the score page even when that XDU login state is not `success/manual`, and the score page itself should surface the real GXU fetch/login error.
- GXU homepage toolbox now shows `成绩查询` and `选课情况` side by side; `选课情况` routes to `GxuCourseSelectionWindow` and pulls the selected-course list from `/yjs/py/xkgl/xkmdcx/findXkmdByXsPage` (includes courses without grades, grouped by semester, with degree/non-degree filters). It caches to `gxu_course_selection.json`, which settings cache-clearing must also delete.
- GXU degree-course classification must treat `非学位*` as non-degree (do not use naive `contains("学位")`), with `englishCourseType == "D"` as fallback when Chinese type text is empty.
- The GXU score archive card should stay compact: keep the identity block compressed to a few lines, place summary metrics in a tight right-side/two-row panel, and avoid reintroducing a tall hero card that pushes the course list below the fold on phone screens.
- GXU native score page should preserve the old "selected courses for calculation" workflow: use a calculate FAB to enter selection mode, let score cards toggle selection in that mode, and show the selected-course credit/average/GPA summary in a bottom bar instead of dropping that capability from the GXU implementation.
- GXU native score data comes from the transcript-preview flow, not the generic template list. The fetch order is `/yjs/py/kcpj/loadJxzlpj` -> `/yjs/py/cjgl/cjdpldy/checkdDycjd` -> `/yjs/py/cjgl/cjdpldy/getCjddyyl`, and the cache file name is `gxu_scores.json`, which settings cache-clearing must also delete.
- GXU 成绩查询在重新登录或清缓存后的首次进入也要稳定：先打开成绩模板页 `/cp/templateList/p/up_016_014` 预热模块，再走 `loadJxzlpj -> checkdDycjd -> getCjddyyl`；若 `loadJxzlpj` 首次返回未就绪，允许带日志地重试一次同样的预热流程，不能再把这种瞬时初始化失败直接暴露给用户。
- App startup bootstrap should stay minimal: keep support-path / preferences / forced GXU mode / package info before `runApp`, but defer cache warmup and notification-service initialization until after the first frame so the native splash is not stretched by non-critical async work.
- Android local size comparisons must use `release` artifacts, ideally `.flutter/bin/flutter build apk --release --split-per-abi`; `build/app/outputs/flutter-apk/app-debug.apk` is a fat debug package and can be around 242 MB because it includes `kernel_blob.bin`, all ABIs, and debug native libraries.
- `pubspec.yaml` 的 `version` 可保持 GXU 品牌语义版本（如 `1.0.0`），但 `+build` 必须单调递增（当前基线至少 `+41`），否则同包名安装会因 versionCode/build number 回退而覆盖失败。
- `StartupGate` still validates SMS-login sessions remotely when a phone number is cached, but `GxuCASession.isYjsxtLoggedIn()` should return `false` immediately when the local GXU cookie jar is empty instead of waiting on a network probe.
- On this Windows machine, Android SDK should use `D:\Android\Sdk`.
- The repository has been moved to the ASCII path `D:\c++\cliProxyApi\CLIProxyAPI_6.6.58_windows_amd64\course_schedule\traintime_pda`; use this real path directly for Flutter and Android commands.
- The old `D:\ttascii` junction and temporary `X:` drive workaround are obsolete after the path rename; if they exist and no process is using them, they can be removed.
- For app-facing code changes, default to rebuilding a debug APK and installing it to the connected phone `3B1F56E9B8L7YW34` with `D:\Android\Sdk\platform-tools\adb.exe` unless the user explicitly says not to.
- `flutter_launcher_icons` is currently only configured for Android and iOS. Before regenerating Android launcher icons, remove stale `android/app/src/main/res/mipmap-*/ic_launcher.webp` and `android/app/src/main/res/mipmap-*/ic_launcher_round.webp` (otherwise Gradle can fail with duplicate launcher-icon resources). Keep only one `ic_launcher_background` color definition (prefer `android/app/src/main/res/values/colors.xml` and delete legacy `android/app/src/main/res/values/ic_launcher_background.xml` if it exists).
- iOS widget build must keep real colorset names: in `ios/Runner.xcodeproj/project.pbxproj`, the `ClasstableWidget` target settings `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` and `ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME` must be `AccentColor` / `WidgetBackground` (not `AppIcon`), otherwise asset-catalog compilation will fail.
- On this Windows machine, Android debug builds can hit Kotlin incremental-cache path-root crashes between the `D:` repo and the `C:` pub cache; keep `kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process` in `android/gradle.properties`.
- On this Windows machine, `flutter build windows` currently fails with `Unable to find suitable Visual Studio toolchain`; Windows icon resources can still be updated in source, but a new desktop executable cannot be produced until the Visual Studio C++ toolchain is installed.
- Catcher2 error reporting now uses `EmailManualHandler(["2484895358@qq.com"])` and also appends every report to `${supportPath}/logs/catcher_reports.log` via `FileHandler(handleWhenRejected: true)`, so local crash logs are kept even when the user cancels the mail send flow.
- Sensitive password-like preferences (`idsPassword`, `schoolNetQueryPassword`, `sportPassword`, `experimentPassword`, `electricityPassword`) are persisted via `flutter_secure_storage` now. App bootstrap migrates any legacy SharedPreferences values into secure storage and removes the plaintext keys; `preference.getString` stays sync by reading an in-memory cache.
- App bootstrap must also call `initializeSecureFileStore()` before UI startup. GXU score / 选课 / 校园网缓存，以及 GXU 课表缓存和用户自定义课表缓存 now write encrypted payloads through `lib/repository/security/secure_file_store.dart`; do not switch those files back to direct plaintext `writeAsString*`.
- Cookie jars for `NetworkSession`, `GxuCASession`, `GxuNetworkSession`, and `SportSession` now use `SecureCookieStorage` backed by `flutter_secure_storage`, with one-time migration from legacy `supportPath/cookie/...` plaintext directories. Do not reintroduce `cookie_jar` `FileStorage` for app sessions.
- Dio HTTP logging is now debug-only and no longer prints request/response bodies or headers by default (to avoid leaking cookies/passwords). Adjust `lib/repository/logger.dart` only when you explicitly need verbose network traces locally.
- Android cleartext traffic allowlist (`android/app/src/main/res/xml/network_security_config.xml`) is now scoped to `self.gxu.edu.cn` only instead of all `gxu.edu.cn` subdomains.
- For iterative Android UI debugging on the connected phone, prefer a persistent `flutter run` session from the real ASCII repo path so Dart-only changes can use hot reload/hot restart instead of reinstalling the APK every time.
- `codex resume` filters sessions by `session_meta.payload.cwd`; after any repo path rename, historical session `.jsonl` files under `C:\Users\彭于晏\.codex\sessions\` may need their stored path prefix updated from the old repo path to the new one, otherwise they will only appear with `codex resume --all`.
- 设置/关于页的 fork 信息（维护者/仓库/上游）统一维护在 `lib/repository/fork_info.dart`；改品牌或仓库地址优先改这里。
- 当前维护仓库 GitHub owner 已切换为 `GaleBird`；本地 `origin`、README、官网源码展示和应用内仓库链接都应保持 `https://github.com/GaleBird/traintime_pda`，不要再写回旧的 `2484895358/traintime_pda`。
- App 检查更新现在读取 DigitalOcean Spaces 清单 `https://myapk.sgp1.cdn.digitaloceanspaces.com/manifests/update.json`，实现位于 `lib/repository/pda_service_session.dart`；不要再接回旧的 `legacy.superbart.top/traintime_pda_backend` 或 GitHub `latest release` 直读接口。
- 更新清单现在必须通过 `RSA-SHA256` 签名校验后才会被接受：公钥和 key id 固定在 `lib/repository/fork_info.dart`，校验逻辑在 `lib/repository/security/update_manifest_security.dart`，下载链接也会限制为受信任的 `https` host。若清单缺签名、签名不匹配或下载地址越界，应用内检查更新必须显式失败，不能静默降级。
- 更新版本比较现在同时比较 `pubspec.yaml` 的语义版本和 `+build`；发布 tag 应与 `pubspec.yaml` 版本完全一致，格式优先使用 `v1.0.1+41` 这类带 build 号的 tag，否则应用内更新提示可能无法正确判断新旧版本。
- Android debug 包（`applicationIdSuffix ".dev"` / `versionNameSuffix "-dev"`）必须视为测试安装：`checkUpdate()` 仍可拉取远端清单用于展示最新发布信息，但比较结果要直接视为 `localAhead`，不能再把 release APK 当作当前 `.dev` 包的可升级版本。
- Android 更新弹窗优先打开与设备 ABI 匹配的 Spaces APK 直链，`UpdateMessage.fdroid` 继续承载 Android 下载地址，GitHub Release 按钮仅作为备用下载入口；维护下载来源时不要恢复 F-Droid 旧链接逻辑。
- `tool/generators/generate_update_manifest.py` 生成的 `update.json` 现包含每个 APK 的 `sha256` 与 `size` 字段（并参与签名）；客户端解析时会校验字段格式，便于后续实现下载产物完整性校验闭环。
- Android 更新比较会先对当前项目的 split APK `versionCode` 做归一化：只有符合 `build.gradle` 覆盖规则的 `411+` / `...1|2|3` 这类 Android build 才会先除以 `10` 还原真实 build（例如安装包 `433` 视为发布 build `43`）；普通通用 APK 的 `41/42/43` 不能再被误判成 split 包。
- 官网下载页现已独立部署在 `gxu.app`：静态资源源码位于 `website/public/`，Node 服务位于 `website/service/`，部署模板在 `website/deploy/`。线上结构是 `Caddy -> /var/www/gxu.app/public + reverse_proxy 127.0.0.1:9080 -> gxu-app.service`，其中 `/api/update` 代理 Spaces `update.json`，`/api/stats` 返回真实下载计数，`/download/*` 先计数再 302 到 DigitalOcean Spaces 或 GitHub Release。
- 官网对外主入口当前是单页首页：首屏只保留下载按钮、版本/下载次数和当前发布摘要；功能与仓库来源继续留在同一页，不要再把首页改回多页面导航入口或超大海报式首屏。
- 官网首页现已去掉独立“首页效果图”区块：功能区改为左侧四张 App 截图轮播、右侧四个仅显示标题的紧凑功能卡；源码区不再放额外解释文案，只保留仓库名、代码地址和跳转入口。
- 官网静态页源码仍在 `website/public/`，注意 `/download/*` 已被后端占用作真实下载跳转接口；即使后续保留其他静态说明页，也不要把静态页面路由放到 `/download/` 下面。
- VPS 上 `gxu-app.service` 以 `azureuser` 身份运行，工作目录 `/home/azureuser/gxuapp/site/service`，统计文件写入 `/home/azureuser/gxuapp/site/data/download-counts.json`；静态站点必须放在 `/var/www/gxu.app/public` 这类 `caddy` 可读目录，不能继续直接从 `/home/azureuser/...` 提供，否则公网会返回 403。
- 应用内“检查更新 -> 下载安装包”现在会先 POST `https://gxu.app/api/downloads/<abi>/count` 记一笔 `app` 来源统计，再继续直开对应 ABI 的 APK 下载地址；官网 `/download/*` 仍记为 `site` 来源，`download-counts.json` 新增 `sources` 字段汇总来源分布。服务端记数前必须先按当前 manifest 解析目标下载项，若该路由在当前发布里不存在则显式返回 404，不得继续记入失效资产；下载资产名匹配时要把 `_` 视为 token 内字符，避免 `x86` 误匹配到 `x86_64`。
- Android 更新下载计数的共享逻辑现在集中在 `lib/repository/update_download_tracker.dart`，`pda_service_session.dart` 负责从清单资产解析 `androidDownloadRouteId`，`update_dialog.dart` 负责通过该 helper 先记数再打开 APK 链接；改这条链路时要连同 helper 与 `test/update_download_tracker_test.dart` 一起提交，避免再次出现 import 已接线但新库文件漏进 patch 的构建错误。
- `gxu.app` 的下载计数路由必须把非法 percent-encoding（如 `/api/downloads/%E0%A4%A/count`）视为客户端错误并返回 `400`，不能让 `decodeURIComponent` 未捕获异常把 Node 服务打挂；官网降级下载矩阵只保留当前真实发布的 `arm64-v8a / armeabi-v7a / x86_64` 三个 ABI，不要再加没有产物的 `x86` 死链。
- 官网页面展示的“下载次数/总下载次数”使用 `stats.totalDownloads`（包含官网跳转 + 应用内更新下载入口的计数）；如需区分来源看 `stats.sources.site/app`。
- `gxu.app` 当前只启用裸域名；`www.gxu.app` 暂不接入，因为现有 DNS/代理链路会导致 ACME 挑战失败并拿不到证书。除非先修好 `www` 的 DNS 指向和代理设置，否则不要把 `www.gxu.app` 再写回 Caddy 站点块。
- GitHub Android 发版工作流现在由 tag push 自动触发，配置文件是 `.github/workflows/release_for_android.yaml`，触发规则为 `v*`；常规发版流程应是：先更新 `pubspec.yaml` 版本、提交并推送 `main`，再创建并推送同版本 tag，让 GitHub Actions 构建并上传 split-per-ABI APK 到 Release。
- Android 发版工作流现在还会把 split-per-ABI APK 上传到 DigitalOcean Spaces `myapk`，并覆盖 `manifests/update.json`；运行前必须在 GitHub Secrets 配置 `DO_SPACES_KEY`、`DO_SPACES_SECRET`、`DO_SPACES_BUCKET`、`DO_SPACES_REGION`、`DO_SPACES_CDN_BASE_URL`。
- Android 发版工作流现在还要求 `UPDATE_MANIFEST_SIGNING_KEY`（PEM 私钥文本，不是 base64）；`tool/generators/generate_update_manifest.py` 会用它对 `update.json` 做签名并写入 `signature` 字段。公钥已固化在应用里，换钥必须同步改 `ForkInfo.updateManifestPublicKey` / `updateManifestKeyId`。
- Android 发版工作流已切到 `actions/checkout@v4` / `actions/setup-java@v4`，并显式启用 Node 24；若 GitHub Actions 再次在 `Build APK` 失败，优先下载失败时自动上传的 artifact `android-release-build-log` 看完整构建日志，不要只看 annotations 里的摘要。
- 当前 Android Release CI 的真实坑点不是 Node 警告，而是 release 签名：若日志出现 `KeytoolException` / `Tag number over 30 is not supported`，多数是 keystore 类型或内容不匹配导致解析失败。工作流会在 `JKS` / `PKCS12` 间自动探测 `storeType` 并写入 `android/key.properties`；若两种类型都无法通过 `keytool -list` 校验，则优先检查 `SIGNING_KEY` 是否为 keystore 文件二进制的 base64（只能编码一次），以及 `SIGNING_PASSWORD` / `SIGNING_ALIAS` 是否正确。
- Android 发版工作流会在签名步骤前创建并持续追加 `build_apk.log`；失败时 artifact 上传不会再出现 “No files were found with the provided path: build_apk.log” 的噪音警告。注意 GitHub 上的 “Re-run jobs” 会复用旧 commit 的 workflow 文件，不会应用后来提交的工作流修复；需要重新推 tag 或用 `workflow_dispatch` 对最新 commit 触发一次新运行。
- 这台机器当前没有 `gh` 命令；若用户要“上传 APK 到 GitHub”，优先走“push tag 触发 GitHub Actions release”而不是依赖本地 GitHub CLI 直传。
- Android debug 包名显示不要再依赖 `build.gradle` 里的单条 `resValue "app_name"`；中文和繁中会被主资源目录覆盖。调试构建专用名称统一放在 `android/app/src/debug/res/values*/strings.xml`。
- 本地安全回归检查脚本是 `tool/security_audit.dart`；它会扫描私钥/签名文件、TLS 绕过、明文 Cookie 存储、危险日志配置和更新签名接入缺失。做安全相关改动后优先运行 `.flutter/bin/dart run tool/security_audit.dart`。
- `tool/generators/generate_gxu_launcher_icon.py` 现在用于把任意源图标准化为实际打包使用的 `assets/gxu.png`；需要替换品牌图时，优先运行该脚本并通过 `--source` 指向新图片，再执行 `flutter_launcher_icons` / `flutter_native_splash`。
- 当前 launcher/splash 图标源图已切到 `assets/Gemini_Generated_Image_2dp0k82dp0k82dp0.png`，并通过 `tool/generators/generate_gxu_launcher_icon.py --source assets/Gemini_Generated_Image_2dp0k82dp0k82dp0.png` 生成 `assets/gxu.png`；后续若重跑图标生成流程，默认以该源图为基准。
- 设计上下文已写入仓库根目录 `.impeccable.md`，后续界面/品牌类改动遵循“校园自然系：西大绿 + 米白 + 金色点缀”。
- `PigPage` 仍是首页底部导航的正式入口；不要再移除“猪图鉴赏”，除非用户明确要求。
- 登录页里的两个外链入口（软件官网 `https://gxu.app` 与研究生教务系统官网 `https://yjsxt.gxu.edu.cn/tp`）现在应压缩进登录卡片底部现有的次级按钮区，与“清除缓存 / 查看网络交互”共用同一个紧凑 `Wrap`；不要再额外新增整行或页面底部独立悬浮层，以免在矮屏、分屏和键盘场景挤掉登录按钮或产生跳变。
- GXU 通知提醒设置页不再显示“物理实验提醒”开关，且 `CourseReminderService` 在 GXU 模式下不得继续安排实验提醒。
- GXU 字标统一走 `lib/page/public_widget/gxu_wordmark.dart`，不要在页面里直接裸用 `SvgPicture.asset('assets/gxu_name.svg')`。当前默认资源已切到透明底 PNG `assets/new_name_wordmark.png`（由 `assets/new_name.png` 派生），因为旧 SVG 字标在真机上存在字形缺损；该组件继续负责暗色主题浅色着色。
- GXU 选课情况页的学期筛选改为显式下拉框，入口文案要让用户直接看出“这里可以选学期”；选课概览保持信息优先的卡片式汇总。
- GXU 选课情况页顶部概览和筛选区保持紧凑，避免“选课概览”和搜索区占据过高首屏；搜索框提示文案用简短表达即可。
- GXU 选课卡片不展示上课时间文本，课程标题下方优先展示老师姓名；若接口返回多个老师，只显示第一个老师名称。
- GXU 选课情况页的概览统计默认使用紧凑标签式汇总，不再保留手机端大号统计块；筛选区里的课程类型筛选直接平铺在面板内，不要再额外套一层大容器。
- GXU 选课情况页的课程类型筛选使用单行分段按钮（全部/学位课/非学位课），不要再做成两行标题 + Chip 的大块布局。
- GXU 选课情况缓存策略不再固定 15 分钟：自动进入页面时需读取研究生系统首页 `/yjsjbxx/init/index/page` 的 `xuankeDate.STATUS`。`进行中/未开始` 自动缓存 24 小时，`已结束` 则持续使用本地缓存直到用户手动刷新；页面刷新按钮必须继续强制拉取远端最新数据。
- GXU 课表卡片现在要优先保证上课地点能完整看清：地点文本改为多行自适应并在极端长度时压缩显示，老师信息只在卡片高度足够时再追加展示；若老师字段包含多人，只展示第一个老师名称。
- GXU 课表卡片里的上课地点继续保持强调显示：地点区域使用更强的字重和浅色底块标签样式，视觉层级要明显高于老师信息。
- GXU “我的日程表”课程卡片视觉结构以 `v1.0.2+45` 为基准：左对齐三段式布局保持“顶部课程名 / 中部整宽地点标签 / 底部老师”，不要再改成居中胶囊式排版；仅允许保留小窗防溢出和 AutoSizeText 步进合法性修复。
- GXU 课表卡片的“超窄列宽紧凑布局”只应在真正极窄的小窗列宽触发；主流 320dp 手机上一天七列后的常规课程卡片仍应保留“顶部课程名 / 中部地点标签 / 底部老师”的三段式布局，老师多人时只显示第一个名字。
- GXU 课表卡片在重叠课程合并和连续布局路径下也要继续传递老师字段，不能因为聚合过程把底部老师行丢掉。
- GXU 日程表在查看周次不是本周时，可在标题栏显示“非本周”状态提示（不可点击）；周次切换仍只保留顶部周次条与左右滑动，不提供“回到本周”入口。日期行需保持紧凑，当前日期高亮时也不能出现 RenderFlex 溢出。
- 关于页不再展示“应用图标”概念入口；旧概念资源 `assets/icon_gxu_concept.svg` 仍可留作品牌素材，但默认不出现在设置页。
- 设置/关于页里的项目介绍保持简洁来源导向：不要再展示“当前维护者 / 维护者主页 / 某人维护版”这类中心化维护者信息，默认只保留“项目来源、当前仓库、上游仓库、开源许可、非官方说明”等必要信息。
- “知道更多”页改为“项目来源优先”的简洁结构：首屏只说明当前 GXU 版本与上游 `Traintime PDA / XDYou` 的关系，再展示当前仓库、上游仓库、开源许可和非官方说明；不要再做成维护者展示页。
- 关于页致谢区改为纯文字表达，使用“感谢原开发团队与贡献者”这类文案即可；不要再恢复贡献者头像墙或把这块写成“当前 GXU 版本全部由这些人共同维护”的表述。
- README 首屏与 App 关于页统一按“GXU 独立维护线”对外呈现：明确当前版本面向广西大学研究生、明确标注上游项目名 `Traintime PDA / XDYou`，同时保留 LICENSE 与源码版权头说明；App 关于页不再做维护者优先展示。仓库独立化历史处理使用 `tool/create_standalone_history.ps1`，不要在脏工作区直接手改主分支历史。
- GXU 成绩页与选课页读取本地加密缓存时，若检测到缓存损坏，必须删除坏缓存并继续走远端拉取；不要再让损坏缓存把页面永久卡在错误态，手动刷新也应能恢复。
- 登录页“清除登录缓存”必须清理 GXU 统一认证与 GXU 校园网等会话 Cookie，而不只是旧的 `NetworkSession`；若部分 Cookie 仓删除失败，要显式提示失败摘要，不能继续提示“清理成功”。
