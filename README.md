# 一、项目
Moonlight-XiaoAI
## 介绍
串流工具moonlight的音箱版本
功能：只输出声音
特性：低延迟

# 二、快速开始
> [!IMPORTANT]
> 目前仅测试运行于 Xiaomi 智能音箱 Pro（OH2P） 机型，其他型号的小爱音箱请自行测试，不保证可以使用
## 2.1 配对服务端sunshine
```bash
cd /tmp/moonlight
chmod a+x moonlight-armhf
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
## 3.1 工作流程
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

从音箱看库文件是否齐全
```
root@OH2P:/tmp/moonlight# ldd /tmp/moonlight/moonlight-armhf
/tmp/moonlight/moonlight-armhf: /usr/lib/libcurl.so.4: no version information available (required by libgamestream.so.4)
/tmp/moonlight/moonlight-armhf: /usr/lib/libcrypto.so.1.0.0: no version information available (required by libgamestream.so.4)
/tmp/moonlight/moonlight-armhf: /usr/lib/libcrypto.so.1.0.0: no version information available (required by libgamestream.so.4)
	libm.so.6 => /lib/libm.so.6 (0xf76ed000)
	libgamestream.so.4 (0xf76cf000)
	libSDL2-2.0.so.0 (0xf7606000)
	libasound.so.2 (0xf755a000)
	libevdev.so.2 (0xf753c000)
	libopus.so.0 (0xf74f8000)
	libudev.so.1 (0xf74e2000)
	libmoonlight-common.so.4 (0xf7499000)
	libpthread.so.0 => /lib/libpthread.so.0 (0xf746f000)
	libc.so.6 => /lib/libc.so.6 (0xf7333000)
	/lib/ld-linux-armhf.so.3 (0xf776f000)
	libcurl.so.4 => /usr/lib/libcurl.so.4 (0xf72e8000)
	libcrypto.so.1.0.0 => /usr/lib/libcrypto.so.1.0.0 (0xf71c0000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0xf7194000)
	libavahi-common.so.3 (0xf717b000)
	libavahi-client.so.3 (0xf7160000)
	libuuid.so.1 (0xf714c000)
	libdl.so.2 => /lib/libdl.so.2 (0xf7139000)
	librt.so.1 => /lib/librt.so.1 (0xf7122000)
	libgcc_s.so.1 => /lib/libgcc_s.so.1 (0xf7107000)
	libcares.so.2 => /usr/lib/libcares.so.2 (0xf70e9000)
	libssl.so.1.0.0 => /usr/lib/libssl.so.1.0.0 (0xf7099000)
	libdbus-1.so.3 => /usr/lib/libdbus-1.so.3 (0xf7050000)
```

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

# 四、写给自己
## 4.1 TODO
sunshine服务端改造，增加audio-only模式，减少网络带宽占用
配套更新当前client端

## 4.2 复盘
### 调研踩坑步骤
#### 1. 背景调研
##### 1.1 实施方法
拉取最新固件解包ROM 分析系统架构，已经存在的依赖库
rom\mico_all_f009a180c_1.58.6.bin
[open-xiaoai](https://github.com/idootop/open-xiaoai) [patch脚本/extract.sh](https://github.com/idootop/open-xiaoai/blob/main/packages/client-patch/src/extract.sh)

##### 1.2 ✅ 验证
AI分析结果文档：
[boot-process-analysis.md](docs\boot-process-analysis.md)

##### 1.3 接下来的步骤
1. 🎯 让AI分析Moonlight移植项目可行性

#### 2. Moonlight 移植项目可行性调研
##### 2.1 实施方法
1. 拉取moonlight-embedded代码让AI分析
2. AI写一个程序验证依赖库
3. AI对2中的验证程序创建脚本，docker交叉编译环境的搭建

##### 2.2 ✅ 验证
可行性调研分析文档
docs\moonlight-dependencies-summary.md

test-demo/test_libs_simple 预期输出
```
╔════════════════════════════════════════════════╗
║   小米智能音箱 - 依赖库测试程序 (简化版)     ║
║   XiaoAI Speaker - Library Test (Simple)      ║
╚════════════════════════════════════════════════╝

=== 系统信息 ===
CPU 架构:   arm (ARM32)
编译时间:   Dec 22 2025 ...

=== 开始测试 ===

[✓] libm (数学库)
[✓] libpthread (线程库)

=== 测试动态库加载 ===

[✓] libopus.so.0 (Opus 音频)
[✓] libcurl.so.4 (cURL HTTP)
[✓] libuuid.so.1 (UUID)
[✓] libssl.so.1.0.0 (OpenSSL)
[✓] libcrypto.so.1.0.0 (OpenSSL Crypto)
[✓] libasound.so.2 (ALSA)
[✓] libz.so.1 (zlib)

