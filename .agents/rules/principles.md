# 🔮 Emacs Engineering Principles & Guidelines

> Regras de engenharia e diretrizes de desenvolvimento para a configuração do GNU Emacs.

---

## 🏛️ Invariantes de Código Elisp

1. **Robustez & Fail-Safe:** Módulos que dependem de compiladores externos (`gcc`, `libvterm`, `tree-sitter`) ou dependências de rede (`elpaca`, `llm`, `gptel`) devem ser protegidos com checagens de disponibilidade (`executable-find`, `condition-case`) e toggles em `init.el`.
2. **Arquitetura de 3 Camadas de Comentários:**
    - Topo do arquivo: Header Banner com 64 `-` (`;; ----...`).
    - Seções principais: Delimitador com 32 `=` (`;; ====...`).
    - Subseções: Delimitador com 32 `-` (`;; ----...`).
    - Sem comentários narrativos inline.
3. **Escopo de Variáveis & Nomenclatura:**
    - Variáveis globais privadas devem usar prefixo semântico de namespace (ex: `scroll/`, `treesit/`, `ia/`).
    - Não poluir o namespace global do Emacs com símbolos curtos e ambíguos.
4. **Performance de Inicialização:**
    - Adiar carregamento de pacotes pesados (`:defer t`, `with-eval-after-load`).
    - Tempo de carregamento interativo deve ser monitorado e mantido enxuto.
5. **Lexical Binding Obrigatório (Linha 1):**
    - Todo arquivo `.el` DEVE começar estritamente com `;;; -*- lexical-binding: t -*-` na Linha 1.
    - Evita warnings do compilador nativo e byte-compiler no Emacs 30/31+, previne vazamento de escopo dinâmico e otimiza compilação `.eln`.
