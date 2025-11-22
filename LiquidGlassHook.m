// LiquidGlassHook.m
// Dylib para forçar flags LiquidGlass em runtime dentro do Instagram

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Sempre retorna YES
static BOOL lg_alwaysYES(id self, SEL _cmd) {
    return YES;
}

// Sempre retorna NO
static BOOL lg_alwaysNO(id self, SEL _cmd) {
    return NO;
}

// Hook genérico: procura todas as classes e metaclasses que respondem
// a um selector e troca a implementação por alwaysYES/alwaysNO.
static void lg_hookSelector(const char *selName, BOOL returnYES) {
    SEL sel = sel_registerName(selName);
    if (!sel) {
        return;
    }

    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) {
        return;
    }

    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    if (!classes) {
        return;
    }

    numClasses = objc_getClassList(classes, numClasses);

    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        if (!cls) continue;

        // Método de instância
        if (class_respondsToSelector(cls, sel)) {
            Method m = class_getInstanceMethod(cls, sel);
            if (m) {
                IMP newImp = returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                method_setImplementation(m, newImp);
            }
        }

        // Método de classe (meta-classe)
        Class meta = object_getClass((id)cls);
        if (meta && class_respondsToSelector(meta, sel)) {
            Method m = class_getClassMethod(cls, sel);
            if (m) {
                IMP newImp = returnYES ? (IMP)lg_alwaysYES : (IMP)lg_alwaysNO;
                method_setImplementation(m, newImp);
            }
        }
    }

    free(classes);
}

// Roda automaticamente quando o dylib é carregado
__attribute__((constructor))
static void lg_init(void) {
    @autoreleasepool {
        // Todos os que queremos sempre ligados (YES)
        const char *yesSels[] = {
            "isLiquidGlassContextMenuEnabled",
            "isLiquidGlassInAppNotificationEnabled",
            "isLiquidGlassToastEnabled",
            "isLiquidGlassToastPeekEnabled",
            "isLiquidGlassAlertDialogEnabled",
        };

        size_t count = sizeof(yesSels) / sizeof(yesSels[0]);
        for (size_t i = 0; i < count; i++) {
            lg_hookSelector(yesSels[i], YES);
        }

        // Offset vertical: provavelmente queremos desativar mitigação.
        lg_hookSelector("shouldMitigateLiquidGlassYOffset", NO);
    }
}
