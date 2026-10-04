# 内核（sdm845 / MateBook E 2019）

## 当前工作内核
- 版本：`6.14.0-rc5`（`uname -r`）
- Image：`/boot/vmlinuz-6.14.0-rc5-75hz`（75Hz 面板实验版；也有 `vmlinuz-6.14.0-rc5`）
- DTB：`/boot/sdm850-huawei-matebook-e-2019-6.14-bt.dtb`（相机电源域已打）
- 配置特点：`CONFIG_LOCALVERSION=""`、`CONFIG_MODVERSIONS=n`、`CONFIG_MODULE_SIG=n`
  → 模块版本魔术 `6.14.0-rc5`，可与 `/lib/modules/6.14.0-rc5` 互换。
- cmdline 需要：`pd_ignore_unused clk_ignore_unused`

## 源码
内核源码基线来自 sdm845-mainline（`linux-sdm845-<ver>-dev`）。
打包时在其上打 `../patches/kernel/` 里的补丁：

| 补丁 | 作用 |
|---|---|
| `huawei_planck_ec.patch` | 华为 EC 驱动（电池/适配器/合盖/Fn/背光） |
| `huawei_planck_devicetree.patch` | 本机设备树（含摄像头节点） |
| `huawei_planck_qseecom.patch` | qseecom |
| `2-8-usb-typec-ucsi-*.patch` | USB-C UCSI |
| `camera_sensors_and_actuator.patch` | s5k3l6xx / gc5025 / cn3927e 相机驱动 |
| `soundwire-qcom-wsa-clkstop-fix.patch` | 扬声器 clock-stop 修复 |
| `matebook-6.14-bt-camera-powerdomains.dts` | 相机电源域 DTS（参考） |

## 构建（Arch Linux ARM 原生）

```sh
# 1) 准备源码树（例如 sdm845-mainline 6.14）
cd /path/to/linux-src
for p in /path/to/dist/patches/kernel/*.patch; do patch -p1 < "$p"; done

# 2) 用与当前一致的最小 config（去掉模块签名/版本，保持模块可复用）
cp /boot/config-6.14.0-rc5 .config
scripts/config --file .config --disable MODULE_SIG --disable MODVERSIONS
make ARCH=arm64 olddefconfig

# 3) 构建
make ARCH=arm64 -j"$(nproc)" Image modules dtbs
```

产物：
- `arch/arm64/boot/Image`
- `arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dtb`
- `drivers/.../*.ko`

## 用 PKGBUILD 打成 Arch 包

见 `PKGBUILD`（把 `_src` 指到你的内核源码目录，或改成从 git 拉取）。

```sh
makepkg -si          # 产出 matebook-e-2019-kernel-<ver>-aarch64.pkg.tar.zst
```

它会安装：
- `/boot/vmlinuz-<ver>`
- `/boot/<dtb>`
- `/lib/modules/<ver>/`（含 EC / 相机 / 音频模块）

## 已有的 deb 包

`linux-image.deb`（旧构建，22MB，Debian 系可直接 `dpkg -i`）。

## 启动配置（GRUB，自定义条目）

```
linux /@/boot/vmlinuz-6.14.0-rc5-75hz root=UUID=... rw rootflags=subvol=@ \
      pd_ignore_unused clk_ignore_unused
devicetree /@/boot/sdm850-huawei-matebook-e-2019-6.14-bt.dtb
initrd /@/boot/initrd.img-6.14.0-rc5
```

## 无 EC 驱动 / 7.1 内核说明
7.1 内核源码也在这台机器上可用（`/home/walleo/kbuild/linux`），但 EC 驱动目前以
6.14 为稳。若用 7.1，需要重新适配 EC/相机补丁。
