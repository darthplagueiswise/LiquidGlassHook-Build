## LiquidGlassHook

A Theos tweak that forces Instagram's LiquidGlass UI gates on iOS 17+.

### What it does
- Hooks the C gates `METAIsLiquidGlassEnabled`, `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`, and `IGTabBarStyleForLauncherSet` via Logos and returns values that keep LiquidGlass enabled.
- Targets only the Instagram bundle (`com.burbn.instagram`).

### Building locally
```bash
git clone https://github.com/youruser/LiquidGlassHook-Build
cd LiquidGlassHook-Build
export THEOS=~/theos
make package
```

The resulting Debian package will be located in `./packages`.

### Installation
Install the generated `.deb` on a jailbroken device or inject the resulting dylib into Instagram using your preferred loader.
