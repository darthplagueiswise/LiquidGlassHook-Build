# Agent Instructions for LiquidGlassIGHook

## Project Purpose
Build **one** iOS `arm64` dylib, `LiquidGlassIGHook.dylib`, that forces Instagram’s
LiquidGlass UI gates ON. No Theos, Logos or MobileSubstrate are allowed.

### Must-hook symbols
| Symbol | Return value you must force |
|--------|----------------------------|
| `BOOL METAIsLiquidGlassEnabled()` | `YES` |
| `BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet()` | `YES` |
| `NSInteger IGTabBarStyleForLauncherSet()` | `2` |

### Build constraints
* **Tool-chain** Apple `clang` via `xcrun --sdk iphoneos`.
* **SDK** resolve with `xcrun --sdk iphoneos --show-sdk-path`.
* **Arch** `arm64`, minimum iOS 17.0.
* **Hooking** `fishhook` only (`rebind_symbols`).
* **Output** exactly one file → `LiquidGlassIGHook.dylib`
  * `install_name` **must** be `@rpath/LiquidGlassIGHook.dylib`.
* **GitHub Actions** uploads the dylib artifact as `LiquidGlassIGHook-dylib`.
* **Workflow runner** must always be `macos-latest` (do not change this back to any other runner).

### Permissions and process
* Codex Agent has full read/write access, including committing changes and merging PRs.
* After a PR is merged, always build and create a release containing two artifacts: the `.deb` package and the `.dylib` binary.

### Forbidden
* Theos / common.mk / tweak.mk
* Logos syntax (`%hook`, `%ctor`, etc.)
* MobileSubstrate / libsubstrate

If a change violates any rule above, discard it.
