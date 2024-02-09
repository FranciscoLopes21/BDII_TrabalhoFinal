-- Inserir administrador
INSERT INTO public.users (nome, apelido, data_nascimento, morada, email, password, tipo_user)
VALUES
    ('Admin', 'Admin', '1980-01-01', 'Administração', 'admin@email.com', 'admin123', 'Admin');

-- Inserir clientes
INSERT INTO public.users (nome, apelido, data_nascimento, morada, email, password, tipo_user)
VALUES
    ('Maria', 'Arminda', '1970-02-16', 'Rua A, Lisboa', 'maria@email.com', '123456', 'Cliente'),
    ('Jose', 'Almeida', '1985-09-20', 'Avenida B, Porto', 'jose@email.com', 'abcdef', 'Cliente'),
    ('Ana', 'Costa', '1995-02-10', 'Rua C, Braga', 'ana@email.com', 'qwerty', 'Cliente'),
    ('Pedro', 'Martins', '1988-11-28', 'Rua D, Faro', 'pedro@email.com', '987654', 'Cliente'),
    ('Sofia', 'Lopes', '1992-08-03', 'Avenida E, Coimbra', 'sofia@email.com', 'p@ssw0rd', 'Cliente');



-- Inserir fornecedores
INSERT INTO public.fornecedores (nome, morada, contacto, email, estado)
VALUES
    ('Intel Corporation', '2200 Mission College Blvd, Santa Clara, CA', '925359117', 'info@intel.com', 'Ativo'),
    ('Advanced Micro Devices (AMD)', '2485 Augustine Dr, Santa Clara, CA', '925359118', 'info@amd.com', 'Ativo'),
    ('NVIDIA Corporation', '2788 San Tomas Expy, Santa Clara, CA', '925359119', 'info@nvidia.com', 'Ativo'),
    ('Samsung Electronics', '129 Samsung-ro, Maetan-dong, Yeongtong-gu, Suwon-si, Gyeonggi-do, South Korea', '925359120', 'support@samsung.com', 'Ativo'),
    ('Corsair', '47100 Bayside Pkwy, Fremont, CA', '925359121', 'support@corsair.com', 'Ativo');


-- Inserir componentes
INSERT INTO public.componentes (nome, referencia, quant, stockminimo, fornecedor_id, categoria, preco, estado)
VALUES
    ('Processador Intel Core i7-11700K', 'BX8070811700K', 200, 50, 1, 'Processador', 350.00, 'Ativo'),
    ('Processador AMD Ryzen 9 5900X', '100-100000061WOF', 50, 150, 2, 'Processador', 550.00, 'Ativo'),
    ('Placa de Vídeo NVIDIA GeForce RTX 3080', '900-1G133-2530-000', 100, 30, 3, 'Placa de Vídeo', 800.00, 'Ativo'),
    ('Placa de Vídeo AMD Radeon RX 6800 XT', '21294-01-20G', 20, 80, 2, 'Placa de Vídeo', 700.00, 'Ativo'),
    ('Memória RAM Corsair Vengeance RGB Pro 16GB', 'CMW16GX4M2D3600C18', 300, 100, 5, 'Memória', 120.00, 'Ativo'),
    ('HD SSD Samsung 970 EVO Plus 500GB', 'MZ-V7S500B/AM', 200, 50, 4, 'Armazenamento', 150.00, 'Ativo');


-- Inserir encomendas
INSERT INTO public.encomendas (id_componente, id_fornecedor, quantidade, preco_peca, preco_final, data_encomenda, data_entrega, estado)
VALUES
    (1, 1, 30, 350.00, 10500.00, '2023-01-10', null,'Pendente'),
    (2, 2, 50, 550.00, 27500.00, '2023-02-15', null,'Pendente'),
    (3, 3, 20, 800.00, 16000.00, '2023-03-20', '2023-04-30','Entregue'),
    (4, 4, 15, 700.00, 10500.00, '2023-04-25', '2023-05-30','Entregue'),
    (5, 5, 40, 120.00, 4800.00, '2023-05-30', null,'Pendente');



