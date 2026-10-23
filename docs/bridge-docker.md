# Bridge 独立容器

当前镜像提供 CyberRT、Python 工具及 Chatter talker，用于先验证 Apollo 通信。
CARLA API 和实际传感器桥接代码尚未加入；后续需按 CARLA 服务端版本安装客户端。

## 构建

在仓库根目录执行（需要 Docker 和依赖下载网络）：

```bash
python3 docker/fetch_deps.py
bash docker/build.sh
```

默认镜像 `apollo-carla-bridge:dev`，Ubuntu 22.04 / Python 3.10。
从 docker/deps 导入宿主机预下载的源码，在镜像内编译依赖、重新构建本仓库，启用 `APOLLO_LEGACY_RTPS=ON`；
不复制宿主机的 `build/` 或 `install/`。默认并行度 4：

```bash
BUILD_JOBS=4 DEPENDENCY_PROXY=github bash docker/build.sh
```

若 Docker Hub 无法访问，可用 `BASE_IMAGE=<可访问的Ubuntu22.04镜像> bash docker/build.sh`
指定基础镜像。不要替换为 Ubuntu 18.04 或其他 Python ABI 的镜像。

可将代理选择改为 `gitee`；它是下载源选择，不是 HTTP 代理。
依赖安装沿用 install.py --source-dir，缺少源码时直接报错。
部分第三方仓库未锁定 commit，首次构建需要较长时间。
此模式避免 Git 克隆，但 APT、pip、bvar 下载仍需网络。

## 启动 talker

```bash
bash docker/run.sh
```

创建 `apollo_carla_bridge`，使用 Docker 默认 bridge 网络、独立 IPC，默认发布 talker。
启动器会打印 Bridge IP 和 Apollo 应使用的网关 IP。容器 IP 动态分配，重建后需重新确认。
不挂载宿主机源码或构建目录，避免覆盖镜像内的编译结果。
可通过 `BRIDGE_IMAGE`、`BRIDGE_CONTAINER`、`CYBER_DOMAIN_ID` 环境变量覆盖默认值。

Apollo 继续使用 host 网络，不要求修改为 `--ipc=host`。
在 Apollo 容器新终端中（先退出旧的 monitor/echo/talker）：

```bash
cd /apollo
source cyber/setup.bash
# 使用 docker/run.sh 打印的 Apollo host-network CYBER_IP，下面仅为示例
export CYBER_IP=172.17.0.1
export CYBER_DOMAIN_ID=80
cyber_channel echo channel/chatter
# 或直接执行 cyber_monitor
```

必须在 source 后设置 CYBER_IP；所有参与通信的 Apollo 进程均使用该地址和相同 domain，
旧进程需要重启。Bridge 自动选择自身容器 IP，不要为 Bridge 填网关地址。
不同 CYBER_IP 使默认 `diff_host: RTPS` 生效，不使用 RTPS 包装脚本。
宿主机防火墙需要允许 docker0 上的 DDS 发现与数据 UDP 通信，不需要配置固定发布端口。
两端继续使用已对齐的 DDS 端口参数和兼容封装。

## 容器操作

```bash
docker logs -f apollo_carla_bridge
docker exec -it apollo_carla_bridge bash
# 容器交互 bash 自动加载 build/setup.bash，可直接运行 cyber_channel 等工具

docker stop apollo_carla_bridge
docker start apollo_carla_bridge
```

重新构建镜像后，停止并删除旧 Bridge 容器，再执行 run.sh；启动脚本不会自动删除已有容器。
若需要传入其他命令：`bash docker/run.sh sleep infinity`，之后 exec 进入容器。
现有 `scripts/cyber_rtps.sh` 保留，供同 IP / 隔离 IPC 的部署调试使用。

## 验证范围

本次已通过 Shell 语法检查；首次构建在拉取 `ubuntu:22.04` 时遭遇 Docker Hub TLS 超时，
尚未完成镜像构建与不同 IP 布局下的实收验证。
此前已验证的宿主机 → Apollo 实收使用 RTPS 包装脚本，不能替代本容器布局的实收验证。
