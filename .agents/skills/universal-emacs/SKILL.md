---
name: universal-emacs
description: Runbook operacional para desenvolvimento, auditoria, compilação de gramáticas Tree-sitter e testes de integridade da configuração GNU Emacs 30+. Use ao adicionar pacotes via Elpaca, atualizar modos federados em usr/local/*, configurar Eglot LSP ou validar inicialização hermética em modo batch.
---

# 🔮 Universal Emacs — Runbook Operacional

Este runbook orienta desenvolvedores e agentes de inteligência artificial no gerenciamento, teste, compilação e diagnóstico da configuração do **GNU Emacs (30+, preparado para 31+)**.

---

## 🏛️ Diretrizes & Baseline Arquitetural

1. **Baseline Estrito: GNU Emacs 30+:** A configuração aproveita recursos nativos do Emacs 30+ (Tree-sitter nativo ABI ≥ 14, compilação nativa com `libgccjit`, Eglot embutido). Falha rápido caso executado em versões inferiores.
2. **Arquitetura FHS Soberana:**
    - `early-init.el`: Otimização do Garbage Collector, supressão de `package.el` e redirecionamento de compilação nativa para `var/cache/eln-cache/`.
    - `init.el`: Carregador modular por feature toggles.
    - `etc/`: Configurações divididas em `init/`, `editor/`, `lang/`, `tools/`, `apps/`.
    - `usr/local/`: Submódulos Git de modos Elisp pessoais (`aweshell`, `aweww`, `emacs-lisp-ts-mode`).
    - `var/`: Estado mutável de runtime (`cache/`, `run/`, `backup/`) — 100% ignorado no Git.
3. **Zero Symlinks Manuais:** O repositório é clonado como árvore canônica diretamente em `${HOME}/.emacs.d`.
4. **Lexical Binding Obrigatório (Linha 1):** Todo e qualquer arquivo `.el` deve conter impreterivelmente `;;; -*- lexical-binding: t -*-` como primeira linha absoluta (Linha 1), antes de qualquer régua ou cabeçalho. Isso elimina warnings de compilação no Emacs 30/31+, previne bugs de escopo dinâmico e potencializa a compilação nativa (`.eln`).

---

## 🧪 1. Validação Sintática & Testes em Modo Batch

Sempre valide a ausência de erros de sintaxe e quebra de carregamento antes de commitar alterações:

```sh
# Via Makefile canônico
make test

# Ou diretamente via script unificado de componente
./emacs.sh test

# Ou via comando puro em modo batch hermético (-Q)
emacs -Q --batch -l early-init.el -l init.el --eval '(message "Emacs init OK")'
```

> [!IMPORTANT]
> O teste deve retornar código de saída `0` sem exceções não tratadas (`void-function`, `void-variable` ou erros de sintaxe).

---

## 🌳 2. Gestão de Gramáticas Tree-sitter Nativas (ABI ≥ 14)

O Emacs 30+ utiliza gramáticas compiladas em C (`libtree-sitter-<lang>.so`). As bibliotecas são mantidas no diretório isolado `tree-sitter/` na raiz da configuração.

Para compilar ou atualizar as gramáticas essenciais (`elisp`, `c`, `cpp`, `python`, `bash`, `rust`, `go`, `json`, `toml`, `yaml`):

```sh
make treesit
# ou: ./emacs.sh treesit
```

Para verificar programaticamente a disponibilidade de uma gramática:

```sh
emacs -Q --batch -l early-init.el -l init.el --eval '
  (message "Elisp Tree-sitter: %s" (treesit-language-available-p (quote elisp)))'
```

---

## 📦 3. Submódulos de Modos Elisp Federados (`usr/local/*`)

Os modos pessoais (`aweshell`, `aweww`, `emacs-lisp-ts-mode`) residem como submódulos Git versionados em `usr/local/`:

```sh
# Atualizar todos os submódulos para a última versão remota sincronizada
make upmodes

# Ou via Git direto
git submodule update --init --recursive --remote --merge
```

---

## 🎨 4. Auto-Indentação e Padronização Elisp

Para garantir a formatação consistente de todos os arquivos `.el` rastreados pelo repositório:

```sh
make indent
# ou: sh bin/indent-all.sh
```

---

## 🎛️ 5. Controle de Recursos por Variáveis de Ambiente

Teste recursos de forma granular sem alterar arquivos de configuração:

```sh
EMACS_AI=1 emacs          # Ativa módulos de IA (gptel, ellama, minuet)
EMACS_LSP=0 emacs         # Desativa Eglot LSP (modo leve de edição pura)
EMACS_TREESIT=0 emacs     # Desativa árvores sintáticas Tree-sitter
EMACS_EAF=0 emacs         # Desativa Emacs Application Framework
```

---

## 🐚 6. Launcher Desktop Eshell (`esh`)

Em sessões gráficas (X11 / Wayland), o comando `esh` (ou `open-eshell`) lança instantaneamente um novo frame do Emacs dedicado ao Eshell com suporte a abas e completions do `aweshell`:

```sh
esh
```

Dentro de qualquer sessão do Emacs, executar `M-x esh` ou `M-x eshell` invoca o `aweshell/new` automaticamente.

---

## 🔗 Links Oficiais de Referência

- [GNU Emacs 30 Manual](https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html)
- [GNU Emacs Lisp Reference Manual](https://www.gnu.org/software/emacs/manual/html_node/elisp/index.html)
- [Elpaca Package Manager](https://github.com/progfolio/elpaca)
- [Aweshell Repository](https://github.com/GabrielFrigo4/aweshell)
- [Aweww Repository](https://github.com/GabrielFrigo4/aweww)
- [Emacs Lisp Tree-sitter Mode](https://github.com/GabrielFrigo4/emacs-lisp-ts-mode)
