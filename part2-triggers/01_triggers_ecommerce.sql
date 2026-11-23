-- ============================================================
--  PARTE 2 — Criando GATILHOS (TRIGGERS) para e-commerce
--  Desafio DIO · SQL Database Specialist
--  Arquivo único — tabelas + triggers + testes
-- ============================================================
--
--  GATILHO = código que executa AUTOMATICAMENTE antes ou
--  depois de um INSERT / UPDATE / DELETE.
--
--  ENTREGÁVEIS DESTE DESAFIO:
--   ✔ Trigger de REMOÇÃO    → BEFORE DELETE
--   ✔ Trigger de ATUALIZAÇÃO→ BEFORE UPDATE
--
--  CONTEXTOS PEDIDOS:
--   · Remoção: usuário exclui a conta → NÃO perder os dados,
--              movemos para uma tabela de arquivo (log).
--   · Atualização: alteração do SALÁRIO BASE de colaborador →
--              registramos a alteração em auditoria.
--
--  ⚠️ ATENÇÃO: sempre selecionar o BANCO antes de criar
--     a trigger (mesma regra das procedures).
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE ecommerce;   -- <<< banco selecionado antes das triggers


-- ============================================================
--  TABELAS
-- ============================================================

-- ------------------------------------------------------------
-- CLIENTE / USUÁRIO da loja
-- ------------------------------------------------------------
DROP TABLE IF EXISTS cliente;
CREATE TABLE cliente (
  id_cliente      INT          NOT NULL AUTO_INCREMENT,
  nome            VARCHAR(100) NOT NULL,
  email           VARCHAR(120) NOT NULL,
  data_cadastro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ativo           BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uq_cliente_email (email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABELA DE ARQUIVO (log) — recebe os clientes EXCLUÍDOS
-- É ela que garante "não perder as informações"
-- ------------------------------------------------------------
DROP TABLE IF EXISTS cliente_arquivo;
CREATE TABLE cliente_arquivo (
  id_arquivo      INT          NOT NULL AUTO_INCREMENT,
  id_cliente      INT          NOT NULL,
  nome            VARCHAR(100),
  email           VARCHAR(120),
  data_cadastro   DATETIME,
  data_exclusao   DATETIME     NOT NULL,
  motivo          VARCHAR(120),
  PRIMARY KEY (id_arquivo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- COLABORADOR (funcionário da loja) — tem salário base
-- ------------------------------------------------------------
DROP TABLE IF EXISTS colaborador;
CREATE TABLE colaborador (
  id_colaborador  INT           NOT NULL AUTO_INCREMENT,
  nome            VARCHAR(100)  NOT NULL,
  cargo           VARCHAR(60),
  salario_base    DECIMAL(10,2) NOT NULL,
  data_admissao   DATE,
  PRIMARY KEY (id_colaborador)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABELA DE AUDITORIA — registra mudanças de salário
-- ------------------------------------------------------------
DROP TABLE IF EXISTS salario_auditoria;
CREATE TABLE salario_auditoria (
  id_auditoria    INT           NOT NULL AUTO_INCREMENT,
  id_colaborador  INT           NOT NULL,
  nome            VARCHAR(100),
  salario_anterior DECIMAL(10,2),
  salario_novo    DECIMAL(10,2),
  percentual      DECIMAL(5,2),
  data_alteracao  DATETIME      NOT NULL,
  usuario         VARCHAR(100),
  PRIMARY KEY (id_auditoria)
) ENGINE=InnoDB;


-- ============================================================
--  DADOS DE TESTE
-- ============================================================
INSERT INTO cliente (nome, email, data_cadastro) VALUES
  ('João Pereira',   'joao@email.com',   '2025-01-10 10:00:00'),
  ('Maria Souza',    'maria@email.com',  '2025-02-15 11:30:00'),
  ('Carlos Lima',    'carlos@email.com', '2025-03-20 09:45:00');

INSERT INTO colaborador (nome, cargo, salario_base, data_admissao) VALUES
  ('Ana Silva',   'Vendedora',      2500.00, '2024-05-01'),
  ('Bruno Costa', 'Estoquista',     2800.00, '2023-08-15'),
  ('Carla Dias',  'Gerente de Loja',5500.00, '2022-01-10');


-- ============================================================
--  TRIGGER 1 — REMOÇÃO  (BEFORE DELETE)
-- ============================================================
--  Objetivo: quando um usuário apagar sua conta, os dados NÃO
--  se perdem — são copiados para cliente_arquivo ANTES da
--  exclusão acontecer.
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_cliente_before_delete
BEFORE DELETE ON cliente
FOR EACH ROW
BEGIN
  INSERT INTO cliente_arquivo
    (id_cliente, nome, email, data_cadastro, data_exclusao, motivo)
  VALUES
    (OLD.id_cliente, OLD.nome, OLD.email, OLD.data_cadastro, NOW(),
     'Exclusão solicitada pelo usuário');
END$$

DELIMITER ;


-- ============================================================
--  TRIGGER 2 — ATUALIZAÇÃO  (BEFORE UPDATE)
-- ============================================================
--  Objetivo: quando o SALÁRIO BASE de um colaborador mudar,
--  registra-se quem era o valor anterior, o novo e o
--  percentual — auditoria automática da alteração.
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_colaborador_before_update
BEFORE UPDATE ON colaborador
FOR EACH ROW
BEGIN
  -- Só audita se o salário realmente mudou
  IF NEW.salario_base <> OLD.salario_base THEN
    INSERT INTO salario_auditoria
      (id_colaborador, nome, salario_anterior, salario_novo,
       percentual, data_alteracao, usuario)
    VALUES
      (OLD.id_colaborador,
       OLD.nome,
       OLD.salario_base,
       NEW.salario_base,
       ROUND(((NEW.salario_base - OLD.salario_base) / OLD.salario_base) * 100, 2),
       NOW(),
       CURRENT_USER());
  END IF;
END$$

DELIMITER ;


-- ============================================================
--  TESTES — executar para verificar as triggers
-- ============================================================

-- ---------- TRIGGER DE REMOÇÃO (BEFORE DELETE) ----------
-- Estado inicial
SELECT 'ANTES da remoção' AS momento;
SELECT * FROM cliente;
SELECT * FROM cliente_arquivo;

-- Exclui o cliente id = 2 (Maria)
DELETE FROM cliente WHERE id_cliente = 2;

-- A trigger copiou os dados para o arquivo
SELECT 'DEPOIS da remoção' AS momento;
SELECT * FROM cliente;
SELECT * FROM cliente_arquivo;   -- Maria deve aparecer aqui


-- ---------- TRIGGER DE ATUALIZAÇÃO (BEFORE UPDATE) ----------
-- Estado inicial
SELECT 'ANTES da atualização' AS momento;
SELECT * FROM colaborador;
SELECT * FROM salario_auditoria;

-- Reajuste de salário da Ana (2500 → 3000) e da Carla (5500 → 6000)
UPDATE colaborador SET salario_base = 3000.00 WHERE id_colaborador = 1;
UPDATE colaborador SET salario_base = 6000.00 WHERE id_colaborador = 3;

-- Alterações SEM mexer em salário NÃO devem gerar auditoria
UPDATE colaborador SET cargo = 'Vendedora Sênior' WHERE id_colaborador = 1;

-- A trigger registrou cada mudança de salário
SELECT 'DEPOIS da atualização' AS momento;
SELECT * FROM colaborador;
SELECT * FROM salario_auditoria; -- Ana e Carla devem aparecer
