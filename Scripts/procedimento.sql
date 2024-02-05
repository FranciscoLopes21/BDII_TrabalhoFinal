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

-- PROCEDIMENTO Adicionar Equipamentos
CREATE OR REPLACE PROCEDURE public.adicionar_equipamento(
    IN p_nome VARCHAR(255),
    IN p_descricao TEXT,
    IN p_modelo VARCHAR(255),
    IN p_desconto INTEGER
)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Utiliza o comando INSERT ... RETURNING diretamente no corpo do procedimento
    INSERT INTO equipamentos (nome, descricao, modelo, desconto, quantidade, stock, preco)
    VALUES (p_nome, p_descricao, p_modelo, p_desconto, 0, 0, 0.0);
END;
$$;





-- Procedimento associar componente e equipamneto
CREATE OR REPLACE PROCEDURE public.associar_equipamento_componente(
    IN p_id_equipamento INTEGER,
    IN p_id_componente INTEGER
)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verifica se a associação já existe
    IF EXISTS (SELECT 1 FROM equipamentos_componentes WHERE id_equipamento = p_id_equipamento AND id_componente = p_id_componente) THEN
        -- Se a associação já existe, aumenta a quantidade
        UPDATE equipamentos_componentes
        SET quantidade = quantidade + 1
        WHERE id_equipamento = p_id_equipamento AND id_componente = p_id_componente;
    ELSE
        -- Se a associação não existe, cria uma nova
        INSERT INTO equipamentos_componentes (id_equipamento, id_componente, quantidade)
        VALUES (p_id_equipamento, p_id_componente, 1);
    END IF;
END;
$$;




-- Procedimento desassociar componente e equipamneto
CREATE OR REPLACE PROCEDURE public.desassociar_equipamento_componente(
    IN p_id_equipamento INTEGER,
    IN p_id_componente INTEGER
)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verifica se a associação existe
    IF EXISTS (SELECT 1 FROM equipamentos_componentes WHERE id_equipamento = p_id_equipamento AND id_componente = p_id_componente) THEN
        -- Se a associação existe, diminui a quantidade ou remove a associação se a quantidade for 1
        UPDATE equipamentos_componentes
        SET quantidade = CASE WHEN quantidade > 1 THEN quantidade - 1 ELSE 0 END
        WHERE id_equipamento = p_id_equipamento AND id_componente = p_id_componente;

        -- Remove a associação se a quantidade for 0
        DELETE FROM equipamentos_componentes
        WHERE id_equipamento = p_id_equipamento AND id_componente = p_id_componente AND quantidade = 0;
    END IF;
END;
$$;



-- Adiciona ordem de produção
CREATE OR REPLACE PROCEDURE inserir_ordemproducao(
    p_id_equipamento INTEGER,
    p_id_maoObra INTEGER,
    p_quantidade INTEGER
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_preco_maoObra MONEY;
    v_preco_total MONEY := 0;  -- Inicializa o acumulador para o preço total dos componentes
    v_preco_componentes MONEY;
    v_componente_info RECORD;
BEGIN
    -- Obter o preço da mão de obra
    SELECT preco INTO v_preco_maoObra FROM maoobra WHERE maoobra_id = p_id_maoObra;

    -- Loop para processar cada componente associado ao equipamento
    FOR v_componente_info IN (SELECT ec.id_componente, ec.quantidade
                              FROM equipamentos_componentes ec
                              WHERE ec.id_equipamento = p_id_equipamento)
    LOOP
        -- Obter o preço do componente multiplicado pela quantidade utilizada na máquina
        SELECT preco * v_componente_info.quantidade INTO v_preco_componentes
        FROM componentes 
        WHERE componentes_id = v_componente_info.id_componente;

        -- Subtrair a quantidade utilizada de cada componente (multiplicada pela quantidade de equipamentos)
        UPDATE componentes
        SET quant = GREATEST(0, quant - (v_componente_info.quantidade * p_quantidade))
        WHERE componentes_id = v_componente_info.id_componente;

        -- Acumular o valor do preço total dos componentes
        v_preco_total := v_preco_total + v_preco_componentes;
    END LOOP;

    -- Calcular o preço total, adicionando o preço total dos componentes ao preço da mão de obra
    DECLARE
        v_preco_total_final MONEY := v_preco_maoObra * p_quantidade + v_preco_total * p_quantidade;
    BEGIN
        -- Inserir na tabela ordemproducao
        INSERT INTO ordemproducao (id_equipamento, id_maoObra, quantidade, preco_maoObra, preco_componentes, preco_total, estado)
        VALUES (p_id_equipamento, p_id_maoObra, p_quantidade, v_preco_maoObra, v_preco_total, v_preco_total_final, 'Produção');
    END;
END;
$$;


-- Concluir Ordem de produção
CREATE OR REPLACE PROCEDURE concluir_ordem_producao(p_id_ordem_prod INTEGER)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_quantidade_produzida INTEGER;
    v_id_equipamento INTEGER;
BEGIN
    -- Verificar se a ordem de produção existe
    IF NOT EXISTS (SELECT 1 FROM ordemproducao WHERE id_ordem_prod = p_id_ordem_prod) THEN
        RAISE EXCEPTION 'Ordem de produção com ID % não encontrada', p_id_ordem_prod;
    END IF;

    -- Obter a quantidade produzida e o ID do equipamento
    SELECT quantidade, id_equipamento INTO v_quantidade_produzida, v_id_equipamento
    FROM ordemproducao
    WHERE id_ordem_prod = p_id_ordem_prod;

    -- Atualizar o estado para 'Concluído'
    UPDATE ordemproducao
    SET estado = 'Concluído'
    WHERE id_ordem_prod = p_id_ordem_prod;

    -- Adicionar a quantidade produzida ao estoque de equipamentos
    UPDATE equipamentos
    SET stock = stock + v_quantidade_produzida
    WHERE id_equipamentos = v_id_equipamento;

    COMMIT;
END;
$$;


-- Cancelar ordem de produção
CREATE OR REPLACE PROCEDURE cancelar_ordem_producao(p_id_ordem_prod INTEGER)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_id_equipamento INTEGER;
    v_quantidade_produzida INTEGER;
    v_componente_info RECORD;
BEGIN
    -- Obter informações sobre a ordem de produção
    SELECT id_equipamento, quantidade INTO v_id_equipamento, v_quantidade_produzida
    FROM ordemproducao
    WHERE id_ordem_prod = p_id_ordem_prod;

    -- Verificar se a ordem de produção existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ordem de produção com ID % não encontrada', p_id_ordem_prod;
    END IF;

    -- Devolver os componentes ao estoque
    FOR v_componente_info IN (
        SELECT ec.id_componente, ec.quantidade
        FROM equipamentos_componentes ec
        WHERE ec.id_equipamento = v_id_equipamento
    )
    LOOP
        UPDATE componentes
        SET quant = quant + (v_componente_info.quantidade * v_quantidade_produzida)
        WHERE componentes_id = v_componente_info.id_componente;
    END LOOP;

    -- Remover a ordem de produção
    DELETE FROM ordemproducao
    WHERE id_ordem_prod = p_id_ordem_prod;

    COMMIT;
END;
$$;










