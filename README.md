# 一、项目
Moonlight-XiaoAI

# 二、快速开始
> [!IMPORTANT]
> 目前仅测试运行于 Xiaomi 智能音箱 Pro（OH2P） 机型，其他型号的小爱音箱请自行测试，不保证可以使用
## 2.1 配对服务端sunshine
```bash
cd /tmp/moonlight
export LD_LIBRARY_PATH=/tmp/moonlight/libs:$LD_LIBRARY_PATH
./moonlight-armhf \
    -platform oh2p \
    -keydir "./certs" \
    pair "10.0.0.14"
```
<img width="1946" height="295" alt="image" src="https://github.com/user-attachments/assets/7940244d-3f4d-4d8f-84a2-0a018fd25cf7" />

服务端输入对应PIN码
<img width="2236" height="813" alt="image" src="https://github.com/user-attachments/assets/62cd708e-0704-4bc1-9e3f-c652c43e080e" />
音箱输出成功配对
<img width="877" height="92" alt="image" src="https://github.com/user-attachments/assets/583835db-f94e-4339-aa6d-e526d19fbf36" />

## 2.2 连接服务端sunshine

```bash
cd /tmp/moonlight
export LD_LIBRARY_PATH=/tmp/moonlight/libs:$LD_LIBRARY_PATH
./moonlight-armhf \
    -platform oh2p \
    -keydir "./certs" \
    -viewonly \
    -width 640 \
    -height 480 \
    -bitrate 1000 \
    -fps 30 \
    -bitrate 5000 \
    -nosops \
    -audio dmixer \
    stream -app "Desktop" "10.0.0.14"
```
<img width="2805" height="1330" alt="image" src="https://github.com/user-attachments/assets/180a8ad6-3192-473d-9a63-c41716e0928e" />

# 三、项目说明
## 3.1.工作流程
```
游戏主机 (PC)
    ↓
[编码] H.264视频 + Opus音频
    ↓
[网络传输] TCP/UDP
    ↓
智能音箱 (Moonlight)
    ↓
[FFmpeg libavformat] 解析容器格式
    ↓
[FFmpeg libavcodec] 解码视频/音频
    ↓
[ALSA] 音频输出到扬声器
```


## 3.2 库文件目录

moonlight-xiaoai\moonlight-build\libs
相关来源目录：
ffmpeg-build\output\lib
moonlight-build\xiaoai-moonlight-embedded\build\libgamestream

### 3.2.1 完整依赖关系树
```
moonlight (主程序)
├── [编译时静态链接]
│   ├── libavcodec.a (FFmpeg 解码器)
│   ├── libavutil.a (FFmpeg 工具)
│   └── libavformat.a (FFmpeg 容器)
├── [运行时动态链接]
│   ├── libmoonlight-common.so.4 (自编译)
│   ├── libgamestream.so.4 (自编译)
│   ├── 音频输出
│   ├── libasound.so.2 (ALSA)
│   └── libopus.so.0 (Opus解码)
├── 网络通信
│   ├── libcurl.so.4
│   │   ├── libssl.so.1.0.0
│   │   ├── libcrypto.so.1.0.0
│   │   ├── libgssapi_krb5.so.2 (可选)
│   │   ├── libldap-2.4.so.2 (可选)
│   │   ├── libidn.so.11
│   │   └── librtmp.so.1
│   └── libavahi-client.so.3
│       └── libavahi-common.so.3
├── 系统功能
│   ├── libudev.so.1
│   ├── libuuid.so.1
│   ├── libevdev.so.2
│   └── libexpat.so
└── 视频输出 (可选)
    └── libSDL2-2.0.so.0
```

### 3.2.2 库文件说明

#### A. FFmpeg 编解码库 (静态链接，编译时依赖)

| 库文件 | 版本 | 来源 | 用途 |
|--------|------|------|------|
| `libavcodec.a` | 4.4.5 | 自编译 (ffmpeg-build) | 视频/音频解码器核心 (H.264/HEVC/Opus/AAC) |
| `libavutil.a` | 4.4.5 | 自编译 (ffmpeg-build) | FFmpeg 工具函数库 (内存/数学/像素格式) |
| `libavformat.a` | 4.4.5 | 自编译 (ffmpeg-build) | 容器格式支持 (MPEG-TS/H.264/HEVC) |

**说明**: 
- 这些是**静态库**（.a 文件），在编译时链接到 moonlight 二进制文件中
- 不需要部署到音箱，已包含在 moonlight 可执行文件内
- 总大小约 3.8 MB，是 Moonlight 解码音视频流的核心引擎
- 必须先编译 FFmpeg，才能编译 Moonlight

**编译位置**: `ffmpeg-build/output/lib/`

**链接方式**:
```bash
# 编译时静态链接
moonlight.o + libavcodec.a + libavutil.a + libavformat.a 
    ↓
moonlight (可执行文件，包含 FFmpeg 代码)
```

