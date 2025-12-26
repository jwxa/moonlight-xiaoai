@echo off
setlocal enabledelayedexpansion
REM Moonlight ARM32 编译脚本
echo ==========================================
echo Moonlight ARM32 Build
echo ==========================================
echo.
echo Target: ARM 32-bit (armhf)
echo Audio: ALSA only
echo.

REM 检查 FFmpeg 库
if not exist "..\ffmpeg-build\output\lib\libavcodec.a" (
    echo [ERROR] FFmpeg libraries not found!
    echo Please compile FFmpeg first. 
    echo Run build-ffmpeg.bat
    pause
    exit /b 1
)
echo [OK] FFmpeg libraries found

REM 检查 Moonlight 源码
if not exist "xiaoai-moonlight-embedded" (
    echo.
    echo [1/5] Cloning Xiaoai Moonlight Embedded v2.6.2...
    git config --global core.autocrlf false
    git clone --depth 1 --branch feature/xiaoai-oh2p https://github.com/jwxa/xiaoai-moonlight-embedded
    if errorlevel 1 (
        echo Error: Failed to clone
        pause
        exit /b 1
    )
    cd xiaoai-moonlight-embedded
    git submodule update --init --recursive
    cd ..
    echo [OK] Cloned successfully
) else (
    echo.
    echo [1/5] Moonlight already cloned
)

echo.
echo [2/5] Checking Docker...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running!
    pause
    exit /b 1
)
echo [OK] Docker is running

docker images ubuntu:16.04 --format "{{.Repository}}:{{.Tag}}" | findstr "ubuntu:16.04" >nul 2>&1
if errorlevel 1 (
    echo Pulling Ubuntu 16.04...
    docker pull ubuntu:16.04
)
echo [OK] Ubuntu 16.04 ready

echo.
echo ==========================================
echo Configuration
echo ==========================================
echo.
echo Build Options:
echo   - SDL: OFF
echo   - ALSA: ON (audio only)
echo.
echo Press any key to continue...
pause >nul

echo.
echo [3/5] Building Moonlight...
echo This may take 5-10 minutes...
echo.

REM 编译 - 添加所有必需的armhf库
docker run --rm -v "%CD%:/work" -v "%CD%\..\ffmpeg-build\output:/ffmpeg" -w /work/xiaoai-moonlight-embedded ubuntu:16.04 /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && echo 'Setting up sources...' && cp /etc/apt/sources.list /etc/apt/sources.list.bak && cp /work/sources.list /etc/apt/sources.list && dpkg --add-architecture armhf && apt-get update -qq && echo 'Installing build tools...' && apt-get install -y -qq build-essential gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf cmake make pkg-config dos2unix git wget && echo 'Installing x86_64 dev packages...' && apt-get install -y -qq libevdev-dev libudev-dev && echo 'Installing armhf libraries...' && apt-get install -y -qq libssl-dev:armhf libexpat1-dev:armhf libasound2-dev:armhf libopus-dev:armhf libcurl4-openssl-dev:armhf libavahi-client-dev:armhf libavahi-common-dev:armhf uuid-dev:armhf libevdev-dev:armhf libudev-dev:armhf libsdl2-dev:armhf && echo 'Setting up environment...' && export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/lib/pkgconfig && mkdir -p /usr/lib/pkgconfig && cp /work/libavcodec.pc /usr/lib/pkgconfig/ && cp /work/libavutil.pc /usr/lib/pkgconfig/ && echo 'Patching source code...' && sed -i 's/if (haptic &&/if (state->haptic \&\&/g' src/input/sdl.c && echo 'Configuring...' && rm -rf build && mkdir -p build && cd build && cmake .. -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=arm -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_C_FLAGS='-I/ffmpeg/include -I/usr/include/arm-linux-gnueabihf' -DCMAKE_CXX_FLAGS='-I/usr/include/arm-linux-gnueabihf' -DCMAKE_EXE_LINKER_FLAGS='-L/ffmpeg/lib -L/usr/lib/arm-linux-gnueabihf -static-libgcc' -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCURL_LIBRARY=/usr/lib/arm-linux-gnueabihf/libcurl.so -DCURL_INCLUDE_DIR=/usr/include -DENABLE_SDL=ON -DENABLE_X11=OFF -DENABLE_WAYLAND=OFF -DENABLE_ALSA=ON -DENABLE_PULSE=OFF -DENABLE_CEC=OFF -DENABLE_PI=OFF && echo 'Building...' && make VERBOSE=1 -j8 2>&1 | tee /work/build.log && if [ -f moonlight ]; then cp moonlight /work/moonlight-armhf && echo 'Build complete!'; else echo 'Build failed!' && exit 1; fi"

echo.
echo [4/5] Extracting ARM dependency libraries...
echo.

REM 创建 libs 目录
if not exist "libs" mkdir libs

REM 从 Docker 容器中复制 ARM (armhf) 依赖库
echo Copying ARM libraries from container...
docker run --rm -v "%CD%:/work" ubuntu:16.04 bash -c "export DEBIAN_FRONTEND=noninteractive && echo 'Setting up sources...' && cp /etc/apt/sources.list /etc/apt/sources.list.bak && cp /work/sources.list /etc/apt/sources.list && dpkg --add-architecture armhf && apt-get update -qq && apt-get install -y -qq libssl-dev:armhf libexpat1-dev:armhf libasound2-dev:armhf libopus-dev:armhf libcurl4-openssl-dev:armhf libavahi-client-dev:armhf libavahi-common-dev:armhf uuid-dev:armhf libudev-dev:armhf libsdl2-dev:armhf && mkdir -p /work/libs && echo 'Copying ARM libraries...' && cp -L /usr/lib/arm-linux-gnueabihf/libudev.so* /work/libs/ 2>/dev/null || true && cp -L /lib/arm-linux-gnueabihf/libudev.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libopus.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libasound.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libcurl.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libssl.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libcrypto.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libexpat.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libavahi-client.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libavahi-common.so* /work/libs/ 2>/dev/null || true && cp -L /lib/arm-linux-gnueabihf/libuuid.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libuuid.so* /work/libs/ 2>/dev/null || true && cp -L /usr/lib/arm-linux-gnueabihf/libSDL2*.so* /work/libs/ 2>/dev/null || true && ls -lh /work/libs/ && echo 'ARM libraries copied successfully'"

echo.
echo ARM libraries extracted to: %CD%\libs
echo.

echo.
echo [5/5] Verifying output...
echo.

if exist "moonlight-armhf" (
    echo [OK] Binary created
    for %%F in (moonlight-armhf) do (
        set SIZE=%%~zF
        set /a SIZE_KB=!SIZE! / 1024
        echo     Size: !SIZE_KB! KB
    )
    
    echo.
    echo Checking binary...
    docker run --rm -v "%CD%:/work" -w /work ubuntu:16.04 bash -c "apt-get update -qq && apt-get install -y -qq file && file moonlight-armhf"
) else (
    echo [ERROR] Binary not found!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Build Complete!
echo ==========================================
echo.
echo Binary: %CD%\moonlight-armhf
echo Libraries: %CD%\libs
echo.

pause
