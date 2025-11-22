# AGENTS.md – LiquidGlassHook-Build (dylib/tweak de LiquidGlass para Instagram iOS 26)

Este repositório constrói uma **dylib/tweak para Instagram** (arm64), usada para habilitar e controlar dinamicamente o **LiquidGlass** e outras flags de UI em iOS 26+, com injeção via Theos / Substrate e sideload.

Este arquivo é o guia principal para agentes (OpenAI Codex, Cursor, Copilot etc.).  
Sempre siga estas instruções antes de editar ou commitar qualquer coisa aqui.

---

## 1. Ambiente de desenvolvimento

- Plataforma esperada: macOS (incluindo `macos-latest` do GitHub Actions).
- Toolchain:
  - Theos instalado e variável `THEOS` configurada.
  - Xcode recente (16.x ou superior).
  - SDK iPhoneOS recente (por ex. `iPhoneOS18.x.sdk`).
- Arquitetura alvo:
  - `arm64` (dispositivos físicos, ex.: iPhone 15 Pro Max).
- Versão mínima de iOS:
  - `-miphoneos-version-min=17.0` ou superior, conforme `TARGET` no Makefile.

Dependências lógicas:

- MobileSubstrate (`mobilesubstrate`) para `MSHookFunction` (hook de C).
- UIKit / Foundation.

---

## 2. Comandos de build e validação

Da raiz do repositório:

1. Limpar build anterior:
   ```bash
   make clean

2.Compilar o tweak/dylib:

make

•Isso usa Theos e o Makefile para gerar .theos/obj/debug/LiquidGlassHook.dylib e/ou pacotes .deb (dependendo da configuração atual do Theos).

3.Verificar o binário gerado (sanity check):
Ajuste o caminho conforme necessário (por ex. o output final da dylib):

file .theos/obj/debug/LiquidGlassHook.dylib
otool -L .theos/obj/debug/LiquidGlassHook.dylib
otool -hV .theos/obj/debug/LiquidGlassHook.dylib

Esperado:
•file: deve mostrar Mach-O 64-bit dynamically linked shared library arm64.
•otool -L: dependências padrão (UIKit, Foundation, Substrate, etc.).
•otool -hV: cabeçalho MH_DYLIB, arquitetura ARM64.

4.Somente considere o trabalho concluído se:
•make clean && make termina sem erros.
•O binário passa nos checks acima.

Se qualquer comando falhar, corrija o código (não altere os comandos aqui sem necessidade forte) e repita.

---

3. Estrutura do projeto

Estrutura típica deste repo:

/
├─ AGENTS.md
├─ Makefile
├─ control
├─ LiquidGlassHook.plist
└─ src/
   └─ IGLiquidGlassHook.xm

•Makefile: define o tweak Theos (TWEAK_NAME = LiquidGlassHook).
•LiquidGlassHook.plist: filtro de injeção (Instagram).
•control: metadados estilo .deb (nome, id, depends).
•src/IGLiquidGlassHook.xm: lógica principal de:
•Configuração dinâmica (NSUserDefaults).
•Hooks C via MobileSubstrate (LiquidGlass gates).
•Hooks de selectors ObjC (isLiquidGlass*Enabled etc.).
•Menu interativo acionado por long press no botão de “mais/configurações” do perfil.

---

4. Convenções de hooks e configuração

Funções C típicas que podem ser hookadas (quando presentes no alvo):
•METAIsLiquidGlassEnabled
•IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
•IGTabBarStyleForLauncherSet

Regras:
•Não altere as assinaturas dessas funções.
•Hooks C devem ser estáveis: preferencialmente wrappers que:
•consultam flags dinâmicas (config), e
•chamam o original quando a flag estiver desligada.

Selectors relevantes de LiquidGlass e UI:
•isLiquidGlassContextMenuEnabled
•isLiquidGlassInAppNotificationEnabled
•isLiquidGlassToastEnabled
•isLiquidGlassToastPeekEnabled
•isLiquidGlassAlertDialogEnabled
•shouldMitigateLiquidGlassYOffset

Regras:
•Usar runtime ObjC (objc_getClassList, class_getInstanceMethod, method_setImplementation) para aplicar hooks nesses selectors.
•É aceitável usar wrappers simples que retornem sempre YES/NO, mas preferencialmente a lógica deve consultar configurações dinâmicas se estas estiverem disponíveis.

A configuração de runtime é centralizada em LGLiquidGlassConfig dentro de IGLiquidGlassHook.xm, usando NSUserDefaults e uma keychain simples de keys (LGLGCoreEnabled, LGLGExtendedUIEnabled, LGLGDebugEnabled).

---

5. Menu interativo (long press no botão de configurações)

O tweak expõe um menu interativo ao:
•Fazer long press (~1s) no botão de “more/settings” do perfil no Instagram, detectado por:
•Classe Instagram IGBadgedNavigationButton.
•accessibilityIdentifier == "profile-more-button".

O menu é um UIAlertController com ações para:
•Alternar:
•“Core LiquidGlass” (enable/disable).
•“Extended UI” (extras de LiquidGlass).
•“Debug log” (liga/desliga logs internos).
•Mostrar estados atuais (ON/OFF).

Hooks de C e de selectors devem ler essas flags sempre que possível, para permitir ajuste “em tempo real” sem reinstalar o tweak (dentro das limitações do hook).

---

6. Instruções específicas para agentes (Codex, Cursor, Copilot, etc.)

Quando você (agente) trabalhar neste repositório:
1.Leia o AGENTS.md antes de qualquer modificação.
2.Confirme a estrutura: Makefile, LiquidGlassHook.plist, control, src/IGLiquidGlassHook.xm.
3.Ao implementar ou modificar hooks:
•Preserve assinaturas de funções C.
•Mantenha a lógica de configuração dinâmica centralizada em LGLiquidGlassConfig.
•Sempre considere o impacto em iOS 26+ e arm64.
4.Sempre rode:

make clean
make
file .theos/obj/debug/LiquidGlassHook.dylib
otool -L .theos/obj/debug/LiquidGlassHook.dylib


5.Commits:
•Mensagens claras, ex.:
•Implement dynamic LiquidGlass C gates
•Add long-press settings menu for LiquidGlass
•Se abrir PR:
•Descreva mudanças, comandos rodados, e limitações conhecidas.
6.Não crie branches novas a menos que explicitamente solicitado.
Trabalhe na branch padrão (main/master) ou na branch indicada pelo usuário.

---

7. Adaptação futura

Se forem adicionados:
•Novos gates C (novas funções de feature flag).
•Novos selectors de UI.

Atualize:
•LGLiquidGlassConfig (novas keys, se necessário).
•Tabelas de selectors/funções dentro de IGLiquidGlassHook.xm.
•Este AGENTS.md, para refletir o fluxo real de build/hook/teste.

Mantenha este arquivo como fonte de verdade sobre como mexer neste tweak.

---
