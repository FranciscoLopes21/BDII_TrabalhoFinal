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
    VALUES (p_id_componente, v_id_fornecedor, p_quantidade, p_preco_peca, p_preco_final, CURRENT_DATE, 'Pendente');
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
        VALUES (p_nome, p_apelido, p_data_nascimento, p_morada, p_email, p_password, 'client');
    END IF;
END;
$$;

-- procedimento Registar Admin
CREATE OR REPLACE PROCEDURE public.registar_admin(
	IN p_nome character varying,
	IN p_apelido character varying,
	IN p_data_nascimento date,
	IN p_morada character varying,
	IN p_email character varying,
	IN p_password character varying)
LANGUAGE 'plpgsql'
AS $BODY$
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
        VALUES (p_nome, p_apelido, p_data_nascimento, p_morada, p_email, p_password, 'admin');
    END IF;
END;
$BODY$;
ALTER PROCEDURE public.registar_admin(character varying, character varying, date, character varying, character varying, character varying)
    OWNER TO postgres;



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
    INSERT INTO equipamentos (nome, descricao, modelo, quantidade, stock, precoUn, preco, desconto, estado, disponivel)
    VALUES (p_nome, p_descricao, p_modelo, 0, 0, 0.0, 0.0, p_desconto, 'Ativo', true);
END;
$$;





