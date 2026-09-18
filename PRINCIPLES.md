# 📜 Princípios de Engenharia & Filosofia do Ecossistema

> _"Rule of Separation: Separate policy from mechanism; separate engine from interface."_<br>
> — Eric S. Raymond, _The Art of UNIX Programming_ (2003)

O **Quarteto de Produtividade** (`Setup`, `Shell`, `Vault`, `Profile`) é um ecossistema federado de 4 repositórios complementares e desacoplados, orquestrado pelo repositório **[Environment](https://github.com/GabrielFrigo4/environment)**. Cada componente é responsável por um domínio distinto: provisionamento de sistema operacional (_Setup_), motor interativo de terminal (_Shell_), cofre criptográfico de segredos (_Vault_) e dotfiles declarativos e skills de IA (_Profile_).

Para garantir longevidade, idempotência e excelência técnica, toda contribuição a qualquer repositório do ecossistema deve obedecer aos **22 Princípios de Engenharia** (17 Princípios UNIX + Regra da Soberania do Usuário + Regra da Autonomia Reentrante + Regra do Hermetismo de Produção + Regra do Desacoplamento Dev-Hub + Regra da Antifragilidade & Resiliência Ativa), às práticas de **Clean Code** adaptadas a scripts de infraestrutura, e às diretrizes arquiteturais unificadas.

---

## 🏛️ Os 22 Princípios de Design (17 Princípios UNIX + Soberania do Usuário + Autonomia Reentrante + Hermetismo de Produção + Desacoplamento Dev-Hub + Antifragilidade & Resiliência Ativa)

### 1. Regra da Modularidade (_Rule of Modularity_)

> _Escreva partes simples conectadas por interfaces limpas._

- O provisionamento de SO é quebrado em receitas atômicas, autocontidas e independentes por ecossistema (`freebsd/`, `linux/`, `windows/`, `common/`).

### 2. Regra da Clareza (_Rule of Clarity_)

> _Clareza é melhor que esperteza._

- Scripts de provisionamento priorizam legibilidade absoluta sobre "one-liners" crípticos ou truques de regex obscuros.
- Nomes de variáveis são autoexplicativos (`TARGET_CONFIG_DIR`, `BACKUP_TIMESTAMP`).

### 3. Regra da Composição (_Rule of Composition_)

> _Projete programas para serem conectados a outros programas._

- As receitas de provisionamento são atômicas e podem ser executadas isoladamente ou encadeadas sequencialmente em pipelines de automação.

### 4. Regra da Separação (_Rule of Separation_)

> _Separe a política do mecanismo; separe o motor da interface._

- **Mecanismo (`Setup`):** Scripts executáveis de automação e provisionamento que sabem _como_ interagir com o sistema operacional, gerenciar pacotes (`pkg`, `dnf`, `apt`, `pacman`, `winget`), configurar privilégios (`sudo`/`doas`) e registrar serviços.
- **Política (`Profile`):** Arquivos declarativos puros (`settings.json`, `.clang-format`, `.stylua.toml`, `extensions.txt`) que definem _o que_ deve ser configurado no espaço do usuário (`$HOME`). O mecanismo nunca embute configurações hardcoded que pertençam ao Profile.

### 5. Regra da Simplicidade (_Rule of Simplicity_)

> _Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário._

- **Clean Host (Santuário):** O sistema operacional hospedeiro permanece mínimo. Não instalamos runtimes pesados no host; desenvolvimento de projetos vive em Containers ou Jails.

### 6. Regra da Parcimônia (_Rule of Parsimony_)

> _Escreva um programa grande apenas quando estiver claro por demonstração que nada mais resolverá._

- Se um comando nativo do gerenciador de pacotes (`dnf install`, `pkg install`, `winget install`) resolve o problema, não criamos wrappers complexos em torno dele.

### 7. Regra da Transparência (_Rule of Transparency_)

> _Projete para a visibilidade para tornar inspeção e depuração fáceis._

- Scripts de bootstrap exibem exatamente quais etapas estão executando, com mensagens sem ruído excessivo mas informativas o bastante para auditoria imediata.

### 8. Regra da Robustez (_Rule of Robustness_)

> _A robustez é filha da transparência e da simplicidade._

- Antes de tentar instalar pacotes ou aplicar configurações, os scripts validam pré-requisitos (`command -v`, variáveis de ambiente necessárias, privilégios).
- Uso extensivo do **ZFS** para snapshots automáticos antes de mudanças críticas no sistema.
- **Sincronização Resiliente & Auto-Cura de Repositórios:** Utilitários e comandos de atualização (`update-*`, `upsh`, `uprc`, `upvt`, etc.) nunca devem abortar nem entrar em loops infinitos causados por discrepâncias de atributos POSIX (`filemode` 0755 vs 0644). Adotam a estratégia em 4 etapas:
    1. _Auto-cura Cirúrgica de Atributos:_ Inspeciona modificações via `git diff --numstat`. Qualquer arquivo com 0 adições e 0 deleções (`0 0 <arquivo>`) representa puramente alteração de permissão ou metadados POSIX, sendo restaurado imediatamente via `checkout -- <arquivo>`, sem criar stashes desnecessários e sem interferir em arquivos com código real.
    2. _Isolamento Defensivo:_ Cria auto-stash rastreável (`autostash-before-update-<timestamp>`) apenas se restarem modificações reais de código ou arquivos novos.
    3. _Cascata de Sincronização:_ Tentativa sequencial de `--ff-only` $\rightarrow$ `--rebase` $\rightarrow$ `pull`.
    4. _Restauração & Proteção de Ganchos:_ Restaura alterações salvas via `stash pop` (reaplicando a auto-cura cirúrgica caso o stash continha permissões antigas) e assegura permissão `chmod 0755` estritamente nos ganchos de `.githooks/`, preservando os modos canônicos de arquivos do repositório.

### 9. Regra da Representação (_Rule of Representation_)

> _Dobre o conhecimento em dados para que a lógica do programa possa ser estúpida e robusta._

- Preferir listas declarativas de pacotes em vez de blocos gigantescos de `if/else` procedural.

### 10. Regra do Menor Espanto (_Rule of Least Surprise_)

> _No design de interfaces, sempre faça a coisa menos surpreendente._

- Seguir estritamente os caminhos convencionais do ecossistema Unix (`/etc/`, `/usr/local/`, `/var/`). Códigos de saída universais: `0` para sucesso, diferente de zero para falhas.

### 11. Regra do Silêncio (_Rule of Silence_)

> _Quando um programa não tem nada surpreendente a dizer, ele não deve dizer nada._

- Scripts utilitários de compilação ou conversão devem executar de forma quieta, emitindo mensagens apenas na ocorrência de erros reais em `stderr`.

### 12. Regra do Reparo (_Rule of Repair_)

> _Quando você precisar falhar, falhe ruidosamente e o mais rápido possível._

- Se o bootstrap não tiver privilégios de administrador ou falhar ao acessar um repositório remoto, ele **aborta imediatamente** (fail-fast via `set -eu`), em vez de deixar a máquina em estado semi-configurado.

### 13. Regra da Economia (_Rule of Economy_)

> _O tempo do programador é caro; economize-o em preferência ao tempo da máquina._

- O objetivo do `Setup` é que você possa reconstruir qualquer estação de trabalho completa em minutos com receitas prontas.

### 14. Regra da Geração (_Rule of Generation_)

> _Evite codificação manual; escreva programas para escrever programas quando puder._

- Utilizar scripts utilitários e geradores de templates em `scripts/` para automações e conversões de formatos.

### 15. Regra da Otimização (_Rule of Optimization_)

> _Prototipe antes de polir. Faça funcionar antes de otimizar._

- Primeiro garanta que o provisionamento funcione de ponta a ponta sem falhas em uma VM limpa ou snapshot ZFS.

### 16. Regra da Diversidade (_Rule of Diversity_)

> _Desconfie de todas as afirmações de "uma única maneira verdadeira"._

- Aceitamos a diversidade de sistemas de forma intencional e estruturada:
    - **FreeBSD:** Foco em KDE Plasma, estabilidade sólida, Jails e ZFS de primeira classe.
    - **Fedora:** Foco em GNOME Shell moderno, Wayland nativo e containers Podman/Incus.
    - **Windows:** Suporte pragmático através de PowerShell, Batch e MSYS2.

### 17. Regra da Extensibilidade (_Rule of Extensibility_)

> _Projete para o futuro, porque ele chegará antes do que você imagina._

- A estrutura de pastas permite plugar um novo sistema operacional em `linux/` (ex: Arch, Rocky) sem alterar as receitas existentes.

### 18. Regra da Soberania do Usuário (_Rule of User Sovereignty_)

> _Honre a escolha explícita e deliberada do usuário antes de impor padrões genéricos._

- **Precedência Local sobre Global (Local > Global):** Em conformidade com o princípio UNIX da localidade e do menor espanto, **o escopo mais específico, intencional e local sempre prevalece sobre o genérico e global**:
    1. **Argumentos de Linha de Comando (CLI):** Flags explícitas têm precedência absoluta (`--context`, `--yes`).
    2. **Variáveis de Ambiente Explícitas:** `$SHELL_REPO_DIR`, `$VAULT_DIR`, `$NVIM_APPNAME`, `$GEMINI_API_KEY`.
    3. **Contexto Local do Projeto:** `.agents/skills/`, `.agents/rules/`, `.githooks/`, `Makefile` local.
    4. **Escopo do Usuário (`$HOME` / XDG):** `~/.shell`, `~/.vault`, `~/.config/...`, `~/.gemini/config/skills/`.
    5. **Escopo Global do Sistema:** `/usr/local/share/shell`, `/usr/local/share/vault`, `/etc/...`.
- **Precedência em Portable AI Skills:** Runbooks locais de projeto (`.agents/skills/`) sobrescrevem ou estendem runbooks globais do usuário (`~/.gemini/config/skills/`), que por sua vez sobrescrevem habilidades nativas da IDE (`builtin/skills`). O projeto é soberano.
- **Preferência de Elevação (`doas > sudo`):** Respeitar a preferência explícita do usuário pelo `doas` através da variável `${ELEVATE}`.
- **Preservação de Escolhas:** Receitas de sistema nunca substituem ou desconfiguram serviços e configurações personalizadas preexistentes do usuário sem aviso explícito.

### 19. Regra da Autonomia Reentrante (_Rule of Reentrant Autonomy & Opportunistic Synergy_)

> _Projete cada módulo para ser 100% autossuficiente e tolerante ao isolamento; conecte-o de forma silenciosa e oportuna quando seus pares estiverem presentes._

- **Cidadão de Primeira Classe Isolado:** Qualquer repositório do ecossistema (`Shell`, `Profile`, `Vault`, `Setup`, `Editor/*`) DEVE poder ser clonado e operado sozinho sem requerer a existência de nenhum outro componente. A ausência de módulos pares NUNCA deve gerar erros, falhas ou avisos ao usuário.
- **Sinergia Oportunística Silenciosa:** Se um componente detectar a presença de outro no ambiente hospedeiro (`Emacs` detectando `Vault`, `Shell` detectando `Vault`, `Profile` sincronizando `Skills`), ele se conecta e ativa recursos avançados imediatamente e em silêncio absoluto.

### 20. Regra do Hermetismo de Produção & Autonomia Soberana (_Rule of Production Hermeticity_)

> _O software é construído para humanos e sistemas operacionais; a inteligência artificial é exclusivamente uma copiloto sob demanda. Nenhum código de produção deve depender de ferramentas de IA._

- **A Invariante do Teste de Fogo (`rm -rf .agents`):** Qualquer repositório do ecossistema DEVE poder ter o diretório `.agents/` sumariamente deletado (`rm -rf .agents`) sem que nenhuma funcionalidade, rotina de compilação, script, teste, instalação, atualização ou comportamento operacional seja afetado. O ecossistema continua 100% íntegro e autônomo.
- **Zero Acoplamento de IA em Runtime:** Nenhum script executável de produção, carregador de terminal (`shell.sh`, `profile.sh`, `vault.sh`, `setup.sh`), arquivo de ambiente (`*.env`, `*.rc`), Makefile, hook de Git (`.githooks/`), pipeline de CI, alias ou função interativa pode depender, referenciar, fazer `source` ou invocar arquivos residentes em diretórios de IA (`.agents/` ou pastas de skills).
- **Natureza Cognitiva das Skills:** Skills e runbooks de IA são artefatos exclusivamente procedimentais e conceituais para auxílio da inteligência artificial e consulta humana. Jamais são bibliotecas de runtime, dependências de compilação ou geradores estruturais do ecossistema.

### 21. Regra do Desacoplamento Dev-Hub vs. Runtime de Produção (_Rule of Production Sovereign Isolation_)

> _A bancada de ferramentas do artesão não deve ser soldada ao produto final; desenvolva no hub, execute nos caminhos canônicos do sistema._

- **O Environment é Exclusivamente Bancada de Desenvolvimento (`~/Documents/Environment`):** O repositório Environment existe para permitir o desenvolvimento conjunto, testes em lote, auditoria estática cruzada e governança do ecossistema. Absolutamente NADA dentro dele deve ser referenciado diretamente pelo sistema operacional hospedeiro.
- **Runtimes de Produção Soberanos:** Cada componente opera de forma 100% autônoma em sua localização canônica recomendada:
    - `Shell`: `/usr/local/share/shell` (padrão de sistema) ou `~/.local/share/shell` / `~/.config/shell` (recomendado rootless).
    - `Profile`: `~/.config/profile` (ou `~/.local/share/profile`).
    - `Vault`: `~/.local/share/vault`, `~/.config/vault` ou `~/.vault` (ou `%USERPROFILE%\.vault`).
    - `Emacs`: `~/.emacs.d`.
    - `Helix`: `~/.config/helix`.
    - `NeoVim`: `~/.config/nvim`.
    - `Vim`: `~/.vim`.
- **Zero Symlinks para a Bancada de Desenvolvimento:** É estritamente proibido criar links simbólicos de sistema, configurações de shell (`.bashrc`, `.zshrc`) ou dotfiles que apontem para a pasta de desenvolvimento `~/Documents/Environment`. O provisionamento no SO deve ser feito exclusivamente clonando cada repositório em sua localização canônica via `make install`.
- **Hierarquia de Resolução de Caminhos (XDG vs. FHS):**
    - **Universal Shell:**
        1. `/usr/local/share/shell` — Padrão prático para o par `root` + administrador do host.
        2. `~/.local/share/shell` — **Recomendado** filosoficamente pela elegância, modularização e desacoplamento rootless.
        3. `~/.config/shell` — Ergonomia unificada sob a pasta central de configurações.
        4. `~/.shell` — Atalho clássico e ambiente Windows MSYS2.
    - **Universal Profile & Universal Vault:**
        1. `~/.local/share/<componente>` (XDG Data).
        2. `~/.config/<componente>` (XDG Config).
        3. `~/.<componente>` (Home direta).
        4. `/usr/local/share/<componente>` — Suportado defensivamente pela cascata, mas **NÃO RECOMENDADO** por violar a segregação de privilégios e modularidade do usuário (especialmente crítico para o Vault, cujos segredos pertencem ao indivíduo).
- **A Filosofia do "Recomendado vs. Padrão":** O termo "Recomendado" expressa o ideal arquitetural (desacoplamento e soberania do usuário sem sudo). O termo "Padrão de Sistema" atende à realidade pragmática de estações administradas onde `root` e usuário precisam do mesmo shell. O ecossistema não é dogmático e acolhe com robustez ambas as necessidades.

### 22. Regra da Antifragilidade & Resiliência Ativa (_Rule of Antifragility & Active Self-Healing_)

> _O que é frágil quebra com a mudança de caminho ou desordem de ambiente; o que é robusto apenas resiste estaticamente; o que é antifrágil auto-descobre, cura em tempo de voo e opera com excelência diante de relocação dinâmica e ausência de recursos._

- **O Triângulo da Resiliência Sistêmica (Taleb):**
    - **Frágil:** Assume um único caminho rígido (`~/.vault/keys/...`). Quebra catastroficamente se o usuário migrar para o padrão XDG (`~/.local/share/vault`), se uma variável de ambiente estiver nula ou se um caminho não existir.
    - **Robusto:** Possui um fallback estático alternativo, mas falha se o contexto diferir do previsto.
    - **Antifrágil:** Adapta-se ativamente à desordem, descobre recursos através de cascata dinâmica de inspeção, auto-cura permissões incorretas em tempo de voo, repara variáveis de ambiente na sessão ativa e opera em qualquer estação de trabalho sem atrito.
- **Cascata Ativa de Descoberta (Active Discovery Cascade):** Nenhuma função, alias, script executável ou loader deve depender cegamente de caminhos fixos ou variáveis desatualizadas. Toda resolução de chaves, segredos ou dependências de runtime inspeciona defensivamente:
    1. Variável de ambiente explícita (se o arquivo apontado existir e for legível).
    2. Diretório ativo do componente (`$VAULT_DIR/keys/...`, `$SHELL_REPO_DIR/...`).
    3. Padrão canônico XDG Data (`${XDG_DATA_HOME:-~/.local/share}/<componente>/...`).
    4. Padrão canônico XDG Config (`${XDG_CONFIG_HOME:-~/.config}/<componente>/...`).
    5. Fallback clássico UNIX no `$HOME` (`~/.<componente>/...`).
    6. Escopo global do sistema (`/usr/local/share/<componente>/...`).
    7. Agente de chaves em memória (`ssh-agent` / `ssh-add -l`).
- **Auto-Cura de Permissões em Tempo de Voo (In-flight Permission Self-Healing):** Se um arquivo de segurança crítica (chave SSH `*.key`, certificado ou arquivo `.env`) for localizado com permissões permissivas demais (ex: `0644`), os utilitários realizam a auto-cura imediata (`chmod 0600 "${key}" 2> "/dev/null" || true`) antes de invocar comandos sensíveis como `ssh`, impedindo que o cliente remoto rejeite a chave com avisos ou recusas de autenticação.
- **Auto-Correção da Sessão (Session Self-Correction):** Ao identificar a localização real e validada de um recurso através da cascata de descoberta, as funções interativas exportam imediatamente a variável corrigida para a sessão ativa (`export FRIGO_SERVER_KEY="${_key}"`), curando o ambiente do usuário para invocações subsequentes e processos-filhos.
- **Zero Falha Cega & Argument Forwarding:** Utilitários e wrappers antifrágeis nunca omitem falhas silenciosamente nem engolem argumentos:
    - Se a chave física não for encontrada no disco, tentam conexão delegada para o agente SSH em execução em vez de passar `-i <caminho_inexistente>`.
    - Encaminham transparentemente todos os parâmetros adicionais (`"$@"`) para o comando subjacente, permitindo execução remota de comandos, flags de porta e modo batch sem atrito.

---

## 🧼 Princípios de Clean Code para Receitas de Infraestrutura

### 1. Princípio da Responsabilidade Única (SRP)

- Cada receita de provisionamento deve ter **uma única razão para mudar**. A receita `fonts.sh` apenas instala fontes; não configura atalhos de teclado nem instala editores.

### 2. Idempotência Rigorosa

- Executar qualquer receita uma, duas ou dez vezes seguidas DEVE produzir o mesmo resultado estável, sem duplicar linhas em arquivos, sem gerar erros de "arquivo já existe" e sem quebrar links.

### 3. Shebang Padrão Absoluto (`#!/usr/bin/env sh`)

- Todo script de shell neste repositório DEVE iniciar com `#!/usr/bin/env sh`.

### 4. Permissões Canônicas em 4 Dígitos Octais

- `chmod 0755` para diretórios e receitas de provisionamento executáveis.
- `chmod 0644` para arquivos de configuração e documentações.
- `chmod 0440` para arquivos de autorização do sistema (ex: `/etc/sudoers.d/*`, `doas.conf`).

### 5. Template Canônico de Receitas & Emissão Semântica

- **Receitas de Provisionamento (`Setup`):** Adotam um cabeçalho compacto de 3 linhas com modo defensivo e emissão pontual:
    ```sh
    #!/usr/bin/env sh
    # ----------------------------------------------------------------
    # Recipe: [Nome do Software / Funcionalidade]
    # ----------------------------------------------------------------
    set -eu

    echo "📦 [Nome]: Iniciando configuração..."

    ELEVATE="$( [ "$(id -u)" -ne 0 ] && { command -v doas > "/dev/null" 2>&1 && echo "doas" || { command -v sudo > "/dev/null" 2>&1 && echo "sudo"; }; } )"

    echo "✅ [Nome]: Configurado com sucesso!"
    ```
- **Utilitários e Orquestradores (`Shell`, `Profile`, `Environment`):** Adotam a biblioteca semântica de emissão (`ui.sh` / `_ui_*`), garantindo TUI ANSI em terminais interativos (`[ -t 1 ]`) e fallback gracioso em texto plano para pipelines e modo batch:
    - `_ui_step`: Marcador de etapa primária em Ciano (`==>`).
    - `_ui_sub`: Subtarefa ou item inspecionado em Azul (`↳`).
    - `_ui_ok`: Conclusão bem-sucedida em Verde (`✅`).
    - `_ui_warn`: Alerta preventivo não-bloqueante em Amarelo (`⚠️ `).
    - `_ui_err`: Notificação de falha direcionada a `stderr` em Vermelho (`❌`).
    - `_ui_info`: Informação contextual ou nota de recarga em Magenta (`ℹ️ `).
    - `_ui_banner`: Delimitador estrutural com réguas duplas de 64 caracteres `=` em Ciano.

### 6. Padrão Exclusivo de Comentários Estruturais (Regra do Não-Vazamento)

- **Zero Comentários Narrativos:** Comentários explicativos inline são estritamente proibidos em código, scripts, templates e exemplos. O código expressa sua intenção através de separação por linhas em branco e nomenclatura semântica.
- **Cabeçalho de Topo (Header Banner):** Exclusivo para as linhas 2 a 4 do arquivo, delimitado por exatamente 64 hífens (`# ----------------------------------------------------------------`).
- **Corpo do Script:** Seções estruturais internas usam estritamente réguas de 32 caracteres (`### ================================` ou `### --------------------------------`), com o título estritamente contido no limite de 32 caracteres (não-vazamento).

### 7. Ordem Canônica de Priorização de Pacotes (Dispatch Universal)

1. **Receitas Multi-OS (`FreeBSD` + `Linux`):**
   `pkg` _(FreeBSD)_ $\rightarrow$ `dnf` _(Fedora)_ $\rightarrow$ `apt` _(Debian)_ $\rightarrow$ `pacman` _(Arch)_
2. **Receitas Exclusivas de Linux (`linux/`):**
   `dnf` _(Fedora)_ $\rightarrow$ `apt` _(Debian)_ $\rightarrow$ `pacman` _(Arch)_

### 8. Preferência Absoluta por Flags Longas Autoexplicativas

- Use sempre flags descritivas: `apt install --yes`, `dnf install --assumeyes`, `pkg install --yes`, `pacman -S --needed --noconfirm`.

### 9. Nomenclatura Semântica de Diretórios

- Coleções contáveis $\rightarrow$ PLURAL (`scripts/`, `docs/`, `fonts/`, `linters/`).
- Áreas de sistema & processos $\rightarrow$ SINGULAR (`system/`, `desktop/`, `server/`, `container/`, `security/`).
- Nomes próprios $\rightarrow$ CANÔNICO (`linux/`, `freebsd/`, `windows/`, `fedora/`, `arch/`, `debian/`).

### 10. Orçamento de Linhas (Regra 8 - 16 - 128 - 256)

- **Piso Rígido (Erro Fatal < 8 linhas):** Nenhum script isolado deve possuir menos de 8 linhas úteis. Scripts de 1 a 7 linhas são terminantemente proibidos como nano-scripts órfãos ou vazios, gerando erro fatal e bloqueio de commit no pre-commit e CI (`sys.exit(1)`).
- **Averiguação Inferior (Aviso <= 16 linhas):** Scripts com 8 a 16 linhas são sinalizados pelos auditores estáticos como candidatos à averiguação e consolidação temática em seus respectivos módulos, evitando fragmentação excessiva.
- **Faixa Canônica (Sweet Spot 17 a 128 linhas):** Faixa de equilíbrio arquitetural ideal entre granularidade atômica, legibilidade UNIX e manutenibilidade Clean Code.
- **Averiguação Superior (Aviso 129 a 255 linhas):** Scripts com 129 a 255 linhas são sinalizados pelos auditores estáticos como candidatos à averiguação e modularização.
- **Teto Rígido (Erro Fatal > 256 linhas):** Nenhum script deve ultrapassar 256 linhas úteis (monólito inaceitável), gerando erro fatal e bloqueio de commit no pre-commit e CI (`sys.exit(1)`), salvo exceções técnicas raras devidamente documentadas na Whitelist dos auditores com justificativa explícita.

### 11. Execução pelo Shell Ativo (_Active Shell Invocation_)

- Funções utilitárias do terminal e rotinas interativas (como `reinstall-shell`, `bench-shell`, `install.sh`) NUNCA devem invocar `sh <script>` de forma cega.
- Em distribuições Linux baseadas em Debian e Ubuntu, `/bin/sh` aponta para o interpretador `dash`, cuja BNF estrita rejeita nomes em `kebab-case` (`-`) em funções (`update-all`, `reinstall-shell`, etc.).
- A execução de sub-rotinas interativas DEVE sempre delegar para o shell ativo em execução seguindo a ordem canônica de preferência: `command -v "$(_detect_shell)" || command -v zsh || command -v bash || command -v sh`. No FreeBSD, o `/bin/sh` permanece como fallback leve de sistema. Scripts instaladores devem conter guards de auto-elevação para o shell interativo suportado do usuário.

### 12. Nomenclatura Kebab-Case para Funções de Shell

- Todas as funções utilitárias do motor interativo (`Shell`) adotam estritamente a convenção **kebab-case** (`reinstall-shell`, `update-editors`, `update-git`, `open-neovim`).
- O interpretador `dash` é formalmente descartado como shell interativo por incompatibilidade com essa convenção, focando a experiência do usuário nos shells suportados (`bash`, `zsh` e FreeBSD `/bin/sh`).
