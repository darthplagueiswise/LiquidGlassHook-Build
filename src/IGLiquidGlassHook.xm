#import <Foundation/Foundation.h>

%hookf(BOOL, METAIsLiquidGlassEnabled)
{
    return YES;
}

%hookf(BOOL, IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)
{
    return YES;
}

%hookf(NSInteger, IGTabBarStyleForLauncherSet)
{
    return 1;
}

%ctor {}
