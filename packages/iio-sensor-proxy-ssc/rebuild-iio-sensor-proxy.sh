#!/bin/sh
# Rebuild iio-sensor-proxy with the "always start the sensor when a client
# claims it" fix (needed for the libssc/SSC accelerometer) and install the
# patched daemon. Run again after a `pacman -Syu` upgrades iio-sensor-proxy.
set -e
PATCH=/home/walleo/kbuild/repo/iio-sensor-proxy-ssc-accel-fix.patch
SRC=/tmp/iio-sensor-proxy-build
BIN=/usr/lib/iio-sensor-proxy

rm -rf "$SRC"
GIT_CONFIG_GLOBAL=/dev/null git clone --depth 1 --branch 3.9 \
    https://gitlab.freedesktop.org/hadess/iio-sensor-proxy "$SRC"
cd "$SRC"
git apply "$PATCH"
meson setup build -Dssc-support=enabled
ninja -C build
sudo cp -a "$BIN" "$BIN.orig" 2>/dev/null || true
sudo install -m0755 build/src/iio-sensor-proxy "$BIN"
sudo systemctl restart iio-sensor-proxy
echo "iio-sensor-proxy rebuilt and installed."
