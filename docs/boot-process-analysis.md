# 小米智能音箱启动流程分析

## 固件信息
- **固件版本**: mico_all_f009a180c_1.58.6
- **设备型号**: OH2P (小米小爱音箱)
- **芯片平台**: Amlogic (晶晨)
- **文件系统**: SquashFS (只读) + UBIFS (可读写数据分区)

---

## 一、启动流程概览

```
U-Boot (Bootloader)
    ↓
Kernel (Linux 4.9.61)
    ↓
/init (initramfs)
    ↓
/sbin/init (BusyBox init)
    ↓
/etc/inittab
    ↓
/etc/init.d/rcS (启动脚本)
    ↓
系统服务启动
```

---

## 二、详细启动阶段

### 阶段 1: Bootloader (U-Boot)
**相关文件**:
- `u-boot.bin.encrypt.usb.bl2`
- `u-boot.bin.encrypt.usb.tpl`
- `boot.img.encrypt`
- `dtb.img.encrypt`

**功能**:
1. 硬件初始化
2. 读取环境变量 `boot_part` (boot0/boot1 双系统切换)
3. 加载内核和设备树
4. 启动 Linux 内核

---

### 阶段 2: 内核初始化
**内核版本**: Linux 4.9.61

**加载的内核模块**:
- `gpio-ir-rx.ko` - 红外接收
- `gpio-ir-tx.ko` - 红外发射
- `skw_wifi_driver.ko` - WiFi 驱动

---

### 阶段 3: Init 脚本 (`/init`)

**文件**: `/init`

**主要功能**:
1. **挂载基础文件系统**
   ```bash
   mount -t proc proc /proc
   mount -t sysfs sysfs /sys
   ```

2. **创建设备节点**
   - `/dev/mtdblock*` - MTD 块设备
   - `/dev/input/event0` - 输入设备
   - `/dev/i2c-*` - I2C 设备

3. **双系统切换逻辑**
   ```bash
   curr_boot=`fw_env -g boot_part`  # 读取当前启动分区 (boot0/boot1)
   
   if [ "$curr_boot" = "boot0" ]; then
       mtd="4"  # 使用 /dev/mtdblock4
   else
       mtd="5"  # 使用 /dev/mtdblock5
   fi
   ```

4. **挂载根文件系统**
   ```bash
   mount -t squashfs /dev/mtdblock${mtd} /mnt
   ```
   - 如果挂载失败，自动切换到另一个系统分区并重启

5. **切换到真实根文件系统**
   ```bash
   exec switch_root -c /dev/console /mnt /sbin/init
   ```

---

### 阶段 4: BusyBox Init (`/sbin/init`)

**配置文件**: `/etc/inittab`

```
::sysinit:/etc/init.d/rcS S boot
::shutdown:/etc/init.d/rcS K shutdown
tts/0::askfirst:/bin/ash --login
ttyS0::askfirst:/bin/ash --login
tty1::askfirst:/bin/ash --login
```

**说明**:
- `sysinit`: 系统初始化，执行 `/etc/init.d/rcS S boot`
- `shutdown`: 关机时执行 `/etc/init.d/rcS K shutdown`
- `askfirst`: 在串口和终端提供登录 shell

---

### 阶段 5: 系统服务启动 (`/etc/init.d/rcS`)

#### 5.1 Boot 脚本 (`/etc/init.d/boot`)
**启动顺序**: S10 (START=10)

**主要任务**:
1. **挂载数据分区**
   ```bash
   ubiattach -p /dev/mtd6
   mount -t ubifs /dev/ubi0_0 /data
   ```
   - 如果挂载失败，格式化数据分区并重新挂载

2. **同步设备信息** (`sync_broadinfo`)
   - 从 unifykeys 读取设备信息：
     - `sn` - 序列号
     - `mac_wifi` - WiFi MAC 地址
     - `mac_bt` - 蓝牙 MAC 地址
     - `miio_did` - 米家设备 ID
     - `miio_key` - 米家设备密钥
   - 写入 `/data/etc/device.info`

3. **WiFi/蓝牙准备**
   ```bash
   wifi_bt_driver_prepare_oh2p()
   mkdir -p /data/wifi /data/bt
   echo "$mac_wifi" > /data/wifi/wifimac.txt
   echo "$mac_bt" > /data/bt/bdaddr
   ```

