--Funções utilizadas

--Funçãp para obter dados do componente
CREATE OR REPLACE FUNCTION public.obter_dados_componente(
	id_componente integer)
    RETURNS TABLE(referencia character varying, preco_peca money) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT c.referencia, c.preco
    FROM componentes c
    WHERE c.componentes_id = id_componente;
END;
$BODY$;

ALTER FUNCTION public.obter_dados_componente(integer)
    OWNER TO postgres;



--Função para listar vendas
CREATE OR REPLACE FUNCTION public.listar_vendas(
	p_id_carrinho integer,
	p_order_by character varying)
    RETURNS TABLE(id_carrinho integer, nome_usuario character varying, total_pago money) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    -- Retornar todas as vendas com estado de pagamento verdadeiro e o nome de cada usuário associado
    IF p_order_by = 'preco_asc' THEN
        RETURN QUERY 
        SELECT carrinho.id_carrinho, users.nome, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE
        ORDER BY carrinho.preço_total ASC;
    ELSIF p_order_by = 'preco_desc' THEN
        RETURN QUERY 
        SELECT carrinho.id_carrinho, users.nome, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE
        ORDER BY carrinho.preço_total DESC;
    ELSE
        RETURN QUERY 
        SELECT carrinho.id_carrinho, users.nome, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_vendas(integer, character varying)
    OWNER TO postgres;



--Função para listar mão de obra
CREATE OR REPLACE FUNCTION public.listar_mao_de_obra(
	p_nome character varying,
	p_order_by character varying)
    RETURNS SETOF maoobra 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
  IF p_order_by = 'preco_asc' THEN
    RETURN QUERY SELECT * FROM maoobra WHERE nome ILIKE '%' || p_nome || '%' ORDER BY preco ASC;
  ELSIF p_order_by = 'preco_desc' THEN
    RETURN QUERY SELECT * FROM maoobra WHERE nome ILIKE '%' || p_nome || '%' ORDER BY preco DESC;
  ELSE
    RETURN QUERY SELECT * FROM maoobra WHERE nome ILIKE '%' || p_nome || '%';
  END IF;

  RETURN;
END;
$BODY$;

ALTER FUNCTION public.listar_mao_de_obra(character varying, character varying)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.listar_mao_de_obra(character varying, character varying) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.listar_mao_de_obra(character varying, character varying) TO postgres;



--Função para listar fornecedores
CREATE OR REPLACE FUNCTION public.listar_fornecedores(
	nome_filter text,
	estado_filter text)
    RETURNS SETOF fornecedores 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    IF nome_filter != '' AND estado_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM fornecedores
        WHERE nome ILIKE '%' || nome_filter || '%'
          AND estado = estado_filter;
    ELSIF nome_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM fornecedores
        WHERE nome ILIKE '%' || nome_filter || '%';
    ELSIF estado_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM fornecedores
        WHERE estado = estado_filter;
    ELSE
        RETURN QUERY
        SELECT *
        FROM fornecedores;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_fornecedores(text, text)
    OWNER TO postgres;



--Função para listar equipamentos
CREATE OR REPLACE FUNCTION public.listar_equipamentos(
	nome_filter text,
	estado_filter text,
	disponibilidade_filter boolean)
    RETURNS SETOF equipamentos 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    IF nome_filter != '' AND estado_filter != '' AND disponibilidade_filter IS NOT NULL THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE nome ILIKE '%' || nome_filter || '%'
          AND estado = estado_filter
          AND disponivel = disponibilidade_filter;
    ELSIF nome_filter != '' AND estado_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE nome ILIKE '%' || nome_filter || '%'
          AND estado = estado_filter;
    ELSIF nome_filter != '' AND disponibilidade_filter IS NOT NULL THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE nome ILIKE '%' || nome_filter || '%'
          AND disponivel = disponibilidade_filter;
    ELSIF estado_filter != '' AND disponibilidade_filter IS NOT NULL THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE estado = estado_filter
          AND disponibilidade = disponibilidade_filter;
    ELSIF nome_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE nome ILIKE '%' || nome_filter || '%';
    ELSIF estado_filter != '' THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE estado = estado_filter;
    ELSIF disponibilidade_filter IS NOT NULL THEN
        RETURN QUERY
        SELECT *
        FROM equipamentos
        WHERE disponivel = disponibilidade_filter;
    ELSE
        RETURN QUERY
        SELECT *
        FROM equipamentos;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_equipamentos(text, text, boolean)
    OWNER TO postgres;



