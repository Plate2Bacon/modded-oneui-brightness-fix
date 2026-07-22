# Changelog
## v3.1

Name like an incremental update to the original one.

Well, new release and new new (maybe working) features that blow your mind away
- Lux Hysteresis Deadzone (LUX_DEADZONE): Ignores minor changes in ambient light (under 8 lux) to stop the screen from constantly micro-flickering in stable lighting.
- Asymmetric Hardware Ramping (RAMP_DIV_UP & RAMP_DIV_DOWN): Uses dual-speed transitions to increase brightness instantly when walking into sunlight, while dimming the screen slowly and smoothly when moving into shadows.
- Dynamic Gear Shifting (ECO_FRAME_MS): Automatically drops the hardware polling rate from 150ms to 1000ms when the lighting environment is completely still, saving battery life.

Maybe it should work across all snapdragon based samsung devices now!

## Modified v3.0.1

- Adding some specific values to the normal Note20
- Adding some delays to the Light sensor data so that it should in a room that well-lid and your head just blocking the light to the light sensor causing it dim down the display even in well-lid area.

## v3.0

- **Fixed bootloop caused by stopping the lights HAL service.** The `stop` command killed a binder service that system_server holds a live reference to, causing a fatal crash on boot. Reverted to permission-lockout only — the HAL process runs but cannot write to the backlight sysfs node. (Thanks to Ngo An Binh for help debugging this on the SM-N981N.)
- `post-fs-data.sh` now sets `chmod 755` on the daemon binary as a safety net for ZIP extraction that may not preserve exec bits.
- Dynamic sysfs discovery: `post-fs-data.sh` scans and locks all real backlight devices, not just a hardcoded path.

## v2.0

- `max_brightness` is now read from sysfs at startup instead of being hardcoded to 510. The daemon automatically detects the device's backlight range.
- Backlight path discovered dynamically by scanning `/sys/class/backlight/` for the device with the highest `max_brightness > 0`.
- No recompilation needed for different devices.

## v1.0

- Initial release.
- Native daemon (`brightd`, 9KB ARM64) with ASensorManager NDK API via dlopen for zero-fork sensor access.
- Median-of-5 filter, asymmetric EMA, hysteresis, proportional ramping.
- Adaptive brightness with persistent slider offset (matching stock behavior).
- HAL lockout via sysfs permission change in `post-fs-data.sh`.
- Falls back to `dumpsys sensorservice` parsing if NDK sensor API unavailable.
