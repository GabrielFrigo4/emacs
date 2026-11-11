# 🤝 Guia de Contribuição

> Diretrizes de desenvolvimento, ciclo de contribuição, quality gates defensivos e convenções de engenharia para repositórios do ecossistema.

---

## 🚀 Setup Inicial

Para configurar o repositório local e ativar as barreiras de qualidade com auto-cura:

1. Ativar os ganchos Git defensivos com permissões canônicas:

```sh
make hooks
```

2. Validar a integridade local e os quality gates integrados:

```sh
make ci
```

---

## 🔄 Ciclo Canônico de Contribuição

Todo o fluxo de desenvolvimento segue o desacoplamento estrito entre a bancada de trabalho e os runtimes de produção:

1. **Bancada de Edição:** Alterações devem ocorrer exclusivamente na bancada em `~/Documents/`. Nunca altere clones ou diretórios de produção diretamente.
2. **Implementação Limpa:** Desenvolva mantendo o código autoexplicativo, respeitando a Taxonomia Tripartite de Comentários e a portabilidade POSIX.
3. **Quality Gates Locais:** Valide seu trabalho localmente executando `make format`, `make audit`, `make test` e `make ci`.
4. **Commit Semântico:** Registre alterações atômicas seguindo a convenção de commits semânticos, protegida pelos ganchos Git com auto-cura.
5. **Deploy Canônico:** Envie as alterações via `git push`. Ambientes de produção recebem atualizações unicamente via `git pull`.

---

## 🛡️ Invariantes de Engenharia

Toda contribuição deve respeitar rigorosamente as diretrizes em [PRINCIPLES.md](PRINCIPLES.md) e [AGENTS.md](AGENTS.md):

1. **Taxonomia Tripartite de Comentários:**
    - _Comentários de Sistema:_ PERMITIDOS (shebangs, pragmas, diretivas de linters).
    - _Comentários Estruturais de 64/32 colunas:_ PERMITIDOS (cabeçalhos de 64 `-` `# ----------------------------------------------------------------`, réguas de 32 caracteres `### ================================` e `### --------------------------------` com títulos em MAIÚSCULO, réguas de 64 `=` em `.gitignore` com títulos em MAIÚSCULO).
    - _Comentários Explicativos/Narrativos:_ PROIBIDOS em código-fonte, configurações e blocos de código dentro de arquivos Markdown.

2. **Invariante de Modos no Git Index (`0755` vs `0644`):**
    - Scripts executáveis e ganchos Git devem manter permissão `0755` (`100755` no Git Index).
    - Arquivos de configuração, documentações, manifestos e fontes devem manter `0644` (`100644` no Git Index).
    - Permissões no índice podem ser ajustadas manualmente quando necessário:
        ```sh
        git update-index --chmod=+x scripts/util.sh
        git update-index --chmod=-x README.md
        ```

3. **Hermetismo de Produção (`rm -rf .agents`):**
    - Nenhum build, script de produção ou execução de aplicação pode depender de arquivos em `.agents/` ou `skills/`.

4. **Portabilidade POSIX e Makefiles Silenciosos:**
    - Scripts de automação devem adotar POSIX `sh` estrito, cabeçalho `#!/usr/bin/env sh` e redirecionamento seguro `> "/dev/null" 2>&1`.
    - Makefiles devem conter `.POSIX: .SILENT:` e flags de supressão de ruído.

---

## 🪝 Quality Gates & Ganchos Git com Auto-Cura

O repositório adota ganchos defensivos com auto-cura ativa em `.githooks/`:

- **`.githooks/pre-commit`:**
    - _Auto-cura de Modos:_ Detecta scripts e binários ajustando permissões para `0755` no disco e no Git Index; normaliza arquivos de texto para `0644`.
    - _Auto-cura de Formatação:_ Remove trailing whitespaces, executa Prettier em Markdowns e manifestos estruturados, corrige cabeçalhos de banners estruturais e re-adiciona ao stage.
    - _Quality Gates Estáticos:_ Bloqueia escapes octais (`\033`), redirecionamentos não aspeados (`> /dev/null`), inconsistências de whitespace/conflito e falhas de sintaxe POSIX (`sh -n`).
- **`.githooks/commit-msg`:**
    - _Auto-cura de Prefixo:_ Valida o prefixo semântico e formata automaticamente a mensagem com `chore:` se o tipo for omitido ou inválido.
    - _Validação de Comprimento:_ Garante mensagens significativas com comprimento mínimo de 8 caracteres.

Para executar os quality gates manualmente:

| Comando       | Finalidade Operacional                                           |
| :------------ | :--------------------------------------------------------------- |
| `make hooks`  | Instala e ativa os ganchos Git locais com permissão `0755`       |
| `make format` | Formata todo o repositório com Prettier e ferramentas canônicas  |
| `make audit`  | Executa suíte estática de integridade, banners e taxonomia       |
| `make test`   | Executa testes unitários e de integração locais                  |
| `make ci`     | Executa o pipeline completo de verificação local antes de commit |

---

## 📝 Convenção de Commits Semânticos

As mensagens de commit devem seguir o padrão:

```text
<tipo>(<escopo>): <descrição objetiva>
```

ou

```text
<tipo>: <descrição objetiva>
```

### Tipos Permitidos:

| Tipo       | Descrição                                                    |
| :--------- | :----------------------------------------------------------- |
| `feat`     | Nova funcionalidade de produto ou sistema                    |
| `fix`      | Correção de bug ou falha de execução                         |
| `docs`     | Alterações estritamente em documentação                      |
| `style`    | Ajustes visuais, formatação de código ou Prettier            |
| `refactor` | Refatoração de código sem alteração funcional externa        |
| `perf`     | Otimização de desempenho, latência ou consumo de recursos    |
| `test`     | Adição ou refatoração de testes automatizados                |
| `build`    | Alterações no sistema de compilação ou dependências externas |
| `ci`       | Ajustes em pipelines de CI ou ganchos Git locais             |
| `chore`    | Tarefas rotineiras de manutenção ou infraestrutura           |
| `revert`   | Reversão de commit anterior                                  |
| `sec`      | Correções ou aprimoramentos de segurança e criptografia      |
| `init`     | Inicialização de repositório, módulo ou estrutura inicial    |

---

## 📖 Referências Obrigatórias

- [README.md](README.md) — Documentação e visão geral do repositório
- [TODO.md](TODO.md) — Roadmap de desenvolvimento e status operacional
- [PRINCIPLES.md](PRINCIPLES.md) — Os 22 Princípios de Engenharia Soberanos
- [AGENTS.md](AGENTS.md) — Manual operacional e briefing para agentes de IA
