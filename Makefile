.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Emacs Lisp Suite
# ----------------------------------------------------------------

.PHONY: help hooks test batch indent format prettier ci upmodes treesit update clean audit

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
	cmd "audit"          "Audita conformidade estrutural e ausência de var/tmp"; \
	cmd "clean"          "Remove resíduos de execução e higieniza bancada"; \
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
	echo "🧪 Validando sintaxe e balanceamento de parênteses (.el)..."
	if command -v emacs > "/dev/null" 2>&1; then \
		emacs -Q --batch --eval '(let ((failed nil)) (dolist (f (directory-files-recursively "." "\\.el$$")) (condition-case err (with-temp-buffer (insert-file-contents f) (emacs-lisp-mode) (check-parens)) (error (message "Erro em %s: %s" f (error-message-string err)) (setq failed t)))) (when failed (kill-emacs 1)))' || exit 1; \
		echo "  ✅ Sintaxe Elisp íntegra em todos os arquivos."; \
		echo "🧪 Validando inicialização batch do Emacs..."; \
		emacs -Q --batch -l early-init.el -l init.el --eval '(when emacs/init-has-errors (kill-emacs 1))' > "/dev/null" 2>&1 || { echo "❌ Falha na inicialização batch do Emacs."; exit 1; }; \
		echo "  ✅ Emacs: batch OK"; \
	else \
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste batch."; \
	fi

clean:
	echo "🧹 Limpando artefatos temporários e de compilação..."
	rm -rf var tmp eln-cache tree-sitter elpa auto-save-list tramp 2> "/dev/null" || true
	find . -type f \( -name "*.elc" -o -name "*.eln" -o -name "*~" -o -name "#*#" -o -name "*.tmp" -o -name "*.log" \) -delete 2> "/dev/null" || true
	echo "  ✅ Ambiente limpo e higienizado!"

audit:
	echo "🔍 Auditando conformidade estrutural do Emacs..."
	if [ -d "var" ] || [ -d "tmp" ]; then \
		echo "❌ Erro: Diretórios var/ ou tmp/ encontrados na bancada!"; \
		exit 1; \
	fi
	echo "  ✅ Emacs: Auditoria aprovada sem inconformidades."

format: indent prettier
	echo "✅ Formatação concluída!"

prettier:
	echo "🎨 Formatando documentações e configurações com Prettier..."
	if command -v prettier > "/dev/null" 2>&1; then \
		prettier --write "**/*.{md,json,jsonc,yml,yaml,html,css}" 2> "/dev/null" || true; \
	elif command -v npx > "/dev/null" 2>&1; then \
		npx --yes prettier --write "**/*.{md,json,jsonc,yml,yaml,html,css}" 2> "/dev/null" || true; \
	fi

indent:
	if [ -f "bin/indent-all.sh" ]; then \
		sh bin/indent-all.sh; \
	fi

ci: test
	echo "🚀 Emacs 100% pronto para produção!"
