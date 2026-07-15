# OneUI ROM Brightness Fix
# WARNING: THIS IS A FORKED VERSION AND CONTAINS SOME OF THE SPECIFIC DATA FOR NORMAL NOTE20 5G SO IF YOU ARE ON OTHER MODELS (e.g: Note20 Ultra, etc) PLEASE CHECK OUT THE ORIGINAL BRIGHTNESS FIX FROM THIS DEVELOPER (https://github.com/combeng6th/oneui-brightness-fix). THANK YOU!
A Magisk module that fixes broken brightness and adaptive brightness on Samsung devices running custom OneUI ROMs or kernels.

## Who this is for

If you're running a **custom ROM or kernel** on a Samsung phone and your brightness is stuck on max, your slider does nothing, or adaptive brightness doesn't work — this module is for you.

This commonly happens when:
- A ROM built for one Samsung phone is ported to a different model
- A custom kernel changes the display driver behavior
- The lights HAL (the software that controls screen brightness) doesn't match your phone's actual display hardware

**This module is NOT needed if your stock brightness already works.** It's specifically for cases where the brightness system is broken.

## What it does

When the brightness is broken on a custom ROM, it's usually because the lights HAL — the piece of software that translates "set brightness to 50%" into actual hardware commands — is sending the wrong values to your screen's backlight controller. On affected devices, the HAL typically writes maximum brightness regardless of what you set the slider to.

This module fixes that in two steps:

1. **Blocks the broken HAL.** At boot, before the broken lights HAL starts up, the module changes file permissions so the HAL can no longer write to the backlight. It doesn't crash or interfere with the HAL process — the writes just silently fail.

2. **Runs its own brightness controller.** A small native daemon (~9KB) starts at boot and takes over. It reads your phone's ambient light sensor directly using Android's built-in sensor API and adjusts the screen brightness smoothly — just like the adaptive brightness you're used to on a stock ROM.

### What works after installing

- **Adaptive brightness** — screen adjusts automatically based on ambient light
- **Slider adjustments** — dragging the slider in auto mode shifts the brightness curve, just like stock (your adjustments are remembered)
- **Manual mode** — turning off adaptive brightness gives you full manual slider control
- **Smooth transitions** — no flickering, no sudden jumps
- **Reboots** — the fix is permanent (installed as a Magisk module)

## Compatibility

Developed and tested on:

- **Galaxy Note 20 Ultra (SM-N9860, Snapdragon 865+)** running [Astro-OS v3.x](https://xdaforums.com/t/closed-astro-os-oneui-8-0-galaxy-note20-series-snapdragon-s23-ultra-port-version-3-1-0-ai-port-camera-enhancements-optimize.4786282/) (OneUI 8, S23 Ultra port)

Should work on any Samsung device where:
- The brightness is broken due to a mismatched lights HAL
- The backlight is controlled via `/sys/class/backlight/panel0-backlight/brightness` (standard Qualcomm MDSS path)
- The ambient light sensor is functional

While designed for the Snapdragon Note 20 Ultra running Astro-OS OneUI 8, the underlying approach should work across modern OneUI ROMs on older Qualcomm-based Samsung devices with similar brightness issues.

**Requirements:**
- Magisk v20.4 or newer
- ARM64 device
- Root access

## Installation

1. Download `oneui-brightness-fix-v1.0.zip` from the [Releases](https://github.com/combeng6th/oneui-brightness-fix/releases) page
2. Open **Magisk Manager** → **Modules** → **Install from storage**
3. Select the ZIP file
4. Reboot

After rebooting, brightness should work immediately. Toggle adaptive brightness on or off from the notification shade as usual.

## Uninstalling

Open Magisk Manager → Modules → tap the trash icon next to "OneUI ROM Brightness Fix" → Reboot. Your original brightness behavior (even if broken) will be restored.

## Tuning

The default brightness curve works well for most indoor and outdoor conditions. If you want to adjust it:

Edit the `AUTO_K` value in `brightd.c`:
```c
#define AUTO_K 50   /* lower number = brighter at the same light level */
```

Rebuild:
```
clang -O2 -Wall -o brightd brightd.c -ldl && llvm-strip brightd
```

Replace the binary in `/data/adb/modules/oneui_brightness_fix/brightd` and reboot.

## How it works (technical details)

The daemon (`brightd`) uses `dlopen` to load Android's `libandroid.so` at runtime and registers a light sensor listener via the `ASensorManager` NDK API. Sensor events arrive directly into the process with zero process forks.

The full brightness pipeline:

```
sensor lux → median filter (5 samples) → asymmetric EMA → saturation curve → user offset → hysteresis → proportional ramp → sysfs write
```

| Stage | Purpose |
|-------|---------|
| **Median filter** | Rejects sensor noise spikes (window of 5 at 100ms intervals) |
| **Asymmetric EMA** | Fast response to brightening (0.3s), gradual darkening (1.2s) |
| **Saturation curve** | `lux * max / (lux + K)` — perceptual mapping that mimics human eye response |
| **User offset** | Captures slider adjustments and applies them persistently across lux changes |
| **Hysteresis** | Ignores small fluctuations to prevent visible jitter |
| **Proportional ramp** | Animates transitions — large changes ramp fast, small changes ramp gently |

If the NDK sensor API is unavailable on your device, the daemon falls back to parsing `dumpsys sensorservice` (one fork per second).

The HAL lockout works by setting the backlight sysfs node to `root:root 0644` in `post-fs-data.sh`, which runs before HAL services start. The HAL opens the file read-only and its writes silently fail. The daemon runs as root and is unaffected.

## Credits

This module was built to fix a hardware-specific brightness issue on [Astro-OS](https://xdaforums.com/t/closed-astro-os-oneui-8-0-galaxy-note20-series-snapdragon-s23-ultra-port-version-3-1-0-ai-port-camera-enhancements-optimize.4786282/), an S23 Ultra port for the Galaxy Note 20 series by the Astro-OS team on XDA Developers. The ROM itself is excellent — this module simply addresses one side effect of running a ported ROM on different display hardware.

I am not affiliated with the Astro-OS project in any way. Just a grateful user giving back.

## License

MIT
