# LiquidGlassHook-Build

Tweak em Theos/MobileSubstrate para forçar as flags centrais de **LiquidGlass** no Instagram, com build automatizado via **GitHub Actions**.

O objetivo é ter uma `.dylib` / `.deb` estável que:

- Liga o gate global de LiquidGlass.
- Liga o gate específico da tab bar LiquidGlass.
- Força o estilo da tab bar para o modo LiquidGlass.
- Funciona como base para futuros hooks adicionais (toasts, context menus, etc.).

> Nota: este projeto é focado em pesquisa / experimentação de UI. Use por sua conta e risco.

---

## Visão geral

Este repositório contém:

- Um tweak Theos chamado **`IGLiquidGlassHook`**.
- Hooks C-level nas funções do framework do Instagram:
  - `METAIsLiquidGlassEnabled`
  - `IGIsCustomLiquidGlassTabBarEnabledForLauncherSet`
  - `IGTabBarStyleForLauncherSet`
- Workflow do GitHub Actions para compilar e empacotar o tweak em um runner macOS.

O resultado do build é um pacote `.deb` (e, opcionalmente, `.dylib`) pronto para injeção no Instagram (via jailbreak tradicional ou ferramentas de injeção em IPA, como Feather, etc.).

---

## Estrutura do repositório

```text
LiquidGlassHook-Build/
├── AGENTS.md                # Instruções para agentes (Codex / automações)
├── Makefile                 # Makefile Theos principal
├── control                  # Metadados do pacote Debian
├── LiquidGlassHook.plist    # Filtro de injeção (bundle com.burbn.instagram)
├── src/
│   └── IGLiquidGlassHook.xm # Código da tweak (Logos)
└── .github/
    └── workflows/
        └── build.yml        # Workflow de build no GitHub Actions


⸻

Requisitos

Para build local (opcional, se você quiser testar fora do Actions):
•macOS com Xcode instalado.
•Theos clonado (normalmente em ~/theos).
•Toolchain iOS arm64 (instalada junto com Xcode).

Para build automático:
•Repositório hospedado no GitHub (este).
•GitHub Actions habilitado.

⸻

Como funciona o tweak

O código em src/IGLiquidGlassHook.xm usa Logos para hookar diretamente as funções C exportadas pelo framework interno:
•BOOL METAIsLiquidGlassEnabled(void);
Sempre retorna YES, ligando o gate global.
•BOOL IGIsCustomLiquidGlassTabBarEnabledForLauncherSet(void);
Sempre retorna YES, garantindo que o conjunto de tabs use o layout LiquidGlass.
•NSInteger IGTabBarStyleForLauncherSet(void);
Retorna constantemente 1, correspondente ao estilo de tab bar que, nos patches estáticos anteriores, ativou a tab bar LiquidGlass.

O tweak é injetado apenas no processo do Instagram via LiquidGlassHook.plist:

<key>Bundles</key>
<array>
  <string>com.burbn.instagram</string>
</array>

Hooks adicionais (por exemplo isLiquidGlassToastEnabled, isLiquidGlassContextMenuEnabled, etc.) podem ser adicionados futuramente em Logos, assim que os símbolos e classes forem confirmados com Ghidra.

⸻

Build local com Theos

Se você tiver o Theos instalado localmente:

export THEOS=~/theos
export THEOS_MAKE_PATH=$THEOS/makefiles

make clean
make package

Saída esperada:
•Pacote .deb em ./packages/.
•Opcionalmente a .dylib na raiz ou em .theos/obj.

⸻

Build automático (GitHub Actions)

O workflow ./.github/workflows/build.yml:
•Roda em macos-13.
•É disparado em:
•push para main/master
•workflow_dispatch (disparo manual)
•Passos principais:
1.Clona o repo.
2.Clona o Theos em $HOME/theos com --recursive.
3.Exporta THEOS e THEOS_MAKE_PATH.
4.Executa make clean && make package.
5.Publica os .deb (e .dylib, se houver) como artefatos chamados LiquidGlassHook-build.

Você encontra os artefatos na aba Actions → run específico → Artifacts.

⸻

Instalação e uso

Existem alguns cenários possíveis:
1.Jailbreak tradicional (Sileo/Zebra/Cydia):
•Transfira o .deb para o dispositivo.
•Instale via gerenciador de pacotes ou com dpkg -i.
2.Injeção em IPA (ex.: Feather / outras ferramentas):
•Extraia a .dylib do .deb (ou use a .dylib gerada diretamente).
•Injete a .dylib no Instagram com a ferramenta de sua escolha.
•Certifique-se de que o plist de filtro ou as configs da ferramenta
estão apontando para o bundle com.burbn.instagram.

Em qualquer caso, após injetar:
•Abra o Instagram.
•A tab bar deve assumir o estilo LiquidGlass (de acordo com os patches já validados).

⸻

Notas de compatibilidade
•Alvo de build: arm64, iphoneos (mínimo iOS 17 por padrão).
•Teste previsto para rodar em versões mais novas (iOS 17–26), desde que:
•Os símbolos METAIsLiquidGlassEnabled, IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
e IGTabBarStyleForLauncherSet continuem presentes.
•Se o Instagram mudar a assinatura ou remover esses símbolos, o tweak pode deixar de ter efeito
(mas, em princípio, não deve quebrar o app se os hooks forem feitos apenas em funções existentes).

⸻

Extensões futuras

Ideias para evoluir o projeto:
•Hookar os booleans adicionais:
•isLiquidGlassContextMenuEnabled
•isLiquidGlassInAppNotificationEnabled
•isLiquidGlassToastEnabled
•isLiquidGlassToastPeekEnabled
•isLiquidGlassAlertDialogEnabled
•Implementar um menu interno (hold em um ícone de settings, por exemplo)
para ligar/desligar dinamicamente os hooks via NSUserDefaults.
•Adicionar flags de debug para logar quando as funções C forem chamadas.

⸻

Licença

Defina aqui a licença que preferir (por exemplo MIT):

Copyright (c) Vader

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
[...]
