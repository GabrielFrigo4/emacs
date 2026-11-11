# 🗺️ Roadmap & Status — GNU Emacs Modular Suite

> **Status:** 🟢 **100% Operacional & Estável — Zero Pendências Ativas**
> Detecção sensorial de hardware/display, tipografia adaptativa, IA local Gemma 4, Org-mode e REPLs interativos foram integralmente concluídos.

---

## 📊 Matriz de Maturidade

| Área                         |   Status    | Cobertura / Estado                                                                         |
| :--------------------------- | :---------: | :----------------------------------------------------------------------------------------- |
| **Detecção de Hardware**     | 🟢 Estável  | Auto-detecção de Wayland (PGTK), X11, libgccjit e Tree-sitter nativo                       |
| **Tipografia Adaptativa**    | 🟢 Estável  | DirectWrite no Windows e HarfBuzz/Fontconfig com ligaduras no UNIX                         |
| **Console Puro & TTY (-nw)** | 🟢 Estável  | Degradação elegante 16/256 cores, mouse xterm/gpm e zero dependência GUI                   |
| **Inteligência Artificial**  | 🟢 Estável  | Integração exclusiva `gemma4:e2b` / `gemma4:e4b` com supressão de think                    |
| **Org-mode & Produtividade** | 🟢 Estável  | Capture templates (`t`/`n`/`j`), exportadores e alinhamento de tags                        |
| **Common Lisp & Elisp**      | 🟢 Estável  | REPLs interativos (SLIME / IELM) com atalhos de avaliação rápida                           |
| **Aweww (LSP da Web)**       | 🟢 Estável  | Arquitetura Dual-Engine com hidratação Chromium-first por SO, fallback eww nativo e doctor |
| **Player Multimídia MPV**    | 🟢 Estável  | Streaming de áudio/YouTube via `mpv` com JSON-IPC e proteção anti-zumbi                    |
| **Suíte de 4 Terminais**     | 🟢 Estável  | Aweshell, Eat (in-place & standalone), Vterm e Term com integração Evil e _ui_*            |
| **Ergonomia no Terminal**    | 🟢 Estável  | `xterm-mouse-mode`, respostas curtas (`use-short-answers t`) e blindagem                   |
| **Robustez & Resiliência**   | 🟢 Estável  | Isolamento de módulos com `condition-case` e boot limpo batch < 0.5s                       |
| **Quality Gates**            | 🟢 Aprovado | Inicialização headless e batch 100% validada via `make test`                               |

---

## 🛡️ Atributos Entregues

- **Zero Pendências:** Ambiente modular Elisp sem código morto, monolítico ou dependências instáveis.
- **Arquitetura Quádrupla de Terminais & Eat Dual-Mode:** Terminal `eat` (`Emulate A Terminal`) integrado em modo dual — standalone (`M-x eat`) com cascata `zsh -> bash -> sh` e integração modal Evil (`eat-semi-char-mode` em Evil Insert e `eat-emacs-mode` em Evil Normal), acoplado ao `aweshell` via `eat-eshell-mode` e `eat-eshell-visual-command-mode` para execução de TUIs in-place sem descontinuar o buffer, com fallback para `aweshell-exec-visual` (`vterm`/`term`), e consolidação de `usr/local/*` como diretórios vendor in-tree diretamente rastreados no Git.
- **Hover Liso no Wayland PGTK:** Polling de hover com taxa de 30ms e `pgtk-wait-for-event-timeout 0.001`, mantendo `track-mouse nil` e o ciclo de piscar do cursor de 1200ms inalterado, com atualização fluida de botões em qualquer buffer.
- **Robustez no Evil & Doc-View:** Carregamento defensivo de bindings do `doc-view-mode-map` com dupla proteção `with-eval-after-load`.
- **EXWM Ergonomia & Clipboard:** Liberação da combinação `C-c` para cópia instantânea em janelas X11, realocação de comandos de controle para a tecla Super e sincronização bidirecional de área de transferência.
- **Integração Google Antigravity & Paridade Aweshell:** Comandos `M-x agy`, `agyc`, `agya`, `agyca` dedicados em terminal (com wrapper SSH no FreeBSD) e despacho visual de TUIs sem corrupção de buffer, com paridade completa de funções `eshell/*`.
- **TTY Escuro no FreeBSD vt(4):** Modo de fundo escuro (`dark`) forçado em `early-init` e hooks de frame/TTY, garantindo contraste idêntico ao Linux.
- **Blindagem da Bancada contra var/ e tmp/:** Redirecionamento automático de estados temporários e rascunhos para diretório temporário efêmero em modo batch ou bancada de desenvolvimento.
- **Projeto Aweww ("LSP da Web"):** Engine autônoma com buffer dedicado `*aweww*`, arquitetura Dual-Engine com hidratação Chromium/Blink V8 (`--dump-dom`), listas dedicadas por SO (Linux, BSD, Darwin, Windows), fallback soberano EWW, pesquisa integrada sem captcha, cache de histórico e diagnóstico via `M-x aweww-doctor`.
- **Player Multimídia Headless (`mpv` JSON-IPC):** Interceptação de URLs de mídia e YouTube com controle interativo por teclas (`P`, `X`, `+`, `-`, `>`, `<`) e sentinelas defensivas prevenindo processos zumbis.
- **Ergonomia no Terminal (`-nw`):** Ativação de `xterm-mouse-mode`, respostas curtas (`use-short-answers t`) e blindagem de avisos de compilação em macros obsoletas no Emacs 31+.
- **Sincronização:** Total alinhamento com os 22 Princípios de Engenharia UNIX do Universal Environment.

---

## 📌 Backlog & Próximos Passos

---

> [!TIP]
> Para detalhes sobre a arquitetura e convenções de engenharia, consulte o [PRINCIPLES.md](PRINCIPLES.md) e o [ENVIRONMENT.md](ENVIRONMENT.md).
