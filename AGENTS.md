# 🤖 AI Agent Briefing

> Diretrizes canônicas, invariantes de engenharia, governança autônoma e protocolo operacional para agentes de inteligência artificial em repositórios do ecossistema.

---

## 🧭 Identidade & Fonte de Contexto

Todo agente de IA que atua neste repositório deve ancorar suas decisões na documentação canônica local antes de executar qualquer alteração. Consulte rigorosamente nesta ordem:

1. [README.md](README.md) — Arquitetura, stack técnica, topologia de diretórios e comandos operacionais específicos do repositório.
2. [TODO.md](TODO.md) — Matriz de status operacional, cobertura de implementação e roadmap de engenharia.
3. [PRINCIPLES.md](PRINCIPLES.md) — Os 22 Princípios de Engenharia UNIX e diretrizes estritas de Clean Code.
4. [CONTRIBUTING.md](CONTRIBUTING.md) — Fluxo Git soberano, convenção de commits semânticos e qualidade local.
5. `ENVIRONMENT.md` — Arquitetura federada do ecossistema (quando presente na raiz do repositório, como no hub `Environment` e seus submódulos centrais).

---

## 🤝 Protocolo Bidirecional de Esclarecimento Proativo

A autonomia operacional do agente é guiada pelo princípio de alinhamento contínuo: nunca assuma silenciosamente suposições ambíguas.

### 🏛️ Alinhamento Socrático (Master -> User)

Qualquer ambiguidade, inconsistência de requisitos, trade-off arquitetural crítico ou especificação incompleta DEVE ser esclarecido proativamente com o usuário via `ask_question` antes do início da execução em massa. É expressamente proibido adotar suposições silenciosas sobre escopo ou tomar ações destrutivas sem validação prévia.

### ⚡ Escalonamento de Subagentes (Worker -> Master)

Subagentes de execução que identificarem qualquer dúvida de escopo, divergência entre especificação e código real, ou risco de efeito colateral inesperado DEVEM interromper a mutação de arquivos e questionar imediatamente o agente orquestrador pai via `send_message`.

---

## ⚠️ Regras Críticas & Invariantes Soberanas

1. **Soberania e Isolamento de Repositórios OSS (`**/OSS/**`):** Projetos de terceiros sob diretórios `OSS/` são estritamente somente-leitura para operações globais, templates, formatação ou auditoria, só podendo ser editados sob ordem explícita e nominal do usuário e seguindo as regras do upstream.
2. **Desacoplamento Bancada vs. Produção & Zero-Dirty Invariant:** Nunca edite clones de produção diretamente (`~/.local/share/*`, `~/.config/*`, `~/.emacs.d`, etc.). Edite exclusivamente na bancada em `~/Documents/`, valide localmente (`make test`, `make ci`), comite e envie via `git push`. A produção recebe atualizações exclusivamente via `git pull` e DEVE manter `git status` 100% limpo a todo momento (Invariante Zero-Dirty).
3. **Hermetismo de Produção (`rm -rf .agents`):** O ecossistema é soberano e independente de ferramentas de IA. Código de produção (scripts, Makefiles, hooks, dotfiles, compiladores) não depende de `.agents/` ou `skills/`. Se o diretório `.agents/` for deletado, o repositório opera com 100% de sua integridade.
4. **Invariante Out-of-the-Box (`0755` / `0644` / `0700` / `0600`):** O repositório deve funcionar imediatamente após um simples `git clone`, sem etapas manuais pós-clone. Permissões octais canônicas devem estar registradas no Git Index (`0755` para executáveis/scripts/hooks, `0644` para arquivos de configuração e documentação, `0700`/`0600` para Vault e chaves). Scripts devem aplicar self-healing de permissões em tempo de execução.
5. **Taxonomia Tripartite de Comentários:** O código adota estritamente três categorias:
    - _Comentários de Sistema:_ PERMITIDOS (shebangs, pragmas, linters).
    - _Comentários Estruturais de 64/32 colunas:_ PERMITIDOS (cabeçalhos de 64 `-` `# ----------------------------------------------------------------`, seções de 32 colunas `### ================================` e `### --------------------------------` com títulos em MAIÚSCULO, réguas de 64 `=` em `.gitignore` `# ================================================================` com títulos em MAIÚSCULO, sem vazamento lateral).
    - _Comentários Explicativos/Narrativos:_ PROIBIDOS em código, arquivos de configuração e blocos de código dentro de Markdowns.
