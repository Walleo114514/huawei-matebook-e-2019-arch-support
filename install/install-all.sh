#!/bin/bash
# Apply the userspace side of the MateBook E 2019 (PAK-AL09) support bundle.
# Run as root on a freshly installed Arch Linux ARM of the same model.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="$(dirname "$HERE")"

echo "== udev: libssc accelerometer + mount matrix =="
install -m0644 "$HERE/90-iio-sensor-proxy-ssc-accel.rules" /etc/udev/rules.d/
udevadm control --reload
udevadm trigger --subsystem-match=misc

echo "== helper scripts =="
install -m0755 "$HERE/planck-accel-matrix.sh"        /usr/local/bin/
install -m0755 "$HERE/planck-ec-no-wakeup.sh"         /usr/local/bin/
install -m0755 "$HERE/planck-lid-blank.sh"            /usr/local/bin/
install -m0755 "$DIST/packages/planck-autobrightness/planck-autobrightness" /usr/local/bin/
install -m0755 "$DIST/packages/planck-camera-capture/planck-camera-capture" /usr/local/bin/

echo "== systemd system units =="
install -m0644 "$HERE/planck-ec-no-wakeup.service" /etc/systemd/system/
install -m0644 "$HERE/planck-lid-blank.service"    /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now planck-ec-no-wakeup.service
systemctl enable --now planck-lid-blank.service

echo "== autobrightness (user service) =="
install -d -o 1000 -g 1000 /home/*/.config/systemd/user 2>/dev/null || true
for h in /home/*; do
	[ -d "$h/.config" ] || continue
	install -d -o "$(stat -c%u "$h")" -g "$(stat -c%g "$h")" "$h/.config/systemd/user"
	install -m0644 -o "$(stat -c%u "$h")" -g "$(stat -c%g "$h")" \
		"$DIST/packages/planck-autobrightness/planck-autobrightness.service" \
		"$h/.config/systemd/user/"
	u=$(basename "$h")
	sudo -u "$u" XDG_RUNTIME_DIR="/run/user/$(id -u "$u")" \
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$u")/bus" \
		systemctl --user daemon-reload 2>/dev/null || true
	sudo -u "$u" XDG_RUNTIME_DIR="/run/user/$(id -u "$u")" \
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$u")/bus" \
		systemctl --user enable --now planck-autobrightness.service 2>/dev/null || true
done

echo "== camera portal (GNOME Snapshot / libcamera) =="
"$HERE/install-camera-portal.sh" || true

echo
echo "Done. Remaining manual steps:"
echo "  * kernel / DTS / modules      -> see kernel/README.md"
echo "  * iio-sensor-proxy (patched)  -> packages/iio-sensor-proxy-ssc/"
echo "  * libcamera sensor helper     -> packages/libcamera-sensor-helper/"
echo "  * static IP                   -> install/set-static-ip.sh <if> <addr/cidr> <gw> <dns>"
