# LiquidGlassHook-Build – Agent instructions

Objective:
- This repo builds a MobileSubstrate / Theos tweak called `IGLiquidGlassHook`
  that forces Instagram’s LiquidGlass tab bar style and related C gates.
- Output: a .deb and a .dylib built by GitHub Actions (macOS runner).

High-level tasks for you as the agent:

1. Repository layout (Theos-style)
   - Ensure the repo has exactly these files at the root:
     - `Makefile`
     - `control`
     - `LiquidGlassHook.plist`
     - `AGENTS.md` (this file)
     - `src/IGLiquidGlassHook.xm`
     - `.github/workflows/build.yml`

   - Do NOT introduce extra nested projects / pods / Xcode projects.
   - This is a single Theos tweak.

2. Makefile
   - Create / overwrite `Makefile` with a minimal Theos tweak configuration:

     - Uses `THEOS` / `THEOS_MAKE_PATH` (no hardcoded absolute paths).
     - Builds for `arm64` only.
     - Target minimum iOS 17.0 (works for iOS 17–26).
     - Tweak name: `IGLiquidGlassHook`.
     - Source file: `src/IGLiquidGlassHook.xm`.
     - Install target process: Instagram (`com.burbn.instagram`).

3. Tweak logic (src/IGLiquidGlassHook.xm)
   - Implement Logos-based hooks (no fishhook, no manual Mach-O walking).
   - Only rely on MobileSubstrate / Logos primitives.

   - Hook these C functions and force LiquidGlass:

     1) `BOOL METAIsLiquidGlassEnabled(void);`
        - Return YES unconditionally.

     2) `BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);`
        - Return YES unconditionally.

     3) `NSInteger IGTabBarStyleForLauncherSet(void);`
        - Return a constant style value that selects the LiquidGlass style.
        - Use value `1` as the forced style (this matches prior manual patches).

   - Additionally, try to hook the LiquidGlass boolean helpers, but make
     the code defensive so the tweak still loads even if a symbol is missing:

     - Candidate signatures:

       `BOOL isLiquidGlassContextMenuEnabled(id self, SEL _cmd);`
       `BOOL isLiquidGlassInAppNotificationEnabled(id self, SEL _cmd);`
       `BOOL isLiquidGlassToastEnabled(id self, SEL _cmd);`
       `BOOL isLiquidGlassToastPeekEnabled(id self, SEL _cmd);`
       `BOOL isLiquidGlassAlertDialogEnabled(id self, SEL _cmd);`

     - Implement these as Logos `%hook` blocks only if the class is known.
       If the exact class cannot be determined reliably, skip them instead
       of guessing. Do NOT break the build over them.

   - The tweak MUST compile cleanly with Theos on a macOS runner with Xcode 16.

4. Package metadata (`control`)
   - Create / overwrite `control` with a valid Debian control file, e.g.:

     - Package: `com.vader.liquidglasshook`
     - Name: `LiquidGlassHook`
     - Architecture: `iphoneos-arm`
     - Depends: `mobilesubstrate`
     - Section: `Tweaks`
     - Version: `0.1.0`
     - Maintainer and Author: use “Vader” as placeholder.
     - Short description: “Force Instagram LiquidGlass UI flags.”

5. Filter plist (`LiquidGlassHook.plist`)
   - Create / overwrite `LiquidGlassHook.plist` with a standard Substrate filter
     that only injects into Instagram:

     - Bundles: `com.burbn.instagram`

6. GitHub Actions workflow
   - Create / overwrite `.github/workflows/build.yml` with a workflow that:
     - Runs on `macos-13` (or newer).
     - On `push` to `main` or `master` and on `workflow_dispatch`.
     - Installs Theos in `$HOME/theos` via `git clone --recursive`.
     - Exports `THEOS` and `THEOS_MAKE_PATH`.
     - Runs `make package` in the repo root.
     - Uploads resulting `.deb` (and optionally `.dylib` if present) as
       an artifact named `LiquidGlassHook-build`.

7. Testing / validation
   - You CANNOT actually run iOS binaries here, but you CAN verify:
     - `make package` exits with status 0.
     - The build produces at least one `.deb` under `./packages`.
   - If `make package` fails, fix the underlying error in the tweak
     sources or Makefile until the build passes.

8. Do NOT:
   - Do not introduce fishhook, custom Mach-O scanners, or manual trampolines.
   - Do not depend on external submodules beyond Theos itself.
   - Do not change the repo into a multi-tweak project.

The final state we want:
- A clean Theos tweak repo that builds successfully on GitHub Actions,
  producing a `.deb` with a tweak that forces Instagram’s LiquidGlass
  tab bar via C-level gates, without hardcoded absolute paths.
