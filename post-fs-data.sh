#!/system/bin/sh
# Lock all real backlight sysfs nodes to root-only write.
# Scans /sys/class/backlight/ and locks any device with max_brightness > 0.
# Dummy/virtual devices (max=0) are skipped.
for d in /sys/class/backlight/*/; do
    max=$(cat "$d/max_brightness" 2>/dev/null)
    [ "$max" -gt 0 ] 2>/dev/null || continue
    chown root:root "$d/brightness"
    chmod 644 "$d/brightness"
done
