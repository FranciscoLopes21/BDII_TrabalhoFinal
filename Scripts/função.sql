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

