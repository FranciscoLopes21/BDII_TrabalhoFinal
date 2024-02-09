-- Tabela users
CREATE TABLE IF NOT EXISTS public.users
(
    user_id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    apelido VARCHAR(255) NOT NULL,
    data_nascimento DATE NOT NULL,
    morada VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    tipo_user VARCHAR(255) NOT NULL
);

-- Tabela Fornecedores
CREATE TABLE IF NOT EXISTS public.fornecedores
(
    fornecedor_id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    morada VARCHAR(255) NOT NULL,
    contacto VARCHAR(9) NOT NULL,
    email VARCHAR(255) NOT NULL,
    estado VARCHAR(20) NOT NULL
);BDII-Grupo11

-- Tabela componentes
CREATE TABLE IF NOT EXISTS public.componentes
(
    componentes_id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    referencia VARCHAR(255) NOT NULL,
    quant INTEGER NOT NULL,
    stockminimo INTEGER NOT NULL,
    fornecedor_id INTEGER REFERENCES public.fornecedores(fornecedor_id),
    categoria VARCHAR(255) NOT NULL,
    preco MONEY NOT NULL,
    estado VARCHAR(20) NOT NULL
);

-- Tabela encomendas
CREATE TABLE IF NOT EXISTS public.encomendas
(
    id_encomenda SERIAL PRIMARY KEY,
    id_componente INTEGER REFERENCES public.componentes(componentes_id),
    id_fornecedor INTEGER REFERENCES public.fornecedores(fornecedor_id),
    quantidade INTEGER NOT NULL,
    preco_peca MONEY NOT NULL,
    preco_final MONEY NOT NULL,
    data_encomenda DATE NOT NULL,
    data_entrega DATE,
    estado VARCHAR(20) NOT NULL
);

-- Tabela guias de encomenda
CREATE TABLE IF NOT EXISTS public.guias_encomenda
(
    id_guia SERIAL PRIMARY KEY,
    id_encomenda INTEGER REFERENCES public.encomendas(id_encomenda),
    dados_json JSONB,
    data_criacao TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela Mão de obra
CREATE TABLE IF NOT EXISTS public.maoobra
(
    maoobra_id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    preco MONEY NOT NULL,
    estado VARCHAR(20) NOT NULL
);

-- Tabela equipamentos
CREATE TABLE IF NOT EXISTS public.equipamentos
(
    id_equipamentos SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    modelo VARCHAR(255) NOT NULL,
    quantidade INTEGER,
    stock INTEGER,
    precoun MONEY,
    preco MONEY,
    estado VARCHAR(20),
    disponivel BOOLEAN
);

-- Tabela equipamentos_componentes
CREATE TABLE IF NOT EXISTS public.equipamentos_componentes
(
    id SERIAL PRIMARY KEY,
    id_equipamento INTEGER REFERENCES public.equipamentos(id_equipamentos),
    id_componente INTEGER REFERENCES public.componentes(componentes_id),
    quantidade INTEGER,
    CONSTRAINT unique_association UNIQUE (id_equipamento, id_componente)
);

-- Tabela ordem de produção
CREATE TABLE IF NOT EXISTS public.ordemproducao
(
    id_ordem_prod SERIAL PRIMARY KEY,
    id_equipamento INTEGER REFERENCES public.equipamentos(id_equipamentos),
    id_maoobra INTEGER REFERENCES public.maoobra(maoobra_id),
    quantidade INTEGER,
    preco_maoobra MONEY,
    preco_componentes MONEY,
    preco_total MONEY,
    estado VARCHAR(20)
);

-- Tabela carrinho
CREATE TABLE IF NOT EXISTS public.carrinho
(
    id_carrinho SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES public.users(user_id),
    estado_pagamento BOOLEAN DEFAULT false,
    preço_total MONEY
);

-- Tabela carrinho_produtos: associa equipamentos ao carrino
CREATE TABLE IF NOT EXISTS public.carrinho_produtos
(
    id_carrinho_prod SERIAL PRIMARY KEY,
    id_carrinho INTEGER REFERENCES public.carrinho(id_carrinho),
    quantidade_equip INTEGER,
    id_equipamentos INTEGER REFERENCES public.equipamentos(id_equipamentos)
);

-- Tabela recibos
CREATE TABLE IF NOT EXISTS public.recibos
(
    id_recibo SERIAL PRIMARY KEY,
    id_carrinho INTEGER REFERENCES public.carrinho(id_carrinho),
    user_id INTEGER REFERENCES public.users(user_id),
    dados_json JSONB,
    data_criacao TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
