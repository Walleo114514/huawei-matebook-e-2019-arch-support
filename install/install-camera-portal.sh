#!/bin/bash
# Make libcamera cameras visible to the XDG Camera portal (GNOME Snapshot,
# Firefox, etc.).  Arch's pipewire package does not ship the libcamera SPA
# plugin, so the portal reports "no camera".
set -e
pacman -S --needed --noconfirm pipewire-libcamera libcamera libcamera-ipa libcamera-tools

# restart the whole camera chain
for u in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $2}'); do
	uid=$(id -u "$u" 2>/dev/null) || continue
	sudo -u "$u" XDG_RUNTIME_DIR="/run/user/$uid" \
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" bash -c '
			systemctl --user restart pipewire.socket pipewire-pulse.socket pipewire.service wireplumber.service
			sleep 4
			systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gnome.service
		' 2>/dev/null || true
done

echo "Installed. IsCameraPresent should now be true after login."
echo "Verify: cam -l   (libcamera-tools)"
