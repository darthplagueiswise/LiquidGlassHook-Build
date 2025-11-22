# LiquidGlassHook

Tweak Theos para forçar permanentemente as flags de **LiquidGlass** no Instagram. O resultado é uma `.dylib` que pode ser injetada manualmente (IPA patching) ou embalada como `.deb` conforme sua pipeline.

## O que o hook faz
- `METAIsLiquidGlassEnabled` → retorna sempre `YES`.
- `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet` → retorna sempre `YES`.
- `IGTabBarStyleForLauncherSet` → retorna sempre `1` para aplicar o estilo LiquidGlass.

## Requisitos
- macOS com Xcode (toolchain iOS arm64). Testado para destino `iphone:clang:latest:16.0` (compatível com iOS 17–26).
- Theos disponível no caminho configurado via `THEOS` e `THEOS_MAKE_PATH`.

## Build local (Theos)
```bash
export THEOS=/opt/theos
export THEOS_MAKE_PATH=$THEOS/makefiles
make clean
make
```
Saída principal: `.theos/obj/arm64/LiquidGlassHook.dylib`.

## Build em CI (GitHub Actions)
1. Abra a aba **Actions** no GitHub.
2. Execute o workflow **Build LiquidGlassHook** via **Run workflow** (disponível para `push` ou acionamento manual).
3. Baixe o artifact **LiquidGlassHook-dylib**, que aponta para `.theos/obj/arm64/LiquidGlassHook.dylib` gerado pelo Theos.

## Uso da .dylib
- Injete `LiquidGlassHook.dylib` na IPA do Instagram (bundle `com.burbn.instagram`) usando Feather, ldid, ou outra pipeline de patch que você já utilize.
- Alternativamente, empacote-a em um `.deb` e instale via gerenciador de pacotes se estiver em ambiente jailbreak.

## Estrutura
```
Makefile                 # Tweak clássico do Theos (TARGET 16.0, arm64)
control                  # Metadados Debian
LiquidGlassHook.plist    # Filtro para com.burbn.instagram
src/IGLiquidGlassHook.xm # Hooks Logos
.github/workflows/build.yml
AGENTS.md
```
