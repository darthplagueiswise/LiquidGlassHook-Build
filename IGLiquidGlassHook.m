// IGLiquidGlassHook.m — versão sem SEG_DATA_CONST, rebinder próprio
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <stdarg.h>
#import <stdlib.h>
#import <string.h>

static void lg_log(NSString *fmt, ...) {
#ifdef DEBUG
    va_list a; va_start(a, fmt);
    NSLogv([NSString stringWithFormat:@"[IGLiquidGlassHook] %@", fmt], a);
    va_end(a);
#endif
}

typedef struct {
    const char *name;
    void       *replacement;
    void      **replaced;
} LGRebinding;

static LGRebinding *lg_rebindings = NULL;
static size_t lg_rebindings_count = 0;

static void lg_rebind_for_image(const struct mach_header *mh, intptr_t slide) {
#if !defined(__LP64__)
    return;
#else
    const struct mach_header_64 *header = (const struct mach_header_64 *)mh;

    const struct load_command *lc = NULL;
    const struct segment_command_64 *seg = NULL, *linkedit = NULL;
    const struct symtab_command *symtab_cmd = NULL;
    const struct dysymtab_command *dysymtab_cmd = NULL;

    uintptr_t cur = (uintptr_t)header + sizeof(struct mach_header_64);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        lc = (const struct load_command *)cur;
        if (lc->cmd == LC_SEGMENT_64) {
            seg = (const struct segment_command_64 *)cur;
            if (strcmp(seg->segname, SEG_LINKEDIT) == 0) linkedit = seg;
        } else if (lc->cmd == LC_SYMTAB) {
            symtab_cmd = (const struct symtab_command *)cur;
        } else if (lc->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (const struct dysymtab_command *)cur;
        }
        cur += lc->cmdsize;
    }
    if (!linkedit || !symtab_cmd || !dysymtab_cmd || lg_rebindings_count == 0) return;

    uintptr_t le_base = (uintptr_t)slide + linkedit->vmaddr - linkedit->fileoff;
    struct nlist_64 *symtab = (struct nlist_64 *)(le_base + symtab_cmd->symoff);
    char *strtab = (char *)(le_base + symtab_cmd->stroff);
    uint32_t *indirect = (uint32_t *)(le_base + dysymtab_cmd->indirectsymoff);

    cur = (uintptr_t)header + sizeof(struct mach_header_64);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        lc = (const struct load_command *)cur;
        if (lc->cmd == LC_SEGMENT_64) {
            seg = (const struct segment_command_64 *)cur;
            const struct section_64 *sec = (const struct section_64 *)(seg + 1);
            for (uint32_t j = 0; j < seg->nsects; j++, sec++) {
                uint32_t type = sec->flags & SECTION_TYPE;
                if (type != S_LAZY_SYMBOL_POINTERS && type != S_NON_LAZY_SYMBOL_POINTERS) continue;

                uint32_t *indices = indirect + sec->reserved1;
                void **slots = (void **)((uintptr_t)slide + sec->addr);
                uint64_t count = sec->size / sizeof(void *);
                for (uint64_t k = 0; k < count; k++) {
                    uint32_t idx = indices[k];
                    if (idx == INDIRECT_SYMBOL_ABS ||
                        idx == INDIRECT_SYMBOL_LOCAL ||
                        idx == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) continue;

                    struct nlist_64 s = symtab[idx];
                    if (s.n_un.n_strx == 0) continue;
                    const char *nm = strtab + s.n_un.n_strx;
                    if (!nm || nm[0] != '_') continue;
                    const char *trim = nm + 1;
                    for (size_t r = 0; r < lg_rebindings_count; r++) {
                        LGRebinding *rb = &lg_rebindings[r];
                        if (strcmp(trim, rb->name) == 0) {
                            if (rb->replaced && *rb->replaced == NULL) *rb->replaced = slots[k];
                            slots[k] = rb->replacement;
                        }
                    }
                }
            }
        }
        cur += lc->cmdsize;
    }
#endif
}

static void lg_dyld_cb(const struct mach_header *mh, intptr_t slide) { lg_rebind_for_image(mh, slide); }

