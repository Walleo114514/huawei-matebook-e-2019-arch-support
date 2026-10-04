#!/bin/sh
# The Huawei EC (i2c 7-0076) is registered as a wakeup source but its IRQ is
# very chatty (spurious events), which aborts s2idle after a few seconds.
# Disable it as a wakeup source so the system can stay suspended. The power
# key (pm8941 pwrkey / gpio-keys) still wakes the system.
for _ in $(seq 1 30); do
    p=/sys/bus/i2c/devices/7-0076/power/wakeup
    if [ -w "$p" ]; then
        echo disabled > "$p"
        exit 0
    fi
    sleep 1
done
exit 0
