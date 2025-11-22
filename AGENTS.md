AGENTS.md – Dylibs iOS (LiquidGlass / Hooks para iOS 26)

Este repositório é focado em construir dylibs para iOS (arm64), usadas como tweaks/injeções em apps (ex.: Instagram / WhatsApp) para habilitar recursos como LiquidGlass e outros experimentos de UI.

Este arquivo é o ponto de referência principal para agentes (OpenAI Codex, Cursor, Copilot etc.).
Sempre siga estas instruções antes de editar ou commitar qualquer coisa aqui.

⸻

1. Ambiente de desenvolvimento

1.1. Sistema e toolchain
	•	Plataforma esperada: macOS recente (runner macos-latest do GitHub Actions).
	•	Toolchain:
	•	Xcode 16.x ou superior.
	•	SDK de iOS / iPhoneOS recente (por exemplo: iPhoneOS18.x.sdk).
	•	Arquitetura alvo:
	•	Apenas arm64 (dispositivos físicos, iPhone 15 Pro Max e similares).
	•	Versão mínima de iOS:
	•	-miphoneos-version-min=17.0 ou superior, conforme definido no Makefile.

1.2. Dependências externas
	•	Uso de APIs de baixo nível:
	•	<mach-o/loader.h>, <mach-o/dyld.h>, <mach-o/nlist.h> para parsing de Mach-O e rebinding.
	•	<objc/runtime.h> para hooks em selectors Objective-C.
	•	Não introduza novas dependências (frameworks externos, pods, etc.) sem necessidade explícita:
	•	A prioridade é manter a dylib mínima, estável e fácil de injetar via ferramentas como Feather.

⸻

2. Comandos de build e validação

Sempre que você modificar código neste repositório:
	1.	Limpe o build anterior:

make clean


	2.	Compile a dylib:

make


	3.	Valide o binário gerado (sanity check mínimo):
A partir da raiz do repo:

file IGLiquidGlassHook.dylib
otool -L IGLiquidGlassHook.dylib
otool -hV IGLiquidGlassHook.dylib

	•	Esperado:
	•	file deve relatar um binário Mach-O 64-bit dynamically linked shared library arm64.
	•	otool -L deve listar dependências padrão (ex.: /System/Library/Frameworks/Foundation.framework/Foundation).
	•	otool -hV deve mostrar MH_DYLIB e arquitetura ARM64.

	4.	Somente considere o trabalho concluído se:
	•	make clean && make finaliza sem erros.
	•	A dylib gerada passa nos checks acima.

Se algum comando falhar, corrija o código (não edite os comandos aqui sem motivo muito forte) e rode novamente até ficar verde.

⸻

3. Estrutura do projeto

Estrutura típica:

/
├─ AGENTS.md                    # ESTE arquivo (orientação para agentes)
├─ IGLiquidGlassHook.m          # Implementação dos hooks (C + ObjC)
├─ Makefile                     # Build da dylib via clang/xcrun
└─ .github/
   └─ workflows/
      └─ build-ig-liquidglass.yml  # CI: make clean && make + upload de artefato

	•	A lógica principal de hooks fica em IGLiquidGlassHook.m.
	•	O fluxo oficial de build é o do Makefile.
Não crie sistemas paralelos (ex.: xcodeproj) sem alinhar este AGENTS.md.

⸻

4. Convenções de código e hooks

4.1. Funções C (gates principais de feature)

Este projeto usa hooks em funções C expostas nos binários/frameworks dos apps:

Exemplos típicos:
	•	METAIsLiquidGlassEnabled
	•	IGIsCustomLiquidGlassTabBarEnabledForLauncherSet
	•	IGTabBarStyleForLauncherSet

Regras:
	1.	Não altere as assinaturas:
	•	Se a função original não recebe parâmetros, o hook deve ser type name(void).
	•	Evite “adivinhar” parâmetros; use sempre o que foi observado via Ghidra/otool.
	2.	Hooks devem ser idempotentes e estáveis:
	•	Meta: forçar retorno de feature flag para “ligado” (ex.: YES ou 1).
	•	Não deve quebrar o fluxo de inicialização do app.
	3.	Ao escrever hooks C, siga o padrão:

static BOOL (*orig_METAIsLiquidGlassEnabled)(void);

static BOOL hooked_METAIsLiquidGlassEnabled(void) {
    // Sempre habilitado
    return YES;
}


	4.	Para rebindings de símbolos:
	•	Use o rebinder interno baseado em Mach-O, ou um fishhook bem configurado.
	•	Não implemente novas técnicas arriscadas (ex.: patch binário em runtime) sem necessidade.

