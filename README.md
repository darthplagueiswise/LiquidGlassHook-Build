# IGLiquidGlassHook

Dylib de hook em tempo de execução para forçar o uso do LiquidGlass em apps Instagram / Meta no iOS, sem precisar repatchear o binário a cada nova versão da IPA.

Este projeto foi pensado para o seguinte fluxo:

- O app (ex.: Instagram) já está descriptografado.
- Você injeta esta `dylib` na IPA usando uma ferramenta como Feather (Ellekit).
- A `dylib` entra no processo e:
  - força os “gates” principais de LiquidGlass (funções C);
  - força diversas flags booleanas de UI LiquidGlass (métodos Objective-C).

## O que este hook faz

### 1. Hooks C (gates principais de LiquidGlass)

São rebindadas, em runtime, as seguintes funções C exportadas pelo framework da Meta:

- `METAIsLiquidGlassEnabled`
- `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`
- `IGTabBarStyleForLauncherSet`

Os hooks fazem:

- `METAIsLiquidGlassEnabled()` → retorna sempre `YES`.
- `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet()` → retorna sempre `YES`.
- `IGTabBarStyleForLauncherSet()` → retorna um estilo constante (por padrão `1`, que deve corresponder ao estilo LiquidGlass usado nos patches estáticos já validados via Ghidra).

Isso substitui os patches estáticos em assembly nesses 3 símbolos, de forma que você não precisa refazer patch em cada nova versão do app enquanto os nomes dos símbolos se mantiverem. O rebinder é interno (não depende de fishhook ou outros submódulos).

### 2. Hooks Objective-C (flags de UI LiquidGlass)

Além das funções C, o hook também intercepta, em runtime, diversos selectors Objective-C relacionados a LiquidGlass:

- `isLiquidGlassContextMenuEnabled`
- `isLiquidGlassInAppNotificationEnabled`
- `isLiquidGlassToastEnabled`
- `isLiquidGlassToastPeekEnabled`
- `isLiquidGlassAlertDialogEnabled`
- `shouldMitigateLiquidGlassYOffset`

O comportamento aplicado:

- Os cinco métodos `*Enabled` passam a retornar sempre `YES`.
- `shouldMitigateLiquidGlassYOffset` passa a retornar `NO` (sem mitigação de offset vertical por padrão; se você preferir outro comportamento, basta ajustar no código).

A implementação percorre todas as classes registradas no runtime e, para cada uma que responda a um desses selectors (método de instância ou de classe), substitui a implementação original por uma função simples que devolve `YES` ou `NO`.

## Estrutura do repositório

- `IGLiquidGlassHook.m`
  Arquivo principal da `dylib`. Contém:
  - Hooks C via rebinder interno (sem dependência externa);
  - Hooks Objective-C em selectors LiquidGlass;
  - Função marcada com `__attribute__((constructor))` que aplica todos os hooks ao carregar.

- `Makefile`
  Script de build minimalista para compilar a `dylib` usando o `clang` e o SDK do iPhoneOS a partir do Xcode.
  Produz `IGLiquidGlassHook.dylib` para arquitetura `arm64`, com alvo mínimo configurável via `IOS_DEPLOYMENT_TARGET` (padrão `26.0`, recomendado para manter compatibilidade com releases recentes; ajuste conforme o SDK disponível, caso sua máquina/local tenha um iOS SDK anterior).

- `.github/workflows/build-ig-liquidglass.yml`
  Workflow do GitHub Actions que:
  - usa `macos-latest` (com Xcode + iPhoneOS SDK);
  - resolve o deployment target solicitado (26.0 por padrão) para o máximo suportado pelo SDK disponível no runner e exporta em `IOS_DEPLOYMENT_TARGET`;
  - roda `make` na raiz do repositório com o deployment target efetivo;
  - inspeciona arquitetura e target mínimo com `lipo` e `otool`;
  - publica `IGLiquidGlassHook.dylib` como artifact em toda execução;
  - cria release e anexa a `dylib` automaticamente quando a execução for disparada por uma tag `v*`.

## Pré-requisitos

Para build local:

- macOS com:
  - Xcode instalado;
  - SDK iPhoneOS disponível (`xcrun --sdk iphoneos --show-sdk-path` deve funcionar).

Para build remoto via GitHub Actions:

- Repositório hospedado no GitHub.
- Workflow de Actions habilitado.
- Para gerar release, crie uma tag `vX.Y.Z` (ex.: `git tag v1.0.0 && git push origin v1.0.0`) ou dispare manualmente o workflow com ref tag; o job `release` vai baixar o artifact gerado no job de build e anexar à release correspondente.

## Observações sobre dependências

O projeto é auto-contido e não requer submódulos adicionais. Para builds locais ou no GitHub Actions, basta ter o Xcode instalado (com o SDK iPhoneOS disponível) para que o Makefile funcione corretamente.
