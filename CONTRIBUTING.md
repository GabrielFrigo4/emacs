# 🤝 Guia de Contribuição — GNU Emacs Suite

> Diretrizes de desenvolvimento, arquitetura modular Elisp, Tree-sitter e quality gates para a suíte de **GNU Emacs**.

---

## 🚀 Setup Inicial da Bancada (Primeiros Passos)

Para clonar e configurar o repositório localmente com todos os ganchos e quality gates ativados:

```sh
# 1. Clonar o repositório
git clone "https://github.com/GabrielFrigo4/emacs.git" "${HOME}/Documents/Emacs"
cd "${HOME}/Documents/Emacs"

# 2. Configurar ganchos Git e permissões canônicas
make hooks

# 3. Validar inicialização em modo batch
make test

# 4. Compilar gramáticas Tree-sitter (opcional, requer emacs 29+)
make treesit

# 5. Executar a suíte de validação local
make ci
```

> [!IMPORTANT]
> O comando `make hooks` configura `core.hooksPath -> .githooks` e aplica permissões canônicas `0755` aos ganchos de pre-commit e commit-msg. Execute-o sempre após um novo clone.

---

## 🛡️ Invariantes de Engenharia no Emacs

1. **Arquitetura Modular & FHS Estrito:**
    - `early-init.el`: Otimizações de garbage collection (`gc-cons-threshold`), inibição de UI redundante e bootstrap do `elpaca`.
    - `init.el`: Carregamento declarativo e orquestração de módulos.
    - `etc/`: Módulos temáticos de configuração (`appearance.el`, `editing.el`, `completion.el`, `lsp.el`, `treesitter.el`).
    - `lib/`: Scripts de formatação e utilitários auxiliares.
    - `usr/`: Modos e submódulos Git locais (`usr/local/*`).
    - `var/`: Estado persistente gerado em tempo de execução (ignorado no versionamento).

2. **Invariante de Clonagem "Out-of-the-Box" (Zero-Tweaks Invariant):**
    - Scripts executáveis (`emacs.sh`, `bin/*.sh`) devem possuir modo octal `100755` no Git Index.
    - Arquivos de configuração Elisp, Markdown e YAML devem possuir modo `100644`.
    - Se cometer um erro de modo no Git Index, corrija com:
        ```sh
        git update-index --chmod=+x emacs.sh
        git update-index --chmod=-x init.el
        ```

3. **Performance & Lazy-Loading:**
    - Inicialização hermética em menos de 500ms.
    - Todo pacote carregado via `use-package` deve priorizar carregamento preguiçoso (`:defer t`, `:commands`, `:mode` ou `:hook`), exceto pacotes visuais imediatos de boot.

4. **Hermetismo Batch (`emacs -Q`):**
    - Nenhuma configuração deve assumir que o ambiente hospedeiro já possui pacotes pré-compilados ou diretórios inexistentes.
    - A inicialização em modo batch `make batch` deve executar de forma limpa e sem erros impeditivos.

---

## 🪝 Quality Gates & Validação Local

O repositório possui validações automatizadas:

```sh
make test      # Testa inicialização batch limpa (early-init + init)
make indent    # Formata e indenta arquivos Elisp
make treesit   # Compila gramáticas Tree-sitter essenciais
make ci        # Executa bateria de qualidade completa
```

Ganchos Git em `.githooks/`:

- **`pre-commit`:** Verifica whitespace, modos octais no Git Index (0755 vs 0644), sintaxe Elisp/shell e formatação.
- **`commit-msg`:** Valida formato semântico da mensagem de commit.

---

## 📝 Convenção de Commits Semânticos

As mensagens de commit devem seguir o formato:

```text
<tipo>(<escopo>): <descrição objetiva>
```

Tipos permitidos: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `ci`, `chore`.

---

## 📖 Referências Canônicas

- [README.md](README.md) — Visão geral da suíte de GNU Emacs
- [PRINCIPLES.md](PRINCIPLES.md) — Princípios de Engenharia e Clean Code
- [AGENTS.md](AGENTS.md) — Briefing para agentes autônomos de IA
- [TODO.md](TODO.md) — Roadmap operacional do Emacs
