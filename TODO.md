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

- [ ] **Detecção dinâmica de hardware e display:** Identificar automaticamente Wayland (PGTK), X11, DirectWrite e aceleração gráfica.
- [ ] **Auto-detecção de compilação nativa:** Detectar presença de `libgccjit` e compilação AOT/JIT com chaveamento de flags.
- [ ] **Desacoplamento modular em `usr/local/`:** Isolar módulos e pacotes locais mantendo inicialização resiliente via `condition-case`.

### 2. 🔤 Tipografia Adaptativa & Engine de Fontes

- [ ] Adicionar suporte a DirectWrite BackEngine Font no Windows para renderização nítida de glifos.
- [ ] Configuração dinâmica de HarfBuzz e Fontconfig em Linux e FreeBSD.
- [ ] Fallback inteligente de fontes Nerd Fonts, símbolos e emojis.

### 3. 📬 Aplicações, Ecossistemas & Linguagens

- [ ] **Cliente de E-mail:** Integrar cliente de e-mail moderno (`mu4e`) com suporte a contas múltiplas.
- [ ] **Common Lisp & Elisp:** Atualizar e aprimorar ferramentas e REPLs interativos para desenvolvimento em Lisp.
- [ ] **Org-mode & Produtividade:** Refinar integração com agenda, capture templates e exportação de documentos.

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de engenharia, consulte o [PRINCIPLES.md](PRINCIPLES.md) e o [ENVIRONMENT.md](ENVIRONMENT.md).
