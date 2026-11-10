# 📜 Princípios de Engenharia & Filosofia de Software

> _"Rule of Separation: Separate policy from mechanism; separate engine from interface."_<br>
> — Eric S. Raymond, _The Art of UNIX Programming_ (2003)

Sistemas computacionais de excelência são sustentados por simplicidade formal, transparência operacional e modularidade rigorosa. Este documento estabelece a constituição técnica universal que rege o desenvolvimento de software, bibliotecas, compiladores, automação e arquitetura de sistemas em qualquer linguagem de programação (C, C++, Rust, Go, Python, Elisp, TypeScript, Shell, Assembly) e domínio.

Para assegurar longevidade, determinismo, idempotência e soberania técnica, todo projeto deve obedecer estritamente aos **22 Princípios Canônicos de Design** (17 Regras UNIX formuladas por Eric S. Raymond acrescidas de 5 Invariantes Soberanas contemporâneas) e às diretrizes fundamentais de **Clean Code, Determinismo e Governança**.

---

## 🏛️ Os 22 Princípios Canônicos de Design (17 Regras UNIX + 5 Invariantes Soberanas)

### 1. Regra da Modularidade (_Rule of Modularity_)

> _Escreva partes simples conectadas por interfaces limpas._

- Sistemas complexos devem ser decompostos em módulos atômicos, ortogonais e desacoplados, minimizando dependências transversais.
- Cada componente deve expor contratos bem definidos e encapsular seu estado interno, permitindo substituição, teste isolado e evolução independente sem efeitos colaterais.

### 2. Regra da Clareza (_Rule of Clarity_)

> _Clareza é melhor que esperteza._

- O código-fonte é lido infinitamente mais vezes do que é escrito. A legibilidade e a inteligibilidade direta superam truques sintáticos, atalhos crípticos ou abstrações obscuras.
- Nomes de funções, tipos, variáveis e constantes devem comunicar intenção inequívoca, dispensando parafraseamento explicativo.

### 3. Regra da Composição (_Rule of Composition_)

> _Projete programas para serem conectados a outros programas._

- Ferramentas e rotinas devem aderir ao modelo universal de I/O em fluxo contínuo (pipes e fluxos de dados tipados ou textuais).
- Interfaces devem aceitar fluxos padrão e emitir saídas previsíveis, facilitando encadeamento, reentrância e automação em pipelines de maior escala.

### 4. Regra da Separação (_Rule of Separation_)

> _Separe a política do mecanismo; separe o motor da interface._

- **Mecanismo:** O núcleo algorítmico, o motor de execução e as rotinas fundamentais que realizam o trabalho computacional bruto.
- **Política:** As configurações declarativas, parâmetros operacionais e regras de negócio que ditam _como_ e _onde_ o mecanismo opera. Mecanismos estáveis toleram mudanças contínuas de política sem requerer recompilação ou refatoração estrutural.

### 5. Regra da Simplicidade (_Rule of Simplicity_)

> _Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário._

- A complexidade é um débito técnico intrínseco que cobra juros em manutenção, segurança e depurabilidade.
- Evite generalizações especulativas, metaprogramação desnecessária e camadas arquiteturais supérfluas. A solução mais simples que satisfaz integralmente os requisitos é a superior.

### 6. Regra da Parcimônia (_Rule of Parsimony_)

> _Escreva um programa grande apenas quando estiver claro por demonstração que nada mais resolverá._

- Reutilize abstrações canônicas de sistema, primitivas nativas e recursos padronizados da plataforma antes de construir novas bibliotecas ou utilitários monolíticos.
- Se uma primitiva existente de sistema operacional ou biblioteca padrão resolve o problema de modo determinístico, rejeite wrappers redundantes.

### 7. Regra da Transparência (_Rule of Transparency_)

> _Projete para a visibilidade para tornar inspeção e depuração fáceis._

- O estado interno do sistema e o fluxo de dados devem ser observáveis sem a necessidade de instrumentações intrusivas.
- Estruturas de dados claras, formatos de serialização auditáveis e logs estruturados em canais apropriados facilitam a depuração imediata por humanos e analisadores estáticos.

### 8. Regra da Robustez (_Rule of Robustness_)

> _A robustez é filha da transparência e da simplicidade._

- Sistemas robustos antecipam condições excepcionais, validam entradas nas fronteiras do sistema e mantêm invariantes estruturais mesmo sob cenários adversos.
- Falhas transitórias externas devem ser contidas por barreiras de isolamento, impedindo corrupção de memória, vazamento de recursos ou inconsistência de estado.

