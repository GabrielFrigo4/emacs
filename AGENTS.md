# 🔮 Emacs Configuration (.emacs.d) — AI Agent Briefing

> Este é o repositório da **configuração do Emacs** de Gabriel Frigo, integrante da **Suíte de Editores** do ecossistema [Universal Environment](https://github.com/GabrielFrigo4/environment).

---

## 🧭 Identidade e Papel

O repositório `.emacs.d` provê um ambiente de desenvolvimento extensível, centrado no GNU Emacs, com suporte modular a Org-mode, LSP (Eglot), Elpaca package manager, EAF e integrações com IA.

---

## 📁 Estrutura Canônica de Diretórios

- **`init.el`**: Ponto de entrada principal, feature toggles com suporte a variáveis de ambiente (`EMACS_AI`, `EMACS_LSP`, etc.) e caminhos do sistema.
- **`early-init.el`**: Otimizações de inicialização precoce e redirecionamento de cache native-comp.
- **`lib/core.el`**: Macros de detecção de SO (Linux, FreeBSD, macOS, Windows) e funções de indentação.
- **`etc/init/`**: Inicialização de pacotes (Elpaca), interface gráfica, atalhos globais e configurações de sessão.
- **`etc/editor/`**: Módulos de edição (`completion.el`, `lsp.el`, `scroll.el`, `treesit.el`, `utils.el`).
- **`etc/apps/`**: Aplicações integradas (`ai.el`, `apps.el`, `eaf.el`, `org.el`).
- **`etc/lang/`**: Modos de linguagens (`latex.el`, `lisp.el`, `markdown.el`, `lang.el`).
- **`etc/tools/`**: Ferramentas externas (`git.el`, `github.el`, `mandoc.el`, `shell.el`, `tools.el`).
- **`bin/`**: Utilitários auxiliares (`indent-all.sh` POSIX, `indent-all.ps1`, `indent-all.cmd`).

---

## ⚠️ Invariantes Críticas para Agentes de IA

1. **Fail-Safe & Graceful Degradation:** Toda biblioteca opcional ou chamada de pacote DEVE degradar graciosamente caso a rede esteja indisponível, a ferramenta não esteja instalada ou a flag correspondente esteja desativada. O Emacs NUNCA deve travar na inicialização.
2. **Zero Comentários Narrativos:** Use a arquitetura de comentários em 3 camadas (`#` ou `;;` com régua de 64 `-` no topo, 32 `=` para seções e 32 `-` para subseções).
3. **Zero Secrets:** Credenciais e chaves de API NUNCA são salvas neste repositório. Use `auth-source` ou variáveis de ambiente injetadas pelo [Vault](https://github.com/GabrielFrigo4/vault).
4. **Independência Git:** Este repositório é um Git Submodule no Environment. Commits feitos aqui pertencem ao repositório `.emacs.d`.
5. **Hermetismo de Produção & Invariante `rm -rf .agents`:** Repositório 100% autônomo. Zero acoplamento de código de produção a `.agents/` ou `skills/` (o Emacs opera plenamente se `.agents/` for deletado).
6. **Bancada de Desenvolvimento vs. Runtimes de Produção:** Em produção, o Emacs reside e opera soberanamente em `~/.emacs.d`. O repositório central `Environment` é exclusivamente uma bancada de desenvolvimento. NUNCA aponte symlinks ou diretórios de runtime para `~/Documents/Environment/Editor/Emacs`.

---

## 🛡️ Regra da Proatividade e Correção Contínua (Boy Scout Rule)

O agente de IA **DEVE SER ATIVAMENTE PROATIVO** na manutenção e aplicação dos padrões canônicos deste repositório.

Se durante a execução de qualquer tarefa (seja criação de novas features, correções pontuais, refatorações ou investigação) o agente identificar qualquer linha de código, script, Makefile ou documentação fora dos padrões estabelecidos, **NÃO DEVE HESITAR NEM IGNORAR**:

1. **Notificar concisamente** o usuário sobre a divergência encontrada.
2. **Corrigir imediatamente a inconformidade**, aplicando o padrão canônico correspondente:
    - **Comentários Narrativos:** Eliminar imediatamente comentários óbvios que apenas narram código executável.
    - **Banners Estruturais:** Ajustar réguas para exatamente 64 hífens no topo ou 32 caracteres com `### ` no corpo.
    - **Portabilidade POSIX:** Substituir bashismos (`[[ ]]`, `&>`, arrays, `source`) por sintaxe estrita POSIX `/bin/sh`.
    - **Shebang Universal:** Garantir sempre `#!/usr/bin/env sh` ou `#!/usr/bin/env python3`.
    - **Sequências ANSI:** Substituir octais crípticos (` `) e `printf` desnecessário por `[ -t 1 ] && echo -n $'\e...'`.
    - **Redirecionamento Seguro:** Envolver destinos em aspas duplas (ex: `> "/dev/null" 2>&1`).
    - **Makefiles:** Assegurar cabeçalho `.POSIX: .SILENT:`, `MAKEFLAGS += --no-print-directory -s`, alinhamento estético de variáveis e zero `@` redundante.
    - **Permissões Canônicas:** Aplicar 4 dígitos octais (`chmod 0755`, `chmod 0644`, `chmod 0700`, `chmod 0600`).

## 📖 Referências Obrigatórias

Antes de qualquer modificação neste ecossistema, consulte:

- **[ENVIRONMENT.md](ENVIRONMENT.md)**: Arquitetura global do ecossistema
- **[PRINCIPLES.md](PRINCIPLES.md)**: Os 21 Princípios de Engenharia UNIX + Clean Code
- **[.agents/rules/principles.md](.agents/rules/principles.md)**: Regras específicas de engenharia Elisp
- **[.agents/skills/](.agents/skills/)**: Runbooks operacionais do Emacs
