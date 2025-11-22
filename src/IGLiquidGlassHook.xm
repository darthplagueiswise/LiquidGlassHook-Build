// src/IGLiquidGlassHook.xm
// Minimal Theos/Logos tweak to force Instagram LiquidGlass tab bar gates.

#import <UIKit/UIKit.h>

// Logos' generated glue code may rely on standard C helpers such as strdup,
// so include the safe C string declarations up front to avoid implicit
// function warnings when compiling under stricter C modes on some runners.
#include <string.h>

#pragma mark - C function prototypes

// These names come from FBSharedFramework; they are C-level gates.
BOOL METAIsLiquidGlassEnabled(void);
BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
NSInteger IGTabBarStyleForLauncherSet(void);

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

// Style resolver for the tab bar; returning 1 matches the value we used
// in the static patch that produced the LiquidGlass bar in your tests.
%hookf(NSInteger, IGTabBarStyleForLauncherSet)
{
    return 1;
}

#pragma mark - Optional boolean helpers (defensive)

// We do NOT guess the class names here – that would risk crashes.
// If later you confirm exact class/selector pairs via Ghidra, they can
// be added as normal %hook blocks, e.g.:
//
// %hook IGSomeConfigClass
// - (BOOL)isLiquidGlassToastEnabled {
//     return YES;
// }
// %end
//
// For now we keep the tweak minimal and safe.

#pragma mark - Constructor

%ctor
{
    // Nothing to do here; Logos will install the C hooks automatically.
}
