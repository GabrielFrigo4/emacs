# 🔮 Emacs Configuration (.emacs.d) — AI Agent Briefing

> Este é o repositório da **configuração do Emacs** de Gabriel Frigo, integrante da **Suíte de Editores** do ecossistema [Universal Environment](https://github.com/GabrielFrigo4/environment).

---

## 🧭 Identidade e Papel

O repositório `.emacs.d` provê um ambiente de desenvolvimento extensível, centrado no GNU Emacs, com suporte modular a Org-mode, LSP (lsp-mode), Elpaca package manager, EAF e integrações com IA.

---

## 📁 Estrutura Canônica de Diretórios

- **`init.el`**: Ponto de entrada principal, feature toggles com suporte a variáveis de ambiente (`EMACS_AI`, `EMACS_LSP`, etc.) e caminhos do sistema.
- **`early-init.el`**: Otimizações de inicialização precoce e redirecionamento de cache native-comp.
- **`lib/core.el`**: Macros de detecção de SO (Linux, FreeBSD, macOS, Windows) e funções de indentação.
- **`etc/init/`**: Inicialização de pacotes (Elpaca), interface gráfica, atalhos globais e configurações de sessão.
- **`etc/editor/`**: Módulos de edição (`completion.el`, `lsp.el`, `scroll.el`, `treesit.el`, `utils.el`).
- **`etc/apps/`**: Aplicações integradas (`ai.el`, `apps.el`, `eaf.el`, `org.el`).
- **`etc/lang/`**: Modos de linguagens (`latex.el`, `lisp.el`, `markdown.el`, `lang.el`).
- **`etc/tools/`**: Ferramentas externas (`git.el`, `github.el`, `mandoc.el`, `shell.el`, `tools.el`).
- **`bin/`**: Utilitários auxiliares (`indent-all.sh` POSIX, `indent-all.ps1`, `indent-all.cmd`).

---

## ⚠️ Invariantes Críticas para Agentes de IA

1. **Fail-Safe & Graceful Degradation:** Toda biblioteca opcional ou chamada de pacote DEVE degradar graciosamente caso a rede esteja indisponível, a ferramenta não esteja instalada ou a flag correspondente esteja desativada. O Emacs NUNCA deve travar na inicialização.
2. **Taxonomia Tripartite de Comentários:** O código adota estritamente três categorias: 1. Comentários de Sistema = PERMITIDOS (shebangs, lexical-binding, pragmas); 2. Comentários Estruturais de 64/32 colunas = PERMITIDOS (header banner 64 `-` ou `;;;`, seções 32 cols `### ===` ou `;;; ===`, réguas de 64 `=` em `.gitignore`, sem vazamento); 3. Comentários Explicativos/Narrativos = PROIBIDOS em código, configs E blocos de código dentro de Markdowns (docstrings Elisp continuam obrigatórias e autônomas).
3. **Zero Secrets:** Credenciais e chaves de API NUNCA são salvas neste repositório. Use `auth-source` ou variáveis de ambiente injetadas pelo [Vault](https://github.com/GabrielFrigo4/vault).
4. **Independência Git:** Este repositório é um Git Submodule no Environment. Commits feitos aqui pertencem ao repositório `.emacs.d`.
5. **Hermetismo de Produção & Invariante `rm -rf .agents`:** Repositório 100% autônomo. Zero acoplamento de código de produção a `.agents/` ou `skills/` (o Emacs opera plenamente se `.agents/` for deletado).
6. **Bancada de Desenvolvimento vs. Runtimes de Produção:** Em produção, o Emacs reside e opera soberanamente em `~/.emacs.d`. O repositório central `Environment` é exclusivamente uma bancada de desenvolvimento. NUNCA aponte symlinks ou diretórios de runtime para `~/Documents/Environment/Editor/Emacs`.
7. **Ciclo Canônico de Propagação & Banimento de Cópia Manual:** Toda alteração é testada na bancada (`make test`, `make ci`), comitada e enviada via Git. Clones de produção recebem atualizações exclusivamente via `git pull` mantendo a working tree limpa (Invariante Zero-Dirty).
8. **Detecção Sensorial Dinâmica de Runtime:** Identificar automaticamente Wayland (PGTK), X11, DirectWrite, compilação nativa AOT/JIT (`libgccjit`) e Tree-sitter nativo (ABI ≥ 14) sem flags forçadas ou dependências quebradas.
9. **Tipografia Adaptativa & Resiliente:** Configurar DirectWrite no Windows e HarfBuzz/Fontconfig no Linux/FreeBSD com fallback automático de fontes sem lançar warnings.
10. **Invariante de Clonagem "Out-of-the-Box" (Zero-Tweaks Git Invariant):** O Emacs deve funcionar imediatamente após `git clone`. Modos octais no Git Index DEVEM ser rigorosamente `0755` para scripts executáveis em `bin/` e hooks, e `0644` para arquivos Elisp e documentação.
11. **Governança de Roadmap (TODO.md):** O repositório mantém seu [TODO.md](TODO.md) atualizado com a Matriz de Status e Backlog de Evolução, sincronizado com o badge no `README.md`.
12. **Invariante de `lexical-binding` na Linha 1:** TODO e qualquer arquivo Emacs Lisp (`.el`) criado ou mantido DEVE conter obrigatoriamente a declaração `;;; -*- lexical-binding: t -*-` estritamente na **primeira linha absoluta** (Linha 1), antes de qualquer régua ou cabeçalho.
13. **Refatoração Sem Legado / Soberania Monousuário (Clean-Break / Zero-Cruft Invariant):** O ecossistema é estritamente pessoal, governado e operado por um único desenvolvedor soberano (Gabriel Frigo). Evite manter resíduos de retrocompatibilidade, shims temporários, wrappers obsoletos, seções de compatibilidade legada ou aliases de transição ao renomear variáveis, comandos, funções, diretórios ou arquivos, salvo se expressamente ordenado pelo usuário. Toda refatoração deve ser atômica, direta, definitiva e limpa (_clean break_), expurgando o identificador antigo integralmente da base de código.
14. **Ergonomia de Cursor & Adaptação Tri-Modal (GUI, PTY 24-Bit e Raw TTY 16-Color):**
    - **Detecção Real do Tipo de Terminal (`tty-type` vs `getenv "TERM"`):** No GNU Emacs, subsistemas de subprocessos (`tramp`, `comint`, `server`) redefinem `TERM=dumb` em `process-environment`. Portanto, toda detecção de terminal DEVE consultar `(tty-type frame)` (em `display-raw-tty-p` e `emacs/set-terminal-cursor`), nunca apenas `(getenv "TERM")`.
    - **Em GUI e PTY 24-Bit (`-nw` em KDE Konsole, Alacritty, etc.):** Mantém o tema `doom-dark+` com fundo `#1e1e1e`, ícones Nerd Fonts ativos e banner ASCII limpo (`2`) no Dashboard quando em modo terminal (`-nw`).
    - **Em Raw TTY (`display-raw-tty-p`):** Aplica `interface/apply-tty-faces` por frame usando os 8 nomes ANSI canônicos do `tty-color-alist` (`"black"`, `"red"`, `"green"`, `"yellow"`, `"blue"`, `"magenta"`, `"cyan"`, `"white"`) combinados com `:weight 'bold` para acessar as cores brilhantes (8–15) sem falhar em terminfos de 8 cores (`TERM=linux` e `TERM=xterm`).
    - **Aweshell / Eshell:** Validação de executáveis em tempo real com cache em hash-table $O(1)$ (`aweshell/executable-cache`), realce imediato via `after-change-functions` e prompt `aweshell/theme-multi` adaptativo (ícones Nerd Font em GUI/PTY e Box Drawing/ASCII limpo em Raw TTY).
15. **Invariante de Autodocumentação Integral em Elisp (GNU Emacs Self-Documenting Standard):**
    - **100% de Cobertura de Docstrings:** Todo formulário `defun`, `defmacro`, `defvar`, `defcustom` e `defface` DEVE conter obrigatoriamente docstring informativa, precisa e autônoma.
    - **Docstrings Não São Comentários Narrativos:** Enquanto comentários inline `;;` narrando código são estritamente proibidos (zero comentários narrativos), docstrings Elisp integram a árvore de introspecção do runtime (`C-h f`, `C-h v`, `C-h k`, `M-x apropos`, ElDoc e `which-key`).
    - **Padrão Canônico de Formatação GNU Elisp:** A primeira linha da docstring deve ser uma oração completa e concisa de até 80 colunas ($\le 80$ cols). Argumentos formais DEVEM ser referenciados rigorosamente em `MAIÚSCULAS` (ex: `ARGS`, `FRAME`, `DIR`). Símbolos correlatos ou referenciados DEVEM ser delimitados por acento grave e apóstrofo (` `simbolo' `) para renderização automática de hiperlinks navegáveis nos buffers `_Help_`.
16. **Ambiente Híbrido Host/Guest (FreeBSD Workstation + Bhyve Linux Runtime):** Em estações FreeBSD, o agente de IA (`agy`) opera isolado dentro de uma máquina virtual Debian no Bhyve (`192.168.8.2`), conectada via NFSv3 à `/home/gabrielf` do host com paridade de UID/GID 1001. O agente executa comandos em ambiente Linux nativo (kernel 6.12/GNU), porém seus arquivos de trabalho residem fisicamente no ZFS do FreeBSD. Ao despachar comandos no terminal, utilize ferramentas Linux disponíveis no guest ou faça a demarcação correta ao editar scripts específicos de cada sistema operacional.
17. **Simetria de Escopo & Não-Assimetria de Subgrupo na Documentação:** Se um comportamento, protocolo ou invariante pertence a todo um grupo de componentes (ex: suíte de editores, shells suportados), documente-o no nível do grupo (documento de arquitetura, README do módulo pai ou especificação geral), evitando a criação de falsas assimetrias. Um sub-membro só deve receber documentação específica se implementar o comportamento de forma mais especializada, detalhada ou otimizada.

---

## 🛡️ Regra da Proatividade e Correção Contínua (Boy Scout Rule)

O agente de IA atua de forma proativa na manutenção e aplicação dos padrões canônicos deste repositório.

Ao identificar linhas ou artefatos fora dos padrões estabelecidos:

1. **Notificar concisamente** o usuário sobre o ajuste realizado.
2. **Corrigir a inconformidade**, aplicando o padrão correspondente:
    - **Lexical Binding Obrigatório:** Garantir `;;; -*- lexical-binding: t -*-` rigorosamente na linha 1 de todos os arquivos `.el`.
    - **Taxonomia Tripartite de Comentários:** Eliminar comentários explicativos óbvios em código, configs e blocos de código em Markdowns, preservando exclusivamente comentários de sistema, docstrings Elisp e delimitadores estruturais (64/32 colunas).
    - **Banners Estruturais:** Ajustar réguas para exatamente 64 hífens no topo ou 32 caracteres com `### ` no corpo (ou réguas `;;;` equivalentes em Elisp e 64 `=` em `.gitignore`).
    - **Portabilidade POSIX:** Substituir bashismos (`[[ ]]`, `&>`, arrays, `source`) por sintaxe estrita POSIX `/bin/sh`.
    - **Shebang Universal:** Garantir sempre `#!/usr/bin/env sh` ou `#!/usr/bin/env python3`.
    - **Sequências ANSI & Escapes:** Não use octais (`\033`, `\001`) para caracteres ou escapes. Use `[ -t 1 ] && echo -n $'\e...'` ou notação hexadecimal (`\x01`, `\x1b`). Octal é exclusivo para permissões POSIX (`chmod 0755`, `chmod 0644`, `umask`).
    - **Redirecionamento Seguro:** Envolver destinos em aspas duplas (ex: `> "/dev/null" 2>&1`).
    - **Makefiles:** Assegurar cabeçalho `.POSIX: .SILENT:`, `MAKEFLAGS += --no-print-directory -s`, alinhamento estético de variáveis e zero `@` redundante.
    - **Permissões Canônicas:** Aplicar 4 dígitos octais (`chmod 0755`, `chmod 0644`, `chmod 0700`, `chmod 0600`).
    - **Invariante Out-of-the-Box:** Garantir modos octais corretos no Git Index e inicialização batch sem requerer intervenção manual pós-clone.
    - **Emissão Semântica de UI:** Substituir `echo` avulsos com emojis pelas rotinas canônicas `_ui_*`.
    - **Antifragilidade & Resiliência:** Resolução ativa de caminhos em cascata, auto-cura de permissões (0600 em chaves/segredos) e validação defensiva de pré-requisitos.
    - **Curadoria Cognitiva:** Capturar decisões estruturais e regras tácitas em skills locais compactas (`.agents/skills/`), mantendo-as atualizadas e expurgando ruído obsoleto.
    - **Refatoração Sem Legado:** Expurgar aliases obsoletos, variáveis mortas e shims de compatibilidade em renomeações.
    - **Elevação Antifrágil & Shift Seguro:** Usar o bloco explícito `if [ "$(id -u)" -ne 0 ]` para resolução de `ELEVATE` (evitando término fatal sob `set -e` como root) e proteger todo comando `shift` com validação prévia de parâmetros (`[ "$#" -ge N ] && shift N`).
    - **Simetria de Documentação:** Mover regras ou invariantes universais documentadas erroneamente em sub-membros específicos para o documento de arquitetura do grupo correspondente, eliminando falsas assimetrias.

---

## 🚀 Comandos de Verificação Rápida (Quality Gates)

| Comando                    | Finalidade Operacional                                                    |
| :------------------------- | :------------------------------------------------------------------------ |
| `make help`                | Exibe o catálogo interativo de comandos disponíveis                       |
| `make test` / `make batch` | Executa carregamento headless em batch mode validando integridade do boot |
| `make treesit`             | Atualiza e compila gramáticas Tree-sitter nativas                         |
| `make format`              | Formata arquivos Elisp com indentação canônica e Prettier                 |
| `make prettier`            | Formata arquivos Markdown e configurações com Prettier                    |
| `make indent`              | Aplica indentação canônica do Emacs em batch em todos os arquivos `.el`   |
| `make hooks`               | Configura permissão `0755` nos ganchos de `.githooks/`                    |
| `make ci`                  | Executa suite completa de integração contínua (`test`)                    |

---

## 📖 Referências Obrigatórias

Antes de qualquer modificação neste ecossistema, consulte:

- **[ENVIRONMENT.md](ENVIRONMENT.md)**: Arquitetura global do ecossistema
- **[PRINCIPLES.md](PRINCIPLES.md)**: Os 22 Princípios de Engenharia UNIX + Clean Code
- **[TODO.md](TODO.md)**: Planejamento estratégico e matriz de status operacional
- **[.agents/rules/principles.md](.agents/rules/principles.md)**: Regras específicas de engenharia Elisp
- **[.agents/skills/](.agents/skills/)**: Runbooks operacionais do Emacs