### 9. Regra da Representação (_Rule of Representation_)

> _Dobre o conhecimento em dados para que a lógica do programa possa ser estúpida e robusta._

- Estruturas de dados refinadas e modelos tabulares declarativos reduzem a necessidade de lógica procedural intrincada e fluxos condicionais ramificados.
- Mapeamentos estáticos, tabelas de símbolos e esquemas formais tornam os programas fáceis de validar, manter e expandir.

### 10. Regra do Menor Espanto (_Rule of Least Surprise_)

> _No design de interfaces, sempre faça a coisa menos surpreendente._

- Interfaces de programação (APIs), comandos de terminal e ferramentas de build devem respeitar as convenções históricas e comportamentos canônicos do domínio.
- Códigos de saída universais (`0` para êxito, diferente de zero para erro), convenções de sinalização POSIX e semântica idempotente asseguram previsibilidade total.

### 11. Regra do Silêncio (_Rule of Silence_)

> _Quando um programa não tem nada surpreendente a dizer, ele não deve dizer nada._

- Utilitários, scripts de build, geradores e transformadores devem operar em silêncio durante operações bem-sucedidas.
- Não polua `stdout` com mensagens de vaidade, banners ou status irrelevantes; preserve o fluxo padrão para dados consumíveis e direcione diagnósticos exclusivamente para `stderr`.

### 12. Regra do Reparo (_Rule of Repair_)

> _Quando você precisar falhar, falhe ruidosamente e o mais rápido possível._

- Falhas devem ser imediatas e explícitas (_fail-fast_). Nunca silencie exceções, erros de alocação ou códigos de retorno anômalos sem tratamento explícito.
- Interrompa a execução no ponto exato da anomalia com diagnóstico técnico preciso em vez de permitir que o programa continue em estado corrompido ou indeterminado.

### 13. Regra da Economia (_Rule of Economy_)

> _O tempo do programador é caro; economize-o em preferência ao tempo da máquina._

- Priorize determinismo de desenvolvimento, velocidade de depuração e interfaces ergonômicas sobre microotimizações prematuras que aumentem a carga cognitiva da engenharia.
- A automação de tarefas repetitivas, testes estáticos instantâneos e tooling determinístico preservam o recurso mais finito da engenharia: a atenção humana.

### 14. Regra da Geração (_Rule of Generation_)

> _Evite codificação manual; escreva programas para escrever programas quando puder._

- Automações declarativas, parsers gerados, geradores de código a partir de esquemas formais e templates estáticos reduzem o erro humano e garantem consistência estrutural.
- Prefira metaprogramação externa (geradores de código determinísticos) à metaprogramação dinâmica em tempo de execução que degrada a transparência operacional.

### 15. Regra da Otimização (_Rule of Optimization_)

> _Prototipe antes de polir. Faça funcionar antes de otimizar._

- A otimização prematura é a raiz de complexidades desnecessárias e vulnerabilidades latentes. Primeiro garanta a corretude formal, os testes unitários e a modularidade da solução.
- Otimize apenas gargalos identificados por instrumentos de perfilamento (_profilers_) empíricos e reproduzíveis sob cargas de trabalho reais.

### 16. Regra da Diversidade (_Rule of Diversity_)

> _Desconfie de todas as afirmações de "uma única maneira verdadeira"._

- A interoperabilidade exige flexibilidade de protocolos e abertura para múltiplos sistemas operacionais, arquiteturas de CPU e padrões de indústria.
- Projete programas para interoperar com diferentes ambientes computacionais sem fixações dogmáticas em uma única distribuição, biblioteca proprietária ou ecossistema fechado.

### 17. Regra da Extensibilidade (_Rule of Extensibility_)

> _Projete para o futuro, porque ele chegará antes do que você imagina._

- Projete interfaces e formatos de dados com capacidade de evolução retrocompatível.
- Use protocolos versionados, pontos de extensão desacoplados e esquemas com tolerância a campos futuros, permitindo crescimento orgânico sem quebras destrutivas.

### 18. Regra da Soberania do Usuário (_Rule of User Sovereignty_)

> _Honre a escolha explícita e deliberada do usuário antes de impor padrões genéricos._

