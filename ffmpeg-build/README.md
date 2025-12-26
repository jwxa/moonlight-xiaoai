# FFmpeg ARM32 编译

为小米智能音箱编译最小化的 FFmpeg 库。

---

## 🎯 目标

编译 FFmpeg 的三个核心库：
- `libavcodec.a` - 视频/音频解码器（H.264, HEVC, AAC, Opus）
- `libavutil.a` - 工具函数库
- `libavformat.a` - 容器格式支持

---

## 🚀 快速开始

### 前置检查（可选）

在编译前，可以运行检查脚本验证环境：

```cmd
test-checks.bat
```

这会检查：
- ✅ Docker 是否运行
- ✅ Ubuntu 16.04 镜像是否存在
- ✅ 磁盘空间是否充足（至少 2GB）
- ✅ FFmpeg 源码是否已克隆

### Windows

```cmd
build-ffmpeg.bat
```

这会：
1. 自动检查 Docker 状态
2. 检查/拉取 Ubuntu 16.04 镜像
3. 检查磁盘空间
4. 克隆 FFmpeg 4.4.5（如果还没有）
5. 使用 Ubuntu 16.04 Docker 编译
6. 生成静态库到 `output/` 目录
7. 验证输出文件

### 预计时间
- 首次运行：10-15 分钟（下载依赖 + 编译）
- 后续运行：5-8 分钟（仅编译）

---

## 📦 输出文件

编译完成后，你会得到：

```
output/
├── lib/
│   ├── libavcodec.a    (~2-3 MB)
│   ├── libavutil.a     (~500 KB)
│   └── libavformat.a   (~800 KB)
└── include/
    ├── libavcodec/
    ├── libavutil/
    └── libavformat/
```

---

## ⚙️ 编译配置

### 启用的功能
- ✅ H.264 解码器（主要）
- ✅ HEVC 解码器
- ✅ AAC 解码器
- ✅ Opus 解码器
- ✅ TCP/UDP 协议
- ✅ MPEG-TS 容器

### 禁用的功能
- ❌ 所有编码器
- ❌ 网络功能
- ❌ 滤镜
- ❌ 重采样
- ❌ 缩放
- ❌ 命令行工具

### 优化选项
- `-Os` - 优化文件大小
- `-ffunction-sections -fdata-sections` - 分段编译
- `-Wl,--gc-sections` - 移除未使用代码
- `--enable-small` - 最小化构建

---

## 🔧 技术细节

### 编译环境
- **Docker 镜像**: ubuntu:16.04
- **工具链**: gcc-arm-linux-gnueabihf
- **目标架构**: ARM 32-bit (armhf)
- **glibc**: 2.23（兼容音箱的 2.25）
- **目标内核**: 3.2.0+（兼容音箱的 4.9.61）

### FFmpeg 版本
- **版本**: 4.4.5（稳定版）
- **发布日期**: 2023
- **选择原因**: 稳定、成熟、资源占用低

---

## 📊 预期文件大小

| 库 | 大小 | 说明 |
|---|---|---|
| libavcodec.a | ~2-3 MB | 解码器（最大） |
| libavutil.a | ~500 KB | 工具函数 |
| libavformat.a | ~800 KB | 容器格式 |
| **总计** | **~3-4 MB** | 静态库总大小 |

音箱有 114.8MB 可用空间，完全足够。

---

## 🔍 验证编译结果

### 检查文件类型
```bash
docker run --rm -v "%CD%:/work" -w /work ubuntu:16.04 bash -c \
  "apt-get update -qq && apt-get install -y -qq file && \
   file output/lib/libavcodec.a"
```

**预期输出**:
```
libavcodec.a: current ar archive
```

### 检查符号
```bash
docker run --rm -v "%CD%:/work" -w /work ubuntu:16.04 bash -c \
  "apt-get update -qq && apt-get install -y -qq binutils-arm-linux-gnueabihf && \
   arm-linux-gnueabihf-nm output/lib/libavcodec.a | grep h264"
```

应该看到 H.264 相关的符号。

---

## 🐛 故障排除

### 问题 1: Docker 未运行

**错误信息**:
```
[ERROR] Docker is not running!
```

**解决方法**:
1. 启动 Docker Desktop
2. 等待 Docker 完全启动
3. 重新运行 `build-ffmpeg.bat`

### 问题 2: Ubuntu 镜像拉取失败

**错误信息**:
```
[ERROR] Failed to pull Ubuntu 16.04 image!
```

**解决方法**:
```cmd
REM 使用国内镜像
docker pull registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04
docker tag registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04 ubuntu:16.04

REM 然后重新运行
build-ffmpeg.bat
```

### 问题 3: Git 克隆失败
**解决方法**:
```cmd
REM 手动克隆
git clone --depth 1 --branch n4.4.5 https://github.com/FFmpeg/FFmpeg.git

REM 然后重新运行
build-ffmpeg.bat
```

### 问题 4: configure 脚本换行符错误

**错误信息**:
```
bash: ./configure: /bin/sh^M: bad interpreter
```

**原因**: Git 在 Windows 上转换了换行符

**快速修复**:
```cmd
REM 方法 1: 修复现有源码（推荐）
fix-line-endings.bat

REM 方法 2: 重新克隆
clean-and-reclone.bat
```

详见：`换行符问题修复.txt`

### 问题 5: 磁盘空间不足

**警告信息**:
```
[WARNING] Low disk space: ~1 GB free
```

**解决方法**:
1. 清理磁盘空间（至少需要 2GB）
2. 清理 Docker：`docker system prune -a`
3. 删除不需要的文件

### 问题 5: Docker 拉取失败
```cmd
REM 使用国内镜像
docker pull registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04
docker tag registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04 ubuntu:16.04
```

### 问题 3: 编译错误
```cmd
REM 清理后重试
rmdir /s /q FFmpeg
rmdir /s /q output
build-ffmpeg.bat
```

### 问题 4: 磁盘空间不足
编译需要约 2GB 临时空间。清理 Docker：
```cmd
docker system prune -a
```

---

## 📝 下一步

编译完成后：

1. ✅ 验证 `output/lib/` 中有三个 `.a` 文件
2. ✅ 验证 `output/include/` 中有头文件
3. 🚀 继续编译 Moonlight（见 `../NEXT_STEPS.md`）

---

## 💡 高级选项

### 添加更多解码器

编辑 `build-ffmpeg.bat`，在配置部分添加：
```bash
--enable-decoder=vp8 \
--enable-decoder=vp9 \
```

### 启用硬件加速（如果支持）

```bash
--enable-hwaccel=h264_v4l2m2m \
```

### 调试构建

移除优化选项，添加调试信息：
```bash
--enable-debug \
--disable-optimizations \
```

---

## 📚 参考资料

- [FFmpeg 官方文档](https://ffmpeg.org/documentation.html)
- [FFmpeg 编译指南](https://trac.ffmpeg.org/wiki/CompilationGuide)
- [交叉编译指南](https://trac.ffmpeg.org/wiki/CompilationGuide/CrossCompilingForARM)

---

**准备好了吗？运行 `build-ffmpeg.bat` 开始编译！** 🚀
