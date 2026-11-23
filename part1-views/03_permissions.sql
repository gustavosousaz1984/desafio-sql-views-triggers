-- ============================================================
--  PARTE 1 — Personalizando acessos com VIEWS
--  Desafio DIO · SQL Database Specialist
--  Arquivo 3/3 — Usuários e PERMISSÕES de acesso às views
-- ============================================================
--
--  REGRAS DO DESAFIO:
--  · Usuário GERENTE  → acesso às informações de employee
--                       E de departamento (inclui gerentes).
--  · Usuário EMPREGADO → NÃO ter acesso às informações
--                       relacionadas a departamentos ou gerentes.
--
--  Como as views ficam armazenadas no banco (como "tabelas"),
--  damos permissão em cima delas usando GRANT/REVOKE.
--
--  ⚠️ Requer privilégio de ADMINISTRADOR (root) para criar
--     usuários e conceder permissões no MySQL.
-- ============================================================

USE company;

-- ------------------------------------------------------------
-- 1. CRIAÇÃO DOS USUÁRIOS
-- ------------------------------------------------------------
CREATE USER IF NOT EXISTS 'gerente'@'%'   IDENTIFIED BY 'SenhaG3r3nt3!';
CREATE USER IF NOT EXISTS 'empregado'@'%' IDENTIFIED BY 'SenhaEmp123!';


-- ------------------------------------------------------------
-- 2. PERMISSÕES DO GERENTE
--    Pode ver TUDO do cenário analítico: empregados,
--    departamentos, gerentes, projetos e dependentes.
-- ------------------------------------------------------------
GRANT SELECT ON company.vw_empregados_por_departamento_localidade TO 'gerente'@'%';
GRANT SELECT ON company.vw_departamentos_e_gerentes                TO 'gerente'@'%';
GRANT SELECT ON company.vw_projetos_por_numero_empregados          TO 'gerente'@'%';
GRANT SELECT ON company.vw_projetos_departamentos_gerentes         TO 'gerente'@'%';
GRANT SELECT ON company.vw_empregados_dependentes_e_gerentes       TO 'gerente'@'%';

-- O gerente também pode consultar as tabelas-base de
-- empregado e departamento (conforme o desafio).
GRANT SELECT ON company.funcionario   TO 'gerente'@'%';
GRANT SELECT ON company.departamento  TO 'gerente'@'%';


-- ------------------------------------------------------------
-- 3. PERMISSÕES DO EMPREGADO
--    Só informações de EMPREGADO — SEM departamento,
--    SEM gerente, SEM visão gerencial.
--
--    Vista permitida: apenas a de dependentes dos próprios
--    colegas empregados, que NÃO expõe dados de departamento
--    nem de gerência.
--
--    Views NEGADAS (não concedidas ao empregado):
--      ✗ vw_departamentos_e_gerentes
--      ✗ vw_projetos_departamentos_gerentes
--      ✗ vw_empregados_por_departamento_localidade
-- ------------------------------------------------------------
GRANT SELECT ON company.vw_empregados_dependentes_e_gerentes TO 'empregado'@'%';
GRANT SELECT ON company.funcionario                          TO 'empregado'@'%';

-- (nenhuma permissão sobre departamento ou views gerenciais)


-- ------------------------------------------------------------
-- 4. Garantir que as permissões sejam aplicadas
-- ------------------------------------------------------------
FLUSH PRIVILEGES;


-- ============================================================
--  CONSULTAS DE VERIFICAÇÃO
-- ============================================================

-- Mostra o que cada usuário pode acessar:
SHOW GRANTS FOR 'gerente'@'%';
SHOW GRANTS FOR 'empregado'@'%';


-- ============================================================
--  COMO TESTAR (depois de rodar este script)
-- ============================================================
-- 1. Conecte-se como GERENTE:
--      mysql -u gerente -p   (senha: SenhaG3r3nt3!)
--      USE company;
--      SELECT * FROM vw_departamentos_e_gerentes;        ✅ funciona
--
-- 2. Conecte-se como EMPREGADO:
--      mysql -u empregado -p (senha: SenhaEmp123!)
--      USE company;
--      SELECT * FROM vw_departamentos_e_gerentes;        ❌ negado
--      SELECT * FROM vw_empregados_dependentes_e_gerentes; ✅ funciona
-- ============================================================


-- ============================================================
--  LIMPEZA (opcional — para remover os usuários ao final do teste)
-- ============================================================
-- REVOKE SELECT ON company.* FROM 'gerente'@'%';
-- REVOKE SELECT ON company.* FROM 'empregado'@'%';
-- DROP USER 'gerente'@'%';
-- DROP USER 'empregado'@'%';
