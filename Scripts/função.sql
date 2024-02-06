-- obter ref e preco de componentes
CREATE OR REPLACE FUNCTION obter_dados_componente(IN id_componente INT)
RETURNS TABLE (
    referencia VARCHAR,
	preco_peca MONEY
)
AS $$
BEGIN
    RETURN QUERY
    SELECT c.referencia, c.preco
    FROM componentes c
    WHERE c.componentes_id = id_componente;
END;
$$ LANGUAGE plpgsql;

-- Criar uma função que aceita um parâmetro de filtro para o nome
CREATE OR REPLACE FUNCTION listar_fornecedores(p_nome VARCHAR(255))
RETURNS SETOF Fornecedores
AS $$
BEGIN
  IF p_nome IS NULL OR p_nome = '' THEN
    RETURN QUERY SELECT * FROM Fornecedores;
  ELSE
    RETURN QUERY SELECT * FROM Fornecedores WHERE nome ILIKE '%' || p_nome || '%';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Permissões necessárias
GRANT EXECUTE ON FUNCTION listar_fornecedores(VARCHAR) TO PUBLIC;



-- Criar uma função que aceita um parâmetro de filtro para o nome e um parâmetro para a ordenação
CREATE OR REPLACE FUNCTION listar_mao_de_obra(p_nome VARCHAR(255), p_order_by VARCHAR(20))
RETURNS SETOF maoobra
AS $$
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
$$ LANGUAGE plpgsql;

-- Permissões necessárias
GRANT EXECUTE ON FUNCTION listar_mao_de_obra(VARCHAR, VARCHAR) TO PUBLIC;




-- Criar a função que será usada na view
CREATE OR REPLACE FUNCTION listar_fornecedores(
    nome_filter TEXT,
    estado_filter TEXT
)
RETURNS SETOF fornecedores
AS $$
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
$$ LANGUAGE PLPGSQL;

-- Listar Componentes
CREATE OR REPLACE FUNCTION listar_encomendas(
  filtro_estado TEXT,
  id_encomenda_filter INT
)
RETURNS TABLE (
  id_encomenda INT,
  nome_fornecedor VARCHAR,
  referencia_componente VARCHAR,
  quantidade INT,
  preco_componente MONEY,
  preco_final MONEY,
  data_encomenda DATE,
  data_entrega DATE,
  estado_encomenda VARCHAR
)
AS $$
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
$$ LANGUAGE PLPGSQL;






-- LISTAR CLIENTES --
CREATE OR REPLACE FUNCTION listar_clientes()
RETURNS SETOF public.users
AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.users WHERE tipo_user = 'client';
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION listar_clientes() TO PUBLIC;