=== 测试总结 ===
通过: 9
失败: 0
总计: 9

🎉 所有测试通过！所有库都可以加载！
```
##### 2.3 遇到的问题
###### 2.3.1 内核版本问题
编译的二进制文件要求 **Linux 内核 5.4.0**，但音箱只有 **4.9.61**
使用 **Ubuntu 16.04** 编译，它会生成兼容旧内核的二进制文件：
- 目标内核：3.2.0（远低于音箱的 4.9.61）✅
- glibc：2.23（兼容音箱的 2.25）✅
- 动态链接器：`/lib/ld-linux-armhf.so.3`（正确）✅

##### 2.4 接下来的步骤
1. ✅ 确认交叉编译环境正常
2. ✅ 确认所有库可以调用
3. 🎯 开始编译 FFmpeg

#### 3. 开始编译 FFmpeg
##### 3.1 实施方法
AI写编译脚本
[README.md](ffmpeg-build\README.md)
**编译脚本**[build-ffmpeg.bat](ffmpeg-build\build-ffmpeg.bat)
[FFmpeg 编译详细指南](ffmpeg-build\BUILD_GUIDE.md)

##### 3.2 ✅ 验证

编译成功后应该看到：
```
[OK] libavcodec.a
     Size: 2 MB
[OK] libavutil.a
     Size: 500 KB
[OK] libavformat.a
     Size: 800 KB

SUCCESS! All libraries built successfully!
```
##### 3.3 接下来的步骤
1. ✅ 编译 FFmpeg
2. 🚀 开始编译 Moonlight

#### 4. 编译 Moonlight
##### 4.1 实施方法
AI写编译脚本

##### 4.2 ✅ 验证
client端连接sunshine成功

##### 4.3 遇到的问题
###### 4.3.1 pair失败
刚开始分析以为是相关libssl.so和libcrypto.so过老导致加密算法不支持，手动编译1.0.2版本后没有解决
继续分析：**HTTP 连接正常** **HTTPS 测试失败** 怀疑和证书有关
AI继续读了下源码 创建测试脚本：setup-moonlight-certs.sh 
```
# Moonlight 默认使用 ~/.cache/moonlight 或 ~/.config/moonlight
CERT_DIR="$HOME/.cache/moonlight"
```
执行后发现报错权限问题
```
mkdir: can't create directory '/root/.cache/': Read-only file system
```
1. ✓ **curl 和 OpenSSL 编译成功**
2. ✓ **HTTP 连接正常**
3. ✗ **HTTPS 测试失败** - 这是正常的！需要客户端证书
4. ✗ **moonlight 无法生成证书** - `/root/.cache` 是只读的

这导致 moonlight 无法在默认位置生成客户端证书。
解决方案：使用 `-keydir` 参数指定可写目录（`/tmp/moonlight/certs`）。
####### 生成的文件
```bash
ls -la /tmp/moonlight/certs/
# client.pem    - 客户端证书
# key.pem       - 私钥  
# client.p12    - PKCS12 格式
# uniqueid.dat  - 设备 ID
```

###### 4.3.2 没有输出声音
让AI写分析脚本 ./diagnose-audio.sh 
```bash
root@OH2P:/tmp/moonlight# ./diagnose-audio.sh 

==========================================

Audio Diagnostics

==========================================

1. Check ALSA devices...

 0 [AMLAXGSOUND    ]: AML-AXGSOUND - AML-AXGSOUND

                      AML-AXGSOUND

 1 [UAC2Gadget     ]: UAC2_Gadget - UAC2_Gadget

                      UAC2_Gadget 0

2. Check ALSA PCM devices...

drwxr-xr-x    2 root     root           280 Dec  7 14:31 .

drwxr-xr-x    7 root     root          3020 Dec  7 14:31 ..

crw-rw----    1 root     audio     116,   0 Jan  1  2015 controlC0

crw-rw----    1 root     audio     116,  32 Dec  7 14:31 controlC1

crw-rw----    1 root     audio     116,  24 Jan  1  2015 pcmC0D0c

crw-rw----    1 root     audio     116,  16 Jan  1  2015 pcmC0D0p

crw-rw----    1 root     audio     116,  25 Jan  1  2015 pcmC0D1c

crw-rw----    1 root     audio     116,  17 Jan  1  2015 pcmC0D1p

crw-rw----    1 root     audio     116,  26 Jan  1  2015 pcmC0D2c

crw-rw----    1 root     audio     116,  18 Jan  1  2015 pcmC0D2p

crw-rw----    1 root     audio     116,  27 Jan  1  2015 pcmC0D3c

crw-rw----    1 root     audio     116,  56 Dec  7 14:31 pcmC1D0c

