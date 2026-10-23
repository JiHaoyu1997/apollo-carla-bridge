# 宿主机 Bridge → Apollo 容器通信验证

此步骤复用 CyberRT C++ talker：每秒向 `channel/chatter` 发布
`apollo.cyber.examples.proto.Chatter`，包含递增的 `seq` 和 `Hello, apollo!`。
暂不连接 CARLA。

## 当前 Apollo 的 DDS 封装兼容模式

当前容器中的 Apollo 使用 `int32 timestamp, int32 seq, string data,
string datatype` 的 UnderlayMessage；独立 CyberRT 原版使用
`uint64 timestamp, uint64 seq, string data`，二者不能直接互通。
为此容器构建 Bridge 时启用兼容模式：

```bash
source install/setup.bash
cmake -S . -B build -DAPOLLO_LEGACY_RTPS=ON
cmake --build build --target cyber_example_talker -j4
```

该开关只改变 DDS 外层封装；不改变频道内部的 Apollo Protobuf 消息。
两种封装不能在同一个通信组混用。切回独立 CyberRT 原版需设置 OFF 并重新构建、重启进程。
兼容模式将外层 timestamp/seq 按旧协议缩为 int32；Protobuf 消息内的时间戳与序号不受影响。

## 网络前提

同一台 Linux 主机建议 Apollo 容器使用 host 网络。用以下命令确认：

```bash
docker inspect -f '{{.HostConfig.NetworkMode}}' apollo_dev_apollo_jihy
ip -4 addr
```

两端使用同一个宿主机可达 IPv4 地址、相同的 domain（示例为 80）。
两端 DDS 端口参数也必须一致。本仓库已对齐当前 Apollo 的
`participant_attr { domain_id_gain: 200 port_base: 10000 }`。
配置更新后执行 `cmake -S . -B build`，并重启 talker；已运行进程不会重新加载配置。
`CYBER_IP` 必须是本机实际拥有的地址，不要照抄其他机器的地址。
两端都使用下面的 RTPS 包装脚本，避免同 IP 时走 SHM 而受 IPC 隔离影响。
此验证不要求修改容器的 IPC 模式，也不会修改原始 Cyber 配置。

同机旧版 Apollo 会将部分单播目的地址改成 `127.0.0.1`。Bridge 的 UDP
接口白名单现同时包含 `CYBER_IP` 和回环地址，保证这些单播消息能够接收。

## 宿主机发布

在本仓库根目录：

```bash
bash scripts/start_bridge_talker.sh <宿主机IPv4> 80
```

保持进程运行。启动入口会自动加载 `build/setup.bash`。

## Apollo 容器接收

先将测试包装脚本复制进容器（在宿主机执行）：

```bash
docker cp scripts/cyber_rtps.sh apollo_dev_apollo_jihy:/tmp/bridge_cyber_rtps.sh
```

进入 Apollo 开发容器，并加载其中的 Apollo 环境：

```bash
cd /apollo
source cyber/setup.bash
export CYBER_IP=<宿主机IPv4>
export CYBER_DOMAIN_ID=80
bash /tmp/bridge_cyber_rtps.sh cyber_channel list
bash /tmp/bridge_cyber_rtps.sh cyber_channel echo channel/chatter
```

如果容器有自己的初始化脚本，先按该镜像的方式加载环境。
包装脚本要求 `CYBER_PATH/conf/cyber.pb.conf` 存在且具有活动的
`transport_conf.communication_mode.diff_proc` 配置，否则会明确退出。

成功标准：容器 `echo` 持续输出 `Hello, apollo!`，`seq` 连续增长。
仅能 list 到频道或 monitor 中看到 writer，不算消息实收验证通过。

## 故障定位

- list 没有频道：检查两端 IP、domain、容器网络模式和 DDS 发现网络。
- list 有频道但 echo 无数据：确认两端命令都经过 RTPS 包装脚本；检查消息类型和 DDS 版本兼容性。
- Python 编码错误且出现 Esafenet：检查容器内 Python 工具的透明解密情况。
- 动态库 not found：确认对应端加载了正确的环境脚本。

包装脚本复制配置到临时目录，将跨进程通信设为 RTPS，退出后清理；
测试结束后原配置不变。安装版本、不同机器、非 host 网络尚需分别验证。

## 实测结果

2026-10-22：宿主机 `10.9.10.11` → `apollo_dev_apollo_jihy`，
使用独立测试 domain 181，容器内 `cyber_channel echo channel/chatter`
连续收到 `Hello, apollo!` 与递增序号。已验证 Chatter 跨容器传输，
尚未验证 CARLA 数据及其他 Apollo 消息类型。
