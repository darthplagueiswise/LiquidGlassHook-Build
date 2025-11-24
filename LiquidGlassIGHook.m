// LiquidGlassIGHook.m – fishhook-only dylib for Instagram
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "fishhook/fishhook.h"

typedef NSInteger IGTabBarStyle;

// Original C symbols (resolved at runtime)
BOOL        METAIsLiquidGlassEnabled(void);
BOOL        IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
IGTabBarStyle IGTabBarStyleForLauncherSet(void);

// Pointers to originals (set by fishhook)
static BOOL (*orig_METAIsLiquidGlassEnabled)(void);
static BOOL (*orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)(void);
static IGTabBarStyle (*orig_IGTabBarStyleForLauncherSet)(void);

// Replacement implementations
static BOOL hook_METAIsLiquidGlassEnabled(void)                       { return YES; }
static BOOL hook_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void){ return YES; }
static IGTabBarStyle hook_IGTabBarStyleForLauncherSet(void)           { return 2; } // "LiquidGlass"

// Install hooks at library load
__attribute__((constructor))
static void LGInstallHooks(void) {
    struct rebinding rebinds[] = {
        {"METAIsLiquidGlassEnabled",               hook_METAIsLiquidGlassEnabled,               (void **)&orig_METAIsLiquidGlassEnabled},
        {"IGIsCustomLiquidGlassTabBarEnabledForLauncherSet", hook_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet, (void **)&orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet},
        {"IGTabBarStyleForLauncherSet",            hook_IGTabBarStyleForLauncherSet,            (void **)&orig_IGTabBarStyleForLauncherSet},
    };
    rebind_symbols(rebinds, sizeof(rebinds)/sizeof(rebinds[0]));
}
