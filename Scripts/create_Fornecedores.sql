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