--Função para listar encomendas
CREATE OR REPLACE FUNCTION public.listar_encomendas(
	filtro_estado text,
	id_encomenda_filter integer)
    RETURNS TABLE(id_encomenda integer, nome_fornecedor character varying, referencia_componente character varying, quantidade integer, preco_componente money, preco_final money, data_encomenda date, data_entrega date, estado_encomenda character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    IF filtro_estado = 'Entregue' AND id_encomenda_filter IS NULL THEN
        RETURN QUERY
        SELECT e.id_encomenda,
               f.nome AS nome_fornecedor,
               c.referencia AS referencia_componente,
               e.quantidade,
               c.preco AS preco_componente,
               e.preco_final,
               e.data_encomenda,
               e.data_entrega,
               e.estado
        FROM encomendas e
        JOIN componentes c ON e.id_componente = c.componentes_id
        JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
        WHERE e.estado = 'Entregue';
    ELSIF filtro_estado = 'Pendente' AND id_encomenda_filter IS NULL THEN
        RETURN QUERY
        SELECT e.id_encomenda,
               f.nome AS nome_fornecedor,
               c.referencia AS referencia_componente,
               e.quantidade,
               c.preco AS preco_componente,
               e.preco_final,
               e.data_encomenda,
               e.data_entrega,
               e.estado
        FROM encomendas e
        JOIN componentes c ON e.id_componente = c.componentes_id
        JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
        WHERE e.estado = 'Pendente';
    ELSIF filtro_estado != 'Entregue' AND filtro_estado != 'Pendente' AND id_encomenda_filter IS NULL THEN
        RETURN QUERY
        SELECT e.id_encomenda,
               f.nome AS nome_fornecedor,
               c.referencia AS referencia_componente,
               e.quantidade,
               c.preco AS preco_componente,
               e.preco_final,
               e.data_encomenda,
               e.data_entrega,
               e.estado
        FROM encomendas e
        JOIN componentes c ON e.id_componente = c.componentes_id
        JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id;
    ELSIF filtro_estado = 'Entregue' AND id_encomenda_filter IS NOT NULL THEN
        RETURN QUERY
        SELECT e.id_encomenda,
               f.nome AS nome_fornecedor,
               c.referencia AS referencia_componente,
               e.quantidade,
               c.preco AS preco_componente,
               e.preco_final,
               e.data_encomenda,
               e.data_entrega,
               e.estado
        FROM encomendas e
        JOIN componentes c ON e.id_componente = c.componentes_id
        JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
        WHERE e.estado = 'Entregue' AND e.id_encomenda = id_encomenda_filter;
    ELSE
        RETURN QUERY
        SELECT e.id_encomenda,
               f.nome AS nome_fornecedor,
               c.referencia AS referencia_componente,
               e.quantidade,
               c.preco AS preco_componente,
               e.preco_final,
               e.data_encomenda,
               e.data_entrega,
               e.estado
        FROM encomendas e
        JOIN componentes c ON e.id_componente = c.componentes_id
        JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
        WHERE e.id_encomenda = id_encomenda_filter;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_encomendas(text, integer)
    OWNER TO postgres;



--Função para listar compras do user
CREATE OR REPLACE FUNCTION public.listar_compras_user(
	p_user_id integer,
	p_id_carrinho integer,
	p_order_by character varying)
    RETURNS TABLE(id_carrinho integer, total_pago money) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    -- Retornar todas as compras do user com estado de pagamento verdadeiro
    IF p_order_by = 'preco_asc' THEN
        RETURN QUERY 
        SELECT carrinho.id_carrinho, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE carrinho.user_id = p_user_id 
            AND (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE
        ORDER BY carrinho.preço_total ASC;
    ELSIF p_order_by = 'preco_desc' THEN
        RETURN QUERY 
        SELECT carrinho.id_carrinho, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE carrinho.user_id = p_user_id 
            AND (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE
        ORDER BY carrinho.preço_total DESC;
    ELSE
        RETURN QUERY 
        SELECT carrinho.id_carrinho, carrinho.preço_total
        FROM carrinho
        INNER JOIN users ON carrinho.user_id = users.user_id
        WHERE carrinho.user_id = p_user_id 
            AND (p_id_carrinho IS NULL OR carrinho.id_carrinho = p_id_carrinho)
            AND carrinho.estado_pagamento = TRUE;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_compras_user(integer, integer, character varying)
    OWNER TO postgres;



--Funão para listar componentes
CREATE OR REPLACE FUNCTION public.listar_componentes(
	filtro text,
	referencia_filter text)
    RETURNS TABLE(componentes_id integer, nome character varying, referencia character varying, quant integer, stockminimo integer, nome_fornecedor character varying, categoria character varying, preco money, estado character varying, estadofor character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    IF filtro = 'em_falta' THEN
        RETURN QUERY
        SELECT c.componentes_id, c.nome, c.referencia, c.quant, c.stockMinimo,
               f.nome AS nome_fornecedor, c.categoria, c.preco, c.estado, f.estado
        FROM componentes c
        JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
        WHERE c.quant < c.stockMinimo;
    ELSE
        RETURN QUERY
        SELECT c.componentes_id, c.nome, c.referencia, c.quant, c.stockMinimo,
               f.nome AS nome_fornecedor, c.categoria, c.preco, c.estado, f.estado
        FROM componentes c
        JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
        WHERE c.referencia ILIKE '%' || referencia_filter || '%';
    END IF;
END;
$BODY$;

ALTER FUNCTION public.listar_componentes(text, text)
    OWNER TO postgres;



--Função para listar clientes
CREATE OR REPLACE FUNCTION public.listar_clientes(
	nome_cliente text)
    RETURNS SETOF users 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
  RETURN QUERY SELECT * FROM public.users WHERE tipo_user = 'client' AND nome ILIKE '%' || nome_cliente || '%';
END;
$BODY$;

ALTER FUNCTION public.listar_clientes(text)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.listar_clientes(text) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.listar_clientes(text) TO postgres;



--Função para listar carrinho
CREATE OR REPLACE FUNCTION public.listar_carrinho(
    p_user_id integer)
RETURNS TABLE(id_carrinho integer, id_equipamento integer, nome_equipamento character varying, quantidade integer, preco_unitario money, preco_final money, preco_total money) 
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        c.id_carrinho,
        cp.id_equipamentos,
        e.nome AS nome_equipamento,
        cp.quantidade_equip,
        e.preco AS preco_unitario,
        (cp.quantidade_equip * e.preco) AS preco_final,
        (
            SELECT SUM(cp.quantidade_equip * e.preco)
            FROM carrinho_produtos cp
            JOIN equipamentos e ON cp.id_equipamentos = e.id_equipamentos
            WHERE cp.id_carrinho = c.id_carrinho
        ) AS preco_total
    FROM
        carrinho c
    JOIN carrinho_produtos cp ON c.id_carrinho = cp.id_carrinho
    JOIN equipamentos e ON cp.id_equipamentos = e.id_equipamentos
    WHERE
        c.user_id = p_user_id
        AND c.estado_pagamento = false;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in listar_carrinho: %', SQLERRM;
END;
$BODY$;

ALTER FUNCTION public.listar_carrinho(integer)
OWNER TO postgres;
