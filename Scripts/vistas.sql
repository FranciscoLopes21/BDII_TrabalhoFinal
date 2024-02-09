--Vistas Usadas

--Vista para listar componentes em falta : DashBoard
CREATE OR REPLACE VIEW public.componentes_em_falta
 AS
 SELECT componentes_id,
    nome,
    referencia,
    quant,
    stockminimo,
    fornecedor_id,
    categoria,
    preco,
    estado
   FROM componentes
  WHERE quant < stockminimo;

ALTER TABLE public.componentes_em_falta
    OWNER TO postgres;



--Vista para listar encomendas pendentes : DashBoard
CREATE OR REPLACE VIEW public.encomendas_pendentes
 AS
 SELECT e.id_encomenda,
    f.nome AS nome_fornecedor,
    c.referencia AS referencia_componente,
    e.quantidade,
    c.preco AS preco_componente,
    e.preco_final,
    e.data_encomenda,
    e.estado
   FROM encomendas e
     JOIN componentes c ON e.id_componente = c.componentes_id
     JOIN fornecedores f ON e.id_fornecedor = f.fornecedor_id
  WHERE e.estado::text = 'Pendente'::text;

ALTER TABLE public.encomendas_pendentes
    OWNER TO postgres;



--Vista para listar equipamentos com stock de equiapamntos inferiores de 3 : DashBoard
CREATE OR REPLACE VIEW public.equipamentos_com_estoque_baixo
 AS
 SELECT id_equipamentos,
    nome,
    descricao,
    modelo,
    quantidade,
    stock,
    precoun,
    preco,
    estado,
    disponivel
   FROM equipamentos
  WHERE stock < 3;

ALTER TABLE public.equipamentos_com_estoque_baixo
    OWNER TO postgres;



--Vista para listar ordem de produtos
CREATE OR REPLACE VIEW public.ordensproducao_view
 AS
 SELECT op.id_ordem_prod AS ordem_id,
    op.id_equipamento,
    e.nome AS nome_equipamento,
    e.modelo AS modelo_equipamento,
    op.id_maoobra,
    m.nome AS nome_maoobra,
    op.preco_maoobra,
    op.preco_componentes,
    op.quantidade,
    op.preco_total,
    op.estado
   FROM ordemproducao op
     JOIN equipamentos e ON op.id_equipamento = e.id_equipamentos
     JOIN maoobra m ON op.id_maoobra = m.maoobra_id;

ALTER TABLE public.ordensproducao_view
    OWNER TO postgres;