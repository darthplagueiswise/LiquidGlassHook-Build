// IGLiquidGlassHook.m
// Dylib para forçar LiquidGlass em runtime (Instagram / apps Meta)
//
// Este hook faz duas coisas:
//  1) Rebind (via fishhook) das funções C centrais de LiquidGlass:
//       - METAIsLiquidGlassEnabled
//       - IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
//       - IGTabBarStyleForLauncherSet
//  2) Hook de selectors Objective-C relacionados a LiquidGlass:
//       - isLiquidGlassContextMenuEnabled
//       - isLiquidGlassInAppNotificationEnabled
//       - isLiquidGlassToastEnabled
//       - isLiquidGlassToastPeekEnabled
//       - isLiquidGlassAlertDialogEnabled
//       - shouldMitigateLiquidGlassYOffset
//
// Depois, injetar IGLiquidGlassHook.dylib na IPA (ex.: via Feather + Ellekit).

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "fishhook/fishhook.h"   // fishhook como submódulo: github.com/facebook/fishhook

#pragma mark - Logging auxiliar

static void lg_log(NSString *fmt, ...) {
#ifdef DEBUG
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[IGLiquidGlassHook] %@", msg);
#endif
}

#pragma mark - Hooks C: gates centrais LiquidGlass (via fishhook)

// Protótipos esperados (sem argumentos). Se no seu Ghidra você
// verificar outra assinatura, ajuste aqui.
static BOOL (*orig_METAIsLiquidGlassEnabled)(void);
static BOOL (*orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)(void);
static int  (*orig_IGTabBarStyleForLauncherSet)(void);

static BOOL hooked_METAIsLiquidGlassEnabled(void) {
    // Gate global sempre ligado
    return YES;
}

static BOOL hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void) {
    // Tab bar LiquidGlass sempre habilitada para o launcher set
    return YES;
}

static int hooked_IGTabBarStyleForLauncherSet(void) {
    // Estilo da tab bar:
    //  - Ajuste este valor se, no seu Ghidra, você identificar outro code
    //    para o estilo LiquidGlass. Na prática, 1 funcionou nos patches estáticos.
    return 1;
}

static void lg_setup_c_hooks(void) {
    struct rebinding rebs[] = {
        {
            .name = "METAIsLiquidGlassEnabled",
            .replacement = (void *)hooked_METAIsLiquidGlassEnabled,
            .replaced = (void **)&orig_METAIsLiquidGlassEnabled
        },
        {
            .name = "IGIsCustomLiquidGlassTabBarEnabledForLauncherSet",
            .replacement = (void *)hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet,
            .replaced = (void **)&orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
        },
        {
            .name = "IGTabBarStyleForLauncherSet",
            .replacement = (void *)hooked_IGTabBarStyleForLauncherSet,
            .replaced = (void **)&orig_IGTabBarStyleForLauncherSet
        },
    };
    rebind_symbols(rebs, sizeof(rebs) / sizeof(rebs[0]));
    lg_log(@"C hooks instalados para META/IG*LiquidGlass* gates");
}

#pragma mark - Hooks ObjC: selectors LiquidGlass

static BOOL lg_alwaysYES(id self, SEL _cmd) {
    return YES;
}

static BOOL lg_alwaysNO(id self, SEL _cmd) {
    return NO;
}

// Hook genérico de selector: encontra qualquer classe/metaclasse que
// responda ao selector e troca a implementação por YES/NO fixo.
static void lg_runtime_hook_selector(const char *selName, BOOL returnYES) {
    SEL sel = sel_registerName(selName);
    if (!sel) {
        lg_log(@"Selector %s não registrado no runtime", [NSString stringWithUTF8String:selName]);
        return;
    }

    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) {
        lg_log(@"objc_getClassList retornou %d classes", numClasses);
        return;
    }

    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    if (!classes) {
        lg_log(@"malloc falhou");
        return;
    }

    numClasses = objc_getClassList(classes, numClasses);
    int hookedCount = 0;

    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        if (!cls) continue;

        // Método de instância
        if (class_respondsToSelector(cls, sel)) {
            Method m = class_getInstanceMethod(cls, sel);
            if (m) {
                IMP newImp = returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                method_setImplementation(m, newImp);
                hookedCount++;
            }
        }

        // Método de classe (meta-class)
        Class meta = object_getClass((id)cls);
        if (meta && class_respondsToSelector(meta, sel)) {
            Method m = class_getClassMethod(cls, sel);
            if (m) {
                IMP newImp = returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                method_setImplementation(m, newImp);
                hookedCount++;
            }
        }
    }

    lg_log(@"Hook selector %s -> %@ (hooks=%d)",
           selName, returnYES ? @"YES" : @"NO", hookedCount);

    free(classes);
}

static void lg_setup_objc_hooks(void) {
    // 1) Flags LiquidGlass “Enabled” – sempre ligadas
    const char *yesSelectors[] = {
        "isLiquidGlassContextMenuEnabled",
        "isLiquidGlassInAppNotificationEnabled",
        "isLiquidGlassToastEnabled",
        "isLiquidGlassToastPeekEnabled",
        "isLiquidGlassAlertDialogEnabled",
    };
    size_t yesCount = sizeof(yesSelectors) / sizeof(yesSelectors[0]);
    for (size_t i = 0; i < yesCount; i++) {
        lg_runtime_hook_selector(yesSelectors[i], YES);
    }

    // 2) Mitigação de deslocamento vertical – desativada (NO) por padrão.
    // Se o efeito visual ficar melhor com mitigação ligada, mude para YES.
    lg_runtime_hook_selector("shouldMitigateLiquidGlassYOffset", NO);
}

#pragma mark - Constructor: ponto de entrada do dylib

__attribute__((constructor))
static void lg_init(void) {
    @autoreleasepool {
        lg_log(@"Inicializando IGLiquidGlassHook");

        // 1) Hooks C nos gates principais (META/IG*TabBar*).
        lg_setup_c_hooks();

        // 2) Hooks ObjC nos selectors de UI LiquidGlass.
        lg_setup_objc_hooks();

        lg_log(@"IGLiquidGlassHook inicializado");
    }
}
