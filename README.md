# 🔮 GNU Emacs Configuration

> Configuração modular, declarativa e resiliente do GNU Emacs para desenvolvimento, edição modal, LSP e Org-mode.

[![Environment](https://img.shields.io/badge/🏛️_Environment-Hub-blue)](https://github.com/GabrielFrigo4/environment)
[![GNU Emacs](https://img.shields.io/badge/GNU_Emacs-30%2B-purple?logo=gnuemacs&logoColor=white)](https://www.gnu.org/software/emacs/)
[![Tree-sitter](https://img.shields.io/badge/Tree--sitter-ABI_14%2B-forestgreen?logo=tree-sitter&logoColor=white)](https://tree-sitter.github.io/tree-sitter/)
[![POSIX](https://img.shields.io/badge/POSIX-Shell_Scripts-orange?logo=gnubash&logoColor=white)](bin/indent-all.sh)
[![License](https://img.shields.io/badge/License-MIT-green?logo=open-source-initiative&logoColor=white)](LICENSE)
[![Roadmap](https://img.shields.io/badge/🗺️_Roadmap-TODO.md-teal)](TODO.md)
[![Contributing](https://img.shields.io/badge/🤝_Contributing-CONTRIBUTING.md-orange)](CONTRIBUTING.md)

---

## 🧭 Visão Geral

Este repositório contém a configuração pessoal do **GNU Emacs (versão 30+, preparado para 31+)** de Gabriel Frigo, integrando a **Suíte de Editores** do [Universal Environment](https://github.com/GabrielFrigo4/environment). A arquitetura prioriza:

- **Baseline Moderno (GNU Emacs 30+):** Exige GNU Emacs 30.1+ com Tree-sitter nativo no core C (ABI ≥ 14) e suporte opcional a compilação nativa AOT/JIT (`libgccjit`).
- **Startup Instantâneo & Resiliente:** Feature toggles defensivos e isolamento de módulos com `condition-case`.
- **Controle Dinâmico:** Flags customizáveis via variáveis de ambiente (`EMACS_AI`, `EMACS_LSP`, `EMACS_TREESIT`).
- **LSP Integrado:** lsp-mode de alta performance para linguagens compiladas e interpretadas.
- **Gerenciador Elpaca:** Gestão assíncrona e declarativa de pacotes.
- **Modos Pessoais Integrados:** Pacotes locais em `usr/local/` (`aweshell` com os 3 temas canônicos do Universal Shell — `multi`, `pill` e `micro` — adaptativos entre GUI/PTY e Raw TTY, além de `aweww` para leitura web dinâmica).
- **Tipografia Homologada:** Projetado e calibrado para **`JetBrainsMono NF`** (`:height 120`), proporcionando proporção equilibrada em Org-mode, mode-line e ícones de buffer, com geometria inicial centrada (`81x27`).
- **Arquitetura de Interface & Flush Cairo PGTK:** Supressão incondicional da `tool-bar` (`interface/apply-tool-bar` configurando `tool-bar-lines 0` e `tool-bar-mode -1` em GUI, EWM e TTY bruto, preservando `menu-bar` exclusivamente em modos gráficos). Flush imediato da superfície Cairo em Wayland PGTK (`track-mouse t` + `interface/pgtk-flush-mouse-hover`), eliminando o atraso de 500ms atrelado ao piscar do cursor nos botões do Dashboard.
- **Terminal Aweshell & Biblioteca Semântica UI:** Integração do Eshell com a biblioteca nativa `_ui_*` (`_ui_banner`, `_ui_step`, `_ui_sub`, `_ui_ok`, `_ui_warn`, `_ui_err`, `_ui_info`) com total paridade semântica com o `Shell/library/ui.sh`. Isolamento do `eshell-mode` via desativação de `completion-preview-mode` no terminal (mantendo delay de `0.2s` e mínimo de `2` caracteres nos buffers convencionais de código/texto), operando com motor de sugestão histórica mais recente e parada em match exato.
- **Correção Ortográfica Bilíngue Sem Processo Externo:** Eliminação definitiva de chamadas síncronas a `/usr/bin/look` (`text-mode-ispell-word-completion nil`, `ispell-look-p nil`) e suporte simultâneo a dicionários de Inglês e Português (`hunspell` com `en_US,pt_BR` via `ispell-hunspell-add-multi-dic`).
- **Autodocumentação Integral em Elisp (GNU Emacs Self-Documenting Standard):** Honrando o pilar clássico do GNU Emacs como máquina Lisp viva e autodocumentada, 100% das definições (`defun`, `defmacro`, `defvar`, `defcustom`, `defface`) e comandos de sistema operacional (`firefox`, `libreoffice`, `apps`, etc.) possuem docstrings canônicas consultáveis em tempo real via `C-h f` (`describe-function`), `C-h v` (`describe-variable`), `C-h k` (`describe-key`), `M-x apropos`, ElDoc e `which-key`. O padrão estrito exige: primeira linha concisa ($\le 80$ colunas), argumentos formais em `MAIÚSCULAS` (ex: `ARGS`, `DIR`), referências a símbolos entre acento grave e apóstrofo (` `simbolo' `) para gerar links hipertextuais navegáveis no buffer `_Help_`, e zero comentários narrativos inline (`;;`).
- **Ergonomia Híbrida Emacs + Evil (`C-z` & `ESC`) e Ciclo Unificado de Cursor (1200ms):** Inicia sempre em **Emacs state** nativo em todos os modos e alterna instantaneamente para **Evil Normal state** via `C-z` (e retorno do Insert/Visual/Replace ao Normal state via `ESC`). Padroniza o ciclo unificado de 1200ms (`blink-cursor-interval 0.6`, `blink-cursor-delay 0.6`, `blink-cursor-blinks 0`) em perfeita sincronia com GTK3/GTK4 (`1200ms`), XTerm, NeoVim e Vim em GUI (`box`, `bar`, `hbar`) e PTY (`\e[1 q`, `\e[3 q`, `\e[5 q`), ficando estático (`noblink`) apenas em consoles Linux Raw TTY (`\e[?2c` a `\e[?6c`, com auto-cura `\e%G\e[?16;238;0c`).
- **Suíte Soberana de Documentos & Substitutos Nativos de Apps:** Leitor nativo acelerado para PDF/DjVu (`pdf-tools` com binário servidor nativo `epdfinfo` e fallback `doc-view-mode` a 192 DPI contínuo com Poppler/MuPDF/DjVuLibre, abertura em cores naturais nítidas e modo escuro/Midnight opcional via `i` ou `m`), EPUB (`nov-mode`), banco de dados relacional (`sqlite-mode`), arquivos compactados (`arc-mode`, `tar-mode`), inspeção de processos (`proced`), comparação visual (`ediff`), calculadora avançada (`calc`), edição binária (`hexl-mode`) e edição de diretórios (`dired` + `wdired`), plenamente integrados ao despachante `$ o <arquivo>` / `$ open <arquivo>`.

---

## 📖 Suíte Soberana de Leitura de Documentos & Aplicações Nativas

O GNU Emacs substitui aplicações gráficas externas através de sua suíte integrada de leitores de documentos e utilitários de sistema nativos, operando com latência nula e integrados ao comando `$ o <arquivo>` / `$ open <arquivo>` no terminal e no Aweshell:

### 1. Leitores Soberanos de Documentos

A visualização de documentos adota o **`pdf-tools`** com o servidor nativo de alta performance **`epdfinfo`** (compilado sobre Poppler-GLib) como motor primário e o **`doc-view-mode`** contínuo (192 DPI) como motor de retaguarda para arquivos PDF, DjVu (`djvulibre` via `ddjvu`), PostScript e imagens, acompanhado do **`nov-mode`** para livros digitais EPUB:

- **Renderização Cromática Fiel:** Todos os documentos abrem por padrão em suas cores naturais e nítidas originais (fundo claro original), preservando fidelidade tipográfica e vetorial. O modo escuro / Midnight Mode (`#e5e9f0` sobre `#1e1e22`) pode ser ativado e desativado sob demanda teclando `i` ou `m`.
- **Enquadramento Automático na Abertura:** Ajuste inteligente imediato de página à janela (`fit-page`) logo após a carga do documento, sem requerer comandos manuais de escala.
- **Ocultação de Cursor (`cursor-type nil`):** O cursor de texto piscante é suprimido durante a leitura tanto no Emacs nativo quanto nos estados Evil (Normal e Motion), eliminando poluição visual sobre as páginas renderizadas.
- **Atalhos Unificados Padrão da Comunidade:**

| Atalho                                         | Ação Operacional                                                       |
| :--------------------------------------------- | :--------------------------------------------------------------------- |
| `j` / `k` ou `<down>` / `<up>`                 | Rolar linhas para baixo / para cima (scroll contínuo suave)            |
| `n` / `p` ou `SPC` / `S-SPC` (`J`/`K`, `PgDn`) | Avançar para a próxima página / retroceder para a anterior             |
| `+` / `=` / `-` / `0`                          | Aumentar zoom, diminuir zoom e restaurar escala original (`100%`)      |
| `w` / `W`                                      | Ajustar largura da página à largura da janela (`fit-width`)            |
| `h` / `H`                                      | Ajustar altura da página à altura da janela (`fit-height`)             |
| `f` / `P`                                      | Enquadrar página completa na janela (`fit-page`)                       |
| `r` / `R`                                      | Girar página em 90 graus no sentido horário (`rotate`)                 |
| `o` / `t`                                      | Exibir sumário / índice estruturado do documento (TOC / Outline)       |
| `g` / `G`                                      | Ir para página específica (`goto-page`) / saltar para a última página  |
| `i` / `m`                                      | Alternar modo escuro sob demanda (`pdf-view-midnight` / invert-colors) |
| `q`                                            | Ocultar / fechar o visualizador de leitura (`quit-window`)             |

| Formato  | Modo Emacs                    | Recursos & Motor de Renderização                                                                                                        |
| :------- | :---------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **PDF**  | `pdf-tools` (`pdf-view-mode`) | Servidor nativo C `epdfinfo` (Poppler GLib), renderização vetorial sub-pixel, seleção precisa de texto e anotações                      |
| **PDF**  | `doc-view-mode` (Fallback)    | Resolução de 192 DPI contínua (`doc-view-continuous t`), aceleração com `pdftoppm` (Poppler) ou `mutool` (MuPDF) e escala interna       |
| **DjVu** | `doc-view-mode` / `djvu`      | Renderização nativa a 192 DPI via motor `ddjvu` (`graphics/djvulibre`), navegação rápida e zoom contínuo                                |
| **EPUB** | `nov-mode`                    | Leitor de e-books com reflow tipográfico dinâmico, largura calibrada (`nov-text-width t`), `visual-line-mode` e renderização de imagens |

### 2. Suíte de Substitutos Nativos de Aplicações

| Utilitário                | Modo Emacs              | Comando / Alias                        | Função Operacional                                                                        |
| :------------------------ | :---------------------- | :------------------------------------- | :---------------------------------------------------------------------------------------- |
| **Bancos SQLite**         | `sqlite-mode`           | `$ o db.sqlite3` ou `$ sql db.sqlite3` | Navegador interativo de esquemas, tabelas e dados SQLite sem necessidade de apps externos |
| **Compactados**           | `arc-mode` / `tar-mode` | `$ o arquivo.zip`                      | Visualização, navegação, edição e extração direta de arquivos ZIP, TAR, GZ, XZ e 7Z       |
| **Imagens**               | `image-mode`            | `$ o foto.png`                         | Visualizador rápido de imagens rasterizadas (PNG, JPEG, WebP) e vetoriais (SVG)           |
| **Processos**             | `proced`                | `$ procs` ou `$ htop`                  | Monitor de processos interativo com envio de sinais (`k` kill, `r` renice)                |
| **Diff & Merge**          | `ediff`                 | `$ ediff file-a file-b`                | Comparador visual granular lado a lado com aplicação refinada de hunks e merge            |
| **Calculadora**           | `calc`                  | `$ calc [expressão]`                   | Calculadora avançada RPN simbólica, algébrica e financeira nativa do Emacs                |
| **Hex Editor**            | `hexl-mode`             | `$ hex arquivo.bin`                    | Editor e inspetor hexadecimal de baixo nível com edição em hexadecimal ou ASCII           |
| **Gerenciador de Pastas** | `dired` + `wdired`      | `$ d` ou `C-x d`                       | Gerenciador dual-pane com modo de edição em lote de nomes de arquivos (`C-x C-q` / `r`)   |

### 3. Ciclo Unificado de Piscar de Cursor (1200ms)

O Emacs alinha perfeitamente seu ciclo de cursor ao padrão do ecossistema:

- **Intervalo:** `blink-cursor-interval 0.6` (600ms aceso, 600ms apagado = ciclo completo de 1200ms).
- **Atraso de Inicialização:** `blink-cursor-delay 0.6` (início após 600ms de inatividade).
- **Persistência Infinita:** `blink-cursor-blinks 0` (o cursor nunca para de piscar por inatividade).
- **Paridade com a Suíte:** Sincronizado com GTK3/GTK4 (`gtk-cursor-blink-time=1200`), XTerm (`*cursorBlink: always`), NeoVim e Vim (`blinkwait600-blinkoff600-blinkon600`).

---

## 📁 Catálogo da Estrutura

| Arquivo / Diretório                      | Descrição                                                                   |
| :--------------------------------------- | :-------------------------------------------------------------------------- |
| [`TODO.md`](TODO.md)                     | Roadmap estratégico, matriz de status e backlog de evolução                 |
| [`CONTRIBUTING.md`](CONTRIBUTING.md)     | Guia de contribuição, configuração de ganchos Git e quality gates           |
| [`emacs.sh`](emacs.sh)                   | Interface unificada de componente (CLI para test, doctor, indent)           |
| [`init.el`](init.el)                     | Ponto de entrada, feature toggles e carregamento central                    |
| [`early-init.el`](early-init.el)         | Otimizações de boot e caminhos do native-comp cache                         |
| [`lib/core.el`](lib/core.el)             | Macros de detecção de SO e rotinas de auto-indentação                       |
| [`etc/init/`](etc/init/)                 | Bootstrap do Elpaca, atalhos globais e interface visual                     |
| [`etc/editor/`](etc/editor/)             | Módulos de LSP, scroll suave, tree-sitter e conclusão                       |
| [`etc/apps/`](etc/apps/)                 | Extensões opcionais: Org-mode, IA (gptel/ellama), EAF                       |
| [`etc/lang/`](etc/lang/)                 | Configurações específicas para LaTeX, Lisp, Markdown                        |
| [`etc/tools/`](etc/tools/)               | Ferramentas de Git, GitHub, manpages e shell interativo                     |
| [`usr/local/`](usr/local/)               | Modos Elisp pessoais integrados (`aweshell`, `aweww`, `emacs-lisp-ts-mode`) |
| [`bin/indent-all.sh`](bin/indent-all.sh) | Script POSIX de auto-indentação de arquivos de configuração                 |

---

## 🚀 Instalação e Uso Rápido

### Opção A — Modo Versionado (Recomendado para Manutenção)

Clona o repositório diretamente no destino canônico com controle de versão Git ativo, permitindo atualizações automáticas contínuas via `uped` ou `git pull`.

#### 🐧 Unix (Linux, FreeBSD, macOS)

```sh
git clone "https://github.com/GabrielFrigo4/emacs.git" "${HOME}/.emacs.d"
```

#### 🪟 Windows (PowerShell Nativo)

```powershell
git clone "https://github.com/GabrielFrigo4/emacs.git" "$HOME\.emacs.d"
```

#### 🪟 Windows (MSYS2 / Git Bash)

```sh
git clone "https://github.com/GabrielFrigo4/emacs.git" "${HOME}/.emacs.d"
```

---

### Opção B — Modo Standalone Limpo (Zero-Bloat / Produção)

> [!TIP]
> **Filosofia Zero-Bloat:** Ideal para servidores, contêineres ou computadores de terceiros onde o controle de versão Git e artefatos de desenvolvimento não são necessários. Clona a árvore rasa (`--depth=1`) e remove metadados (`.git*`, `.agents`, `*.md`), deixando apenas a configuração estritamente executável.

#### 🐧 Unix (Linux, FreeBSD, macOS & MSYS2)

```sh
git clone --depth=1 "https://github.com/GabrielFrigo4/emacs.git" "${HOME}/.emacs.d" && \
  rm -rf "${HOME}/.emacs.d/.git"* "${HOME}/.emacs.d/.agents" "${HOME}/.emacs.d/"*.md
```

#### 🪟 Windows (PowerShell)

```powershell
git clone --depth=1 "https://github.com/GabrielFrigo4/emacs.git" "$HOME\.emacs.d"
Remove-Item -Recurse -Force "$HOME\.emacs.d\.git*", "$HOME\.emacs.d\.agents", "$HOME\.emacs.d\*.md" -ErrorAction SilentlyContinue
```

---

### 🔤 Pré-requisito Visual: Tipografia & Nerd Fonts

> [!IMPORTANT]
> Esta configuração exige uma **Nerd Font** para renderizar corretamente as ligaduras, os ícones do `dashboard`, `doom-modeline`, árvores de diretórios e glifos do `nerd-icons` (em terminais Linux Raw TTY de 16 cores, o sistema faz _fallback_ automático para modo texto puro).
> O motor tipográfico (`etc/init/typography.el`) foi homologado e calibrado especificamente com a **`JetBrainsMono Nerd Font`** (`JetBrainsMono NF`) como fonte primária e **`Symbols Nerd Font Mono`** (`NFM.ttf`) como fallback dedicado de ícones.

Para ter a experiência visual completa, instale as fontes antes do primeiro uso:

#### 🐧 Unix (Linux, FreeBSD, macOS) — Instalação Rápida Standalone

Para baixar a **JetBrainsMono Nerd Font** (fonte primária homologada com ligaduras) e a **Symbols Nerd Font Mono** (fallback universal de ícones para o `nerd-icons`), execute os comandos abaixo:

```sh
FONTS_DIR="${HOME}/.local/share/fonts"
mkdir -p "${FONTS_DIR}" && _TMP_DIR="$(mktemp -d)"

curl -fsSL -o "${_TMP_DIR}/JetBrainsMono.zip" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -qo "${_TMP_DIR}/JetBrainsMono.zip" -d "${FONTS_DIR}"

curl -fsSL -o "${_TMP_DIR}/NerdFontsSymbolsOnly.zip" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip"
unzip -qo "${_TMP_DIR}/NerdFontsSymbolsOnly.zip" -d "${FONTS_DIR}"

rm -rf "${_TMP_DIR}" "${FONTS_DIR}/OFL.txt" "${FONTS_DIR}/LICENSE"* "${FONTS_DIR}/README.md"
command -v fc-cache > "/dev/null" 2>&1 && fc-cache -f "${FONTS_DIR}"
```

#### 🪟 Windows (PowerShell / Winget)

Para instalar de forma rápida no Windows utilizando o gerenciador de pacotes nativo:

```powershell
winget install -e --id DEVCOM.JetBrainsMonoNerdFont
```

> 💡 **Dica Interna do Emacs:** Caso já tenha a `JetBrainsMono Nerd Font` instalada e queira baixar apenas a fonte complementar de ícones (`Symbols Nerd Font Mono` / `NFM.ttf`) diretamente de dentro do Emacs, basta executar:
>
> ```elisp
> M-x nerd-icons-install-fonts
> ```

---

### ⚙️ Integração com o Universal Environment

Quando operado a partir do [Universal Environment](https://github.com/GabrielFrigo4/environment):

- **Atualizar a suíte de editores com o upstream:**

```sh
make uped
```

- **Implantar o repositório no destino canônico (`~/.emacs.d`):**

```sh
make deploy
```

---

### 🧠 Autodetecção Oportunística & Controle de Recursos

A configuração opera de forma **100% autônoma e reentrante**:

- **EAF (Emacs Application Framework):** Auto-ativado se o Emacs rodar em modo gráfico (`display-graphic-p`), a pasta existir em `opt/` e o `python3` estiver no PATH.
- **Módulos de IA (gptel, ellama, org-ai) e Minuet:** Auto-ativados se houver credenciais disponíveis em variáveis de ambiente (`GEMINI_API_KEY`, etc.), no Vault local (`~/.vault` / `/usr/local/share/vault`) ou em arquivos `.authinfo.gpg`.
- **Tree-sitter & LaTeX:** Auto-ativados se o suporte estiver compilado no Emacs (`treesit-available-p`) ou os compiladores (`latex`/`pdflatex`) estiverem no PATH.
- Em ambientes sem esses recursos, a inicialização ocorre de forma pura e instantânea (&lt; 50ms), sem alertas ou falhas.

Caso deseje forçar ou desativar recursos explicitamente, utilize as variáveis de ambiente:

```sh
EMACS_AI=1 emacs
EMACS_EAF=0 emacs
EMACS_LSP=0 emacs
```

---

### 💻 Executar com Recursos Customizados

- **Boot padrão (mínimo e ultra-rápido):**

```sh
emacs
```

- **Habilitar IA sob demanda:**

```sh
EMACS_AI=1 emacs
```

- **Modo diagnóstico e teste de sintaxe via script CLI:**

```sh
./emacs.sh test
```

- **Compilar todas as gramáticas Tree-sitter essenciais (ou via `./emacs.sh treesit`):**

```sh
make treesit
```

- **Atualizar os submódulos de modos Elisp federados (`usr/local/*`):**

```sh
make upmodes
```

- **Lançar diretamente uma nova janela com Eshell/aweshell (se no ambiente desktop):**

```sh
esh
```

---

## 🚀 Setup do Projeto & Ganchos Git

Para configurar o ambiente de desenvolvimento local, ativar os quality gates automáticos e validar a integridade da suíte:

- **`make hooks`**: Configura `.githooks` e permissões canônicas.
- **`make test`**: Valida inicialização limpa em modo batch (`make batch`).
- **`make treesit`**: Compila gramáticas Tree-sitter essenciais.
- **`make ci`**: Bateria completa de validação local.

```sh
make hooks
make test
make treesit
make ci
```

> 🤝 **Instruções Detalhadas:** Consulte o [CONTRIBUTING.md](CONTRIBUTING.md) para convenções de commits, arquitetura modular Elisp, diretrizes de lazy-loading e quality gates.