4.2. Hooks em selectors Objective-C

Esta dylib também hooka selectors relacionados a feature flags de UI:

Exemplos:
	•	isLiquidGlassContextMenuEnabled
	•	isLiquidGlassInAppNotificationEnabled
	•	isLiquidGlassToastEnabled
	•	isLiquidGlassToastPeekEnabled
	•	isLiquidGlassAlertDialogEnabled
	•	shouldMitigateLiquidGlassYOffset

Regras:
	1.	Use runtime ObjC (class_getInstanceMethod, class_getClassMethod, method_setImplementation).
	2.	Hooks genéricos de retorno simples seguem o padrão:

static BOOL lg_alwaysYES(id self, SEL _cmd) { return YES; }
static BOOL lg_alwaysNO (id self, SEL _cmd) { return NO;  }


	3.	Ao procurar e patchar selectors:
	•	Percorra a lista de classes com objc_getClassList.
	•	Para cada classe que responde ao selector, troque a implementação pelo lg_alwaysYES ou lg_alwaysNO conforme previsto.
	•	Não altere outras propriedades ou ivars; o foco é apenas o retorno booleano.

⸻

5. Segurança, limites e o que NÃO fazer

Para manter o projeto utilizável e estável:
	•	Não introduzir:
	•	Syscalls diretas ou APIs privadas que possam causar crash ou rejeição óbvia.
	•	Qualquer lógica que dependa de jailbreak ou root (assuma ambiente não-jailbroken com injeção via ferramentas de sideload).
	•	Não alterar:
	•	Nome do arquivo principal da dylib (IGLiquidGlassHook.dylib) sem atualizar o Makefile e este AGENTS.md.
	•	Assinaturas públicas das funções/seletores mencionados aqui, a menos que a análise binária prove que estão erradas.
	•	Não adicionar:
	•	Networking interno à dylib.
	•	Telemetria, log remoto ou qualquer coisa que “fale com a internet”.

Este projeto é exclusivamente para hook de UI/client-side, sem comunicação de rede adicional.

⸻

6. Instruções para agentes (Codex, Cursor, Copilot, etc.)

Se você é um agente de código (OpenAI Codex, Cursor, GitHub Copilot, etc.), siga este fluxo sempre que trabalhar neste repo:
	1.	Ler AGENTS.md antes de qualquer modificação.
	2.	Quando receber uma tarefa, faça no mínimo:
	•	Confirmar a estrutura dos arquivos:
	•	IGLiquidGlassHook.m
	•	Makefile
	•	.github/workflows/build-ig-liquidglass.yml (se existir)
	•	Rodar:

make clean
make


	3.	Se make falhar:
	•	Leia o erro de compilação.
	•	Corrija somente os arquivos necessários (normalmente IGLiquidGlassHook.m e/ou Makefile).
	•	Rode novamente make clean && make.
	•	Repita até o build ser bem-sucedido.
	4.	Antes de concluir a tarefa, rode:

file IGLiquidGlassHook.dylib
otool -L IGLiquidGlassHook.dylib

e verifique se:
	•	O binário é um Mach-O 64-bit válido para arm64.
	•	As dependências parecem razoáveis (nada estranho ou extra).

	5.	Commits e Pull Requests:
	•	Use mensagens de commit claras, por exemplo:
	•	Fix LiquidGlass selector hooks
	•	Refine Mach-O rebinder for arm64
	•	Ao abrir PR:
	•	Descreva:
	•	O que foi alterado (hooks, assinaturas, lógica do rebinder).
	•	Os comandos que você rodou (make clean && make, file, otool -L) e resultados.
	6.	Não crie branches novas a menos que o usuário peça explicitamente:
	•	Trabalhe normalmente na branch padrão (main / master) ou na branch indicada na issue/tarefa.

⸻

7. Como adaptar para outros tweaks/dylibs

Ao usar este template em outros repositórios de dylib:
	•	Atualize:
	•	Nome da dylib no Makefile e aqui no AGENTS.md.
	•	Lista de funções C e selectors relevantes (por exemplo, outras feature flags).
	•	Mantenha:
	•	Seção de build e validação (make clean && make, file, otool).
	•	Regras de segurança e limites.
	•	Instruções para agentes (passos 1–6 da seção anterior).

Trate este arquivo como documentação viva:
se o fluxo real de build/test mudar, atualize AGENTS.md primeiro para que os agentes sempre saibam o caminho correto.
