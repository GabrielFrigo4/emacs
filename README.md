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
- **Ergonomia Híbrida Emacs + Evil (`C-z` & `ESC`) e Cursores Dinâmicos (`blink` em GUI/PTY e `noblink` em TTY):** Inicia sempre em **Emacs state** nativo em todos os modos e alterna instantaneamente para **Evil Normal state** via `C-z` (e retorno do Insert/Visual/Replace ao Normal state via `ESC`). Sincroniza os formatos de cursor dinâmicos e piscantes (`blink`) idênticos ao Vim/NeoVim/Helix em GUI (`box`, `bar`, `hbar`) e PTY (`\e[1 q`, `\e[3 q`, `\e[5 q`), ficando estático (`noblink`) apenas em consoles Linux Raw TTY (`\e[?2c` a `\e[?6c`, com auto-cura `\e%G\e[?16;238;0c`).

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
