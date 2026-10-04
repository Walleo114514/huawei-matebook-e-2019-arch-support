# HUAWEI MateBook E 2019 (PAK-AL09 / sdm850) — Arch Linux ARM 支持补丁集

本目录汇总了让这台机器在 mainline Linux 下可用所需的全部改动，
按"能否直接复用"分成几个部分。相同型号（PAK-AL09）可直接套用。

运行环境：Arch Linux ARM (aarch64)、内核 6.14.0-rc5 (自编，见 `kernel/`)、KDE Plasma / Plasma Mobile。

---

## 目录

- `patches/kernel/`      — 内核/DTS 补丁（编译内核时打）
- `patches/userspace/`   — 用户态补丁（iio-sensor-proxy、libcamera、bluez-qt 等）
- `packages/`            — 可直接 `makepkg` 的 Arch PKGBUILD
- `install/`             — 一键安装脚本 + systemd/udev 配置
- `kernel/`              — 内核打包与说明
- `windows/`             — 从华为 Windows 驱动提取的原始配置（传感器/相机/ACPI DSDT）

---

## 一、本会话（auto-rotation / camera / sensor 阶段）新增的改动

### 1. 显示器 DT 电源域（相机 MCLK 修复）★
问题：CAMCC 传感器主时钟（`cam_cc_mclk*`）"status stuck at off"，相机开流失败。
修复：给两个摄像头节点加主线同款电源域：
```dts
front-camera@36 { power-domains = <&clock_camcc TITAN_TOP_GDSC>; };
rear-camera@10  { power-domains = <&clock_camcc TITAN_TOP_GDSC>; };
```
- 现成 DTS：`patches/kernel/matebook-6.14-bt-camera-powerdomains.dts`
- 现成 DTB：`install/rebuild-dtb.sh`

### 2. iio-sensor-proxy 的 libssc 加速度计修复 ★
问题：`ClaimAccelerometer` 时 `set_polling(TRUE)` 从不被调用（多客户端 claim 时），
加速度计永远无数据 → 自动旋转不工作。
修复：`client_add()` 里设备存在时无条件 `driver_set_polling(sensor_device, TRUE)`。
- 补丁：`patches/userspace/iio-sensor-proxy-ssc-accel-fix.patch`
- 重编脚本：`packages/iio-sensor-proxy-ssc/`

### 3. 加速度计挂载矩阵（自动旋转方向）★
问题：旋转方向相反（传感器 X 轴相对面板反了）。
修复（udev 属性，非代码）：
```
ACCEL_MOUNT_MATRIX="-1, 0, 0; 0, -1, 0; 0, 0, 1"
```
- 规则：`install/90-iio-sensor-proxy-ssc-accel.rules`
- 调参脚本：`install/planck-accel-matrix.sh`

### 4. 自动亮度守护进程 ★
问题：KDE PowerDevil 无环境光自动亮度；传感器本身正常（LTR578，遮住→0 lux）。
修复：`planck-autobrightness`（Python，systemd 用户服务）：读 iio-sensor-proxy
的环境光 → 调 PowerDevil `setBrightness`。
- 脚本+服务：`packages/planck-autobrightness/`

### 5. Camera portal（GNOME Snapshot / libcamera）★
问题：`org.freedesktop.portal.Camera.IsCameraPresent=false`——Arch 的 pipewire 不带
libcamera 摄像头插件。
修复：安装 `pipewire-libcamera`（extra 仓库），重启 pipewire/portal。
- 见 `install/install-camera-portal.sh`