6. **Portabilidade POSIX, Makefiles Silenciosos & Boy Scout Rule:**
    - Sintaxe estrita POSIX `sh` (`#!/usr/bin/env sh`, sem bashismos).
    - Makefiles silenciosos com `.POSIX: .SILENT:`, `MAKEFLAGS += --no-print-directory -s`, subshells `(cd dir && $(MAKE))` e zero `@` redundante.
    - Sequências ANSI via `$'\e'` ou notação hexadecimal `\x1b` (nunca octal `\033`).
    - Redirecionamento seguro envolvendo destinos em aspas duplas (ex: `> "/dev/null" 2>&1`).
    - Refatoração Clean-Break sem legado (expurgar shims, aliases obsoletos e variáveis mortas).
    - Simetria de escopo e não-assimetria de subgrupo na documentação.
    - Emissão semântica de UI via rotinas canônicas `_ui_*`.
    - **Boy Scout Rule:** Ao identificar qualquer inconformidade com os padrões estabelecidos, notifique concisamente o usuário e aplique a correção de forma proativa.
7. **Governança Multi-Agente Argos:**
    - _Gatilho Semântico do Argos:_ Ao identificar menção a "Argos", "gerenciador de agentes", "orquestrador" ou requisições de delegação em subagentes, carregue e siga obrigatoriamente a skill global `argos-multi-agent-orchestrator` (ou a respectiva skill da família Argos) ANTES de invocar qualquer tool de delegação.
    - _Bloqueio de `native_swarm` e Polling via Cron:_ É vedado invocar a tool `swarm` por iniciativa própria (restrita a pedidos com a palavra literal `"swarm"`). É proibido utilizar `schedule` (cron) para monitoramento periódico de agentes.
    - _Herança Dinâmica & Papéis Semânticos Agnósticos:_ Em chamadas de delegação (`invoke_subagent`, `swarm`), utilize por padrão a herança nativa do modelo ativo da sessão (`Model: 'inherit'` ou omissão explícita) — ou o tier rápido nativo exposto pelo runtime atual, sem fixar nomes comerciais ou versões. Estruture a delegação nos papéis _Master Orchestrator / Planner Agent_, _Specialist Sub-Agent / Execution Worker_ e _Adversarial Verifier / QA Agent_.

---

## 🚀 Comandos Canônicos de Verificação (Quality Gates)

| Comando       | Finalidade Operacional                                           |
| :------------ | :--------------------------------------------------------------- |
| `make help`   | Exibe o catálogo interativo de comandos disponíveis              |
| `make test`   | Executa a suíte automatizada de testes locais                    |
| `make audit`  | Executa as suítes de auditoria estática de padrões e integridade |
| `make format` | Formata código-fonte e documentações com Prettier e linters      |
| `make ci`     | Executa a pipeline local completa de validação integrada         |
| `make hooks`  | Configura e ativa os ganchos Git com permissões canônicas (0755) |

---

## 📖 Referências Obrigatórias

- [README.md](README.md) — Visão geral, arquitetura e stack técnica
- [TODO.md](TODO.md) — Roadmap de tarefas e matriz de cobertura
- [PRINCIPLES.md](PRINCIPLES.md) — Os 22 Princípios de Engenharia Soberanos
- [CONTRIBUTING.md](CONTRIBUTING.md) — Guia de contribuição, fluxo Git e convenções
