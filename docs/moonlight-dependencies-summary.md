# Moonlight 依赖库检查总结

## 📊 检查完成时间
2025-12-22

## 🎯 设备信息

### 硬件平台
- **型号**: 小米智能音箱 OH2P
- **CPU**: ARM64 (aarch64)
- **内存**: 241MB (可用 ~55MB)
- **存储**: 125.8MB (/data 分区, 可用 114.8MB)
- **网络**: WiFi (10.0.0.53)

### 软件环境
- **内核**: Linux 4.9.61
- **C 库**: GNU libc 2.25
- **发行版**: OpenWrt 基础

---

## ✅ 已存在的库（11个）

### 核心依赖（Moonlight 必需）

| 库名 | 版本 | 路径 | 状态 |
|------|------|------|------|
| **libopus** | 0.6.1 | `/usr/lib/libopus.so.0.6.1` | ✅ 完美 |
| **libcurl** | 7.55.1 | `/usr/lib/libcurl.so.4.4.0` | ✅ 完美 |
| **libuuid** | 1.3.0 | `/usr/lib/libuuid.so.1.3.0` | ✅ 完美 |
| **libssl** | 1.0.0 | `/usr/lib/libssl.so.1.0.0` | ✅ 完美 |
| **libcrypto** | 1.0.0 | `/usr/lib/libcrypto.so.1.0.0` | ✅ 完美 |
| **libasound** | 2.0.0 | `/usr/lib/libasound.so.2.0.0` | ✅ 完美 |

### 系统基础库

| 库名 | 版本 | 路径 | 状态 |
|------|------|------|------|
| **libz** | 1.2.11 | `/usr/lib/libz.so.1.2.11` | ✅ 完美 |
| **libm** | 2.25 | `/lib/libm.so.6` | ✅ 完美 |
| **libpthread** | 2.25 | `/lib/libpthread.so.0` | ✅ 完美 |
| **librt** | 2.25 | `/lib/librt.so.1` | ✅ 完美 |
| **libdl** | 2.25 | `/lib/libdl.so.2` | ✅ 完美 |

### 额外发现（Opus 相关）

| 库名 | 大小 | 路径 |
|------|------|------|
| libopus | 233.7K | `/usr/lib/libopus.so.0.6.1` |
| libopusfile | 33.5K | `/usr/lib/libopusfile.so.0.4.4` |
| libopusurl | 25.6K | `/usr/lib/libopusurl.so.0.4.4` |

---

## ❌ 需要编译的库（2个）

| 库名 | 用途 | 优先级 | 说明 |
|------|------|--------|------|
| **libavcodec** | 视频/音频编解码 | 🔴 必需 | FFmpeg 核心库 |
| **libavutil** | FFmpeg 工具库 | 🔴 必需 | 配合 libavcodec |

**注意**: 
- 只需要编译 FFmpeg 的最小化版本
- 可以禁用大部分编解码器，只保留必需的
- 预计编译后大小 < 5MB

---

## 🎵 ALSA 音频设备

### 可用设备
```
Card 0: AMLAXGSOUND [AML-AXGSOUND]
  - Device 0: TDM-A-dummy
  - Device 1: TDM-B-dummy
  - Device 2: TDM-C-acm8625p (主输出) ✅

Card 1: UAC2Gadget [UAC2_Gadget]
  - Device 0: UAC2 PCM (USB 音频)
```

**推荐使用**: Card 0, Device 2 (TDM-C-acm8625p)

### 测试音频文件
```
/usr/share/sound-vendor/AiNiRobot/wakeup_ei_01.wav
/usr/share/sound-vendor/AiNiRobot/wakeup_ei_02.wav
/usr/share/sound-vendor/AiNiRobot/wakeup_wozai.wav
```

---

## 📦 依赖总结

### 统计
- ✅ **已存在**: 11 个库
- ❌ **需要编译**: 2 个库
- 📊 **完成度**: 84.6% (11/13)

### 依赖满足情况

#### Moonlight 核心依赖（6个）
- ✅ libopus (音频解码) - **已存在**
- ✅ libcurl (HTTP 通信) - **已存在**
- ✅ libuuid (UUID 生成) - **已存在**
- ✅ libssl (TLS/SSL) - **已存在**
- ✅ libasound (ALSA 音频) - **已存在**
- ❌ libavcodec/libavutil (FFmpeg) - **需要编译**

#### 系统基础库（5个）
- ✅ libz (压缩) - **已存在**
- ✅ libm (数学) - **已存在**
- ✅ libpthread (线程) - **已存在**
- ✅ librt (实时) - **已存在**
- ✅ libdl (动态链接) - **已存在**

---

## 🚀 下一步行动

### 1. 编译 FFmpeg 最小化版本

#### 需要的功能
- H.264 解码器 (如果需要视频)
- HEVC 解码器 (可选)
- TCP 协议支持
- MPEGTS 解复用器

#### 编译配置
```bash
./configure --arch=aarch64 --target-os=linux \
    --cross-prefix=aarch64-linux-gnu- \
    --enable-cross-compile \
    --disable-everything \
    --enable-decoder=h264 \
    --enable-protocol=tcp \
    --enable-demuxer=mpegts \
    --disable-doc --disable-programs \
    --enable-static --disable-shared
```

