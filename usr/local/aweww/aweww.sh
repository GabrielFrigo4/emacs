#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: Aweww (Awesome EWW) Component
# ----------------------------------------------------------------
set -eu

_AWEWW_ROOT="$(cd "$(dirname "$0")" && pwd)"

_self_heal_perms() {
	if [ -d "${_AWEWW_ROOT}/.git" ] && command -v git > "/dev/null" 2>&1; then
		git -C "${_AWEWW_ROOT}" config core.hooksPath .githooks 2> "/dev/null" || true
	fi
	if [ -d "${_AWEWW_ROOT}/.githooks" ]; then
		chmod 0755 "${_AWEWW_ROOT}/.githooks/"* 2> "/dev/null" || true
	fi
	[ -f "${_AWEWW_ROOT}/aweww.sh" ] && chmod 0755 "${_AWEWW_ROOT}/aweww.sh" 2> "/dev/null" || true
}
_self_heal_perms

_aweww_help() {
	cat <<- EOF
		Aweww — Interface Unificada de Componente

		Uso:
		  aweww.sh [comando]

		Comandos:
		  test      Valida integridade e compilacao batch de todos os .el
		  compile   Compila bytecode (.elc) de todos os modulos
		  clean     Remove artefatos de bytecode (.elc)
		  doctor    Verifica ambiente Emacs e presenca de utilitarios
		  help      Exibe esta mensagem de ajuda
	EOF
}

_aweww_test() {
	echo "🧪 [Aweww] Validando integridade sintática e compilação..."
	if command -v emacs > "/dev/null" 2>&1; then
		emacs -Q --batch -L "${_AWEWW_ROOT}" --eval '
			(let ((err-count 0))
			  (dolist (f (directory-files "'"${_AWEWW_ROOT}"'" nil "\\.el$"))
			    (condition-case err
			        (byte-compile-file (expand-file-name f "'"${_AWEWW_ROOT}"'"))
			      (error
			       (setq err-count (1+ err-count))
			       (message "❌ Erro em %s: %s" f err))))
			  (when (> err-count 0)
			    (kill-emacs 1)))' > "/dev/null" 2>&1 && \
		rm -f "${_AWEWW_ROOT}/"*.elc && echo "  ✅ Aweww: 100% testado e aprovado!"
	else
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste de compilação."
	fi
}

_aweww_compile() {
	echo "⚙️  [Aweww] Compilando bytecode (.elc)..."
	emacs -Q --batch -L "${_AWEWW_ROOT}" -f batch-byte-compile "${_AWEWW_ROOT}/"*.el && \
		echo "  ✅ Bytecode compilado com sucesso!"
}

_aweww_clean() {
	echo "🧹 [Aweww] Limpando arquivos de compilação (.elc)..."
	rm -f "${_AWEWW_ROOT}/"*.elc && echo "  ✅ Limpeza concluída!"
}

_aweww_doctor() {
	echo "🔍 [Aweww] Diagnóstico do componente..."
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
	test)           _aweww_test ;;
	compile)        _aweww_compile ;;
	clean)          _aweww_clean ;;
	doctor)         _aweww_doctor ;;
	help|-h|--help) _aweww_help ;;
	*)
		echo "❌ Comando desconhecido: ${_cmd}" >&2
		_aweww_help >&2
		exit 1
		;;
esac
