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
    m.preco AS preco_maoObra,
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
CREATE OR REPLACE VIEW public.vista_encomendas
 AS
 SELECT e.id_encomenda,
    c.referencia,
    e.quantidade,
    e.preco_final,
    e.data_encomenda,
    e.estado
   FROM encomendas e
     JOIN componentes c ON e.id_componente = c.componentes_id;

ALTER TABLE public.vista_encomendas
    OWNER TO postgres;