### 6. libcamera 的 gc5025/s5k3l6xx sensor helper ★
问题：软件 ISP 的 AGC 因缺少 `CameraSensorHelper` 而无法调曝光 → 预览全黑。
修复：在 `src/ipa/libipa/camera_sensor_helper.cpp` 加：
```cpp
class CameraSensorHelperGc5025 : public CameraSensorHelper {
public: CameraSensorHelperGc5025() { gain_ = AnalogueGainLinear{ 1, 0, 0, 32 }; } };
REGISTER_CAMERA_SENSOR_HELPER("gc5025", CameraSensorHelperGc5025)
class CameraSensorHelperS5k3l6xx : public CameraSensorHelper {
public: CameraSensorHelperS5k3l6xx() { gain_ = AnalogueGainLinear{ 1, 0, 0, 32 }; } };
REGISTER_CAMERA_SENSOR_HELPER("s5k3l6xx", CameraSensorHelperS5k3l6xx)
```
- 补丁：`patches/userspace/libcamera-sensor-helper-gc5025-s5k3l6xx.patch`
- 重编脚本：`packages/libcamera-sensor-helper/`

### 7. planck-camera-capture（后摄抓图）★
问题：`v4l2` 抓后摄默认全黑（无 AE；且 1052x780 模式坏）。
修复：脚本改为 4208x3120 + 拉满曝光/增益，去马赛克成 PNG。
- `packages/planck-camera-capture/`

### 8. SLPI 传感器稳定（禁用 `planck-slpi-reinit`）★
问题：该服务对已在运行的 SLPI 做 stop/start → SLPI `start timed out` 卡死 →
fastrpc 内核 oops → 传感器全灭。**实测就是它导致开机后传感器失效。**
修复：禁用该服务（SLPI 现在能自行正常启动）。
```
systemctl disable --now planck-slpi-reinit.service
```

### 9. 静态度 IP（NetworkManager）
`chb666` 连接改为 `192.168.101.194/24`，网关/DNS `192.168.101.1`。
见 `install/set-static-ip.sh`（按自己的网段改）。

---

## 二、更早的会话已完成（已在本仓库中）

- **EC 驱动** `huawei-planck-ec`：电池、适配器、合盖/开盖、Fn 键等
  (`patches/kernel/huawei_planck_ec.patch`)
- **设备树补丁** `huawei_planck_devicetree.patch`
- **qseecom / UCSI(USB-C) 补丁** `huawei_planck_qseecom.patch`、
  `2-8-usb-typec-ucsi-*.patch`
- **相机传感器驱动** `camera_sensors_and_actuator.patch`
  (s5k3l6xx / gc5025 / cn3927e —— 注意：见下方"已知限制")
- **音频**：S16LE 规则 + UCM 软链，削波已修
  （`soundwire-qcom-wsa-clkstop-fix.patch`、`Qualcomm__sdm850__*.conf`）
- **蓝牙**：DT `local-bd-address` + 开机上电服务；
  `bluez-qt` rfkill 补丁 (`patches/userspace/bluez-qt-rfkill-unblocked.patch`)
- **s2idle**：禁用华为 EC 唤醒源 (`planck-ec-no-wakeup.service`)

---

## 三、已知限制（非软件可修）

- **摄像头（前 gc5025 / 后 s5k3l6xx）不出正常像素**：
  - 后摄传感器**配置完全正确且已进流**（寄存器回读全部生效）；
  - **数字彩条测试图案**能出满量程数据 → CAMSS/VFE 通路正常；
  - 但正常像素模式 **4208 全黑 / 2104 只有一条均匀带**；
  - 两个不同传感器、不同驱动、不同 MCLK 均如此 → 判定为**模组/硬件层面**。
    软件侧（驱动、寄存器、曝光、CAMSS、libcamera、portal）已排查穷尽。
- 外接显示器（USB-C DP）表现仍一般。

---

## 四、快速套用（相同型号）

```sh
tar xf matebook-e-2019-arch-support.tar.gz
cd matebook-e-2019-arch-support
sudo ./install/install-all.sh      # 装用户态补丁/脚本/服务/udev
# 内核/DTS、iio-sensor-proxy、libcamera 见各自目录的 README
```

详见各子目录 README。