-- Inserir guias de encomenda
INSERT INTO public.guias_encomenda (id_encomenda, dados_json, data_criacao)
VALUES
    (1, '{"Preco_peca": "350,00 €", "Quantidade": 30, "Preco_final": "10500.00 €", "ID encomenda": 1, "Data_encomenda": "2023-01-10", "Referencia componente": "BX8070811700K"}', '2023-01-10 09:00:00'),
    (2, '{"Preco_peca": "550,00 €", "Quantidade": 50, "Preco_final": "27500,00 €", "ID encomenda": 2, "Data_encomenda": "2023-02-15", "Referencia componente": "100-100000061WOF"}', '2023-02-15 10:30:00'),
    (3, '{"Preco_peca": "800,00 €", "Quantidade": 20, "Preco_final": "16000,00 €", "ID encomenda": 3, "Data_encomenda": "2023-03-20", "Referencia componente": "900-1G133-2530-000"}', '2023-03-20 11:45:00'),
    (4, '{"Preco_peca": "700,00 €", "Quantidade": 15, "Preco_final": "10500,00 €", "ID encomenda": 4, "Data_encomenda": "2023-04-25", "Referencia componente": "21294-01-20G"}', '2023-04-25 08:20:00'),
    (5, '{"Preco_peca": "120,00 €", "Quantidade": 40, "Preco_final": "4800,00 €", "ID encomenda": 5, "Data_encomenda": "2023-05-30", "Referencia componente": "CMW16GX4M2D3600C18"}', '2023-05-30 15:00:00');




-- Inserir Mão de obra
INSERT INTO public.maoobra (nome, preco, estado)
VALUES
    ('Técnico de Montagem', 25.00, 'Ativo'),
    ('Engenheiro de Desenvolvimento', 50.00, 'Inativo'),
    ('Técnico de Manutenção', 30.00, 'Ativo');






-- Inserir equipamentos
INSERT INTO public.equipamentos (nome, descricao, modelo, quantidade, stock, precoun, preco, estado, disponivel)
VALUES
    ('Computador Gamer', 'Computador desktop para jogos de última geração.', 'CG-2023', 4, 50, 1390.00, 2000.00, 'Ativo', true),
    ('Notebook Profissional', 'Notebook potente para uso profissional e empresarial.', 'NP-2023', 3, 30, 1200.00, 1500.00, 'Ativo', true),
    ('Servidor Empresarial', 'Servidor robusto para aplicações empresariais críticas.', 'SE-2023', 7, 20, 3000.00, 4050.00, 'Ativo', true);





-- Inserir associação entre equipamentos e componentes
INSERT INTO public.equipamentos_componentes (id_equipamento, id_componente, quantidade)
VALUES
    (1, 1, 1),
    (1, 3, 1),
    (1, 5, 2),
    (2, 1, 1),
    (2, 4, 1),
    (2, 6, 1),
    (3, 1, 2),
    (3, 2, 1),
    (3, 5, 4);



INSERT INTO public.ordemproducao (id_equipamento, id_maoobra, quantidade, preco_maoobra, preco_componentes, preco_total, estado)
VALUES
    (1, 1, 3, 25.00, 1390.00, 4245.00, 'Produção'),
    (2, 2, 4, 50.00, 1200.00, 5000.00, 'Produção'),
    (3, 3, 5, 30.00, 3000.00, 15150.00, 'Produção');



INSERT INTO public.carrinho (user_id, estado_pagamento, preço_total)
VALUES
    (2, false, 0.00),
    (3, true, 7550.00),
    (4, false, 0.00),
    (5, true, 7550.00),
    (6, false, 0.00);



INSERT INTO public.carrinho_produtos (id_carrinho, quantidade_equip, id_equipamentos)
VALUES
    (1, 1, 1),
    (1, 1, 2),
    (1, 1, 3),
    (2, 2, 1),
    (2, 1, 2),
    (2, 1, 3),
    (3, 1, 1),
    (3, 1, 2),
    (3, 2, 3),
    (4, 1, 1),
    (4, 2, 2),
    (4, 1, 3),
    (5, 2, 1),
    (5, 1, 2),
    (5, 1, 3);


INSERT INTO public.recibos (id_carrinho, user_id, dados_json, data_criacao)
VALUES

    (2, 3, '{"total_pago": "7 550,00 €", "id_carrinho": 2, "equipamentos_pagos": [{"quantidade": 1, "total_item": "2000,00 €", "preco_unitario": "2000,00 €", "nome_equipamento": "Computador Gamer"}, {"quantidade": 1, "total_item": "1200,00 €", "preco_unitario": "1200,00 €", "nome_equipamento": "Notebook Profissional"}, {"quantidade": 1, "total_item": "3000,00 €", "preco_unitario": "3000,00 €", "nome_equipamento": "Notebook Profissional"}]}', '2023-06-17 11:20:00'),

    (4, 5, '{"total_pago": "7 550,00 €", "id_carrinho": 2, "equipamentos_pagos": [{"quantidade": 1, "total_item": "2000,00 €", "preco_unitario": "2000,00 €", "nome_equipamento": "Computador Gamer"}, {"quantidade": 1, "total_item": "1200,00 €", "preco_unitario": "1200,00 €", "nome_equipamento": "Notebook Profissional"}, {"quantidade": 1, "total_item": "3000,00 €", "preco_unitario": "3000,00 €", "nome_equipamento": "Notebook Profissional"}]}', '2023-06-19 08:15:00');




