#import <Foundation/Foundation.h>
#import <substrate.h>

__attribute__((weak_import)) BOOL METAIsLiquidGlassEnabled(void);
__attribute__((weak_import)) BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
__attribute__((weak_import)) NSInteger IGTabBarStyleForLauncherSet(void);

static BOOL forceLiquidGlassFlag(void)
{
    return YES;
}

static NSInteger forceLiquidGlassStyle(void)
{
    return 1;
}

static void hookIfPresent(const char *name, void *replace, void **original)
{
    void *symbol = MSFindSymbol(NULL, name);
    if (symbol != NULL) {
        MSHookFunction(symbol, replace, original);
    }
}

%ctor
{
    hookIfPresent("_METAIsLiquidGlassEnabled", (void *)forceLiquidGlassFlag, NULL);
    hookIfPresent("_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet", (void *)forceLiquidGlassFlag, NULL);
    hookIfPresent("_IGTabBarStyleForLauncherSet", (void *)forceLiquidGlassStyle, NULL);
}
