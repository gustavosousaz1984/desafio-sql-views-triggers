-- ============================================================
--  PARTE 1 — Personalizando acessos com VIEWS
--  Desafio DIO · SQL Database Specialist
--  Arquivo 1/3 — Esquema COMPANY completo + dados de teste
-- ============================================================
--  Diferente do desafio anterior (só 3 tabelas), as 5 views
--  exigem também PROJETOS, DEPENDENTES e a relação de
--  trabalho (trabalha_em). Aqui está o modelo completo.
--
--  Observação sobre a dependência CÍCLICA:
--  departamento.gerente_ssn → funcionario.ssn
--  funcionario.numero_departamento → departamento.numero
--  Resolvido criando as tabelas e adicionando a FK do gerente
--  via ALTER TABLE no final (após popular os dados).
-- ============================================================

CREATE DATABASE IF NOT EXISTS company
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE company;

-- ------------------------------------------------------------
-- DEPARTAMENTO  (a FK de gerente_ssn é adicionada no final)
-- ------------------------------------------------------------
CREATE TABLE departamento (
  numero              INT          NOT NULL,
  nome                VARCHAR(40)  NOT NULL,
  gerente_ssn         CHAR(11),            -- FK adicionada via ALTER (cíclica)
  data_inicio_gerente DATE,
  PRIMARY KEY (numero),
  UNIQUE KEY uk_departamento_nome (nome)
) ENGINE=InnoDB COMMENT='Departamentos da empresa';

-- ------------------------------------------------------------
-- LOCALIZACAO_DEPARTAMENTO (N:N → tabela associativa)
-- ------------------------------------------------------------
CREATE TABLE localizacao_departamento (
  numero_departamento INT         NOT NULL,
  localizacao         VARCHAR(40) NOT NULL,
  PRIMARY KEY (numero_departamento, localizacao),
  CONSTRAINT fk_locdep_departamento
    FOREIGN KEY (numero_departamento) REFERENCES departamento (numero)
) ENGINE=InnoDB COMMENT='Cidades de atuação dos departamentos';

-- ------------------------------------------------------------
-- FUNCIONARIO
-- ------------------------------------------------------------
CREATE TABLE funcionario (
  ssn                CHAR(11)     NOT NULL,
  primeiro_nome       VARCHAR(20)  NOT NULL,
  nome_meio          CHAR(1),
  ultimo_nome         VARCHAR(20)  NOT NULL,
  data_nascimento     DATE,
  endereco            VARCHAR(60),
  sexo                CHAR(1),
  salario             DECIMAL(10,2),
  salario_base        DECIMAL(10,2),       -- usado no contexto do desafio
  super_ssn           CHAR(11),            -- chefia (auto-referência)
  numero_departamento INT          NOT NULL,
  PRIMARY KEY (ssn),
  CONSTRAINT fk_func_departamento
    FOREIGN KEY (numero_departamento) REFERENCES departamento (numero),
  CONSTRAINT fk_func_superior
    FOREIGN KEY (super_ssn) REFERENCES funcionario (ssn)
) ENGINE=InnoDB COMMENT='Funcionários da empresa';

-- ------------------------------------------------------------
-- PROJETO
-- ------------------------------------------------------------
CREATE TABLE projeto (
  numero             INT         NOT NULL,
  nome               VARCHAR(40) NOT NULL,
  localizacao        VARCHAR(40),
  numero_departamento INT        NOT NULL,
  PRIMARY KEY (numero),
  UNIQUE KEY uk_projeto_nome (nome),
  CONSTRAINT fk_projeto_departamento
    FOREIGN KEY (numero_departamento) REFERENCES departamento (numero)
) ENGINE=InnoDB COMMENT='Projetos da empresa';

-- ------------------------------------------------------------
-- TRABALHA_EM (N:N funcionário ↔ projeto)
-- ------------------------------------------------------------
CREATE TABLE trabalha_em (
  ssn_funcionario CHAR(11)     NOT NULL,
  numero_projeto  INT          NOT NULL,
  horas           DECIMAL(4,1) NOT NULL DEFAULT 0.0,
  PRIMARY KEY (ssn_funcionario, numero_projeto),
  CONSTRAINT fk_trab_funcionario
    FOREIGN KEY (ssn_funcionario) REFERENCES funcionario (ssn),
  CONSTRAINT fk_trab_projeto
    FOREIGN KEY (numero_projeto) REFERENCES projeto (numero)
) ENGINE=InnoDB COMMENT='Alocação de empregados nos projetos';

-- ------------------------------------------------------------
-- DEPENDENTE (1:N funcionário → dependentes)
-- ------------------------------------------------------------
CREATE TABLE dependente (
  ssn_funcionario   CHAR(11)    NOT NULL,
  nome_dependente   VARCHAR(20) NOT NULL,
  sexo              CHAR(1),
  data_nascimento   DATE,
  parentesco        VARCHAR(20),
  PRIMARY KEY (ssn_funcionario, nome_dependente),
  CONSTRAINT fk_dep_funcionario
    FOREIGN KEY (ssn_funcionario) REFERENCES funcionario (ssn)
) ENGINE=InnoDB COMMENT='Dependentes dos funcionários';


-- ============================================================
--  DADOS DE TESTE
-- ============================================================

-- Departamentos (gerente_ssn ainda NULL — será preenchido depois)
INSERT INTO departamento (numero, nome, gerente_ssn, data_inicio_gerente) VALUES
  (1, 'Pesquisa',      NULL, '2020-01-15'),
  (2, 'Administração', NULL, '2019-06-01'),
  (3, 'Direção',       NULL, '2018-03-10');