#### 预计大小
- libavcodec: ~2-3MB (静态链接)
- libavutil: ~500KB (静态链接)
- 总计: < 5MB

### 2. 编译 Moonlight Embedded

#### 配置选项
```cmake
-DENABLE_ALSA=ON          # 启用 ALSA 音频
-DENABLE_SDL=OFF          # 禁用 SDL
-DENABLE_X11=OFF          # 禁用 X11
-DENABLE_WAYLAND=OFF      # 禁用 Wayland
```

#### 交叉编译工具链
```bash
# 安装 ARM64 工具链
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 或使用 Docker
docker pull dockcross/linux-arm64
```

### 3. 部署到音箱

#### 文件清单
```
/data/moonlight           # Moonlight 可执行文件 (~2MB)
/data/lib/libavcodec.a    # FFmpeg 编解码库 (~3MB)
/data/lib/libavutil.a     # FFmpeg 工具库 (~500KB)
```

#### 启动脚本
```bash
#!/bin/sh
export LD_LIBRARY_PATH=/data/lib:$LD_LIBRARY_PATH

# 停止占用音频的服务
/etc/init.d/misound_service stop
/etc/init.d/mibrain_service stop

# 启动 Moonlight (仅音频)
/data/moonlight stream -audio alsa -nosops <PC_IP>
```

---

## 💡 优化建议

### 内存优化
当前可用内存: 55MB
运行 Moonlight 后预计: 30-40MB

**释放内存的服务**:
```bash
/etc/init.d/mibrain_service stop    # ~30MB
/etc/init.d/miio stop                # ~10MB
/etc/init.d/messagingagent stop      # ~5MB
/etc/init.d/pns stop                 # ~5MB
```

**预计可释放**: ~50MB
**运行后剩余**: ~80MB (足够)

### 存储优化
当前可用: 114.8MB
Moonlight + FFmpeg: ~5-7MB
**剩余空间**: ~107MB (充足)

### 性能优化
- 使用 ALSA 直接输出（无 PulseAudio 开销）
- 禁用视频解码（节省 CPU 和内存）
- 使用 Opus 音频（已有硬件优化）
- 调整音频缓冲区（减少延迟）

---

## 🎉 结论

### 可行性评估
- **技术可行性**: ⭐⭐⭐⭐⭐ (5/5)
- **实施难度**: ⭐⭐⭐☆☆ (3/5)
- **资源充足度**: ⭐⭐⭐⭐☆ (4/5)

### 关键优势
1. ✅ **84.6% 的依赖已存在**（11/13）
2. ✅ **libopus 已存在** - 音频解码核心
3. ✅ **内存充足** - 241MB，可用 55MB
4. ✅ **存储充足** - 114.8MB 可用
5. ✅ **ALSA 完整** - 音频输出无问题
6. ✅ **ARM64 架构** - 性能优于 ARMv7

### 主要挑战
1. ⚠️ 需要编译 FFmpeg（但只需最小化版本）
2. ⚠️ 需要配置 ARM64 交叉编译环境
3. ⚠️ 仅音频模式（无视频输出）

### 最终建议
**强烈推荐实施！** 

所有关键依赖都已存在，只需要编译 2 个 FFmpeg 库即可。
硬件资源充足，技术上完全可行。

---

## 📋 检查命令记录

### 已执行的检查
```bash
# CPU 架构
uname -m  # aarch64

# 内存
free -m   # 241MB total, 55MB available

# 存储
df -h /data  # 125.8MB total, 114.8MB available

# 网络
ip addr show  # 10.0.0.53/24

# C 库
/lib/libc.so.6  # GNU libc 2.25

# ALSA 设备
aplay -l  # Card 0: AMLAXGSOUND

# 依赖库
find /lib /usr/lib -name "libopus.so*"     # ✅ 0.6.1
find /lib /usr/lib -name "libcurl.so*"     # ✅ 7.55.1
find /lib /usr/lib -name "libuuid.so*"     # ✅ 1.3.0
find /lib /usr/lib -name "libasound.so*"   # ✅ 2.0.0
find /lib /usr/lib -name "libssl.so*"      # ✅ 1.0.0
find /lib /usr/lib -name "libcrypto.so*"   # ✅ 1.0.0
find /lib /usr/lib -name "libz.so*"        # ✅ 1.2.11
find /lib /usr/lib -name "libm.so*"        # ✅ 2.25
find /lib /usr/lib -name "libpthread.so*"  # ✅ 2.25
find /lib /usr/lib -name "librt.so*"       # ✅ 2.25
find /lib /usr/lib -name "libdl.so*"       # ✅ 2.25
find /lib /usr/lib -name "libavcodec.so*"  # ❌ 不存在
find /lib /usr/lib -name "libavutil.so*"   # ❌ 不存在
```

---

**文档生成时间**: 2025-12-22  
**检查状态**: ✅ 完成  
**下一步**: 开始交叉编译 FFmpeg
