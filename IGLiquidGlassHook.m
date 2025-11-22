// IGLiquidGlassHook.m
// Dylib para forçar LiquidGlass em runtime (Instagram / apps Meta)
//
// Hooks:
//  - Funções C (gates principais de LiquidGlass):
//      METAIsLiquidGlassEnabled
//      IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
//      IGTabBarStyleForLauncherSet
//  - Selectors Objective-C (flags de UI LiquidGlass):
//      isLiquidGlassContextMenuEnabled
//      isLiquidGlassInAppNotificationEnabled
//      isLiquidGlassToastEnabled
//      isLiquidGlassToastPeekEnabled
//      isLiquidGlassAlertDialogEnabled
//      shouldMitigateLiquidGlassYOffset
//
// Tudo em um único arquivo, sem dependência de fishhook externo.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

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

#pragma mark - Mini rebinder (estilo fishhook) para arm64

typedef struct {
    const char *name;     // nome da função C (sem o '_')
    void       *replacement;
    void      **replaced;
} LGRebinding;

static LGRebinding *lg_rebindings = NULL;
static size_t       lg_rebindings_count = 0;

static void lg_rebind_for_image(const struct mach_header *mh, intptr_t slide) {
#if !defined(__LP64__)
    // Só nos importam binários 64-bit (arm64)
    return;
#else
    const struct mach_header_64 *header = (const struct mach_header_64 *)mh;

    const struct load_command    *lc = NULL;
    const struct segment_command_64 *seg_cmd = NULL;
    const struct segment_command_64 *linkedit = NULL;
    const struct symtab_command     *symtab_cmd = NULL;
    const struct dysymtab_command   *dysymtab_cmd = NULL;

    uintptr_t cursor = (uintptr_t)header + sizeof(struct mach_header_64);

    for (uint32_t i = 0; i < header->ncmds; i++) {
        lc = (const struct load_command *)cursor;

        if (lc->cmd == LC_SEGMENT_64) {
            seg_cmd = (const struct segment_command_64 *)cursor;
            if (strcmp(seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit = seg_cmd;
            }
        } else if (lc->cmd == LC_SYMTAB) {
            symtab_cmd = (const struct symtab_command *)cursor;
        } else if (lc->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (const struct dysymtab_command *)cursor;
        }

        cursor += lc->cmdsize;
    }

    if (!linkedit || !symtab_cmd || !dysymtab_cmd || lg_rebindings_count == 0) {
        return;
    }

    uintptr_t linkedit_base = (uintptr_t)slide +
                              linkedit->vmaddr -
                              linkedit->fileoff;

    struct nlist_64 *symtab = (struct nlist_64 *)(linkedit_base + symtab_cmd->symoff);
    char            *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
    uint32_t        *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);

    cursor = (uintptr_t)header + sizeof(struct mach_header_64);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        lc = (const struct load_command *)cursor;

        if (lc->cmd == LC_SEGMENT_64) {
            seg_cmd = (const struct segment_command_64 *)cursor;

            // Procurar seções de ponteiros de símbolo em __DATA / __DATA_CONST
            if (strcmp(seg_cmd->segname, SEG_DATA) != 0 &&
                strcmp(seg_cmd->segname, SEG_DATA_CONST) != 0) {
                cursor += lc->cmdsize;
                continue;
            }

            const struct section_64 *sect = (const struct section_64 *)(seg_cmd + 1);

            for (uint32_t j = 0; j < seg_cmd->nsects; j++, sect++) {
                uint32_t type = sect->flags & SECTION_TYPE;
                if (type != S_LAZY_SYMBOL_POINTERS &&
                    type != S_NON_LAZY_SYMBOL_POINTERS) {
                    continue;
                }

                uint32_t *indirect_indices = indirect_symtab + sect->reserved1;
                void    **symbol_bindings  = (void **)((uintptr_t)slide + sect->addr);
                uint64_t  bind_count       = sect->size / sizeof(void *);

                for (uint64_t k = 0; k < bind_count; k++) {
                    uint32_t sym_index = indirect_indices[k];

                    if (sym_index == INDIRECT_SYMBOL_ABS ||
                        sym_index == INDIRECT_SYMBOL_LOCAL ||
                        sym_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) {
                        continue;
                    }

                    struct nlist_64 sym = symtab[sym_index];
                    if (sym.n_un.n_strx == 0) continue;

                    const char *sym_name = strtab + sym.n_un.n_strx;
                    if (!sym_name || sym_name[0] != '_') continue;

                    // Comparar com nossos nomes (sem o '_')
                    const char *trimmed = sym_name + 1;

                    for (size_t r = 0; r < lg_rebindings_count; r++) {
                        LGRebinding *reb = &lg_rebindings[r];
                        if (strcmp(trimmed, reb->name) == 0) {
                            if (reb->replaced && *reb->replaced == NULL) {
                                *reb->replaced = symbol_bindings[k];
                            }
                            symbol_bindings[k] = reb->replacement;
                        }
                    }
                }
            }
        }

        cursor += lc->cmdsize;
    }
#endif
}

static void lg_dyld_callback(const struct mach_header *mh, intptr_t slide) {
    lg_rebind_for_image(mh, slide);
}

static int lg_rebind_symbols(LGRebinding rebs[], size_t count) {
    // Expandir vetor global
    size_t new_count = lg_rebindings_count + count;
    LGRebinding *new_array = malloc(sizeof(LGRebinding) * new_count);
    if (!new_array) return -1;

    if (lg_rebindings && lg_rebindings_count > 0) {
        memcpy(new_array, lg_rebindings, sizeof(LGRebinding) * lg_rebindings_count);
    }
    memcpy(new_array + lg_rebindings_count, rebs, sizeof(LGRebinding) * count);

    free(lg_rebindings);
    lg_rebindings = new_array;
    lg_rebindings_count = new_count;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dyld_register_func_for_add_image(lg_dyld_callback);

        // Também aplicar em imagens já carregadas
        uint32_t image_count = _dyld_image_count();
        for (uint32_t i = 0; i < image_count; i++) {
            const struct mach_header *mh = _dyld_get_image_header(i);
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            lg_rebind_for_image(mh, slide);
        }
    });

    return 0;
}

#pragma mark - Hooks C: gates centrais LiquidGlass

// Protótipos (sem argumentos). Ajuste se seu Ghidra mostrar outra assinatura.
static BOOL (*orig_METAIsLiquidGlassEnabled)(void);
static BOOL (*orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)(void);
static int  (*orig_IGTabBarStyleForLauncherSet)(void);

static BOOL hooked_METAIsLiquidGlassEnabled(void) {
    return YES;
}

static BOOL hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void) {
    return YES;
}

static int hooked_IGTabBarStyleForLauncherSet(void) {
    // Ajuste este valor se descobrir outro code de estilo para LiquidGlass.
    return 1;
}

static void lg_setup_c_hooks(void) {
    LGRebinding rebs[] = {
        { "METAIsLiquidGlassEnabled",
          (void *)hooked_METAIsLiquidGlassEnabled,
          (void **)&orig_METAIsLiquidGlassEnabled },
        { "IGIsCustomLiquidGlassTabBarEnabledForLauncherSet",
          (void *)hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet,
          (void **)&orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet },
        { "IGTabBarStyleForLauncherSet",
          (void *)hooked_IGTabBarStyleForLauncherSet,
          (void **)&orig_IGTabBarStyleForLauncherSet },
    };
    lg_rebind_symbols(rebs, sizeof(rebs) / sizeof(rebs[0]));
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
        lg_log(@"Selector %s não registrado no runtime",
               [NSString stringWithUTF8String:selName]);
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