-- Procedimento associar componente e equipamneto
CREATE OR REPLACE PROCEDURE public.associar_equipamento_componente(
    IN p_id_equipamento INTEGER,
    IN p_id_componente INTEGER
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_preco_componente MONEY;
    v_quantidade_atual INTEGER;
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

    -- Atualiza a quantidade total de componentes no equipamento
    SELECT SUM(quantidade) INTO v_quantidade_atual
    FROM equipamentos_componentes
    WHERE id_equipamento = p_id_equipamento;

    UPDATE equipamentos
    SET quantidade = v_quantidade_atual
    WHERE id_equipamentos = p_id_equipamento;

    -- Atualiza o preço unitário do equipamento
    SELECT SUM(c.preco * ec.quantidade) INTO v_preco_componente
    FROM equipamentos_componentes ec
    JOIN componentes c ON ec.id_componente = c.componentes_id
    WHERE ec.id_equipamento = p_id_equipamento;

    UPDATE equipamentos
    SET precoUn = v_preco_componente
    WHERE id_equipamentos = p_id_equipamento;
END;
$$;





-- Procedimento desassociar componente e equipamneto
CREATE OR REPLACE PROCEDURE public.desassociar_equipamento_componente(
    IN p_id_equipamento INTEGER,
    IN p_id_componente INTEGER
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_preco_componente MONEY;
    v_quantidade_atual INTEGER;
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

    -- Atualiza a quantidade total de componentes no equipamento
    SELECT SUM(quantidade) INTO v_quantidade_atual
    FROM equipamentos_componentes
    WHERE id_equipamento = p_id_equipamento;

    UPDATE equipamentos
    SET quantidade = v_quantidade_atual
    WHERE id_equipamentos = p_id_equipamento;

    -- Atualiza o preço unitário do equipamento
    SELECT SUM(c.preco * ec.quantidade) INTO v_preco_componente
    FROM equipamentos_componentes ec
    JOIN componentes c ON ec.id_componente = c.componentes_id
    WHERE ec.id_equipamento = p_id_equipamento;

    UPDATE equipamentos
    SET precoUn = v_preco_componente
    WHERE id_equipamentos = p_id_equipamento;
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
    v_componente_disponivel BOOLEAN := TRUE;
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

        -- Verificar se há componentes suficientes para produzir a quantidade desejada
        SELECT quant >= (v_componente_info.quantidade * p_quantidade) INTO v_componente_disponivel
        FROM componentes
        WHERE componentes_id = v_componente_info.id_componente;

        IF NOT v_componente_disponivel THEN
            RAISE EXCEPTION 'Componente insuficiente para produzir a quantidade desejada';
        END IF;

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









-- Desativar Fornecedor
CREATE OR REPLACE PROCEDURE desativarFornecedores(id_f INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se fornecedor existe
    IF NOT EXISTS (SELECT 1 FROM fornecedores WHERE fornecedor_id = id_f) THEN
        RAISE EXCEPTION 'Fornecedor com ID % não encontrada', id_f;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE fornecedores
    SET estado = 'Inativo'
    WHERE fornecedor_id = id_f;

    COMMIT;
END;
$$;

-- Ativar Fornecedor
CREATE OR REPLACE PROCEDURE ativarFornecedores(id_f INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se fornecedor existe
    IF NOT EXISTS (SELECT 1 FROM fornecedores WHERE fornecedor_id = id_f) THEN
        RAISE EXCEPTION 'Fornecedor com ID % não encontrada', id_f;
    END IF;

    -- Atualizar o estado para 'Ativo'
    UPDATE fornecedores
    SET estado = 'Ativo'
    WHERE fornecedor_id = id_f;

    COMMIT;
END;
$$;

-- Editar Fornecedor
CREATE OR REPLACE FUNCTION editar_fornecedor(
    p_id_fornecedor INT,
    p_nome VARCHAR,
	p_morada VARCHAR,
    p_contacto VARCHAR(9),
	p_email VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar se o fornecedor existe
    IF NOT EXISTS (SELECT 1 FROM fornecedores WHERE fornecedor_id = p_id_fornecedor) THEN
        RAISE EXCEPTION 'Fornecedor com ID % não encontrado', p_id_fornecedor;
    END IF;

    -- Atualizar os dados do fornecedor
    UPDATE fornecedores
    SET
        nome = p_nome,
        morada = p_morada,
		contacto = p_contacto,
		email = p_email
    WHERE fornecedor_id = p_id_fornecedor;

END;
$$;


-- Criar componente
CREATE OR REPLACE PROCEDURE adicionar_componente(
    p_nome VARCHAR,
    p_referencia VARCHAR,
    p_quant INT,
    p_stockMinimo INT,
    p_fornecedor_id INT,
    p_categoria VARCHAR,
    p_preco MONEY
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    INSERT INTO componentes (nome, referencia, quant, stockMinimo, fornecedor_id, categoria, preco, estado)
    VALUES (p_nome, p_referencia, p_quant, p_stockMinimo, p_fornecedor_id, p_categoria, p_preco, 'Ativo');
END;
$$;

-- Editar componente
CREATE OR REPLACE FUNCTION editar_componente(
    p_id_componente INT,
    p_nome VARCHAR,
    p_referencia VARCHAR,
    p_quant INT,
    p_stockMinimo INT,
    p_fornecedor_id INT,
    p_categoria VARCHAR,
    p_preco MONEY
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar se o fornecedor existe
    IF NOT EXISTS (SELECT 1 FROM componentes WHERE componentes_id = p_id_componente) THEN
        RAISE EXCEPTION 'Componente com ID % não encontrado', p_id_componente;
    END IF;

    -- Atualizar os dados do fornecedor
    UPDATE componentes
    SET
        nome = p_nome,
        referencia = p_referencia,
		quant = p_quant,
		stockminimo = p_stockMinimo,
		fornecedor_id = p_fornecedor_id,
		categoria = p_categoria,
		preco = p_preco
    WHERE componentes_id = p_id_componente;

END;
$$;

-- desativar Componente
CREATE OR REPLACE PROCEDURE desativarComponente(id_c INTEGER)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    v_equipamento_row RECORD;
    v_quantidade_componentes INTEGER;
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM componentes WHERE componentes_id = id_c) THEN
        RAISE EXCEPTION 'Componente com ID % não encontrado', id_c;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE componentes
    SET estado = 'Inativo'
    WHERE componentes_id = id_c;

    -- Loop pelos equipamentos que utilizam o componente desativado
    FOR v_equipamento_row IN (SELECT id_equipamento, quantidade FROM equipamentos_componentes WHERE id_componente = id_c) LOOP
        -- Obter os valores do registro atual
        v_quantidade_componentes := v_equipamento_row.quantidade;

        -- Atualizar a quantidade e o preço unitário do equipamento
        UPDATE equipamentos
        SET quantidade = quantidade - v_quantidade_componentes,
            precoUn = precoUn - (v_quantidade_componentes * (SELECT preco FROM componentes WHERE componentes_id = id_c))
        WHERE id_equipamentos = v_equipamento_row.id_equipamento;
    END LOOP;

    -- Remover o componente da tabela equipamentos_componentes
    DELETE FROM equipamentos_componentes WHERE id_componente = id_c;

    -- Commit da transação
    COMMIT;
END;
$$;



-- Ativar Componente
CREATE OR REPLACE PROCEDURE ativarComponente(id_c INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM componentes WHERE componentes_id = id_c) THEN
        RAISE EXCEPTION 'Fornecedor com ID % não encontrada', id_c;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE componentes
    SET estado = 'Ativo'
    WHERE componentes_id = id_c;
	
    COMMIT;
END;
$$;



-- Chegou encomenda
CREATE OR REPLACE PROCEDURE entregar_encomenda(id_encomenda_param INT)
LANGUAGE 'plpgsql'
AS $$
DECLARE
    id_componente_param INT;
    quantidade_param INT;
BEGIN
    -- Obter o id_componente e a quantidade da encomenda
    SELECT id_componente, quantidade INTO id_componente_param, quantidade_param
    FROM encomendas
    WHERE id_encomenda = id_encomenda_param;

    -- Atualizar o estado da encomenda para "Entregue" e definir a data de entrega como a data atual
    UPDATE encomendas
    SET estado = 'Entregue', data_entrega = CURRENT_DATE
    WHERE id_encomenda = id_encomenda_param;

    -- Adicionar a quantidade de componentes à tabela componentes
    UPDATE componentes
    SET quant = quant + quantidade_param
    WHERE componentes_id = id_componente_param;
END;
$$;


-- Cancelar Encomenda
CREATE OR REPLACE PROCEDURE cancelar_encomenda(id_e INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM encomendas WHERE id_encomenda = id_e) THEN
        RAISE EXCEPTION 'Encomenda com ID % não encontrada', id_e;
    END IF;

    -- Excluir a encomenda da tabela encomendas
    DELETE FROM encomendas WHERE id_encomenda = id_e;
	
    COMMIT;
END;
$$;



-- Adicionar mao de obra
CREATE OR REPLACE PROCEDURE adicionar_mao_obra(
   nome_param VARCHAR,
    preco_param MONEY
)
AS $$
BEGIN
    INSERT INTO maoObra (nome, preco, estado)
    VALUES (nome_param, preco_param, 'Ativo');
END;
$$ LANGUAGE PLPGSQL;


-- Editar mao de obra
CREATE OR REPLACE PROCEDURE editar_maoObra(
    maoObra_id_param INT,
    nome_param VARCHAR,
    preco_param MONEY
)
AS $$
BEGIN
    -- Verificar se a mão de obra com o ID fornecido existe
    IF NOT EXISTS (SELECT 1 FROM maoObra WHERE maoObra_id = maoObra_id_param) THEN
        RAISE EXCEPTION 'Mão de obra com ID % não encontrada.', maoObra_id_param;
    END IF;

    -- Atualizar os campos da mão de obra
    UPDATE maoObra
    SET
        nome = nome_param,
        preco = preco_param
    WHERE maoObra_id = maoObra_id_param;

END;
$$ LANGUAGE PLPGSQL;

-- Desativar mao de obra
CREATE OR REPLACE PROCEDURE desativarMaoObra(id_mo INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM maoObra WHERE maoobra_id = id_mo) THEN
        RAISE EXCEPTION 'Mão de obra com ID % não encontrada', id_mo;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE maoObra
    SET estado = 'Inativo'
    WHERE maoobra_id = id_mo;
	

    COMMIT;
END;
$$;

-- Ativar mao de obra
CREATE OR REPLACE PROCEDURE ativarMaoObra(id_mo INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM maoObra WHERE maoobra_id = id_mo) THEN
        RAISE EXCEPTION 'Mão de obra com ID % não encontrada', id_mo;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE maoObra
    SET estado = 'Ativo'
    WHERE maoobra_id = id_mo;
	

    COMMIT;
END;
$$;



CREATE OR REPLACE PROCEDURE public.desativarequipamento(
	IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE equipamentos
    SET estado = 'Inativo',
		disponivel = False
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.desativarequipamento(integer)
    OWNER TO postgres;


CREATE OR REPLACE PROCEDURE ativarEquipamento(id_e INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;

    -- Atualizar o estado para 'Inativo'
    UPDATE equipamentos
    SET estado = 'Ativo'
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$$;



CREATE OR REPLACE PROCEDURE indisponivelEquipamento(id_e INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;

    -- Atualizar o disponivel para indisponivel
    UPDATE equipamentos
    SET disponivel = false
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$$;


CREATE OR REPLACE PROCEDURE disponivelEquipamento(id_e INTEGER)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se componente existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;

    -- Atualizar o indisponivel para disponivel
    UPDATE equipamentos
    SET disponivel = true
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$$;



CREATE OR REPLACE PROCEDURE adicionar_equipamento_preco(
    p_id_equipamento INTEGER,
    p_preco MONEY
)
LANGUAGE 'plpgsql'
AS $$
BEGIN
    -- Verificar se o equipamento existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = p_id_equipamento) THEN
        RAISE EXCEPTION 'Equipamento com ID % não encontrado', p_id_equipamento;
    END IF;

    -- Atualizar o preço do equipamento
    UPDATE equipamentos
    SET preco = p_preco
    WHERE id_equipamentos = p_id_equipamento;

    COMMIT;
END;
$$;
