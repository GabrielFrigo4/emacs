#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: GNU Emacs Component
# ----------------------------------------------------------------
set -eu

_EMACS_ROOT="$(cd "$(dirname "$0")" && pwd)"

_emacs_help() {
	cat <<- EOF
		GNU Emacs — Interface Unificada de Componente

		Uso:
		  emacs.sh [comando]

		Comandos:
		  test      Valida inicializacao batch limpa do Emacs
		  doctor    Verifica presenca do binario emacs e ambiente
		  indent    Formata e indenta arquivos Elisp
		  upmodes   Atualiza submodulos Elisp em usr/local/
		  help      Exibe esta mensagem de ajuda
	EOF
}

_emacs_upmodes() {
	echo "🔄 [Emacs] Atualizando submódulos Elisp locais..."
	git -C "${_EMACS_ROOT}" submodule update --init --recursive --remote --merge
	echo "  ✅ Submódulos Elisp atualizados com sucesso!"
}

_emacs_test() {
	echo "🧪 [Emacs] Validando inicialização batch..."
	if command -v emacs > "/dev/null" 2>&1; then
		emacs -Q --batch -l "${_EMACS_ROOT}/early-init.el" -l "${_EMACS_ROOT}/init.el" --eval '(message "Emacs batch OK")' > "/dev/null" 2>&1 && echo "  ✅ Emacs: batch OK"
	else
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste batch."
	fi
}

_emacs_doctor() {
	echo "🔍 [Emacs] Diagnóstico do componente..."
	if command -v emacs > "/dev/null" 2>&1; then
		echo "  ✅ emacs detectado: $(command -v emacs)"
		emacs --version | head -n 1 | sed 's/^/     /'
	else
		echo "  ❌ emacs não encontrado no PATH."
	fi
}

_emacs_indent() {
	if [ -f "${_EMACS_ROOT}/bin/indent-all.sh" ]; then
		sh "${_EMACS_ROOT}/bin/indent-all.sh"
	else
		echo "ℹ️  Script indent-all.sh não encontrado."
	fi
}

_cmd="${1:-help}"
case "${_cmd}" in
	test|batch) _emacs_test ;;
	doctor)     _emacs_doctor ;;
	indent)     _emacs_indent ;;
	upmodes)    _emacs_upmodes ;;
	help|-h|--help) _emacs_help ;;
	*)
		echo "❌ Comando desconhecido: ${_cmd}" >&2
		_emacs_help >&2
		exit 1
		;;
esac