crw-rw----    1 root     audio     116,  48 Dec  7 14:31 pcmC1D0p

crw-rw----    1 root     audio     116,  33 Jan  1  2015 timer

3. Check audio mixer...

--- Master volume ---

Simple mixer control 'Master',0

  Capabilities: pvolume

  Playback channels: Front Left - Front Right

  Limits: Playback 0 - 16

  Mono:

  Front Left: Playback 16 [100%]

  Front Right: Playback 16 [100%]

--- PCM volume ---

No PCM control

--- All controls ---

Simple mixer control 'Master',0

Simple mixer control 'HCIC shift gain from coeff',0

Simple mixer control 'Loopback Enable',0

Simple mixer control 'Loopback datain source',0

Simple mixer control 'Loopback tmdin lb source',0

Simple mixer control 'PDM Filter Mode',0

Simple mixer control 'PDM Gain',0

Simple mixer control 'SPDIFIN Sample Rate',0

Simple mixer control 'bluetooth',0

Simple mixer control 'mysoftvol',0

Simple mixer control 'notifyvol',0

Simple mixer control 'pdm dclk',0

Simple mixer control 'usbvol',0

4. Check running processes...

5. Test audio output (if aplay available)...

Playing test tone...

**** List of PLAYBACK Hardware Devices ****

card 0: AMLAXGSOUND [AML-AXGSOUND], device 0: TDM-A-dummy dummy-0 []

  Subdevices: 1/1

  Subdevice #0: subdevice #0

card 0: AMLAXGSOUND [AML-AXGSOUND], device 1: TDM-B-dummy dummy-1 []

  Subdevices: 1/1

  Subdevice #0: subdevice #0

card 0: AMLAXGSOUND [AML-AXGSOUND], device 2: TDM-C-acm8625p multicodec-2 []

  Subdevices: 0/1

  Subdevice #0: subdevice #0

card 1: UAC2Gadget [UAC2_Gadget], device 0: UAC2 PCM [UAC2 PCM]

  Subdevices: 1/1

  Subdevice #0: subdevice #0

6. Check ALSA configuration...

--- /etc/asound.conf ---

# oh2p asound.conf

pcm.!default {

    type plug

    slave {

        pcm "vis"

        format S16_LE

        rate 48000

    }

}

pcm.vis {

    type file

    slave.pcm "tocopy"

    file "|safe_fifo /tmp/vis_audio.fifo /tmp/mis_audio.fifo"

}

pcm.tocopy {

    type copy

    slave {

        pcm "Playback"

    }

}

pcm.Playback {

    type plug

    slave.pcm {

        type softvol

        slave.pcm "dmixer"

        control {

            name "mysoftvol"

            card 0

        }

        min_dB -51.0

        max_dB 0.0

    }

}

pcm.usb_up {

    type plug

    slave {

        pcm "hw:UAC2Gadget"

        rate 48000

        format S16_LE

        channels 2

    }

}

pcm.CaptureUsbDown {

    type plug

    slave.pcm {

        type dsnoop

        ipc_key 3333

        ipc_perm 0666

        slave {

            pcm "hw:UAC2Gadget"

            rate 48000

            format S16_LE

            channels 2

            period_size 480

            periods 8

        }

    }

}

pcm.notify {

    type plug

    slave {

        pcm {

            type softvol

            slave.pcm dmixer

            control {

                name "notifyvol"

                card 0

            }

            min_dB -51.0

            max_dB 0.0

        }

        channels 2

        format S16_LE

        rate 48000

    }

}

pcm.dmixer {

    type dmix

    ipc_key 1024

    slave {

        pcm "hw:0,2"

        format S16_LE

        period_size 480

        buffer_size 4800

        rate 48000

    }

    bindings {

        0 0

        1 1

    }

}

ctl.dmixer {

    type hw

    card 0

    device 1

}

pcm.dsp {

    type plug

    slave.pcm "dmixer"     # use our new PCM here

}

ctl.mixer {

    type hw

    card 0

}

pcm.dis {

    type plug

    slave.pcm noop

}

pcm.mico_record {

    type plug

    slave.pcm Capture

}

pcm.noop {

    type plug

    slave.pcm Capture

}

pcm.Capture {

    type plug

    slave.pcm {

        type dsnoop

        ipc_key 1024

        ipc_perm 0666

        slave {

            pcm "hw:0,3"

            rate 48000

            format S32_LE

            channels 4

            period_size 384

            buffer_size 6144

        }

    }

}

defaults.pcm.rate_converter "speexrate_medium"

No ~/.asoundrc

7. Set volume to 100%...

