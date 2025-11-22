#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// -------------------------------------------------------
//  Configuração dinâmica via NSUserDefaults
// -------------------------------------------------------

static NSString * const kLGLGCoreEnabledKey      = @"LGLGCoreEnabled";
static NSString * const kLGLGExtendedUIEnabledKey = @"LGLGExtendedUIEnabled";
static NSString * const kLGLGDebugEnabledKey     = @"LGLGDebugEnabled";

@interface LGLiquidGlassConfig : NSObject
@end

@implementation LGLiquidGlassConfig

+ (NSUserDefaults *)defaults {
    // Separar por suite se quiser, por enquanto usa padrão do app
    return [NSUserDefaults standardUserDefaults];
}

+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)def {
    NSUserDefaults *d = [self defaults];
    if ([d objectForKey:key] == nil) return def;
    return [d boolForKey:key];
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    NSUserDefaults *d = [self defaults];
    [d setBool:value forKey:key];
    [d synchronize];
}

+ (BOOL)coreEnabled {
    return [self boolForKey:kLGLGCoreEnabledKey defaultValue:YES];
}

+ (BOOL)extendedUIEnabled {
    return [self boolForKey:kLGLGExtendedUIEnabledKey defaultValue:YES];
}

+ (BOOL)debugEnabled {
    return [self boolForKey:kLGLGDebugEnabledKey defaultValue:NO];
}

+ (void)toggleCore {
    [self setBool:![self coreEnabled] forKey:kLGLGCoreEnabledKey];
}

+ (void)toggleExtendedUI {
    [self setBool:![self extendedUIEnabled] forKey:kLGLGExtendedUIEnabledKey];
}

+ (void)toggleDebug {
    [self setBool:![self debugEnabled] forKey:kLGLGDebugEnabledKey];
}

@end

static void LGLog(NSString *format, ...) {
    if (![LGLiquidGlassConfig debugEnabled]) return;
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"[LiquidGlassHook] %@", msg);
}

// -------------------------------------------------------
//  Declarações de funções C (gates LiquidGlass)
//  (presentes nos frameworks do Instagram)
// -------------------------------------------------------

extern BOOL METAIsLiquidGlassEnabled(void);
extern BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
extern int  IGTabBarStyleForLauncherSet(void);

// Ponteiros para originais
static BOOL (*orig_METAIsLiquidGlassEnabled)(void);
static BOOL (*orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)(void);
static int  (*orig_IGTabBarStyleForLauncherSet)(void);

// Wrappers hookados

static BOOL lg_METAIsLiquidGlassEnabled(void) {
    if ([LGLiquidGlassConfig coreEnabled]) {
        LGLog(@"METAIsLiquidGlassEnabled -> forced YES");
        return YES;
    }
    if (orig_METAIsLiquidGlassEnabled) {
        return orig_METAIsLiquidGlassEnabled();
    }
    return METAIsLiquidGlassEnabled();
}

static BOOL lg_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void) {
    if ([LGLiquidGlassConfig coreEnabled]) {
        LGLog(@"IGIsCustomLiquidGlassTabBarEnabledForLauncherSet -> forced YES");
        return YES;
    }
    if (orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet) {
        return orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet();
    }
    return IGIsCustomLiquidGlassTabBarEnabledForLauncherSet();
}

static int lg_IGTabBarStyleForLauncherSet(void) {
    if ([LGLiquidGlassConfig coreEnabled]) {
        LGLog(@"IGTabBarStyleForLauncherSet -> forced LiquidGlass style (1)");
        return 1; // estilo LiquidGlass (ajuste conforme mapeamento real)
    }
    if (orig_IGTabBarStyleForLauncherSet) {
        return orig_IGTabBarStyleForLauncherSet();
    }
    return IGTabBarStyleForLauncherSet();
}

static void LGInstallCGates(void) {
    LGLog(@"Installing C gates with MSHookFunction");
    MSHookFunction((void *)METAIsLiquidGlassEnabled,
                   (void *)lg_METAIsLiquidGlassEnabled,
                   (void **)&orig_METAIsLiquidGlassEnabled);

    MSHookFunction((void *)IGIsCustomLiquidGlassTabBarEnabledForLauncherSet,
                   (void *)lg_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet,
                   (void **)&orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet);

    MSHookFunction((void *)IGTabBarStyleForLauncherSet,
                   (void *)lg_IGTabBarStyleForLauncherSet,
                   (void **)&orig_IGTabBarStyleForLauncherSet);
}

// -------------------------------------------------------
//  Hooks de selectors ObjC (isLiquidGlass*Enabled, etc.)
// -------------------------------------------------------

static BOOL lg_alwaysYES(id self, SEL _cmd) { return YES; }
static BOOL lg_alwaysNO (id self, SEL _cmd) { return NO;  }

typedef struct {
    const char *selName;
    BOOL        returnYES;
} LGSelectorPatch;

// Lista inicial de selectors de LiquidGlass / UI
static const LGSelectorPatch kLiquidGlassSelectors[] = {
    {"isLiquidGlassContextMenuEnabled",       YES},
    {"isLiquidGlassInAppNotificationEnabled", YES},
    {"isLiquidGlassToastEnabled",            YES},
    {"isLiquidGlassToastPeekEnabled",        YES},
    {"isLiquidGlassAlertDialogEnabled",      YES},
    {"shouldMitigateLiquidGlassYOffset",     NO},
};

