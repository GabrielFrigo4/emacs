---
description: Regra canônica com os 22 princípios soberanos de engenharia e diretrizes operacionais.
globs: "**/*"
always_on: true
---

# 📜 Princípios Soberanos de Engenharia & Diretrizes Canônicas

Todo trabalho de engenharia e desenvolvimento neste repositório obedece rigorosamente aos 22 Princípios de Engenharia (17 Princípios UNIX de Eric S. Raymond + 5 Regras de Soberania & Antifragilidade).

## 🏛️ Os 22 Princípios de Design

1. **Modularidade:** Partes simples conectadas por interfaces limpas.
2. **Clareza:** Clareza é melhor que esperteza; legibilidade sobre truques crípticos.
3. **Composição:** Projete programas para serem conectados a outros programas.
4. **Separação:** Separe política do mecanismo; separe o motor da interface.
5. **Simplicidade:** Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário.
6. **Parcimônia:** Escreva código grande apenas quando demonstrado que nada menor resolverá.
7. **Transparência:** Projete para visibilidade facilitando inspeção e auditoria.
8. **Robustez:** Robustez advém da simplicidade e da validação defensiva de invariantes.
9. **Representação:** Dobre conhecimento em dados/estruturas antes de espalhar lógica condicional.
10. **Menor Espanto:** Siga sempre as convenções canônicas menos surpreendentes da plataforma.
11. **Silêncio:** Programas devem executar quietos no sucesso, reportando apenas falhas reais.
12. **Reparo:** Falhe ruidosamente e o mais rápido possível (fail-fast).
13. **Economia:** Economize o tempo humano de engenharia em preferência ao tempo de máquina.
14. **Geração:** Evite código mecânico e repetitivo; automatize scaffolds e templates.
15. **Otimização:** Meça antes de otimizar; nunca sacrifique clareza por micro-otimizações precoces.
16. **Diversidade:** Desconfie de visões absolutistas; forneça interoperabilidade e portabilidade.
17. **Extensibilidade:** Projete para o futuro reconhecendo que os requisitos irão evoluir.
18. **Soberania do Usuário:** Infraestrutura e dados pertencem ao criador; repatrie dependências de nuvem e serviços proprietários.
19. **Autonomia Reentrante:** Toda operação deve ser idempotente, auto-recuperável e executável repetidamente sem efeitos colaterais.
20. **Hermetismo de Produção:** Deleção de `.agents/` e governança de IA não interfere em nenhum artefato de build ou execução de produção (`rm -rf .agents`).
21. **Desacoplamento Dev-Hub:** O código canônico reside na bancada de desenvolvimento; instalações em produção são atualizadas via pull limpo.
22. **Antifragilidade & Resiliência Ativa:** O sistema se fortalece sob estresse e perturbação com auto-cura em tempo de voo e fallback dinâmico em cascata.

## 🎯 Invariantes Operacionais

- **Makefile Silencioso:** Todo repositório possui `Makefile` POSIX `.SILENT:` com help colorido interativo (`make help`).
- **Githooks Autônomos:** Pre-commit e commit-msg em POSIX `sh` sem dependências globais externas.
- **Permissões Canônicas:** `chmod 0755` para `.githooks/*` e scripts/entrypoints executáveis iniciados com shebang `#!`; `chmod 0644` para bibliotecas `sourced`, arquivos de configuração, código-fonte e documentação.
