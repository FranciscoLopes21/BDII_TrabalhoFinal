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
)

CREATE TABLE Fornecedores (
    fornecedor_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    morada VARCHAR NOT NULL,
    contacto VARCHAR(9) NOT NULL,
    email VARCHAR NOT NULL
);

CREATE TABLE maoObra (
    maoObra_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    preco MONEY  NOT NULL
);

CREATE TABLE componentes (
	componentes_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    referencia VARCHAR NOT NULL,
    quant INT NOT NULL,
	stockMinimo INT NOT NULL,
    fornecedor_id SERIAL REFERENCES fornecedores(fornecedor_id),
    categoria VARCHAR NOT NULL,
    preco MONEY  NOT NULL
);

CREATE TABLE encomendas (
    id_encomenda SERIAL PRIMARY KEY,
    id_componente INTEGER REFERENCES componentes(componentes_id),
    id_fornecedor INTEGER REFERENCES fornecedores(fornecedor_id),
    quantidade INTEGER,
    preco_peca MONEY,
    preco_final MONEY,
    data_encomenda DATE,
    estado VARCHAR(20)
);

CREATE TABLE guias_encomenda (
    id_guia SERIAL PRIMARY KEY,
    id_encomenda INTEGER REFERENCES encomendas(id_encomenda),
    dados_json JSONB,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);