Simple mixer control 'Master',0

  Capabilities: pvolume

  Playback channels: Front Left - Front Right

  Limits: Playback 0 - 16

  Mono:

  Front Left: Playback 16 [100%]

  Front Right: Playback 16 [100%]

Volume set to 100%

==========================================

Diagnostics complete

==========================================

If you see audio devices above, try:

  1. Increase volume: amixer set Master 100%

  2. Unmute: amixer set Master unmute

  3. Check PC audio: Make sure PC is playing sound

  4. Restart stream: ./play
```

```
/etc/asound.conf
```

###### 音频路由图

```
输入源：
├─ Type-C USB (UAC2Gadget) → usb_up / CaptureUsbDown
├─ 蓝牙 (bluetooth control)
├─ 网络应用 (notify, mysoftvol)
└─ Moonlight (新增)

混音层：
├─ dmixer (硬件混音器) ← 所有音频汇聚这里
│   ├─ IPC key: 1024
│   ├─ 输出: hw:0,2 (TDM-C)
│   └─ 格式: S16_LE, 48000Hz
│
└─ 软件音量控制
    ├─ mysoftvol (主音量)
    ├─ notifyvol (通知音量)
    └─ usbvol (USB 音量)

输出：
└─ hw:0,2 (TDM-C-acm8625p) ← 物理扬声器

确认输出设备要选择dmixer, 编写脚本测试直接通过dmixer能否输出声音，成功
```
#!/bin/sh

echo "=========================================="
echo "Moonlight Audio Diagnostics"
echo "=========================================="
echo ""

echo "Step 1: Verify dmixer works with aplay"
echo "---"
if command -v aplay >/dev/null 2>&1; then
    echo "Testing dmixer with aplay..."
    if command -v speaker-test >/dev/null 2>&1; then
        timeout 3 speaker-test -t wav -c 2 -l 1 -D dmixer 2>&1 | head -5
        echo "✓ dmixer works with aplay"
    else
        echo "✓ aplay available (speaker-test not found)"
    fi
else
    echo "✗ aplay not available"
fi
echo ""
```

继续尝试依旧没有声音，由于当时的启动命令只能通过platform指定为fake启动，故让AI分析内部逻辑究竟会不会有音频输出
```
# Start streaming
# Note: Removed -platform fake because it disables audio output
/tmp/moonlight/moonlight-armhf \
    -platform oh2p \
    -keydir "$CERT_DIR" \
    -viewonly \
    -width 640 \
    -height 480 \
    -bitrate 1000 \
    -fps 30 \
    -bitrate 5000 \
    -nosops \
    -audio dmixer \
    stream -app "$APP" "$SERVER"
```
发现只能pair和stream相关，实际音频流并不会在音箱播放

想要使用platform为pi进行编译运行，由于没有屏幕显示，依旧报错
```
root@OH2P:/tmp/moonlight# export SDL_VIDEODRIVER=dummy

root@OH2P:/tmp/moonlight# export SDL_AUDIODRIVER=alsa

root@OH2P:/tmp/moonlight# export AUDIODEV=dmixer

root@OH2P:/tmp/moonlight# ./moonlight-audio-only stream -platform sdl -keydir=/tmp/moonlight/certs -app "Desktop" "10.0.0.14"

./moonlight-audio-only: libcurl.so.4: no version information available (required by libgamestream.so.4)

./moonlight-audio-only: libcrypto.so.1.0.0: no version information available (required by libgamestream.so.4)

./moonlight-audio-only: libcrypto.so.1.0.0: no version information available (required by libgamestream.so.4)

Connecting to 10.0.0.14...

# 脚本过度精简，使用 --disable-video --disable-events 完全禁用了这些子系统
Could not initialize SDL - SDL not built with events support
Could not initialize SDL - SDL not built with video support

# 新的错误 SDL: could not create window - exiting 说明 SDL 初始化成功了，但在创建窗口时失败。这是因为 dummy 驱动虽然编译了，但 moonlight 的 SDL 代码仍然尝试创建实际窗口。
SDL: could not create window - exiting
```

原构建脚本的 SDL2 配置**过度精简**：
```bash
--disable-video    # 完全禁用视频
--disable-events   # 完全禁用事件
```

但 moonlight 源代码 (`src/sdl.c:42`) 强制要求：
```c
SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)
```
于是让AI编写了一个platform为oh2p的，支持音频流，把视频流自动忽略丢弃

# 五、巨人的肩膀
## 项目列表
[open-xiaoai](https://github.com/idootop/open-xiaoai)
[moonlight-embedded](https://github.com/moonlight-stream/moonlight-embedded)
[moonlight-common-c](https://github.com/moonlight-stream/moonlight-common-c)
[ffmpeg](https://github.com/FFmpeg/FFmpeg.git)
...

## 工具
kira
claude
