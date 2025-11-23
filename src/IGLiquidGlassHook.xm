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
    void *symbol = MSFindSymbol(NULL, name);
    if (symbol != NULL) {
        MSHookFunction(symbol, replace, original);
    }
}

%ctor {}
