# LiquidGlassHook

A simple Theos tweak that forces Instagram's LiquidGlass UI gates on modern iOS versions.

## What it does
- Hooks the three LiquidGlass C gates and always enables them:
  - `METAIsLiquidGlassEnabled`
  - `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`
  - `IGTabBarStyleForLauncherSet` (returns style `1`)
- Optional Instagram selector helpers are not hooked because their owning classes are
  not reliably identified; the tweak favors stability over guessing.

## Building locally
```bash
git clone https://github.com/youruser/LiquidGlassHook-Build
cd LiquidGlassHook-Build
export THEOS="$HOME/theos"
make package    # outputs ./packages/*.deb
```

## Installation
Install the generated `.deb` on a jailbroken device or inject the built
`IGLiquidGlassHook.dylib` into Instagram (`com.burbn.instagram`).

## CI
GitHub Actions (macOS) clones Theos, exports the required environment variables,
builds the package with `make package`, and uploads the resulting artifacts.
