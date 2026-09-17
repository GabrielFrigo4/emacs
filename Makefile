.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Emacs Lisp Suite
# ----------------------------------------------------------------

.PHONY: help test batch indent ci

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
	echo ""


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
