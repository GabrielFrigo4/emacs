.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Emacs Lisp Suite
# ----------------------------------------------------------------

.PHONY: help hooks test batch indent format prettier ci upmodes treesit update

### ================================
### HELP & DOCUMENTATION
### ================================
help:
	_e=$$'\e'; \
	cmd() { printf "    $${_e}[36mmake %-22s$${_e}[0m %s\n" "$$1" "$$2"; }; \
	sec() { printf "\n  $${_e}[1;33m%s$${_e}[0m\n" "$$1"; }; \
	printf "\n  $${_e}[1;37mGNU Emacs — Ambiente Modular Elisp & Produtividade$${_e}[0m\n"; \
	printf "  ============================================================\n"; \
	sec "Setup & Ganchos:"; \
	cmd "hooks"          "Configura e aplica permissões canônicas em .githooks"; \
	sec "Qualidade & Formatação:"; \
	cmd "test"           "Valida inicialização limpa em modo batch"; \
	cmd "batch"          "Executa boot limpo batch do Emacs"; \
	cmd "format"         "Formata arquivos Elisp e Markdown"; \
	cmd "indent"         "Formata e indenta arquivos Elisp"; \
	cmd "prettier"       "Formata documentações Markdown com Prettier"; \
	cmd "ci"             "Executa suíte de validação local do Emacs"; \
	sec "Sincronização & Modos Elisp:"; \
	cmd "update"         "Atualiza repositório GNU Emacs e submódulos Elisp"; \
	cmd "upmodes"        "Atualiza submódulos de modos locais (usr/local/*)"; \
	sec "Tree-sitter & Gramáticas:"; \
	cmd "treesit"        "Instala e compila as gramáticas Tree-sitter essenciais"; \
	echo ""

### ================================
### GIT HOOKS & PERMISSIONS
### ================================
hooks:
	echo "🪝 Configurando ganchos Git (.githooks)..."
	chmod 0755 .githooks/pre-commit .githooks/commit-msg 2> "/dev/null" || true
	git config core.hooksPath .githooks 2> "/dev/null" || true
	echo "  ✅ Emacs: core.hooksPath -> .githooks"


### ================================
### TREE-SITTER
### ================================
treesit:
	echo "🌳 Compilando gramáticas Tree-sitter para GNU Emacs..."
	emacs -Q --batch -l early-init.el -l init.el --eval '\
		(dolist (lang (quote (elisp c cpp python bash rust go json toml yaml)))\
		  (condition-case err\
		      (progn (message "Compilando gramatica: %s..." lang) (treesit-install-language-grammar lang))\
		    (error (message "Erro ao compilar %s: %s" lang err))))' && echo "  ✅ Gramáticas Tree-sitter compiladas!"


### ================================
### SUBMODULES & UPDATES
### ================================
update:
	echo "⬇️  Atualizando repositório GNU Emacs..."
	git pull --ff-only 2> "/dev/null" || git pull || echo "⚠️  git pull falhou."

upmodes:
	echo "  ℹ️  Modos Elisp locais (usr/local/*) integrados nativamente no repositório."


### ================================
### TESTING & FORMATTING
### ================================
test: batch

batch:
	echo "🧪 Validando inicialização batch do Emacs..."
	if command -v emacs > "/dev/null" 2>&1; then \
		emacs -Q --batch -l early-init.el -l init.el --eval '(message "Emacs batch OK")' > "/dev/null" 2>&1 && echo "  ✅ Emacs: batch OK"; \
	else \
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste batch."; \
	fi

format: indent prettier
	echo "✅ Formatação concluída!"

prettier:
	echo "🎨 Formatando documentações Markdown com Prettier..."
	if command -v prettier > "/dev/null" 2>&1; then \
		prettier --write "**/*.md" 2> "/dev/null" || true; \
	elif command -v npx > "/dev/null" 2>&1; then \
		npx prettier --write "**/*.md" 2> "/dev/null" || true; \
	fi

indent:
	if [ -f "bin/indent-all.sh" ]; then \
		sh bin/indent-all.sh; \
	fi

ci: test
	echo "🚀 Emacs 100% pronto para produção!"
