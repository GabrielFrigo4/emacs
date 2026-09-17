# 🔮 GNU Emacs Configuration

> Configuração modular, declarativa e resiliente do GNU Emacs para desenvolvimento, edição modal, LSP e Org-mode.

[![Environment](https://img.shields.io/badge/🏛️_Environment-Hub-blue)](https://github.com/GabrielFrigo4/environment)
[![GNU Emacs](https://img.shields.io/badge/GNU_Emacs-29%2B-purple?logo=gnuemacs&logoColor=white)](https://www.gnu.org/software/emacs/)
[![POSIX](https://img.shields.io/badge/POSIX-Shell_Scripts-orange?logo=gnubash&logoColor=white)](bin/indent-all.sh)
[![License](https://img.shields.io/badge/License-MIT-green?logo=open-source-initiative&logoColor=white)](LICENSE)

---

## 🧭 Visão Geral

Este repositório contém a configuração pessoal do **GNU Emacs** de Gabriel Frigo, integrando a **Suíte de Editores** do [Universal Environment](https://github.com/GabrielFrigo4/environment). A arquitetura prioriza:

- **Startup Instantâneo & Resiliente:** Feature toggles defensivos e isolamento de módulos com `condition-case`.
- **Controle Dinâmico:** Flags customizáveis via variáveis de ambiente (`EMACS_AI`, `EMACS_LSP`, `EMACS_TREESIT`).
- **LSP Integrado:** Eglot nativo de alta performance para linguagens compiladas e interpretadas.
- **Gerenciador Elpaca:** Gestão assíncrona e declarativa de pacotes.

---

## 📁 Catálogo da Estrutura

| Diretório / Arquivo                      | Descrição                                                   |
| :--------------------------------------- | :---------------------------------------------------------- |
| [`init.el`](init.el)                     | Ponto de entrada, feature toggles e carregamento central    |
| [`early-init.el`](early-init.el)         | Otimizações de boot e caminhos do native-comp cache         |
| [`lib/core.el`](lib/core.el)             | Macros de detecção de SO e rotinas de auto-indentação       |
| [`etc/init/`](etc/init/)                 | Bootstrap do Elpaca, atalhos globais e interface visual     |
| [`etc/editor/`](etc/editor/)             | Módulos de LSP, scroll suave, tree-sitter e conclusão       |
| [`etc/apps/`](etc/apps/)                 | Extensões opcionais: Org-mode, IA (gptel/ellama), EAF       |
| [`etc/lang/`](etc/lang/)                 | Configurações específicas para LaTeX, Lisp, Markdown        |
| [`etc/tools/`](etc/tools/)               | Ferramentas de Git, GitHub, manpages e shell interativo     |
| [`bin/indent-all.sh`](bin/indent-all.sh) | Script POSIX de auto-indentação de arquivos de configuração |

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

### ⚙️ Integração com o Universal Environment

Quando operado a partir do [Universal Environment](https://github.com/GabrielFrigo4/environment):

```sh
# Atualizar a suíte de editores com o upstream
make uped

# Implantar o repositório no destino canônico (~/.emacs.d)
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

```sh
# Boot padrão (mínimo e ultra-rápido)
emacs

# Habilitar IA sob demanda
EMACS_AI=1 emacs

# Modo diagnóstico e teste de sintaxe
emacs -Q --batch -l early-init.el -l init.el --eval '(message "Boot OK")'
```