#### B. 核心音频库 (Core Audio - 运行时依赖)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libasound.so.2.0.0` | 2.0.0 | `libasound2:armhf` | ALSA音频输出核心库 |
| `libopus.so.0.5.2` | 0.5.2 | `libopus0:armhf` | Opus音频解码器 |

**说明**: 这是音频串流的运行时核心依赖，必须部署到音箱。

#### C. 网络通信库 (Network - 运行时依赖)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libcurl.so.4.4.0` | 7.47.0 | `libcurl4-openssl-dev:armhf` | HTTP/HTTPS客户端 |
| `libssl.so.1.0.0` | 1.0.2g | `libssl-dev:armhf` | SSL/TLS加密通信 |
| `libcrypto.so.1.0.0` | 1.0.2g | `libssl-dev:armhf` | 加密算法库 |

**说明**: 用于与游戏主机建立安全连接，运行时必需。

#### D. 服务发现库 (Service Discovery - 运行时依赖)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libavahi-client.so.3.2.9` | 0.6.32 | `libavahi-client-dev:armhf` | mDNS客户端 |
| `libavahi-common.so.3.5.3` | 0.6.32 | `libavahi-common-dev:armhf` | mDNS通用库 |

**说明**: 用于局域网内自动发现游戏主机，运行时必需。

#### E. 系统基础库 (System - 运行时依赖)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libudev.so.1.6.4` | 229 | `libudev-dev:armhf` | 设备管理 |
| `libuuid.so.1.3.0` | 2.27.1 | `uuid-dev:armhf` | UUID生成 |
| `libexpat.so` | 2.1.0 | `libexpat1-dev:armhf` | XML解析 |
| `libevdev.so.2.1.12` | 1.4.6 | `libevdev-dev:armhf` | 输入设备事件处理 |

**说明**: 系统级基础功能支持，运行时必需。

#### F. 认证和安全库 (Authentication - 运行时依赖，可选)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libgssapi_krb5.so.2.2` | 1.13.2 | `libgssapi-krb5-2:armhf` | Kerberos GSSAPI |
| `libkrb5.so.3.3` | 1.13.2 | `libkrb5-3:armhf` | Kerberos 5 |
| `libk5crypto.so.3.1` | 1.13.2 | `libk5crypto3:armhf` | Kerberos加密 |
| `libkrb5support.so.0.1` | 1.13.2 | `libkrb5support0:armhf` | Kerberos支持库 |
| `libcom_err.so.2.1` | 1.42.13 | 系统自带 | 错误处理 |

**说明**: 用于企业级认证（可选，大多数家庭用户不需要）。

#### G. LDAP 支持库 (Directory Services - 运行时依赖，可选)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libldap-2.4.so.2.10.5` | 2.4.42 | `libldap-2.4-2:armhf` | LDAP客户端 |
| `libldap_r-2.4.so.2.10.5` | 2.4.42 | `libldap-2.4-2:armhf` | LDAP可重入版本 |
| `liblber-2.4.so.2.10.5` | 2.4.42 | `liblber-2.4-2:armhf` | BER编码 |
| `libsasl2.so.2.0.25` | 2.1.26 | `libsasl2-2:armhf` | SASL认证 |

**说明**: LDAP目录服务支持（可选）。

#### H. 其他网络协议库 (运行时依赖，可选)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libidn.so.11.6.15` | 1.32 | `libidn11:armhf` | 国际化域名 |
| `librtmp.so.1` | 2.4 | `librtmp1:armhf` | RTMP协议 |

#### I. SDL2 图形库 (运行时依赖，可选)

| 库文件 | 版本 | 来源包 | 用途 |
|--------|------|--------|------|
| `libSDL2-2.0.so.0.4.0` | 2.0.4 | `libsdl2-dev:armhf` | SDL2图形库 |

**说明**: 仅在启用视频输出时需要，纯音频版本不需要。

#### J. Moonlight 自编译库 (运行时依赖)

| 库文件 | 版本 | 来源 | 用途 |
|--------|------|------|------|
| `libmoonlight-common.so.4` | 2.6.2 | 编译生成 | Moonlight通用库 |
| `libgamestream.so.4` | 2.6.2 | 编译生成 | GameStream协议库 |

**说明**: 这些是 Moonlight 项目自己编译生成的库。



# 常见问题
## 1. 缺少so文件
如libgamestream.so.4
/tmp/moonlight/moonlight-armhf: error while loading shared libraries: libgamestream.so.4: cannot open shared object file: No such file or directory
用软连接 / 复制项目里的libs
```shell
root@OH2P:/tmp/moonlight# cd libs/
root@OH2P:/tmp/moonlight/libs# ln -s libgamestream.so.2.6.2 libgamestream.so.4
```