4. **音频配置**
   ```bash
   alsactl -f /etc/asound.state restore
   ```

5. **时间初始化**
   - 设置时区为 PRC (中国)
   - 从固件编译时间初始化系统时间

6. **设置主机名**
   ```bash
   hostname_set()  # 使用设备型号作为主机名
   ```

---

#### 5.2 服务启动顺序 (按 S 编号)

| 顺序 | 服务名 | 功能 |
|------|--------|------|
| S10 | boot | 基础系统初始化 |
| S11 | sysctl | 内核参数配置 |
| S13 | check_mac | MAC 地址检查 |
| S15 | alsa | 音频系统 |
| S20 | ledd | LED 灯控制 |
| S41 | quickplayer | 快速播放器 |
| S50 | adbd | Android Debug Bridge |
| S50 | cron | 定时任务 |
| S50 | dropbear | SSH 服务器 |
| S50 | micosysd | **核心系统守护进程** |
| S50 | syslog-ng | 系统日志 |
| S54 | pns_ubus_helper | 推送通知辅助 |
| S55 | pns | 推送通知服务 |
| S60 | dbus | D-Bus 消息总线 |
| S61 | wireless | WiFi 管理 |
| S62 | bluetoothd | 蓝牙守护进程 |
| S62 | dnsmasq | DNS/DHCP 服务 |
| S62 | miio | **米家物联网服务** |
| S62 | miio_agent | 米家代理 |
| S62 | miio_client | 米家客户端 |
| S65 | debug_hq_skwifi | WiFi 调试 |
| S70 | alarm | 闹钟服务 |
| S70 | coredump | 崩溃转储 |
| S70 | mediaplayer | 媒体播放器 |
| S70 | messagingagent | 消息代理 |
| S70 | mico_helper | 小爱助手 |
| S75 | bluetooth | 蓝牙服务 |
| S79 | idmruntime | IDM 运行时 |
| S85 | mico_aivs_lab | AI 语音实验室 |
| S90 | micovis | 视觉服务 |
| S92 | touchpad | 触摸板 |
| S95 | done | 启动完成标记 |
| S96 | mibrain_service | **小爱大脑服务** |
| S96 | mico_ai_crontab | AI 定时任务 |
| S96 | mico_ir_agent | 红外遥控代理 |
| S96 | nano_httpd | HTTP 服务器 |
| S96 | voip | 语音通话 |
| S97 | usb | USB 服务 |
| S98 | gpio_switch | GPIO 开关 |
| S99 | boot-test-end | 启动测试结束 |
| S99 | misound_service | **小爱音频服务** |
| S99 | urandom_seed | 随机数种子 |
| S99 | zsilentboot | 静默启动 |

---

## 六、核心服务详解

### 1. micosysd (S50)
**功能**: 核心系统守护进程
- 使用 procd 管理
- 自动重启机制
- 负责系统级服务协调

### 2. miio (S62)
**功能**: 米家物联网协议栈
- 启动 `miio_client` 和 `miio_agent`
- 运行 `miio_helper` 辅助进程
- 处理米家设备绑定和通信

**关键配置**:
- `/data/etc/miio.cfg` - 米家注册状态 (由 `miio_fix_registed_file()` 创建)
- `/data/wifi/stereo_ssid` - 立体声配对 SSID (从 `/data/wifi/micowpa.conf` 迁移)
- `/data/wifi/wpa.conf` - WiFi 配置文件
- `/usr/share/mico/miio.cfg` - 米家功能配置 (ROM 内置)

### 3. mibrain_service (S96)
**功能**: 小爱同学 AI 大脑
- 语音识别和处理
- 智能对话引擎
- 蓝牙模式下不启动

### 4. misound_service (S99)
**功能**: 音频处理服务
- 音频流管理
- 音效处理
- 音量控制

---

## 四、配置文件系统详解

### 配置文件来源和创建时机

#### 1. `/data/etc/device.info`
**创建**: `sync_broadinfo()` 函数 (在 `/etc/init.d/boot` 中)
**来源**: 从 unifykeys 读取硬件信息
```bash
echo "deviceid" > /sys/class/unifykeys/name
sn=`cat /sys/class/unifykeys/read`
echo "didkey" > /sys/class/unifykeys/name
res=`cat /sys/class/unifykeys/read`
miio_did=`echo $res | cut -d '|' -f 2`
miio_key=`echo $res | cut -d '|' -f 3`
```
**内容**: SN, MAC地址, 米家DID/KEY, 设备型号

