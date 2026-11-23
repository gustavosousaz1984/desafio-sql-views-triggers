-- ============================================================
--  PARTE 1 — Personalizando acessos com VIEWS
--  Desafio DIO · SQL Database Specialist
--  Arquivo 2/3 — Criação das 5 VIEWS
-- ============================================================
--  Uma VIEW é uma "tabela virtual" armazenada no banco. Não
--  guarda dados próprios — guarda a QUERY. Isso permite:
--    · simplificar consultas complexas
--    · controlar ACESSO por usuário (permissão em cima da view)
--
--  Cada view abaixo responde a 1 dos cenários do desafio.
-- ============================================================

USE company;


-- ------------------------------------------------------------
-- VIEW 1 — Número de empregados por departamento e localidade
-- Cenário: "Número de empregados por departamento e localidade"
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_empregados_por_departamento_localidade AS
SELECT
    d.numero                          AS numero_departamento,
    d.nome                            AS departamento,
    ld.localizacao                    AS localidade,
    COUNT(f.ssn)                      AS total_empregados
FROM departamento d
LEFT JOIN localizacao_departamento ld
       ON ld.numero_departamento = d.numero
LEFT JOIN funcionario f
       ON f.numero_departamento = d.numero
GROUP BY d.numero, d.nome, ld.localizacao;


-- ------------------------------------------------------------
-- VIEW 2 — Lista de departamentos e seus gerentes
-- Cenário: "Lista de departamentos e seus gerentes"
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_departamentos_e_gerentes AS
SELECT
    d.numero                          AS numero_departamento,
    d.nome                            AS departamento,
    CONCAT(f.primeiro_nome, ' ',
           COALESCE(CONCAT(f.nome_meio, ' '), ''),
           f.ultimo_nome)             AS gerente,
    f.ssn                             AS ssn_gerente,
    d.data_inicio_gerente             AS inicio_gestao
FROM departamento d
LEFT JOIN funcionario f
       ON f.ssn = d.gerente_ssn;


-- ------------------------------------------------------------
-- VIEW 3 — Projetos com maior número de empregados (ORDER DESC)
-- Cenário: "Projetos com maior número de empregados
--           (ex: por ordenação desc)"
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_projetos_por_numero_empregados AS
SELECT
    p.numero                          AS numero_projeto,
    p.nome                            AS projeto,
    d.nome                            AS departamento,
    COUNT(t.ssn_funcionario)          AS total_empregados,
    SUM(t.horas)                      AS total_horas
FROM projeto p
INNER JOIN departamento d
        ON d.numero = p.numero_departamento
LEFT  JOIN trabalha_em t
        ON t.numero_projeto = p.numero
GROUP BY p.numero, p.nome, d.nome
ORDER BY total_empregados DESC, total_horas DESC;


-- ------------------------------------------------------------
-- VIEW 4 — Lista de projetos, departamentos e gerentes
-- Cenário: "Lista de projetos, departamentos e gerentes"
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_projetos_departamentos_gerentes AS
SELECT
    p.numero                          AS numero_projeto,
    p.nome                            AS projeto,
    p.localizacao                     AS localidade_projeto,
    d.numero                          AS numero_departamento,
    d.nome                            AS departamento,
    CONCAT(g.primeiro_nome, ' ',
           COALESCE(CONCAT(g.nome_meio, ' '), ''),
           g.ultimo_nome)             AS gerente_departamento
FROM projeto p
INNER JOIN departamento d
        ON d.numero = p.numero_departamento
LEFT  JOIN funcionario g
        ON g.ssn = d.gerente_ssn;


-- ------------------------------------------------------------
-- VIEW 5 — Empregados com dependentes + se são gerentes
-- Cenário: "Quais empregados possuem dependentes e se são gerentes"
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_empregados_dependentes_e_gerentes AS
SELECT
    f.ssn,
    CONCAT(f.primeiro_nome, ' ',
           COALESCE(CONCAT(f.nome_meio, ' '), ''),
           f.ultimo_nome)             AS empregado,
    d.nome                            AS departamento,
    COUNT(dep.nome_dependente)        AS total_dependentes,
    CASE
        WHEN EXISTS (SELECT 1
                       FROM departamento dp
                      WHERE dp.gerente_ssn = f.ssn)
        THEN 'Sim'
        ELSE 'Não'
    END                               AS e_gerente
FROM funcionario f
INNER JOIN departamento d
        ON d.numero = f.numero_departamento
LEFT  JOIN dependente dep
        ON dep.ssn_funcionario = f.ssn
GROUP BY f.ssn, empregado, d.nome
HAVING COUNT(dep.nome_dependente) > 0
ORDER BY e_gerente DESC, total_dependentes DESC;


-- ============================================================
--  CONSULTAS DE TESTE — veja cada view em ação
-- ============================================================
SELECT * FROM vw_empregados_por_departamento_localidade;
SELECT * FROM vw_departamentos_e_gerentes;
SELECT * FROM vw_projetos_por_numero_empregados;
SELECT * FROM vw_projetos_departamentos_gerentes;
SELECT * FROM vw_empregados_dependentes_e_gerentes;
