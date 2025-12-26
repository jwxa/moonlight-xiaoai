# FFmpeg 编译详细指南

---

## 📋 前置要求

### 必需
- ✅ Docker Desktop（已安装并运行）
- ✅ Git（用于克隆 FFmpeg）
- ✅ 至少 2GB 可用磁盘空间

### 可选
- 稳定的网络连接（首次下载依赖）

---

## 🚀 编译步骤

### 步骤 1: 准备工作

```cmd
REM 确保在 ffmpeg-build 目录
cd ffmpeg-build

REM 检查 Docker 是否运行
docker ps
```

### 步骤 2: 开始编译

```cmd
build-ffmpeg.bat
```

### 步骤 3: 等待完成

编译过程分为 5 个阶段：

1. **[1/5] 克隆 FFmpeg** (~1-2 分钟)
   - 下载 FFmpeg 4.4.5 源码
   - 使用 `--depth 1` 加速

2. **[2/5] 拉取 Docker 镜像** (~30 秒)
   - 下载 Ubuntu 16.04 镜像（首次）
   - 后续运行会使用缓存

3. **[3/5] 安装依赖** (~1-2 分钟)
   - 安装 ARM 交叉编译工具链
   - 安装 yasm（汇编优化）

4. **[4/5] 配置 FFmpeg** (~10 秒)
   - 检测系统
   - 生成 Makefile

5. **[5/5] 编译** (~5-10 分钟)
   - 编译源码
   - 生成静态库

### 步骤 4: 验证结果

```cmd
check-output.bat
```

应该看到：
```
[OK] libavcodec.a
     Size: 2000000+ bytes
[OK] libavutil.a
     Size: 500000+ bytes
[OK] libavformat.a
     Size: 800000+ bytes

[SUCCESS] All libraries found!
```

---

## 📂 目录结构

编译完成后：

```
ffmpeg-build/
├── FFmpeg/              # FFmpeg 源码（自动克隆）
│   ├── libavcodec/
│   ├── libavutil/
│   └── libavformat/
├── output/              # 编译输出
│   ├── lib/
│   │   ├── libavcodec.a
│   │   ├── libavutil.a
│   │   └── libavformat.a
│   └── include/
│       ├── libavcodec/
│       ├── libavutil/
│       └── libavformat/
├── build-ffmpeg.bat     # 编译脚本
├── check-output.bat     # 检查脚本
└── README.md            # 说明文档
```

---

## ⏱️ 时间估算

| 阶段 | 首次运行 | 后续运行 |
|------|---------|---------|
| 克隆 FFmpeg | 1-2 分钟 | 跳过 |
| 拉取 Docker | 30 秒 | 跳过（缓存）|
| 安装依赖 | 1-2 分钟 | 1-2 分钟 |
| 配置 | 10 秒 | 10 秒 |
| 编译 | 5-10 分钟 | 5-10 分钟 |
| **总计** | **10-15 分钟** | **5-10 分钟** |

---

## 🔍 编译输出解读

### 正常输出示例

```
==========================================
FFmpeg ARM32 Build for XiaoAI Speaker
==========================================

Target: ARM 32-bit (armhf)
Kernel: 3.2.0+ (compatible with 4.9.61)
glibc: 2.23 (compatible with 2.25)

[1/5] Cloning FFmpeg...
Cloning into 'FFmpeg'...
...

[2/5] Pulling Ubuntu 16.04 Docker image...
16.04: Pulling from library/ubuntu
...

[3/5] Installing build dependencies...
Dependencies installed!

[4/5] Configuring FFmpeg...
...
install prefix            /work/output
source path               .
C compiler                arm-linux-gnueabihf-gcc
...

[5/5] Building FFmpeg...
This will take several minutes...
CC      libavcodec/h264dec.o
CC      libavcodec/h264_cabac.o
...
AR      libavcodec/libavcodec.a
...

Build complete!

==========================================
Build Complete!
==========================================

[OK] libavcodec.a
[OK] libavutil.a
[OK] libavformat.a
```

### 错误输出示例

如果看到错误：

```
Error: Failed to clone FFmpeg
```
→ 检查网络连接，或手动克隆

```
Cannot connect to the Docker daemon
```
→ 启动 Docker Desktop

```
make: *** [libavcodec/libavcodec.a] Error 1
```
→ 查看详细错误信息，可能需要清理重试

---

## 🐛 常见问题

### Q1: 编译很慢怎么办？

**A**: 这是正常的，FFmpeg 编译需要时间。可以：
- 关闭其他程序释放 CPU
- 确保 Docker 有足够资源（设置 → Resources）
- 使用 SSD 而非 HDD

### Q2: 如何重新编译？

**A**: 
```cmd
REM 清理输出
rmdir /s /q output

REM 重新编译
build-ffmpeg.bat
```

### Q3: 如何完全重新开始？

**A**:
```cmd
REM 删除所有内容
rmdir /s /q FFmpeg
rmdir /s /q output

REM 重新编译
build-ffmpeg.bat
```

### Q4: 编译失败怎么办？

**A**: 按顺序检查：
1. Docker 是否运行？`docker ps`
2. 磁盘空间是否足够？至少 2GB
3. 网络是否正常？
4. 查看错误信息，搜索解决方案

### Q5: 可以在 Linux/Mac 上编译吗？

**A**: 可以！创建 `build-ffmpeg.sh`：
```bash
#!/bin/bash
# 类似的逻辑，使用 bash 语法
```

---

## 📊 资源占用

### 磁盘空间
- FFmpeg 源码：~200 MB
- 编译临时文件：~1 GB
- 输出文件：~4 MB
- **总计**：~1.2 GB

### 内存
- Docker 容器：~1 GB
- 编译进程：~500 MB
- **建议**：至少 2 GB 可用内存

### CPU
- 使用所有可用核心（`make -j$(nproc)`）
- 单核：~20 分钟
- 4 核：~5 分钟
- 8 核：~3 分钟

---

## 🎯 优化建议

### 加速编译

1. **增加 Docker CPU 限制**
   - Docker Desktop → Settings → Resources
   - 增加 CPU 核心数

2. **使用 ccache**（高级）
   ```bash
   apt-get install ccache
   export CC="ccache arm-linux-gnueabihf-gcc"
   ```

3. **减少启用的解码器**
   - 只保留 H.264
   - 移除 HEVC, AAC, Opus

### 减小输出大小

1. **更激进的优化**
   ```bash
   --extra-cflags="-Os -flto"
   --extra-ldflags="-flto"
   ```

2. **移除调试符号**（已默认）
   ```bash
   --disable-debug
   ```

3. **使用 strip**（已默认）
   ```bash
   arm-linux-gnueabihf-strip libavcodec.a
   ```

---

## ✅ 验证清单

编译完成后，确认：

- [ ] `output/lib/libavcodec.a` 存在（~2-3 MB）
- [ ] `output/lib/libavutil.a` 存在（~500 KB）
- [ ] `output/lib/libavformat.a` 存在（~800 KB）
- [ ] `output/include/libavcodec/` 目录存在
- [ ] `output/include/libavutil/` 目录存在
- [ ] `output/include/libavformat/` 目录存在
- [ ] 运行 `check-output.bat` 显示 SUCCESS

---

## 🚀 下一步

编译成功后：

1. ✅ 验证输出文件
2. 🚀 编译 Moonlight（见 `../NEXT_STEPS.md`）
3. 🎮 部署到音箱测试

---

**遇到问题？** 查看 `README.md` 的故障排除部分，或检查 Docker 日志。
