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