# AGENTS.md — LiquidGlassHook-Build

You are working in the repository `LiquidGlassHook-Build`.

This repo is a **Theos tweak for Instagram** (bundle `com.burbn.instagram`) whose only purpose is to build a `.dylib` / `.deb` that forces Instagram’s internal LiquidGlass gates ON. The user will handle IPA patching and injection separately (e.g. Feather). You do **not** need to build or patch the IPA here.

---

## 1. What this project is

- A **single Theos tweak**:
  - Name: `LiquidGlassHook` (or `IGLiquidGlassHook` in code).
  - Target app: Instagram (`com.burbn.instagram`).
  - Architecture: `arm64` only.
  - Purpose: override C-level gates like:
    - `METAIsLiquidGlassEnabled`
    - `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`
    - `IGTabBarStyleForLauncherSet`
  - Implementation: **Logos hooks** (`%hookf`), no fishhook, no custom Mach-O scanners.

- Output:
  - A compiled `.dylib` inside the build directory.
  - A packaged `.deb` in `packages/` via `make package`.

The final `.dylib` / `.deb` will later be injected into an Instagram IPA outside this repo.

---

## 2. Files that must exist and stay in sync

At minimum, ensure these files exist and are consistent:

- `AGENTS.md` (this file)
- `README.md` (high-level description, basic build instructions)
- `Makefile` (Theos tweak config)
- `control` (Debian package metadata)
- `LiquidGlassHook.plist` (Substrate filter for Instagram)
- `src/IGLiquidGlassHook.xm` (main tweak source, Logos)
- `.github/workflows/build.yml` (GitHub Actions workflow that runs Theos)

Do **not** introduce extra subprojects or complex folder structures. This repository is a **single** tweak.

---

## 3. Makefile requirements

The `Makefile` must:

- Use Theos tweak style, not a custom clang script.
- Not hardcode absolute paths to Theos; use variables.

Example shape (you may refine, but keep the pattern):

```
TARGET := iphone:clang:latest
ARCHS  := arm64

INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LiquidGlassHook

$(TWEAK_NAME)_FILES      = $(wildcard src/*.xm)
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_CFLAGS     = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

Important:
•No fishhook libraries, no extra .m files for hooks.
•Only Logos .xm files under src/.
```

⸻

4. Tweak implementation expectations (src/IGLiquidGlassHook.xm)

The tweak should:
•Use Logos hooks for C functions:

```
%hookf(BOOL, METAIsLiquidGlassEnabled) { return YES; }

%hookf(BOOL, IGIsCustomLiquidGlassTabBarEnabledForLauncherSet, id launcherSet) {
    return YES;
}

typedef NSInteger IGTabBarStyle;
static const IGTabBarStyle IGTabBarStyleLiquidGlass = 2; // chosen by reverse-engineering

%hookf(IGTabBarStyle, IGTabBarStyleForLauncherSet, id launcherSet) {
    return IGTabBarStyleLiquidGlass;
}
```

•Not declare extern prototypes for these functions (Logos must own the symbol).
•Not call the “original” inside these hooks (we want a hard override).
•Optionally hook additional C gates if they exist (e.g. METAIsLiquidGlassToastEnabled), but:
•Only if they are real C functions in the target binary.
•Hooks must be written as %hookf(...) { return YES; } style.

Do not add manual MSHookFunction / MSFindSymbol code unless explicitly requested.

⸻

5. GitHub Actions workflow

.github/workflows/build.yml must:
•Run on macos-latest (or macos-15).
•Clone Theos into $HOME/theos with --recursive.
•Export:
•THEOS=$HOME/theos
•THEOS_MAKE_PATH=$THEOS/makefiles
•Run:

```
make clean
make package FINALPACKAGE=1
```

•Upload artifacts:
•The built .deb in packages/.
•Optionally the built .dylib in .theos/obj/....

Use Theos standard layout; do not implement your own build system.

⸻

6. How you (the agent) should behave

When editing this repo:
1.Do not try to install or run Theos inside the Codex/Workspace environment.
That environment does not have Xcode SDKs or Theos by default. Local make will usually fail there.
2.Your job is to make sure:
•The Makefile is correct for Theos.
•The tweak source (src/IGLiquidGlassHook.xm) is syntactically valid and uses Logos correctly.
•The GitHub Actions workflow is correctly configured to:
•clone Theos,
•export THEOS and THEOS_MAKE_PATH,
•run make package.
3.You may run lightweight commands like:
•ls, cat, sed to inspect and edit files.
•But you do not need to run make inside Codex.
•Consider make in this environment a synthetic check that can fail; the real build happens in GitHub Actions.
4.When making changes:
•Keep diffs minimal and focused.
•Always explain briefly in the commit message what you changed, e.g.:
•Fix Theos path in Makefile
•Convert tweak to pure Logos %hookf for LiquidGlass gates
•Update GitHub Actions workflow to macos-latest
5.Treat GitHub Actions as the canonical build:
•After edits, the user will push.
•The build workflow will run.
•If it passes, the tweak is considered successfully built.

⸻

7. What this repo is not
•It is not a full IPA patcher.
•It is not responsible for signing or installing the IPA.
•It is not a multi-app tweak bundle.

Avoid adding:
•Any new app targets.
•Any IPA manipulation tools.
•Any code that assumes root / jailbreak-only paths outside Theos standard flow.

The only goal here: produce a reliable LiquidGlassHook tweak binary (.dylib/.deb) that forces LiquidGlass on Instagram, using Theos and GitHub Actions.

What I recommend you do now:

1. Replace your current `AGENTS.md` in the repo with the content above (via GitHub web editor or Codex).
2. In Codex, when you open the Workspace, you don’t need a huge extra prompt anymore; just say something curto tipo:
   - “Follow AGENTS.md and fix whatever is needed so `build` workflow passes and produces the dylib.”

This should stop Codex from “overthinking” (trying to patch IPAs, trying to run Theos locally, etc.) and keep it locked on exactly what you want: a clean Theos tweak that GitHub Actions can build.
