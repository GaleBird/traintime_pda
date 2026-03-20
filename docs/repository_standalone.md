# 仓库独立化处理说明

本仓库当前的代码、README 与 App 关于页已经按 GXU 独立维护线整理。

如果你要让 GitHub 页面不再显示为 fork，并尽量弱化上游贡献者在仓库首页的可见度，需要分两步做：

## 1. 生成新的干净历史

在工作区干净的前提下运行：

```powershell
pwsh ./tool/create_standalone_history.ps1
```

执行后会得到：

- `standalone-main`：新的单提交干净历史分支
- `legacy-history-before-standalone`：旧历史标签
- `legacy/main-before-standalone`：旧历史备份分支

## 2. 迁移到独立仓库

推荐做法：

1. 在 GitHub 上新建一个普通仓库，不要从 fork 创建。
2. 将 `standalone-main` 推送到新仓库，并设为默认分支。
3. 将 README、关于页里的维护者/上游说明一并带过去。
4. 保留 `LICENSE` 与源码文件中的版权头。

如果你坚持继续使用当前仓库地址，则需要在 GitHub 侧处理 fork 关系；本地代码无法直接替你完成这个动作。
