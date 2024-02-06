--Vista para DashBoard componentes em falta
CREATE OR REPLACE VIEW public.componentes_em_falta AS
SELECT *
FROM Componentes
WHERE quant < stockminimo;



CREATE OR REPLACE VIEW ordensproducao_view AS
SELECT
    op.id_ordem_prod AS ordem_id,
    op.id_equipamento,
    e.nome AS nome_equipamento,
    e.modelo AS modelo_equipamento,
    op.id_maoObra,
    m.nome AS nome_maoObra,
    op.preco_maoObra,  -- Utiliza a nova coluna preco_maoObra
    op.preco_componentes,  -- Utiliza a nova coluna preco_componentes
    op.quantidade,
    op.preco_total,
    op.estado
FROM
    ordemproducao op
JOIN
    equipamentos e ON op.id_equipamento = e.id_equipamentos
JOIN
    maoobra m ON op.id_maoObra = m.maoobra_id;


-- Mostrar encomendas
CREATE OR REPLACE VIEW encomendas_pendentes AS
SELECT
    e.id_encomenda,
    f.nome AS nome_fornecedor,
    c.referencia AS referencia_componente,
    e.quantidade,
    c.preco AS preco_componente,
    e.preco_final,
    e.data_encomenda,
    e.estado
FROM
    encomendas e
    JOIN componentes c ON e.id_componente = c.componentes_id
    JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
WHERE
    e.estado = 'Pendente';


