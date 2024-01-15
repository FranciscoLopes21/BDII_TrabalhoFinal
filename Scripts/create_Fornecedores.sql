CREATE TABLE Fornecedores (
    fornecedor_id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    morada VARCHAR NOT NULL,
    contacto VARCHAR(9) NOT NULL,
    email VARCHAR NOT NULL
);