- **Precedência Local sobre Global (Local > Global):** O escopo mais específico, intencional e local sempre prevalece sobre o genérico e global:
    1.  **Argumentos de Linha de Comando (CLI):** Flags e argumentos explícitos (`--config`, `--output`, `--verbose`).
    2.  **Variáveis de Ambiente Explícitas:** Configurações declaradas na sessão ativa (`$APP_CONFIG`, `$TARGET_DIR`).
    3.  **Contexto Local do Projeto:** Arquivos de configuração na raiz do repositório (`.config/`, `Makefile`, manifestos locais).
    4.  **Escopo do Usuário (`$HOME` / XDG):** Configurações canônicas de usuário (`~/.config/app/`, dotfiles pessoais).
    5.  **Escopo Global do Sistema:** Padrões do sistema operacional (`/etc/app/`, `/usr/local/etc/`).
- **Precedência em Runbooks e Instruções Operacionais:** Diretrizes locais de projeto (`.agents/skills/`, regras locais) têm soberania estrita sobre diretrizes globais do usuário ou ferramentas nativas do ambiente. O projeto define seu próprio contrato.
- **Respeito aos Privilégios e Escolhas:** Sistemas não devem modificar arquivos de usuário ou sobrescrever configurações preexistentes sem consentimento explícito.

### 19. Regra da Autonomia Reentrante & Sinergia Oportunística (_Rule of Reentrant Autonomy_)

> _Projete cada módulo para ser 100% autossuficiente e tolerante ao isolamento; conecte-o de forma silenciosa e oportuna quando seus pares estiverem presentes._

- **Cidadão de Primeira Classe Isolado:** Qualquer repositório, módulo ou utilitário deve poder ser clonado, compilado e operado de forma isolada, sem exigir a presença obrigatória de outros componentes do ecossistema. A ausência de módulos pares nunca deve gerar falhas, quebras de build ou avisos ruídosos.
- **Sinergia Oportunística Silenciosa:** Se um componente detectar a presença de módulos complementares no ambiente hospedeiro, ele se integra e ativa recursos estendidos de modo transparente e em silêncio.
- **Reentrância Idempotente:** Operações de inicialização, compilação ou sincronização devem ser repetíveis com segurança a qualquer momento, auto-curando o estado sem intervenção manual.

### 20. Regra do Hermetismo de Produção & Invariante `rm -rf .agents` (_Rule of Production Hermeticity_)

> _O software é construído para humanos e sistemas de produção; assistentes de automação cognitiva são sob demanda. Nenhum código de produção deve depender de ferramentas de IA._

- **A Invariante do Teste de Fogo (`rm -rf .agents`):** Qualquer repositório deve permitir que o diretório `.agents/` seja deletado sumariamente (`rm -rf .agents`) mantendo 100% de sua integridade operacional, capacidade de compilação, suítes de teste, automações de build e rotinas de deploy.
- **Zero Acoplamento de IA em Runtime:** Nenhum script executável de produção, binário, Makefile, hook de Git, pipeline de CI/CD ou módulo de biblioteca pode depender, invocar ou referenciar arquivos de assistentes ou diretórios de IA.
- **Natureza Cognitiva:** Runbooks e diretrizes cognitivas são artefatos consultivos para auxílio contextual, jamais bibliotecas de tempo de execução ou pré-requisitos de build.

### 21. Regra do Desacoplamento entre Bancada de Desenvolvimento e Runtime de Produção (_Rule of Sovereign Runtime Isolation_)

> _A bancada de ferramentas do artesão não deve ser soldada ao produto final; desenvolva no repositório, execute nos caminhos canônicos do sistema._

- **Isolamento entre Fonte e Runtime:** Repositórios de código-fonte são exclusivamente bancadas de desenvolvimento e versionamento. Nenhum arquivo dentro da árvore de desenvolvimento deve ser consumido diretamente por runtimes do sistema sem passar por etapas formais de instalação (`make install`, empacotamento ou deploy determinístico).
- **Invariante da Produção Imaculada (Zero-Dirty Invariant):** Ambientes de produção e instalações ativas devem permanecer íntegros e limpos. Não crie links simbólicos de dotfiles ou artefatos que apontem para pastas temporárias ou árvores de desenvolvimento em constante mutação.
- **Ciclo Obrigatório de Propagação:** O fluxo de entrega obedece a um pipeline estrito e auditável: validação local na bancada $\rightarrow$ integração e commit no controle de versão $\rightarrow$ deploy canônico em produção via gerenciador de pacotes, release ou automação soberana.

### 22. Regra da Antifragilidade & Auto-Cura Ativa (_Rule of Antifragility & Active Self-Healing_)

> _O que é frágil quebra com a mudança de caminho ou desordem de ambiente; o que é robusto apenas resiste estaticamente; o que é antifrágil auto-descobre, cura em tempo de voo e opera com excelência diante de relocação dinâmica e ausência de recursos._