static void LGApplySelectorPatches(void) {
    LGLog(@"Applying selector patches for LiquidGlass");

    int classCount = objc_getClassList(NULL, 0);
    if (classCount <= 0) return;

    Class *classes = (Class *)malloc(sizeof(Class) * classCount);
    if (!classes) return;

    classCount = objc_getClassList(classes, classCount);

    size_t patchCount = sizeof(kLiquidGlassSelectors) / sizeof(kLiquidGlassSelectors[0]);

    for (size_t p = 0; p < patchCount; p++) {
        const char *selName = kLiquidGlassSelectors[p].selName;
        SEL sel = sel_registerName(selName);
        if (!sel) continue;

        for (int i = 0; i < classCount; i++) {
            Class cls = classes[i];

            // Métodos de instância
            if (class_respondsToSelector(cls, sel)) {
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    IMP imp = kLiquidGlassSelectors[p].returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                    method_setImplementation(m, imp);
                    LGLog(@"Patched instance selector %s on class %s", selName, class_getName(cls));
                }
            }

            // Métodos de classe
            Class meta = object_getClass((id)cls);
            if (meta && class_respondsToSelector(meta, sel)) {
                Method m = class_getClassMethod(cls, sel);
                if (m) {
                    IMP imp = kLiquidGlassSelectors[p].returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                    method_setImplementation(m, imp);
                    LGLog(@"Patched class selector %s on class %s", selName, class_getName(cls));
                }
            }
        }
    }

    free(classes);
}

// -------------------------------------------------------
//  Menu interativo – long press no botão de "more/settings"
//  baseado no padrão do SCInsta (IGBadgedNavigationButton)
// -------------------------------------------------------

@interface IGBadgedNavigationButton : UIButton
@property (nonatomic, copy) NSString *accessibilityIdentifier;
@end

static void LGPresentConfigMenuFromView(UIView *sourceView) {
    LGLog(@"Presenting LiquidGlass config menu");

    NSString *coreState     = [LGLiquidGlassConfig coreEnabled]      ? @"ON" : @"OFF";
    NSString *extendedState = [LGLiquidGlassConfig extendedUIEnabled]? @"ON" : @"OFF";
    NSString *debugState    = [LGLiquidGlassConfig debugEnabled]     ? @"ON" : @"OFF";

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"LiquidGlass Hook"
                                message:[NSString stringWithFormat:
                                         @"Core: %@\nExtended UI: %@\nDebug: %@",
                                         coreState, extendedState, debugState]
                                preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *toggleCore = [UIAlertAction
                                 actionWithTitle:[NSString stringWithFormat:@"Toggle Core (is %@)", coreState]
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * _Nonnull action) {
        [LGLiquidGlassConfig toggleCore];
        LGLog(@"Core LiquidGlass toggled -> %d", [LGLiquidGlassConfig coreEnabled]);
    }];

    UIAlertAction *toggleExtended = [UIAlertAction
                                     actionWithTitle:[NSString stringWithFormat:@"Toggle Extended UI (is %@)", extendedState]
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * _Nonnull action) {
        [LGLiquidGlassConfig toggleExtendedUI];
        LGLog(@"Extended UI toggled -> %d", [LGLiquidGlassConfig extendedUIEnabled]);
    }];

    UIAlertAction *toggleDebug = [UIAlertAction
                                  actionWithTitle:[NSString stringWithFormat:@"Toggle Debug (is %@)", debugState]
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
        [LGLiquidGlassConfig toggleDebug];
        LGLog(@"Debug toggled -> %d", [LGLiquidGlassConfig debugEnabled]);
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Fechar"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];

    [alert addAction:toggleCore];
    [alert addAction:toggleExtended];
    [alert addAction:toggleDebug];
    [alert addAction:cancel];

    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    UIViewController *root = window.rootViewController;
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }

    // Em iPad/ActionSheet, configurar popover
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = sourceView.bounds;

    [root presentViewController:alert animated:YES completion:nil];
}

%hook IGBadgedNavigationButton

- (void)didMoveToWindow {
    %orig;

    @try {
        if ([self.accessibilityIdentifier isEqualToString:@"profile-more-button"]) {
            // Evitar adicionar múltiplos recognizers
            BOOL alreadyAdded = NO;
            for (UIGestureRecognizer *gr in self.gestureRecognizers) {
                if ([gr isKindOfClass:[UILongPressGestureRecognizer class]] &&
                    [NSStringFromSelector(gr.action) containsString:@"lg_handleLiquidGlassLongPress"]) {
                    alreadyAdded = YES;
                    break;
                }
            }
            if (!alreadyAdded) {
                UILongPressGestureRecognizer *longPress =
                [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(lg_handleLiquidGlassLongPress:)];
                longPress.minimumPressDuration = 0.8;
                [self addGestureRecognizer:longPress];
                LGLog(@"Added LiquidGlass long-press gesture to profile-more-button");
            }
        }
    } @catch (__unused NSException *e) {
        // Falha silenciosa para não quebrar o app
    }
}

%new - (void)lg_handleLiquidGlassLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        LGPresentConfigMenuFromView(self);
    }
}

%end

// -------------------------------------------------------
//  Entry point do tweak
// -------------------------------------------------------

%ctor {
    @autoreleasepool {
        LGLog(@"LiquidGlassHook ctor – starting installation");
        LGInstallCGates();
        LGApplySelectorPatches();
        LGLog(@"LiquidGlassHook ctor – installation done");
    }
}