-- Localizações
INSERT INTO localizacao_departamento (numero_departamento, localizacao) VALUES
  (1, 'São Paulo'),
  (1, 'Rio de Janeiro'),
  (2, 'São Paulo'),
  (2, 'Maceió'),
  (3, 'Maceió');

-- Funcionários (12 no total)
--   Departamento 1 (Pesquisa)      → 6
--   Departamento 2 (Administração) → 4
--   Departamento 3 (Direção)       → 2
INSERT INTO funcionario
  (ssn, primeiro_nome, nome_meio, ultimo_nome, data_nascimento, endereco, sexo,
   salario, salario_base, super_ssn, numero_departamento)
VALUES
  -- Chefias (super_ssn NULL) — serão os gerentes
  ('12345678901', 'Ana',     'L', 'Silva',    '1980-05-10', 'Rua A, 100',   'F', 15000.00, 15000.00, NULL,          1),
  ('98765432109', 'Bruno',   'M', 'Costa',    '1978-11-22', 'Rua B, 200',   'M', 14000.00, 14000.00, NULL,          2),
  ('45612378945', 'Carla',   'P', 'Dias',     '1975-02-28', 'Rua C, 300',   'F', 16000.00, 16000.00, NULL,          3),
  -- Departamento 1 — Pesquisa
  ('11122233344', 'Diego',   'R', 'Souza',    '1990-07-14', 'Rua D, 400',   'M',  8000.00,  8000.00, '12345678901', 1),
  ('22233344455', 'Elena',   'T', 'Martins',  '1992-09-08', 'Rua E, 500',   'F',  7500.00,  7500.00, '12345678901', 1),
  ('33344455566', 'Felipe',  'G', 'Oliveira', '1988-12-01', 'Rua F, 600',   'M',  8200.00,  8200.00, '12345678901', 1),
  ('44455566677', 'Gabriela','H', 'Lima',     '1993-03-19', 'Rua G, 700',   'F',  7000.00,  7000.00, '12345678901', 1),
  ('55566677788', 'Henrique','J', 'Pereira',  '1991-06-25', 'Rua H, 800',   'M',  7800.00,  7800.00, '12345678901', 1),
  -- Departamento 2 — Administração
  ('66677788899', 'Isabela', 'K', 'Rocha',    '1989-08-30', 'Rua I, 900',   'F',  9000.00,  9000.00, '98765432109', 2),
  ('77788899900', 'João',    'N', 'Alves',    '1985-04-17', 'Rua J, 1000',  'M',  9500.00,  9500.00, '98765432109', 2),
  ('88899900011', 'Karina',  'B', 'Fernandes','1994-01-05', 'Rua K, 1100',  'F',  8500.00,  8500.00, '98765432109', 2),
  -- Departamento 3 — Direção
  ('99900011122', 'Lucas',   'C', 'Mendes',   '1983-10-11', 'Rua L, 1200',  'M', 12000.00, 12000.00, '45612378945', 3);

-- Agora que funcionários existem, definimos os gerentes
UPDATE departamento SET gerente_ssn = '12345678901' WHERE numero = 1; -- Ana
UPDATE departamento SET gerente_ssn = '98765432109' WHERE numero = 2; -- Bruno
UPDATE departamento SET gerente_ssn = '45612378945' WHERE numero = 3; -- Carla

-- Projetos
INSERT INTO projeto (numero, nome, localizacao, numero_departamento) VALUES
  (100, 'Software X',  'São Paulo',      1),
  (200, 'Sistema Y',   'Rio de Janeiro', 1),
  (300, 'App Mobile',  'São Paulo',      2),
  (400, 'BI Analytics','Maceió',         3);

-- Alocação de empregados nos projetos (Proj 100 = mais gente)
INSERT INTO trabalha_em (ssn_funcionario, numero_projeto, horas) VALUES
  -- Projeto 100 → 5 empregados (maior)
  ('12345678901', 100, 20.0),
  ('11122233344', 100, 30.0),
  ('22233344455', 100, 25.0),
  ('33344455566', 100, 30.0),
  ('44455566677', 100, 20.0),
  -- Projeto 200 → 2 empregados
  ('11122233344', 200, 10.0),
  ('55566677788', 200, 15.0),
  -- Projeto 300 → 3 empregados
  ('98765432109', 300, 20.0),
  ('66677788899', 300, 30.0),
  ('77788899900', 300, 25.0),
  -- Projeto 400 → 2 empregados
  ('45612378945', 400, 15.0),
  ('99900011122', 400, 30.0);

-- Dependentes (nem todo mundo tem)
INSERT INTO dependente (ssn_funcionario, nome_dependente, sexo, data_nascimento, parentesco) VALUES
  ('12345678901', 'Pedro',   'M', '2012-03-15', 'Filho'),
  ('12345678901', 'Paula',   'F', '2015-07-22', 'Filha'),
  ('98765432109', 'Rafael',  'M', '2010-11-03', 'Filho'),
  ('45612378945', 'Beatriz', 'F', '2011-05-19', 'Filha'),
  ('11122233344', 'Sofia',   'F', '2018-01-30', 'Filha'),
  ('11122233344', 'Thiago',  'M', '2020-09-12', 'Filho'),
  ('66677788899', 'Laura',   'F', '2016-04-08', 'Filha');


-- ============================================================
--  Adiciona a FK CÍCLICA do gerente (após os dados existirem)
-- ============================================================
ALTER TABLE departamento
  ADD CONSTRAINT fk_departamento_gerente
  FOREIGN KEY (gerente_ssn) REFERENCES funcionario (ssn);
