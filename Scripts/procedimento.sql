--Procedimentos Usados

--Procediemtno para remover equipamentos do carrinho
CREATE OR REPLACE PROCEDURE public.remover_equipamento_carrinho(
	IN p_id_carrinho integer,
	IN p_id_equipamento integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_quantidade_equip INTEGER;
    v_preco_total_equip MONEY;
BEGIN
    -- Obter a quantidade do equipamento a remover
    SELECT quantidade_equip, quantidade_equip * equipamentos.preco INTO v_quantidade_equip, v_preco_total_equip
    FROM carrinho_produtos
    JOIN equipamentos ON carrinho_produtos.id_equipamentos = equipamentos.id_equipamentos
    WHERE carrinho_produtos.id_carrinho = p_id_carrinho AND carrinho_produtos.id_equipamentos = p_id_equipamento;

    -- Remover equipamentos da tabela carrinho_produtos
    DELETE FROM carrinho_produtos
    WHERE id_carrinho = p_id_carrinho AND id_equipamentos = p_id_equipamento;

    -- Atualizar o stock do equipamento removido
    UPDATE equipamentos
    SET stock = stock + v_quantidade_equip
    WHERE id_equipamentos = p_id_equipamento;

    -- Atualizar o preço total do carrinho
    UPDATE carrinho
    SET preço_total = preço_total - CAST(v_preco_total_equip AS MONEY)
    WHERE id_carrinho = p_id_carrinho;

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.remover_equipamento_carrinho(integer, integer)
    OWNER TO postgres;



--Procedimento para registar cliente
CREATE OR REPLACE PROCEDURE public.registar_cliente(
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
        -- Inserir o user Cliente na tabela 'users'
        INSERT INTO users (nome, apelido, data_nascimento, morada, email, password, tipo_user)
        VALUES (p_nome, p_apelido, p_data_nascimento, p_morada, p_email, p_password, 'client');
    END IF;
END;
$BODY$;
ALTER PROCEDURE public.registar_cliente(character varying, character varying, date, character varying, character varying, character varying)
    OWNER TO postgres;



--Procedimento para registar admin
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



--Procedimento para inserir uma nova ordem de produção
CREATE OR REPLACE PROCEDURE public.inserir_ordemproducao(
	IN p_id_equipamento integer,
	IN p_id_maoobra integer,
	IN p_quantidade integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_preco_maoObra MONEY;
    v_preco_total MONEY := 0;
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
        -- Obter o preço do componente multiplicado pela quantidade utilizada no equipamento
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
        -- retirar a quantidade utilizada de cada componente (multiplicada pela quantidade de equipamentos)
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
$BODY$;
ALTER PROCEDURE public.inserir_ordemproducao(integer, integer, integer)
    OWNER TO postgres;



--Procedimento para inserir um novo fornecedor
CREATE OR REPLACE PROCEDURE public.inserir_fornecedor(
	IN p_nome character varying,
	IN p_morada character varying,
	IN p_contacto character varying,
	IN p_email character varying)
LANGUAGE 'sql'
AS $BODY$
INSERT INTO fornecedores (nome, morada, contacto, email, estado)
VALUES (p_nome, p_morada, p_contacto, p_email, 'Ativo');
$BODY$;
ALTER PROCEDURE public.inserir_fornecedor(character varying, character varying, character varying, character varying)
    OWNER TO postgres;



--Procedimento para inserir uma nova encomenda
CREATE OR REPLACE PROCEDURE public.inserir_encomenda(
	IN p_id_componente integer,
	IN p_quantidade integer,
	IN p_preco_peca money,
	IN p_preco_final money)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_id_fornecedor INTEGER;
    v_id_encomenda INTEGER;
	v_referencia VARCHAR;
    v_dados_encomenda JSONB;
BEGIN
    -- seleciona o id_fornecedor na tabela componentes
    SELECT fornecedor_id INTO v_id_fornecedor
    FROM componentes
    WHERE componentes_id = p_id_componente;
	SELECT referencia INTO v_referencia
    FROM componentes
    WHERE componentes_id = p_id_componente;
    -- Inserir dados na tabela encomendas
    INSERT INTO encomendas (id_componente, id_fornecedor, quantidade, preco_peca, preco_final, data_encomenda, estado)
    VALUES (p_id_componente, v_id_fornecedor, p_quantidade, p_preco_peca, p_preco_final, CURRENT_DATE, 'Pendente')
    RETURNING id_encomenda INTO v_id_encomenda;
    -- Criar dados da encomenda em formato JSON
    v_dados_encomenda = jsonb_build_object(
        'ID encomenda', v_id_encomenda,
        'Referencia componente', v_referencia,
        'Quantidade', p_quantidade,
        'Preco_peca', p_preco_peca,
        'Preco_final', p_preco_final,
        'Data_encomenda', CURRENT_DATE
    );
    -- Inserir a guia de encomenda na tabela guias_encomenda
    INSERT INTO guias_encomenda (id_encomenda, dados_json, data_criacao)
    VALUES (v_id_encomenda, v_dados_encomenda, CURRENT_TIMESTAMP);
END;
$BODY$;
ALTER PROCEDURE public.inserir_encomenda(integer, integer, money, money)
    OWNER TO postgres;




--Procedimento para laterar a disponibilidade para indisponivel "false"
CREATE OR REPLACE PROCEDURE public.indisponivelequipamento(
	IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se o equipamento existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;
    -- Atualizar o disponivel para indisponivel "false"
    UPDATE equipamentos
    SET disponivel = false
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.indisponivelequipamento(integer)
    OWNER TO postgres;



--Procedimento para finalizar compras e criar recibo
CREATE OR REPLACE PROCEDURE public.finalizarcompra_criarrecibo(
    IN p_user_id integer,
    IN p_id_carrinho integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_total_pago MONEY;
    v_dados_equipamentos JSONB;
BEGIN
    -- Alterar o estado do pagamento do carrinho para True
    UPDATE carrinho
    SET estado_pagamento = true
    WHERE id_carrinho = p_id_carrinho;

    -- Obter o total pago da tabela de carrinho
    SELECT preço_total INTO v_total_pago
    FROM carrinho
    WHERE id_carrinho = p_id_carrinho;

    -- Criar o JSON com os equipamentos pagos e a quantidade
    SELECT jsonb_build_object(
               'id_carrinho', p_id_carrinho,
               'total_pago', v_total_pago,
               'equipamentos_pagos', jsonb_agg(jsonb_build_object(
                                        'nome_equipamento', equipamentos.nome,
                                        'quantidade', carrinho_produtos.quantidade_equip,
                                        'preco_unitario', equipamentos.preco,
                                        'total_item', equipamentos.preco * carrinho_produtos.quantidade_equip
                                    ))
           )
    INTO v_dados_equipamentos
    FROM carrinho_produtos
    JOIN equipamentos ON carrinho_produtos.id_equipamentos = equipamentos.id_equipamentos
    WHERE id_carrinho = p_id_carrinho;

    -- Inserir o recibo na tabela recibos
    INSERT INTO recibos (id_carrinho, user_id, dados_json)
    VALUES (p_id_carrinho, p_user_id, v_dados_equipamentos);

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.finalizarcompra_criarrecibo(integer, integer)
    OWNER TO postgres;




--Procedimento para entregar encomenda
CREATE OR REPLACE PROCEDURE public.entregar_encomenda(
	IN id_encomenda_param integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.entregar_encomenda(integer)
    OWNER TO postgres;



--Procedimento para editar mão de obra
CREATE OR REPLACE PROCEDURE public.editar_maoobra(
	IN maoobra_id_param integer,
	IN nome_param character varying,
	IN preco_param money)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se a mão de obra com o ID mão de obra existe
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
$BODY$;
ALTER PROCEDURE public.editar_maoobra(integer, character varying, money)
    OWNER TO postgres;



--Procedimento para editar fornecedor
CREATE OR REPLACE PROCEDURE public.editar_fornecedor(
	IN p_id_fornecedor integer,
	IN p_nome character varying,
	IN p_morada character varying,
	IN p_contacto character varying,
	IN p_email character varying)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.editar_fornecedor(integer, character varying, character varying, character varying, character varying)
    OWNER TO postgres;



--Procedimetno para editar equipamento
CREATE OR REPLACE PROCEDURE public.editar_equipamento(
	IN p_equipamento_id integer,
	IN p_nome character varying,
	IN p_descricao text,
	IN p_modelo character varying)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE equipamentos
    SET nome = p_nome,
        descricao = p_descricao,
        modelo = p_modelo
    WHERE id_equipamentos = p_equipamento_id;
END;
$BODY$;
ALTER PROCEDURE public.editar_equipamento(integer, character varying, text, character varying)
    OWNER TO postgres;



--Procedimento para editar componente
CREATE OR REPLACE PROCEDURE public.editar_componente(
    IN p_id_componente integer,
    IN p_nome character varying,
    IN p_referencia character varying,
    IN p_quant integer,
    IN p_stockminimo integer,
    IN p_fornecedor_id integer,
    IN p_categoria character varying,
    IN p_preco money)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se o componente existe
    PERFORM 1 FROM public.componentes WHERE componentes_id = p_id_componente;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Componente com ID % não encontrado', p_id_componente;
    END IF;
    -- Atualizar os dados do componente
    UPDATE public.componentes
    SET
        nome = p_nome,
        referencia = p_referencia,
        quant = p_quant,
        stockminimo = p_stockminimo,
        fornecedor_id = p_fornecedor_id,
        categoria = p_categoria,
        preco = p_preco
    WHERE componentes_id = p_id_componente;

END;
$BODY$;
ALTER PROCEDURE public.editar_componente(integer, character varying, character varying, integer, integer, integer, character varying, money)
    OWNER TO postgres;






--Procedimento para trocar estado do equipamento para disponivel "true"
CREATE OR REPLACE PROCEDURE public.disponivelequipamento(
	IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se equipamento existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;
    -- Atualizar o indisponivel para disponivel "true"
    UPDATE equipamentos
    SET disponivel = true
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.disponivelequipamento(integer)
    OWNER TO postgres;



--Procedimento para desativar mão de obra
CREATE OR REPLACE PROCEDURE public.desativarmaoobra(
	IN id_mo integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se mão de obra existe
    IF NOT EXISTS (SELECT 1 FROM maoObra WHERE maoobra_id = id_mo) THEN
        RAISE EXCEPTION 'Mão de obra com ID % não encontrada', id_mo;
    END IF;
    -- Atualizar o estado para 'Inativo'
    UPDATE maoObra
    SET estado = 'Inativo'
    WHERE maoobra_id = id_mo;

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.desativarmaoobra(integer)
    OWNER TO postgres;



--Procedimento para desativar fornecedor
CREATE OR REPLACE PROCEDURE public.desativarfornecedores(
	IN id_f integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.desativarfornecedores(integer)
    OWNER TO postgres;



--Procedimento para desativar equipamento
CREATE OR REPLACE PROCEDURE public.desativarequipamento(
	IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se equipamento existe
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



--Procedimento para desativar componente
CREATE OR REPLACE PROCEDURE public.desativarcomponente(
	IN id_c integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
        -- Obter os valores do registo atual
        v_quantidade_componentes := v_equipamento_row.quantidade;

        -- Atualizar a quantidade e o preço unitário do equipamento
        UPDATE equipamentos
        SET quantidade = quantidade - v_quantidade_componentes,
            precoUn = precoUn - (v_quantidade_componentes * (SELECT preco FROM componentes WHERE componentes_id = id_c))
        WHERE id_equipamentos = v_equipamento_row.id_equipamento;
    END LOOP;

    -- Remover o componente da tabela equipamentos_componentes
    DELETE FROM equipamentos_componentes WHERE id_componente = id_c;

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.desativarcomponente(integer)
    OWNER TO postgres;



--Procedimento para desassociar componentes de equipamentos
CREATE OR REPLACE PROCEDURE public.desassociar_equipamento_componente(
	IN p_id_equipamento integer,
	IN p_id_componente integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.desassociar_equipamento_componente(integer, integer)
    OWNER TO postgres;



--Procedimento para concluir ordem de produção
CREATE OR REPLACE PROCEDURE public.concluir_ordem_producao(
	IN p_id_ordem_prod integer)
LANGUAGE 'plpgsql'
AS $BODY$
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

    -- Adicionar a quantidade produzida ao stock de equipamentos
    UPDATE equipamentos
    SET stock = stock + v_quantidade_produzida
    WHERE id_equipamentos = v_id_equipamento;

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.concluir_ordem_producao(integer)
    OWNER TO postgres;



--Procedimento para cancelar ordem de produção
CREATE OR REPLACE PROCEDURE public.cancelar_ordem_producao(
	IN p_id_ordem_prod integer)
LANGUAGE 'plpgsql'
AS $BODY$
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

    -- Devolver os componentes ao stock
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
$BODY$;
ALTER PROCEDURE public.cancelar_ordem_producao(integer)
    OWNER TO postgres;



--Procedimento para cancelar encomenda
CREATE OR REPLACE PROCEDURE public.cancelar_encomenda(
    IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se a encomenda existe
    IF NOT EXISTS (SELECT 1 FROM encomendas WHERE id_encomenda = id_e) THEN
        RAISE EXCEPTION 'Encomenda com ID % não encontrada', id_e;
    END IF;

    -- Excluir os registros relacionados na tabela guias_encomenda
    DELETE FROM guias_encomenda WHERE id_encomenda = id_e;

    -- Excluir a encomenda da tabela encomendas
    DELETE FROM encomendas WHERE id_encomenda = id_e;

    -- Confirmar a transação
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.cancelar_encomenda(integer)
    OWNER TO postgres;




--Procedimento para ativar mão de obra
CREATE OR REPLACE PROCEDURE public.ativarmaoobra(
	IN id_mo integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se mão de obra existe
    IF NOT EXISTS (SELECT 1 FROM maoObra WHERE maoobra_id = id_mo) THEN
        RAISE EXCEPTION 'Mão de obra com ID % não encontrada', id_mo;
    END IF;
    -- Atualizar o estado para 'Ativo'
    UPDATE maoObra
    SET estado = 'Ativo'
    WHERE maoobra_id = id_mo;
	

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.ativarmaoobra(integer)
    OWNER TO postgres;



--Procedimento para ativar fornecedores
CREATE OR REPLACE PROCEDURE public.ativarfornecedores(
	IN id_f integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.ativarfornecedores(integer)
    OWNER TO postgres;



--Procedimento para ativar equipamentos
CREATE OR REPLACE PROCEDURE public.ativarequipamento(
	IN id_e integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Verificar se equipamento existe
    IF NOT EXISTS (SELECT 1 FROM equipamentos WHERE id_equipamentos = id_e) THEN
        RAISE EXCEPTION 'Equipamentos com ID % não encontrada', id_e;
    END IF;
    -- Atualizar o estado para 'Ativo'
    UPDATE equipamentos
    SET estado = 'Ativo'
    WHERE id_equipamentos = id_e;
	
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE public.ativarequipamento(integer)
    OWNER TO postgres;



--Procedimento para ativar componente
CREATE OR REPLACE PROCEDURE public.ativarcomponente(
	IN id_c integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.ativarcomponente(integer)
    OWNER TO postgres;



--Procedimento para associar componente a maquina
CREATE OR REPLACE PROCEDURE public.associar_equipamento_componente(
	IN p_id_equipamento integer,
	IN p_id_componente integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.associar_equipamento_componente(integer, integer)
    OWNER TO postgres;



--Procedimento para adicionar mão de obra
CREATE OR REPLACE PROCEDURE public.adicionar_mao_obra(
	IN nome_param character varying,
	IN preco_param money)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO maoObra (nome, preco, estado)
    VALUES (nome_param, preco_param, 'Ativo');
END;
$BODY$;
ALTER PROCEDURE public.adicionar_mao_obra(character varying, money)
    OWNER TO postgres;



--Procedimento para adicionar preco a equipamento
CREATE OR REPLACE PROCEDURE public.adicionar_equipamento_preco(
	IN p_id_equipamento integer,
	IN p_preco money)
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
ALTER PROCEDURE public.adicionar_equipamento_preco(integer, money)
    OWNER TO postgres;



--Procedimento para adicionar equipamento a carrinho
CREATE OR REPLACE PROCEDURE public.adicionar_equipamento_carrinho(
	IN p_user_id integer,
	IN p_id_equipamento integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_id_carrinho INTEGER;
    v_estado_pagamento BOOLEAN;
    v_quantidade_equip INTEGER;
    v_preco_equipamento MONEY := 0.0;  -- Inicialize com 0
BEGIN
    -- Verifique se o usuário tem um carrinho aberto
    SELECT id_carrinho, estado_pagamento INTO v_id_carrinho, v_estado_pagamento
    FROM carrinho
    WHERE user_id = p_user_id AND estado_pagamento = false;

    -- Se nenhum carrinho aberto for encontrado ou se o carrinho existente tiver estado_pagamento = true, crie um novo
    IF v_id_carrinho IS NULL OR v_estado_pagamento = true THEN
        INSERT INTO carrinho (user_id, estado_pagamento, preço_total)
        VALUES (p_user_id, false, 0.0)
        RETURNING id_carrinho INTO v_id_carrinho;
    END IF;

    -- Verifique se o equipamento já está presente no carrinho
    SELECT quantidade_equip INTO v_quantidade_equip
    FROM carrinho_produtos
    WHERE id_carrinho = v_id_carrinho AND id_equipamentos = p_id_equipamento;

    -- Se o equipamento estiver presente, atualize a quantidade, caso contrário, insira um novo registro
    IF FOUND THEN
        -- Atualize a quantidade de equipamento no carrinho
        UPDATE carrinho_produtos SET quantidade_equip = v_quantidade_equip + 1
        WHERE id_carrinho = v_id_carrinho AND id_equipamentos = p_id_equipamento;
    ELSE
        -- Adicione o equipamento a carrinho_produtos
        INSERT INTO carrinho_produtos (id_carrinho, quantidade_equip, id_equipamentos)
        VALUES (v_id_carrinho, 1, p_id_equipamento);
    END IF;

    -- Obtenha o preço do equipamento que está sendo adicionado
    SELECT preco INTO v_preco_equipamento
    FROM equipamentos
    WHERE id_equipamentos = p_id_equipamento;

    -- Verifique se o preço do equipamento foi obtido com sucesso antes de atualizar o preço total do carrinho
    IF FOUND THEN
        -- Atualize o preço total do carrinho com o preço do equipamento adicionado
        UPDATE carrinho
        SET preço_total = preço_total + v_preco_equipamento
        WHERE id_carrinho = v_id_carrinho;
    END IF;

    -- Atualize o estoque do equipamento na tabela equipamentos
    UPDATE equipamentos
    SET stock = stock - 1
    WHERE id_equipamentos = p_id_equipamento;

    COMMIT;  -- Evite COMMIT dentro do procedimento
END;
$BODY$;




--Procedimento para adicionar equipamento
CREATE OR REPLACE PROCEDURE public.adicionar_equipamento(
	IN p_nome character varying,
	IN p_descricao text,
	IN p_modelo character varying)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO equipamentos (nome, descricao, modelo, quantidade, stock, precoUn, preco, estado, disponivel)
    VALUES (p_nome, p_descricao, p_modelo, 0, 0, 0.0, 0.0, 'Ativo', false);
END;
$BODY$;
ALTER PROCEDURE public.adicionar_equipamento(character varying, text, character varying)
    OWNER TO postgres;




--Procedimento para adicionar componente
CREATE OR REPLACE PROCEDURE public.adicionar_componente(
	IN p_nome character varying,
	IN p_referencia character varying,
	IN p_quant integer,
	IN p_stockminimo integer,
	IN p_fornecedor_id integer,
	IN p_categoria character varying,
	IN p_preco money)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO componentes (nome, referencia, quant, stockMinimo, fornecedor_id, categoria, preco, estado)
    VALUES (p_nome, p_referencia, p_quant, p_stockMinimo, p_fornecedor_id, p_categoria, p_preco, 'Ativo');
END;
$BODY$;
ALTER PROCEDURE public.adicionar_componente(character varying, character varying, integer, integer, integer, character varying, money)
    OWNER TO postgres;