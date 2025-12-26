@echo off
setlocal enabledelayedexpansion
REM FFmpeg ARM32 编译脚本 - 简化版
REM 使用 Ubuntu 16.04 确保兼容性

echo ==========================================
echo FFmpeg ARM32 Build for XiaoAI Speaker
echo ==========================================
echo.
echo Target: ARM 32-bit (armhf)
echo Kernel: 3.2.0+ (compatible with 4.9.61)
echo glibc: 2.23 (compatible with 2.25)
echo.

REM 检查磁盘空间（简化版，仅提示）
echo [INFO] Please ensure at least 2 GB free disk space
echo.

REM 检查是否已克隆 FFmpeg
if not exist "FFmpeg" (
    echo [1/5] Cloning FFmpeg...
    echo Configuring Git to preserve line endings...
    git config --global core.autocrlf false
    git clone --depth 1 --branch n4.4.5 https://github.com/FFmpeg/FFmpeg.git
    if errorlevel 1 (
        echo Error: Failed to clone FFmpeg
        pause
        exit /b 1
    )
    echo [OK] FFmpeg cloned successfully
) else (
    echo [1/5] FFmpeg already cloned, skipping...
)

echo.
echo [2/5] Checking Docker and Ubuntu 16.04 image...
echo.

REM 检查 Docker 是否运行
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running!
    echo.
    echo Please start Docker Desktop and try again.
    echo.
    pause
    exit /b 1
)
echo [OK] Docker is running

REM 检查 Ubuntu 16.04 镜像是否存在
docker images ubuntu:16.04 --format "{{.Repository}}:{{.Tag}}" | findstr "ubuntu:16.04" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Ubuntu 16.04 image not found, pulling...
    echo This may take a few minutes...
    echo.
    docker pull ubuntu:16.04
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to pull Ubuntu 16.04 image!
        echo.
        echo Try using a mirror:
        echo docker pull registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04
        echo docker tag registry.cn-hangzhou.aliyuncs.com/library/ubuntu:16.04 ubuntu:16.04
        echo.
        pause
        exit /b 1
    )
    echo [OK] Ubuntu 16.04 image pulled successfully
) else (
    echo [OK] Ubuntu 16.04 image already exists
)

echo.
echo ==========================================
echo Pre-build Check Summary
echo ==========================================
echo.
echo [OK] Docker is running
echo [OK] Ubuntu 16.04 image ready
echo [OK] FFmpeg source ready
echo.
echo Ready to build FFmpeg for ARM32!
echo This will take 10-15 minutes on first run.
echo.
echo Press any key to continue, or Ctrl+C to cancel...
pause >nul

echo.
echo [3/5] Installing dependencies and configuring...
echo This may take a few minutes...
echo.

REM 使用 bash 明确执行，设置正确的 shell 环境
docker run --rm -v "%CD%:/work" -w /work/FFmpeg ubuntu:16.04 /bin/bash -c "export CONFIG_SHELL=/bin/bash && export SHELL=/bin/bash && apt-get update -qq && apt-get install -y -qq gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf make yasm pkg-config dos2unix && echo '' && echo 'Converting line endings...' && dos2unix configure 2>/dev/null || true && find . -type f -name '*.sh' -exec dos2unix {} \; 2>/dev/null || true && echo '' && echo '[4/5] Configuring FFmpeg...' && /bin/bash ./configure --arch=arm --target-os=linux --cross-prefix=arm-linux-gnueabihf- --enable-cross-compile --prefix=/work/output --disable-everything --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages --disable-programs --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-network --disable-avdevice --disable-swresample --disable-swscale --disable-postproc --disable-avfilter --enable-avcodec --enable-avformat --enable-avutil --enable-decoder=h264 --enable-decoder=hevc --enable-decoder=aac --enable-decoder=opus --enable-protocol=tcp --enable-protocol=udp --enable-demuxer=mpegts --enable-demuxer=h264 --enable-demuxer=hevc --enable-parser=h264 --enable-parser=hevc --enable-parser=aac --enable-static --disable-shared --enable-small --disable-debug --extra-cflags='-Os -ffunction-sections -fdata-sections' --extra-ldflags='-Wl,--gc-sections' && echo '' && echo '[5/5] Building FFmpeg...' && echo 'This will take several minutes...' && make -j$(nproc) && echo '' && echo 'Installing...' && make install"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo Build Failed!
    echo ==========================================
    echo.
    echo Possible causes:
    echo 1. Network connection issues
    echo 2. Insufficient disk space
    echo 3. Docker resource limits
    echo.
    echo Troubleshooting:
    echo - Check Docker Desktop settings (Resources)
    echo - Ensure at least 2GB free disk space
    echo - Try running again (may be temporary network issue)
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Build Complete!
echo ==========================================
echo.

echo Verifying output files...
echo.

set BUILD_SUCCESS=1

if exist "output\lib\libavcodec.a" (
    echo [OK] libavcodec.a
    for %%F in (output\lib\libavcodec.a) do (
        set SIZE=%%~zF
        set /a SIZE_MB=!SIZE! / 1048576
        echo     Size: !SIZE_MB! MB
    )
) else (
    echo [MISSING] libavcodec.a
    set BUILD_SUCCESS=0
)

if exist "output\lib\libavutil.a" (
    echo [OK] libavutil.a
    for %%F in (output\lib\libavutil.a) do (
        set SIZE=%%~zF
        set /a SIZE_KB=!SIZE! / 1024
        echo     Size: !SIZE_KB! KB
    )
) else (
    echo [MISSING] libavutil.a
    set BUILD_SUCCESS=0
)

if exist "output\lib\libavformat.a" (
    echo [OK] libavformat.a
    for %%F in (output\lib\libavformat.a) do (
        set SIZE=%%~zF
        set /a SIZE_KB=!SIZE! / 1024
        echo     Size: !SIZE_KB! KB
    )
) else (
    echo [MISSING] libavformat.a
    set BUILD_SUCCESS=0
)

echo.

if %BUILD_SUCCESS%==1 (
    echo ==========================================
    echo SUCCESS! All libraries built successfully!
    echo ==========================================
    echo.
    echo Output directory: %CD%\output
    echo Libraries: %CD%\output\lib
    echo Headers: %CD%\output\include
    echo.
    echo ==========================================
    echo Next Steps
    echo ==========================================
    echo.
    echo 1. Verify output
    echo 2. Compile Moonlight
    echo.
) else (
    echo ==========================================
    echo WARNING: Some libraries are missing!
    echo ==========================================
    echo.
    echo Please check the build output above for errors.
    echo You may need to run the build again.
    echo.
)

pause