- **Triângulo da Resiliência Sistêmica:**
    - _Frágil:_ Assume caminhos absolutos rígidos e configurações fixas; falha catastroficamente se um recurso for relocado ou uma variável estiver ausente.
    - _Robusto:_ Possui caminhos alternativos estáticos, mas paralisa diante de variações imprevistas do ambiente.
    - _Antifrágil:_ Descobre recursos ativamente através de cascatas defensivas de inspeção, auto-cura permissões e estados inconsistentes em tempo de execução e adapta-se à dinâmica do ambiente.
- **Cascata Ativa de Descoberta:** Resoluções de dependências, arquivos de configuração e executáveis devem consultar defensivamente:
    1.  Variáveis de ambiente explícitas da sessão ativa.
    2.  Parâmetros locais do diretório do projeto.
    3.  Padrões canônicos de usuário (especificações XDG ou equivalentes de plataforma).
    4.  Padrões canônicos do sistema operacional (FHS, `/etc`, `/usr/local`).
- **Auto-Cura Defensiva:** Sistemas devem auto-reparar permissões inseguras em arquivos sensíveis (ex: corrigindo credenciais privadas para `0600`), restabelecer diretórios essenciais inexistentes e contornar ausências transitórias sem abortos cegos.

---

## 🧼 Princípios Universais de Clean Code, Determinismo & Governança

### 1. Princípio da Responsabilidade Única (SRP) & Orçamento de Complexidade

- Cada módulo, arquivo, classe ou função deve possuir **uma única razão para mudar**. Funções operam em uma única tarefa com coesão absoluta.
- **Orçamento de Linhas e Complexidade:**
    - _Piso Rígido (< 8 linhas):_ Scripts ou rotinas atômicas com menos de 8 linhas devem ser avaliados para incorporação ao módulo pai, evitando dispersão excessiva.
    - _Faixa Canônica (16 a 128 linhas):_ Equilíbrio de legibilidade, granularidade e auditabilidade.
    - _Teto Rígido (> 256 linhas):_ Arquivos com mais de 256 linhas devem ser modularizados e decompostos em submódulos complementares, salvo casos justificados de tabelas estáticas de dados.

### 2. Idempotência Rigorosa & Determinismo de Build/Execução

- Executar qualquer processo de automação, build, teste ou provisionamento uma, duas ou múltiplas vezes consecutivas deve produzir exatamente o mesmo estado final estável, sem efeitos colaterais cumulativos, sem duplicações e sem falhas por recursos pré-existentes.
- Builds devem ser determinísticos: mesmos insumos de código e dependências devem gerar artefatos binários idênticos byte-a-byte, eliminando variações de carimbo temporal ou ordem não-determinística de filesystem.

### 3. Invariante Out-of-the-Box (Zero Manual Tweaks Post-Clone) & Permissões Octais Canônicas

- Repositórios clonados devem operar imediatamente sem requerer ajustes manuais pós-clone. Modos de permissão POSIX devem estar rigorosamente registrados no índice do Git:
    - `chmod 0755` para diretórios, scripts executáveis e ganchos de automação.
    - `chmod 0644` para arquivos de configuração, código-fonte e documentação.
    - `chmod 0700` / `chmod 0600` para diretórios e arquivos de segurança crítica e credenciais privadas.
- Scripts e utilitários devem aplicar auto-cura de permissões em tempo de execução caso clonados sob sistemas de arquivos que não preservam bits octais POSIX.

### 4. Taxonomia Tripartite de Comentários (Regra do Não-Vazamento)

O código adota estritamente três categorias formais de comentários, com banimento absoluto de narrativas óbvias:

1. **Comentários de Sistema (PERMITIDOS):** Instruções indispensáveis para o sistema operacional, compiladores, interpretadores e linters (ex.: shebangs `#!/usr/bin/env sh`, pragmas `#pragma once`, diretivas `;;; -*- lexical-binding: t -*-`, anotações de linters).
2. **Comentários Estruturais de 64/32 Colunas (PERMITIDOS):**
    - _Cabeçalho de Topo:_ Exclusivo para as linhas 2 a 4 do arquivo, delimitado por exatamente 64 hífens (`# ----------------------------------------------------------------`).
    - _Seções e Subseções Internas:_ Delimitadores internos usam estritamente réguas de 32 colunas (`### ================================` para seções primárias ou `### --------------------------------` para subseções), com títulos em LETRAS MAIÚSCULAS contidos no limite de 32 caracteres (sem parênteses ou colchetes). Em arquivos `.gitignore`, seções estruturais usam réguas de 64 sinais de igualdade (`# ================================================================`).
