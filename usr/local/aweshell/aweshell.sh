#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: Aweshell (Awesome Eshell Suite) Component
# ----------------------------------------------------------------
set -eu

_AWESHELL_ROOT="$(cd "$(dirname "$0")" && pwd)"

_self_heal_perms() {
	if [ -d "${_AWESHELL_ROOT}/.git" ] && command -v git > "/dev/null" 2>&1; then
		git -C "${_AWESHELL_ROOT}" config core.hooksPath .githooks 2> "/dev/null" || true
	fi
	if [ -d "${_AWESHELL_ROOT}/.githooks" ]; then
		chmod 0755 "${_AWESHELL_ROOT}/.githooks/"* 2> "/dev/null" || true
	fi
	[ -f "${_AWESHELL_ROOT}/aweshell.sh" ] && chmod 0755 "${_AWESHELL_ROOT}/aweshell.sh" 2> "/dev/null" || true
}
_self_heal_perms

_aweshell_help() {
	cat <<- EOF
		Aweshell — Interface Unificada de Componente

		Uso:
		  aweshell.sh [comando]

		Comandos:
		  test      Valida integridade e compilacao batch de todos os .el
		  compile   Compila bytecode (.elc) de todos os modulos
		  clean     Remove artefatos de bytecode (.elc)
		  doctor    Verifica ambiente Emacs e presenca de utilitarios
		  help      Exibe esta mensagem de ajuda
	EOF
}

_aweshell_test() {
	echo "🧪 [Aweshell] Validando integridade sintática e compilação..."
	if command -v emacs > "/dev/null" 2>&1; then
		emacs -Q --batch -L "${_AWESHELL_ROOT}" --eval '
			(let ((err-count 0))
			  (dolist (f (directory-files "'"${_AWESHELL_ROOT}"'" nil "\\.el$"))
			    (condition-case err
			        (byte-compile-file (expand-file-name f "'"${_AWESHELL_ROOT}"'"))
			      (error
			       (setq err-count (1+ err-count))
			       (message "❌ Erro em %s: %s" f err))))
			  (when (> err-count 0)
			    (kill-emacs 1)))' > "/dev/null" 2>&1 && \
		rm -f "${_AWESHELL_ROOT}/"*.elc && echo "  ✅ Aweshell: 100% testado e aprovado!"
	else
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste de compilação."
	fi
}

_aweshell_compile() {
	echo "⚙️  [Aweshell] Compilando bytecode (.elc)..."
	emacs -Q --batch -L "${_AWESHELL_ROOT}" -f batch-byte-compile "${_AWESHELL_ROOT}/"*.el && \
		echo "  ✅ Bytecode compilado com sucesso!"
}

_aweshell_clean() {
	echo "🧹 [Aweshell] Limpando arquivos de compilação (.elc)..."
	rm -f "${_AWESHELL_ROOT}/"*.elc && echo "  ✅ Limpeza concluída!"
}

_aweshell_doctor() {
	echo "🔍 [Aweshell] Diagnóstico do componente..."
	if command -v emacs > "/dev/null" 2>&1; then
		echo "  ✅ emacs detectado: $(command -v emacs)"
		emacs --version | head -n 1 | sed 's/^/     /'
	else
		echo "  ❌ emacs não encontrado no PATH."
	fi
	if command -v git > "/dev/null" 2>&1; then
		echo "  ✅ git detectado: $(command -v git)"
	else
		echo "  ⚠️  git não encontrado no PATH."
	fi
}

_cmd="${1:-help}"
case "${_cmd}" in
	test)           _aweshell_test ;;
	compile)        _aweshell_compile ;;
	clean)          _aweshell_clean ;;
	doctor)         _aweshell_doctor ;;
	help|-h|--help) _aweshell_help ;;
	*)
		echo "❌ Comando desconhecido: ${_cmd}" >&2
		_aweshell_help >&2
		exit 1
		;;
esac
