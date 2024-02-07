CREATE TABLE IF NOT EXISTS public.users
(
    user_id integer NOT NULL DEFAULT nextval('users_user_id_seq'::regclass),
    nome character varying COLLATE pg_catalog."default" NOT NULL,
    apelido character varying COLLATE pg_catalog."default" NOT NULL,
    data_nascimento date NOT NULL,
    morada character varying COLLATE pg_catalog."default" NOT NULL,
    email character varying COLLATE pg_catalog."default" NOT NULL,
    password character varying COLLATE pg_catalog."default" NOT NULL,
    tipo_user character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (user_id)
);

CREATE TABLE Fornecedores (
    fornecedor_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    morada VARCHAR NOT NULL,
    contacto VARCHAR(9) NOT NULL,
    email VARCHAR NOT NULL,
    estado VARCHAR(20)
);

CREATE TABLE maoObra (
    maoObra_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    preco MONEY  NOT NULL
    estado character varying(20) NOT NULL
);

CREATE TABLE componentes (
	componentes_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    referencia VARCHAR NOT NULL,
    quant INT NOT NULL,
	stockMinimo INT NOT NULL,
    fornecedor_id SERIAL REFERENCES fornecedores(fornecedor_id),
    categoria VARCHAR NOT NULL,
    preco MONEY  NOT NULL,
    estado VARCHAR(20) NOT NULL
);

CREATE TABLE encomendas (
    id_encomenda SERIAL PRIMARY KEY,
    id_componente INTEGER REFERENCES componentes(componentes_id),
    id_fornecedor INTEGER REFERENCES fornecedores(fornecedor_id),
    quantidade INTEGER NOT NULL,
    preco_peca MONEY NOT NULL,
    preco_final MONEY NOT NULL,
    data_encomenda DATE NOT NULL,
	data_entrega DATE,
    estado VARCHAR(20) NOT NULL
);

CREATE TABLE guias_encomenda (
    id_guia SERIAL PRIMARY KEY,
    id_encomenda INTEGER REFERENCES encomendas(id_encomenda),
    dados_json JSONB,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE equipamentos (
    id_equipamentos SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    modelo VARCHAR(255) NOT NULL,
    quantidade INT,
	stock INT,
    precoUn MONEY,
    preco MONEY,
    desconto INT
);



CREATE TABLE equipamentos_componentes (
    id SERIAL PRIMARY KEY,
    id_equipamento INTEGER REFERENCES equipamentos(id_equipamentos),
    id_componente INTEGER REFERENCES componentes(componentes_id),
    quantidade INTEGER,
    CONSTRAINT unique_association UNIQUE (id_equipamento, id_componente)
);


CREATE TABLE ordemproducao (
    id_ordem_prod SERIAL PRIMARY KEY,
    id_equipamento INTEGER REFERENCES equipamentos(id_equipamentoS),
    id_maoObra INTEGER REFERENCES maoobra(maoobra_id),
    preco_maoObra MONEY, -- Nova coluna para armazenar o preço da mão de obra
    preco_componentes MONEY, -- Nova coluna para armazenar o preço dos componentes
    quantidade INTEGER,
    preco_total MONEY,
	estado VARCHAR(20)
);


CREATE TABLE carrinho (
    id_carrinho SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    estado_pagamento BOOLEAN DEFAULT false,
    preço_total MONEY
);

CREATE TABLE carrinho_produtos (
    id_carrinho SERIAL NOT NULL REFERENCES carrinho(id_carrinho),
    id_carrinhoequip SERIAL PRIMARY KEY,
    quantidade_equip INTEGER,
    id_equipamentos SERIAL NOT NULL REFERENCES equipamentos(id_equipamentos)
);

CREATE TABLE recibos (
    id_recibo SERIAL PRIMARY KEY,
    id_carrinho INTEGER REFERENCES carrinho(id_carrinho),
    dados_json JSONB,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);