-- procedimento unserir encomneda
CREATE OR REPLACE PROCEDURE public.inserir_encomenda(
    IN p_id_componente INTEGER,
    IN p_quantidade INTEGER,
    IN p_preco_peca MONEY,
    IN p_preco_final MONEY)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_id_fornecedor INTEGER;
BEGIN
    -- Buscar o id_fornecedor na tabela componentes
    SELECT fornecedor_id INTO v_id_fornecedor
    FROM componentes
    WHERE componentes_id = p_id_componente;

    -- Inserir dados na tabela encomendas
    INSERT INTO encomendas (id_componente, id_fornecedor, quantidade, preco_peca, preco_final, data_encomenda, estado)
    VALUES (p_id_componente, v_id_fornecedor, p_quantidade, p_preco_peca, p_preco_final, CURRENT_DATE, 'pendente');
END;
$$;

-- procedimento Registar Cliente
CREATE OR REPLACE PROCEDURE registar_Cliente(
    p_nome VARCHAR(255),
    p_apelido VARCHAR(255),
    p_data_nascimento DATE,
    p_morada VARCHAR(255),
    p_email VARCHAR(255),
    p_password VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Verificar se o user já existe na tabela 'users'
    SELECT EXISTS (SELECT 1 FROM users WHERE email = p_email) INTO v_user_exists;

    IF v_user_exists THEN
        RAISE EXCEPTION 'Este email já está em uso.';
    ELSE
        -- Inserir o user Cliente na tabela 'users'
        INSERT INTO users (nome, apelido, data_nascimento, morada, email, password, tipo_user)
        VALUES (p_nome, p_apelido, p_data_nascimento, p_morada, p_email, p_password, 'Client');
    END IF;
END;
$$;

-- procedimento Registar Admin
CREATE OR REPLACE PROCEDURE registar_Admin(
    p_nome VARCHAR(255),
    p_apelido VARCHAR(255),
    p_data_nascimento DATE,
    p_morada VARCHAR(255),
    p_email VARCHAR(255),
    p_password VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Verificar se o user já existe na tabela 'users'
    SELECT EXISTS (SELECT 1 FROM users WHERE email = p_email) INTO v_user_exists;

    IF v_user_exists THEN
        RAISE EXCEPTION 'Este email já está em uso.';
    ELSE
        -- Inserir o user Admin na tabela 'users'
        INSERT INTO users (nome, apelido, data_nascimento, morada, email, password, tipo_user)
        VALUES (p_nome, p_apelido, p_data_nascimento, p_morada, p_email, p_password, 'Admin');
    END IF;
END;
$$;

