# 🗺️ Roadmap & Backlog

> Planejamento estratégico, status operacional e visão de futuro para a evolução da configuração do **GNU Emacs**.

---

## 📊 Status do Projeto

| Área                                 |   Status   | Cobertura / Estado                                             |
| :----------------------------------- | :--------: | :------------------------------------------------------------- |
| **🔮 GNU Emacs Core (30+)**          | 🟢 Estável | Baseline 30.1+ com Tree-sitter nativo e compilação `libgccjit` |
| **🌳 Native Tree-sitter (ABI ≥ 14)** | 🟢 Estável | Suporte a gramáticas modernas sem wrappers externos            |
| **📦 Gerenciador Elpaca**            | 🟢 Estável | Gestão assíncrona, declarativa e paralela de pacotes           |
| **⚡ Eglot LSP Integrado**           | 🟢 Estável | Protocolo LSP de alto desempenho no core sem bloat             |
| **🎨 Visual & Temas**                | 🟢 Estável | Tema escuro, modeline limpa e renderização minimalista         |
| **🧪 Boot Headless & Batch Mode**    |  🟢 100%   | Inicialização sem falhas sob `emacs --batch` no CI             |

---

## 🎯 Grandes Épicos & Backlog

### 1. 🏛️ Arquitetura Modular & Auto-Detecção Sensorial

- [x] **Detecção dinâmica de hardware e display:** Identificar automaticamente Wayland (PGTK), X11, DirectWrite e aceleração gráfica.
- [x] **Auto-detecção de compilação nativa:** Detectar presença de `libgccjit` e compilação AOT/JIT com chaveamento de flags.
- [x] **Desacoplamento modular com `condition-case`:** Isolar módulos e pacotes locais mantendo inicialização resiliente.

### 2. 🔤 Tipografia Adaptativa & Engine de Fontes

- [x] Adicionar suporte a DirectWrite BackEngine Font no Windows para renderização nítida de glifos.
- [x] Configuração dinâmica de HarfBuzz e Fontconfig em Linux e FreeBSD.
- [x] Fallback inteligente de fontes Nerd Fonts, símbolos e emojis.

### 3. 📬 Aplicações, Ecossistemas & Linguagens

- [ ] **Cliente de E-mail:** Integrar cliente de e-mail moderno (`mu4e`) com suporte a contas múltiplas.
- [ ] **Common Lisp & Elisp:** Atualizar e aprimorar ferramentas e REPLs interativos para desenvolvimento em Lisp.
- [ ] **Org-mode & Produtividade:** Refinar integração com agenda, capture templates e exportação de documentos.

### 4. 🤖 Integração de IA Local (Ollama & LLMs)

- [x] **Modernização dos modelos Ollama no `gptel`:** Atualizado exclusivamente com `gemma4:e2b` e `gemma4:e4b`.
- [x] **Detecção automática do Ollama:** Implementado `ollama-detect-p` com probe TCP e degradação graciosa.
- [ ] **Explorar `el-llm` e backends alternativos:** Avaliar integração com pacote `llm` para unificação de providers locais.
- [ ] **Integração com `org-ai` via Ollama:** Configurar `org-ai` para usar modelos locais como fallback quando APIs cloud estiverem indisponíveis.

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de engenharia, consulte o [PRINCIPLES.md](PRINCIPLES.md) e o [ENVIRONMENT.md](ENVIRONMENT.md).
