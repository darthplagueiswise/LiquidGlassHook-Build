#import <Foundation/Foundation.h>

typedef NSInteger IGTabBarStyle;
static const IGTabBarStyle IGTabBarStyleLiquidGlass = 2;

%hookf(BOOL, METAIsLiquidGlassEnabled) {
    return YES;
}

%hookf(BOOL, IGIsCustomLiquidGlassTabBarEnabledForLauncherSet, id launcherSet) {
    return YES;
}

%hookf(IGTabBarStyle, IGTabBarStyleForLauncherSet, id launcherSet) {
    return IGTabBarStyleLiquidGlass;
}
