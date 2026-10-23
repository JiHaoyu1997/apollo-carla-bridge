# 第三方源码下载目录

在宿主机仓库根目录运行：

```bash
python3 docker/fetch_deps.py
```

脚本从 `install.py` 读取 GitHub 地址及 `_clone_repo` 的版本、浅克隆参数，
一次下载全部 14 个仓库（包括 vendor 的 foonathan/memory 子依赖）。可从任意工作目录运行，默认保存到本目录。

```bash
python3 docker/fetch_deps.py --attempts 5
python3 docker/fetch_deps.py --dry-run
python3 docker/fetch_deps.py --dest /其他目录
```

重复执行会检查并跳过已有仓库，不更新或覆盖已有源码；来源或指定版本不符时报错。
每个仓库默认最多尝试 3 次，间隔退避；可用 `--attempts` 调整。
中途失败可重跑，失败的临时下载会清理。setup 和 nlohmann_json 沿用安装脚本，
没有固定版本，首次下载的是默认分支。下载内容不提交到本仓库。

这里只下载源码，不编译、不应用补丁。Dockerfile 将本目录复制到镜像内的 third_party，
通过 install.py --source-dir 强制使用已有源码，不再 Git 克隆。
还未涵盖 bvar 压缩包或构建过程自动下载的子依赖，不能视为完整离线依赖集。
bvar、APT、pip 和其他非 Git 下载仍需要网络。
