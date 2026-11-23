# 🔐 Desafio SQL — Views com Permissões e Triggers

Projeto do curso **SQL Database Specialist (DIO)** cobrindo duas competências essenciais de SGBD:

- **Parte 1 — Views e Permissões:** criação de visões para cenários analíticos e controle de acesso por tipo de usuário (gerente × empregado).
- **Parte 2 — Triggers:** gatilhos `BEFORE DELETE` e `BEFORE UPDATE` no cenário de e-commerce.

> **Autor:** Gustavo Sousa · [LinkedIn](https://www.linkedin.com/in/gustavosousaz/) · [GitHub](https://github.com/gustavosousaz1984)

---

## 📁 Estrutura do projeto

```
desafio-sql-views-triggers/
├── README.md                       ← este arquivo
├── part1-views/
│   ├── 01_company_schema.sql       ← esquema company completo + dados
│   ├── 02_views.sql                ← as 5 views do desafio
│   └── 03_permissions.sql          ← usuários + GRANT/REVOKE
└── part2-triggers/
    └── 01_triggers_ecommerce.sql   ← tabelas + triggers + testes
```

---

## ▶️ Como executar

MySQL 8.x — execute na ordem dentro do MySQL Workbench, DBeaver ou linha de comando:

**Parte 1 — Views e permissões**
```bash
mysql -u root -p < part1-views/01_company_schema.sql
mysql -u root -p < part1-views/02_views.sql
mysql -u root -p < part1-views/03_permissions.sql   # requer root
```

**Parte 2 — Triggers**
```bash
mysql -u root -p < part2-triggers/01_triggers_ecommerce.sql
```

> 📌 Cada script de objeto (triggers, procedures) **seleciona o banco (`USE`)** antes de criar — boa prática exigida nos desafios.

---

## 🔐 Parte 1 — Views e permissões

### O que é uma VIEW

Uma **view** é uma "tabela virtual" armazenada no banco como uma **query nomeada**. Ela não guarda dados próprios — guarda a consulta. Isso permite:
- simplificar consultas complexas
- **controlar o acesso** concedendo permissão (`GRANT`) em cima dela

### As 5 views criadas

| # | View | Cenário do desafio |
|---|---|---|
| 1 | `vw_empregados_por_departamento_localidade` | Número de empregados por departamento e localidade |
| 2 | `vw_departamentos_e_gerentes` | Lista de departamentos e seus gerentes |
| 3 | `vw_projetos_por_numero_empregados` | Projetos com maior número de empregados (ORDER DESC) |
| 4 | `vw_projetos_departamentos_gerentes` | Lista de projetos, departamentos e gerentes |
| 5 | `vw_empregados_dependentes_e_gerentes` | Empregados com dependentes e se são gerentes |

### Controle de acesso por usuário

| Usuário | Pode acessar | Não pode acessar |
|---|---|---|
| **`gerente`** | Todas as views + tabelas `funcionario` e `departamento` | — |
| **`empregado`** | `vw_empregados_dependentes_e_gerentes` + `funcionario` | ❌ Views de departamento/gerente |

**Regras aplicadas:**
- ✅ **Gerente** vê informações de empregado **e** departamento (inclui gerentes)
- ❌ **Empregado** **não** tem acesso a informações de departamento ou gerência — as views `vw_departamentos_e_gerentes`, `vw_projetos_departamentos_gerentes` e `vw_empregados_por_departamento_localidade` simplesmente **não foram concedidas** a ele

**Como o MySQL aplica:** sem `GRANT`, o usuário recebe erro `command denied`. A segurança é **por omissão negada** — só acessa o que foi concedido.

### Teste rápido

```bash
mysql -u gerente -p    # senha: SenhaG3r3nt3!
USE company;
SELECT * FROM vw_departamentos_e_gerentes;   -- ✅ funciona

mysql -u empregado -p  # senha: SenhaEmp123!
USE company;
SELECT * FROM vw_departamentos_e_gerentes;   -- ❌ Access denied
```

---

## ⚡ Parte 2 — Triggers (gatilhos)

### O que é uma TRIGGER

Um trecho de código que executa **automaticamente** antes ou depois de um `INSERT`/`UPDATE`/`DELETE`, para cada linha afetada (`FOR EACH ROW`).

### As 2 triggers do desafio

| Trigger | Tipo | Tabela | O que faz |
|---|---|---|---|
| `trg_cliente_before_delete` | **BEFORE DELETE** | `cliente` | Antes de excluir um usuário, copia seus dados para `cliente_arquivo` — **nada se perde** |
| `trg_colaborador_before_update` | **BEFORE UPDATE** | `colaborador` | Antes de alterar, se o **salário base** mudou, registra auditoria (valor anterior → novo + %) |

### Destaques técnicos

- **`OLD` vs `NEW`:** `OLD` = valor antes da operação; `NEW` = valor depois. A trigger de remoção usa `OLD` para arquivar; a de atualização compara `NEW.salario_base` com `OLD.salario_base`.
- **Condicional (`IF`):** a trigger de atualização só grava auditoria **se o salário realmente mudou** — mudar só o cargo não gera registro.
- **Funções úteis:** `NOW()` (data/hora), `CURRENT_USER()` (quem alterou), `ROUND()` (percentual).

### Fluxo da trigger de remoção

```
DELETE FROM cliente WHERE id_cliente = 2;
        │
        ▼  (BEFORE DELETE dispara)
INSERT INTO cliente_arquivo (...) VALUES (OLD...., NOW(), ...)
        │
        ▼
linha removida de `cliente`
```

---

## 🛠️ Tecnologias

- **MySQL 8.x** (SGBD)
- **MySQL Workbench / DBeaver** (cliente)
- **SQL** — DDL (views, usuários, GRANT), DML, triggers
- **Git / GitHub** (versionamento)

---

## 📚 O que este projeto demonstra

| Competência | Aplicação |
|---|---|
| **Modelagem analítica** | Transformar queries complexas em views reutilizáveis |
| **Segurança e permissões** | Criar usuários e aplicar princípio do menor privilégio com `GRANT` |
| **Automatização** | Triggers `BEFORE DELETE` e `BEFORE UPDATE` com lógica condicional |
| **Auditoria e rastreio** | Preservação de dados excluídos + log de alterações salariais |
| **Boas práticas** | `USE` antes de criar objetos; comentar cada decisão |