static int lg_rebind_symbols(LGRebinding *arr, size_t cnt) {
    size_t newc = lg_rebindings_count + cnt;
    LGRebinding *nw = malloc(sizeof(LGRebinding) * newc);
    if (!nw) return -1;
    if (lg_rebindings_count) memcpy(nw, lg_rebindings, sizeof(LGRebinding) * lg_rebindings_count);
    memcpy(nw + lg_rebindings_count, arr, sizeof(LGRebinding) * cnt);
    free(lg_rebindings); lg_rebindings = nw; lg_rebindings_count = newc;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _dyld_register_func_for_add_image(lg_dyld_cb);
        uint32_t n = _dyld_image_count();
        for (uint32_t i = 0; i < n; i++) {
            const struct mach_header *mh = _dyld_get_image_header(i);
            intptr_t sl = _dyld_get_image_vmaddr_slide(i);
            lg_rebind_for_image(mh, sl);
        }
    });
    return 0;
}

// —— C gates (assinaturas sem argumentos) ——
static BOOL (*orig_METAIsLiquidGlassEnabled)(void);
static BOOL (*orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet)(void);
static int  (*orig_IGTabBarStyleForLauncherSet)(void);

static BOOL hooked_METAIsLiquidGlassEnabled(void) { return YES; }
static BOOL hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void) { return YES; }
static int  hooked_IGTabBarStyleForLauncherSet(void) { return 1; }

static void lg_setup_c_hooks(void) {
    LGRebinding r[] = {
        { "METAIsLiquidGlassEnabled", (void*)hooked_METAIsLiquidGlassEnabled, (void**)&orig_METAIsLiquidGlassEnabled },
        { "IGIsCustomLiquidGlassTabBarEnabledForLauncherSet", (void*)hooked_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet, (void**)&orig_IGIsCustomLiquidGlassTabBarEnabledForLauncherSet },
        { "IGTabBarStyleForLauncherSet", (void*)hooked_IGTabBarStyleForLauncherSet, (void**)&orig_IGTabBarStyleForLauncherSet },
    };
    lg_rebind_symbols(r, sizeof(r)/sizeof(r[0]));
}

// —— ObjC selectors ——
static BOOL lg_yes(id self, SEL _cmd) { return YES; }
static BOOL lg_no (id self, SEL _cmd) { return NO;  }

static void lg_hook_selector(const char *selName, BOOL retYES) {
    SEL s = sel_registerName(selName);
    if (!s) return;
    int n = objc_getClassList(NULL, 0);
    if (n <= 0) return;
    Class *list = (Class *)malloc(sizeof(Class) * n);
    if (!list) return;
    n = objc_getClassList(list, n);
    for (int i = 0; i < n; i++) {
        Class c = list[i];
        if (class_respondsToSelector(c, s)) {
            Method m = class_getInstanceMethod(c, s);
            if (m) method_setImplementation(m, retYES ? (IMP)lg_yes : (IMP)lg_no);
        }
        Class meta = object_getClass((id)c);
        if (meta && class_respondsToSelector(meta, s)) {
            Method m = class_getClassMethod(c, s);
            if (m) method_setImplementation(m, retYES ? (IMP)lg_yes : (IMP)lg_no);
        }
    }
    free(list);
}

static void lg_setup_objc_hooks(void) {
    const char *yesSels[] = {
        "isLiquidGlassContextMenuEnabled",
        "isLiquidGlassInAppNotificationEnabled",
        "isLiquidGlassToastEnabled",
        "isLiquidGlassToastPeekEnabled",
        "isLiquidGlassAlertDialogEnabled",
    };
    for (size_t i = 0; i < sizeof(yesSels)/sizeof(yesSels[0]); i++) lg_hook_selector(yesSels[i], YES);
    lg_hook_selector("shouldMitigateLiquidGlassYOffset", NO);
}

// —— Entry point ——
__attribute__((constructor))
static void lg_init(void) {
    @autoreleasepool {
        lg_setup_c_hooks();
        lg_setup_objc_hooks();
    }
}
