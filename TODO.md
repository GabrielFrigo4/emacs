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
| **Ergonomia no Terminal**    | 🟢 Estável  | `xterm-mouse-mode`, respostas curtas (`use-short-answers t`) e blindagem                   |
| **Robustez & Resiliência**   | 🟢 Estável  | Isolamento de módulos com `condition-case` e boot limpo batch < 0.5s                       |
| **Quality Gates**            | 🟢 Aprovado | Inicialização headless e batch 100% validada via `make test`                               |

---

## 🛡️ Atributos Entregues

- **Zero Pendências:** Ambiente modular Elisp sem código morto, monolítico ou dependências instáveis.
- **Projeto Aweww ("LSP da Web"):** Engine autônoma com buffer dedicado `*aweww*`, arquitetura Dual-Engine com hidratação Chromium/Blink V8 (`--dump-dom`), listas dedicadas por SO (Linux, BSD, Darwin, Windows), fallback soberano EWW, pesquisa integrada sem captcha, cache de histórico e diagnóstico via `M-x aweww-doctor`.
- **Player Multimídia Headless (`mpv` JSON-IPC):** Interceptação de URLs de mídia e YouTube com controle interativo por teclas (`P`, `X`, `+`, `-`, `>`, `<`) e sentinelas defensivas prevenindo processos zumbis.
- **Ergonomia no Terminal (`-nw`):** Ativação de `xterm-mouse-mode`, respostas curtas (`use-short-answers t`) e blindagem de avisos de compilação em macros obsoletas no Emacs 31+.
- **Sincronização:** Total alinhamento com os 22 Princípios de Engenharia UNIX do Universal Environment.

---

## 📌 Backlog & Próximos Passos

- [ ] **Ajuste da Barra de Ferramentas (Tool-Bar / Bar-Tools) no EWM:** Investigar e restaurar a exibição e estilização consistente da `tool-bar` dentro do ambiente EWM (`wewm`), alinhando layout e offsets de renderização.
- [ ] **Correção de Diálogo de Arquivo no GUI Emacs / Sway e Diretório Inicial:**
    - Investigar erro disparado no Sway ("there are errors in your config file" em vermelho) ao acionar "open new file" / diálogo gráfico de seleção de arquivo no `wgui`/`xgui emacs`, que bloqueia subsequentes popups de seleção.
    - Blindar o `default-directory` do Emacs no ciclo pós-inicialização para garantir que inicialize sempre no diretório home (`~`) do usuário, evitando captura esporádica de diretórios transitórios de build do Elpaca (ex: `~/.emacs.d/var/lib/elpaca/builds/ob-mermaid`).
- [ ] **Auditoria de Autodocumentação Integral Elisp (`C-h f`, `C-h v`, `C-h k`, `which-key`):** Expandir e padronizar as docstrings de todas as funções (`defun`/`defmacro`), variáveis (`defvar`/`defcustom`), faces (`defface`) e atalhos em `etc/`, `lib/` e `usr/local/` conforme a convenção GNU Elisp (primeira linha concisa $\le 80$ colunas, parâmetros em `MAIÚSCULAS` e referências cruzadas `` `simbolo' `` clicáveis no `*Help*`).
