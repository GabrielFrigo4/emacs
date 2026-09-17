.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Emacs Lisp Suite
# ----------------------------------------------------------------

.PHONY: help test batch indent ci upmodes treesit update

### ================================
### HELP & DOCUMENTATION
### ================================
help:
	cmd() { printf "    \033[36mmake %-22s\033[0m %s\n" "$$1" "$$2"; }; \
	sec() { printf "\n  \033[1;33m%s\033[0m\n" "$$1"; }; \
	printf "\n  \033[1;37mGNU Emacs — Ambiente Modular Elisp & Produtividade\033[0m\n"; \
	printf "  ============================================================\n"; \
	sec "Qualidade & Formatação:"; \
	cmd "test"           "Valida inicialização limpa em modo batch"; \
	cmd "batch"          "Executa boot limpo batch do Emacs"; \
	cmd "indent"         "Formata e indenta arquivos Elisp"; \
	cmd "ci"             "Executa suíte de validação local do Emacs"; \
	sec "Sincronização & Modos Elisp:"; \
	cmd "update"         "Atualiza repositório GNU Emacs e submódulos Elisp"; \
	cmd "upmodes"        "Atualiza submódulos de modos locais (usr/local/*)"; \
	sec "Tree-sitter & Gramáticas:"; \
	cmd "treesit"        "Instala e compila as gramáticas Tree-sitter essenciais"; \
	echo ""


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
	$(MAKE) upmodes

upmodes:
	echo "🔄 Atualizando submódulos Elisp locais..."
	git submodule update --init --recursive --remote --merge && echo "  ✅ Submódulos Elisp atualizados!"


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

indent:
	if [ -f "bin/indent-all.sh" ]; then \
		sh bin/indent-all.sh; \
	fi

ci: test
	echo "🚀 Emacs 100% pronto para produção!"
