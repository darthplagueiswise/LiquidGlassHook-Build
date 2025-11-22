// src/IGLiquidGlassHook.xm
// Theos/Logos tweak that forces Instagram LiquidGlass tab bar gates.

#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
// C-level gates exposed by Instagram frameworks.
BOOL METAIsLiquidGlassEnabled(void);
BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
NSInteger IGTabBarStyleForLauncherSet(void);
#ifdef __cplusplus
}
#endif

#pragma mark - C gate hooks

// Global LiquidGlass meta-gate
%hookf(BOOL, METAIsLiquidGlassEnabled)
{
    // Always report LiquidGlass as enabled
    return YES;
}

// Specific gate for the custom LiquidGlass tab bar for launcher set
%hookf(BOOL, IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)
{
    // Always enable the custom LiquidGlass tab bar
    return YES;
}

// Style resolver for the tab bar; returning 1 matches the LiquidGlass style
%hookf(NSInteger, IGTabBarStyleForLauncherSet)
{
    return 1;
}

#pragma mark - Optional boolean helpers (defensive)

// Keep the tweak minimal and safe; add extra hooks here once class names
// and selectors are confirmed (e.g., isLiquidGlassToastEnabled, etc.).

#pragma mark - Constructor

%ctor
{
    // Logos installs the C hooks automatically.
}
