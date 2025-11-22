# LiquidGlassHook-Build – Agent instructions

Objective
- This repo builds a single Theos tweak named `LiquidGlassHook` that emits a `.dylib` for manual injection into Instagram (iOS 26) via Feather, ldid, or any IPA patching pipeline.
- Core logic lives in `src/IGLiquidGlassHook.xm` and forces the LiquidGlass UI gates (_METAIsLiquidGlassEnabled, _IGIsCustomLiquidGlassTabBarEnabledForLauncherSet, _IGTabBarStyleForLauncherSet). Hooks are simple Logos `%hookf` overrides returning `YES` or style `1`.
- No extra submodules (Theos is fetched dynamically during CI builds).

Repository layout
- Keep a classic Theos tweak structure at repo root: `Makefile`, `control`, `LiquidGlassHook.plist`, `AGENTS.md`, `src/IGLiquidGlassHook.xm`, and `.github/workflows/build.yml`.

Build instructions
- GitHub Actions: open the Actions tab and run the `Build LiquidGlassHook` workflow via **Run workflow**. When it finishes, download the `LiquidGlassHook-dylib` artifact (built from `.theos/obj/arm64/LiquidGlassHook.dylib`).
- Local (optional): export THEOS and THEOS_MAKE_PATH, then run `make clean` and `make`.

Using the output
- Take the generated `LiquidGlassHook.dylib` and inject it into the Instagram IPA using Feather / ldid / your existing patch pipeline. The filter plist targets `com.burbn.instagram` only.

Coding notes
- Keep hooks limited to the confirmed C gates above; add extra selectors only once their classes are confirmed. Avoid private SDK headers that are not in a standard Theos setup.