#### 2. `/data/etc/miio.cfg`
**创建**: `miio_fix_registed_file()` 函数 (在 `boot_function.sh` 中)
**触发条件**: 当用户 UID 存在时
```bash
local uid=$(micocfg_uid)
[ x"$uid" == x"-1" -o x"$uid" == x"" ] && return
micocfg_set /data/etc/miio.cfg registed true
```
**用途**: 标记设备已注册到米家

#### 3. `/data/wifi/stereo_ssid`
**创建**: `handle_old_stereo_ssid()` 函数 (在 `/etc/init.d/miio` 中)
**来源**: 从旧配置文件迁移
```bash
local old_ssid="$(micocfg_get /data/wifi/micowpa.conf stereo_ssid)"
if [ "$old_ssid" != "" ]; then
    echo "$old_ssid" > /data/wifi/stereo_ssid
fi
```
**用途**: 保存立体声配对的 WiFi SSID

#### 4. `/data/wifi/wpa.conf`
**路径定义**: `/etc/init.d/wireless`
```bash
WIRELESS_CONF="/data/wifi/wpa.conf"
```
**用途**: WPA WiFi 连接配置

#### 5. `/data/etc/messaging.cfg`
**创建**: `binfo_translate_to_config()` 函数
**来源**: 从旧 UCI 格式转换
```bash
cat /data/messagingagent/messaging | \
  awk -F "[ \']" '{if($1~/option/) printf tolower($2)" = \""$4"\";\n"}' \
  > /data/etc/messaging.cfg
```
**用途**: 消息推送配置

#### 6. `/data/etc/sound.cfg`
**创建**: `/etc/init.d/misound_service`
**来源**: 从 ROM 复制默认配置
```bash
if [ ! -f /data/etc/sound.cfg ]; then
    cp /usr/share/mico/sound.cfg /data/etc/sound.cfg
fi
```
**用途**: 音频系统配置

#### 7. `/data/etc/nightmode.cfg`
**创建**: `/etc/init.d/ledd`
**默认内容**:
```bash
total="night";
light="night";
volume="night";
start="22:00";
stop="06:00";
```
**用途**: 夜间模式时间和行为配置

#### 8. `/data/bt/bluetooth.cfg`
**创建**: `bluetooth_init()` 函数
**内容**: 蓝牙可发现性、可连接性、使能状态
```bash
micocfg_bt_discoverable_set 1
micocfg_bt_connectable_set 1
micocfg_bt_enable_set 1
```

#### 9. `/usr/share/mico/miio.cfg` (ROM 内置)
**位置**: 只读文件系统
**用途**: 定义米家功能特性
- `wifi_direct` - WiFi Direct 支持
- `wifi_scan` - WiFi 扫描功能
- `http_dns_support` - HTTP DNS 支持

### 配置文件格式

系统使用两种配置格式：

1. **Key-Value 格式** (新格式)
```
key = "value";
sn = "12345/ABCDE";
mac_wifi = "AA:BB:CC:DD:EE:FF";
```

2. **UCI 格式** (旧格式，已废弃)
```
config section 'name'
    option key 'value'
```

系统启动时会自动将旧 UCI 格式转换为新的 Key-Value 格式。

---

## 五、文件系统结构

### MTD 分区布局
```
/dev/mtd0 - bootloader
/dev/mtd1 - env (环境变量)
/dev/mtd2 - dtb (设备树)
/dev/mtd3 - reserved
/dev/mtd4 - boot0 (系统分区 A)
/dev/mtd5 - boot1 (系统分区 B)
/dev/mtd6 - data (用户数据分区 UBIFS)
```

