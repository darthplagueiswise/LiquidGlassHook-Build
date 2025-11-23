## LiquidGlassHook

A Theos tweak that forces Instagram's internal LiquidGlass UI gates on iOS.

### What it does
- Hooks the C gates `METAIsLiquidGlassEnabled`, `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`, and `IGTabBarStyleForLauncherSet` via Logos and returns values that keep LiquidGlass enabled.
- Targets only the Instagram bundle (`com.burbn.instagram`).

### Building
```
# Set up Theos beforehand
export THEOS=~/theos
export THEOS_MAKE_PATH=$THEOS/makefiles

make clean
make package FINALPACKAGE=1
```

The resulting Debian package will be located in `./packages`, and the built dylib will be under `.theos/obj/`.

### Installation
Install the generated `.deb` on a jailbroken device or inject the resulting dylib into Instagram using your preferred loader.
