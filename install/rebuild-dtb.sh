#!/bin/bash
# Patch the running DTB with the camera power-domains (fixes the CAMCC MCLK
# "status stuck at off" that prevented both cameras from powering up).
#
# Usage: rebuild-dtb.sh /boot/sdm850-huawei-matebook-e-2019-6.14-bt.dtb
set -e
DTB="${1:?path to the DTB in use}"
[ -f "$DTB" ] || { echo "no such dtb: $DTB"; exit 1; }
command -v fdtput >/dev/null || { echo "install dtc first (pacman -S dtc)"; exit 1; }

cp -a "$DTB" "$DTB.bak-$(date +%Y%m%d-%H%M%S)"
# TITAN_TOP_GDSC == 5 in qcom,camcc-sdm845.h
for node in \
  /soc@0/cci@ac4a000/i2c-bus@1/front-camera@36 \
  /soc@0/cci@ac4a000/i2c-bus@0/rear-camera@10 ; do
	fdtput -t i "$DTB" "$node" power-domains 0xd8 0x05
	echo "patched $node"
done
echo "done. Reboot for it to take effect."