### 关键目录
```
/data/              - 用户数据分区 (可读写)
  ├── etc/          - 配置文件
  │   ├── device.info      - 设备信息 (SN, MAC, DID, KEY)
  │   ├── miio.cfg         - 米家注册状态
  │   ├── messaging.cfg    - 消息推送配置
  │   ├── sound.cfg        - 音频配置
  │   └── nightmode.cfg    - 夜间模式配置
  ├── wifi/         - WiFi 配置
  │   ├── wifimac.txt      - WiFi MAC 地址
  │   ├── wpa.conf         - WPA 配置
  │   ├── stereo_ssid      - 立体声配对 SSID
  │   └── config.txt       - WiFi 驱动配置
  ├── bt/           - 蓝牙配置
  │   ├── bdaddr           - 蓝牙 MAC 地址
  │   └── bluetooth.cfg    - 蓝牙设置
  ├── miio/         - 米家数据
  └── init.sh       - 自定义启动脚本 (patch 添加)

/usr/share/mico/    - ROM 内置配置模板
  ├── miio.cfg            - 米家功能配置 (wifi_direct, wifi_scan 等)
  ├── sound.cfg           - 默认音频配置
  └── messaging/          - 消息配置模板
```

---

## 七、固件 Patch 修改内容

### 1. SSH 启用 (01-ssh.patch)
- **移除 SSH 启动限制**
- 原固件需要 `/data/ssh_en` 文件或特定渠道才能启动 SSH
- Patch 后无条件启动 dropbear SSH 服务

### 2. 登录修改 (02-login.patch)
- **修改 root 密码**: 替换为自定义密码哈希
- **禁用串口登录验证**: `ttyS0` 直接进入 shell
- **禁用 PAM 认证**: 注释掉 `libmico-pam.so`，使用标准 Unix 认证

### 3. OTA 禁用 (03-ota.patch)
- **禁用固件升级**: 防止官方 OTA 覆盖修改
- 修改 `/bin/ota`、`/bin/flash.sh`、`/etc/init.d/wireless`
- 所有升级函数直接返回失败

### 4. 自定义启动脚本 (04-start.patch)
- **添加自定义启动钩子**
- 在 `/etc/rc.local` 中添加：
  ```bash
  [ -f "/data/init.sh" ] && sh /data/init.sh &
  ```
- 允许用户在 `/data/init.sh` 中添加自定义启动命令

---

## 八、启动时间线

```
0s    - U-Boot 启动
1s    - 内核加载
2s    - /init 执行，挂载根文件系统
3s    - /sbin/init 启动
4s    - S10 boot 脚本执行
5s    - 基础服务启动 (S11-S50)
6s    - 网络服务启动 (S60-S62)
8s    - 应用服务启动 (S70-S96)
10s   - 启动完成 (S99)
```

---

## 九、关键配置工具

### micocfg 系列命令
用于读写设备配置的工具集：

```bash
micocfg_sn              # 序列号
micocfg_mac             # WiFi MAC
micocfg_bt_mac          # 蓝牙 MAC
micocfg_model           # 设备型号
micocfg_version         # 固件版本
micocfg_uid             # 用户 ID
micocfg_miot_did        # 米家设备 ID
micocfg_miot_key        # 米家设备密钥
micocfg_work_mode       # 工作模式 (normal/bluetooth)
```

---

## 十、调试和开发

### 串口访问
- **波特率**: 115200
- **端口**: ttyS0
- **登录**: 直接进入 ash shell (已 patch)

### SSH 访问
- **端口**: 22
- **用户**: root
- **密码**: 由 patch 设置

### 日志查看
```bash
logread                 # 查看系统日志
dmesg                   # 查看内核日志
cat /proc/kmsg          # 实时内核消息
```

### 自定义启动
创建 `/data/init.sh`:
```bash
#!/bin/sh
# 自定义启动脚本
echo "Custom init script running..."
# 添加你的命令
```

---

## 十一、总结

小米智能音箱采用标准的 Linux 启动流程，基于 OpenWrt 框架构建。启动过程分为：
1. **Bootloader 阶段**: U-Boot 双系统切换
2. **内核阶段**: Linux 4.9.61 + 驱动加载
3. **Init 阶段**: 挂载文件系统和设备初始化
4. **服务阶段**: 按顺序启动 50+ 个系统服务

核心服务包括：
- **micosysd**: 系统守护进程
- **miio**: 米家物联网
- **mibrain_service**: AI 语音引擎
- **misound_service**: 音频处理

通过 patch 可以：
- 启用 SSH 访问
- 禁用 OTA 升级
- 添加自定义启动脚本
- 修改系统行为