3. **Comentários Explicativos/Narrativos (PROIBIDOS):** É estritamente proibido inserir comentários que parafraseiem o código, expliquem lógica algorítmica óbvia ou atuem como muleta para código confuso. Esta proibição aplica-se a código-fonte, arquivos de configuração e **blocos de código dentro de arquivos Markdown**.

### 5. Autoexplicabilidade & Nomenclatura Semântica

- O design das funções, a tipagem e os nomes escolhidos devem tornar a leitura do código autoexplicativa.
- Nomenclatura de diretórios:
    - _Coleções contáveis:_ Plural (`scripts/`, `docs/`, `tests/`, `tools/`).
    - _Domínios e subsistemas:_ Singular (`system/`, `core/`, `network/`, `security/`).

### 6. Automação Portável & Makefiles POSIX Silenciosos

- Automações baseadas em `make` devem aderir ao padrão POSIX, garantindo execução uniforme em qualquer variante de Unix.
- Makefiles adotam cabeçalho padronizado com silenciamento global, dispensando `@` individual em cada comando:
    ```make
    .POSIX:
    .SILENT:
    MAKEFLAGS += --no-print-directory -s
    ```
- Sub-rotinas recursivas em subdiretórios devem isolar contexto em subshells: `(cd dir && $(MAKE))`.

### 7. Portabilidade POSIX em Scripts & Banimento de Octal em Escapes ANSI

- Scripts portáveis de automação utilizam interpretador POSIX `/bin/sh` com shebang universal `#!/usr/bin/env sh`.
- Bashismos (`[[ ]]`, `&>`, arrays, diretiva `source`) são banidos em scripts `/bin/sh`.
- **Banimento de Octais em Caracteres e Escapes ANSI:** Nunca utilize notação octal (`\033`, `\001`) para caracteres de escape de terminal. Utilize `$'\e'` ou notação hexadecimal (`\x1b`). A notação octal é reservada com exclusividade para permissões POSIX (`chmod 0755`, `chmod 0644`, `umask`).

### 8. Quoting Defensivo, Redirecionamentos Seguros & Elevação Antifrágil

- Variáveis e caminhos devem ser sistematicamente envolvidos por aspas duplas (`"$VAR"`, `"$PATH_DIR"`), prevenindo expansões acidentais e quebras por espaços em branco.
- Redirecionamentos devem proteger alvos com aspas duplas: `> "/dev/null" 2>&1`.
- Detecção e elevação de privilégios devem validar o identificador de usuário defensivamente, prevenindo falhas sob `set -e`:
    ```sh
    #!/usr/bin/env sh
    # ----------------------------------------------------------------
    # CANONICAL PRIVILEGE ELEVATION PATTERN
    # ----------------------------------------------------------------
    set -eu

    ELEVATE=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v doas > "/dev/null" 2>&1; then
            ELEVATE="doas"
        elif command -v sudo > "/dev/null" 2>&1; then
            ELEVATE="sudo"
        fi
    fi

    [ "$#" -ge 1 ] && shift 1
    ```
- Comandos `shift` sob `set -e` devem ser previamente protegidos com validação de parâmetros (`[ "$#" -ge N ] && shift N`), prevenindo o término fatal exigido pelo padrão POSIX para _special built-ins_.

### 9. Refatoração Sem Legado (Clean-Break / Zero-Cruft Invariant)

- A evolução de código deve ser limpa e direta. Ao renomear variáveis, comandos, funções ou caminhos, não mantenha shims transitórios, aliases obsoletos ou camadas de compatibilidade mortas.
- Refatorações devem ser atômicas, consistentes e definitivas (_clean break_), expurgando resíduos técnicos no próprio ciclo de modificação.

### 10. Simetria de Escopo & Não-Assimetria de Subgrupo na Documentação

- **Comportamento Universal Pertence à Camada do Grupo:** Se um comportamento, protocolo, capacidade ou invariante de segurança é compartilhado por todo um conjunto de componentes, ele deve ser documentado no nível de abstração do grupo (documento de arquitetura, especificação geral ou README raiz).
- **Proibição de Falsa Especialização:** É proibido rotular um submembro específico com uma propriedade universal do grupo como se fosse uma característica exclusiva dele, evitando criar falsas assimetrias e confusão arquitetural.
- **Especialização Legítima:** Um componente específico só deve documentar particularidades se implementar o comportamento de forma substancialmente especializada, aprofundada ou otimizada.
