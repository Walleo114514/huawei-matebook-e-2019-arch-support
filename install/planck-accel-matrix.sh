#!/bin/sh
# Change the accelerometer mount matrix for the Huawei MateBook E 2019 (SSC/libssc)
# and reload it immediately. Usage:
#
#   planck-accel-matrix.sh                 # show current matrix
#   planck-accel-matrix.sh "-1, 0, 0; 0, 1, 0; 0, 0, 1"   # set matrix
#   planck-accel-matrix.sh xflip           # -1, 0, 0; 0, 1, 0; 0, 0, 1
#   planck-accel-matrix.sh yflip           #  1, 0, 0; 0,-1, 0; 0, 0, 1
#   planck-accel-matrix.sh rot180          # -1, 0, 0; 0,-1, 0; 0, 0, 1
#   planck-accel-matrix.sh identity        #  1, 0, 0; 0, 1, 0; 0, 0, 1
set -e
RULES=/etc/udev/rules.d/90-iio-sensor-proxy-ssc-accel.rules

case "$1" in
	xflip)    MTX="-1, 0, 0; 0, 1, 0; 0, 0, 1" ;;
	yflip)    MTX=" 1, 0, 0; 0,-1, 0; 0, 0, 1" ;;
	rot180)   MTX="-1, 0, 0; 0,-1, 0; 0, 0, 1" ;;
	identity) MTX=" 1, 0, 0; 0, 1, 0; 0, 0, 1" ;;
	"")       grep -h 'ACCEL_MOUNT_MATRIX' "$RULES"; exit 0 ;;
	*)        MTX="$1" ;;
esac

sudo sed -i -E 's#^(\s*SUBSYSTEM==\"misc\", KERNEL==\"fastrpc-\*\", ENV\{ACCEL_MOUNT_MATRIX\}=).*#\1"'"$MTX"'"#' "$RULES"
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=misc
sudo systemctl restart iio-sensor-proxy
echo "Mount matrix set to: $MTX"
echo "Restarted iio-sensor-proxy."
