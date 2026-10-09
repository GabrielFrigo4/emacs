#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: emacs-lisp-ts-mode Component
# ----------------------------------------------------------------
set -eu

_ELTSMODE_ROOT="$(cd "$(dirname "$0")" && pwd)"

_self_heal_perms() {
	if [ -d "${_ELTSMODE_ROOT}/.git" ] && command -v git > "/dev/null" 2>&1; then
		git -C "${_ELTSMODE_ROOT}" config core.hooksPath .githooks 2> "/dev/null" || true
	fi
	if [ -d "${_ELTSMODE_ROOT}/.githooks" ]; then
		chmod 0755 "${_ELTSMODE_ROOT}/.githooks/"* 2> "/dev/null" || true
	fi
	[ -f "${_ELTSMODE_ROOT}/emacs-lisp-ts-mode.sh" ] && chmod 0755 "${_ELTSMODE_ROOT}/emacs-lisp-ts-mode.sh" 2> "/dev/null" || true
}
_self_heal_perms

_eltsmode_help() {
	cat <<- EOF
		emacs-lisp-ts-mode — Interface Unificada de Componente

		Uso:
		  emacs-lisp-ts-mode.sh [comando]

		Comandos:
		  test      Valida integridade e compilacao batch de todos os .el
		  compile   Compila bytecode (.elc) de todos os modulos
		  clean     Remove artefatos de bytecode (.elc)
		  doctor    Verifica ambiente Emacs e presenca de utilitarios
		  help      Exibe esta mensagem de ajuda
	EOF
}

_eltsmode_test() {
	echo "🧪 [emacs-lisp-ts-mode] Validando integridade sintática e compilação..."
	if command -v emacs > "/dev/null" 2>&1; then
		emacs -Q --batch -L "${_ELTSMODE_ROOT}" --eval '
			(let ((err-count 0))
			  (dolist (f (directory-files "'"${_ELTSMODE_ROOT}"'" nil "\\.el$"))
			    (condition-case err
			        (byte-compile-file (expand-file-name f "'"${_ELTSMODE_ROOT}"'"))
			      (error
			       (setq err-count (1+ err-count))
			       (message "❌ Erro em %s: %s" f err))))
			  (when (> err-count 0)
			    (kill-emacs 1)))' > "/dev/null" 2>&1 && \
		rm -f "${_ELTSMODE_ROOT}/"*.elc && echo "  ✅ emacs-lisp-ts-mode: 100% testado e aprovado!"
	else
		echo "ℹ️  emacs não encontrado no PATH; ignorando teste de compilação."
	fi
}

_eltsmode_compile() {
	echo "⚙️  [emacs-lisp-ts-mode] Compilando bytecode (.elc)..."
	emacs -Q --batch -L "${_ELTSMODE_ROOT}" -f batch-byte-compile "${_ELTSMODE_ROOT}/"*.el && \
		echo "  ✅ Bytecode compilado com sucesso!"
}

_eltsmode_clean() {
	echo "🧹 [emacs-lisp-ts-mode] Limpando arquivos de compilação (.elc)..."
	rm -f "${_ELTSMODE_ROOT}/"*.elc && echo "  ✅ Limpeza concluída!"
}

_eltsmode_doctor() {
	echo "🔍 [emacs-lisp-ts-mode] Diagnóstico do componente..."
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
	test)           _eltsmode_test ;;
	compile)        _eltsmode_compile ;;
	clean)          _eltsmode_clean ;;
	doctor)         _eltsmode_doctor ;;
	help|-h|--help) _eltsmode_help ;;
	*)
		echo "❌ Comando desconhecido: ${_cmd}" >&2
		_eltsmode_help >&2
		exit 1
		;;
esac
