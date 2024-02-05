from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.db import connection
from .forms import formularioRegisto, formualarioRegistoEquipamentos, formularioLogin, formularioAdiconarFornecedor, formularioAdiconarMaoObra, formularioAdicionarComponentes, formularioAdiconarEncomenda, formularioCriarOrdemPorducao
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from django.contrib.auth import login, authenticate
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth import logout
from django.core.exceptions import ValidationError
import re
import json
from django.http import JsonResponse, HttpResponse
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from django.db import connection

# Create your views here.
def home(request):
    return render(request, 'home.html')

# regista um novo Cliente
def registarUtilizador(request):
    if request.method == 'POST':
        form = formularioRegisto(request.POST)
        if form.is_valid():
            email = form.cleaned_data["email"],
            nome = form.cleaned_data["nome"], 
            apelido = form.cleaned_data["apelido"], 
            dataNascimento = form.cleaned_data["data_nascimento"],
            morada = form.cleaned_data["morada"], 
            passwordEcryp = make_password(form.cleaned_data["password"])

            with connection.cursor() as cursor:
                try:
                    cursor.execute(
                        "CALL registar_Cliente(%s, %s, %s, %s,%s, %s)", [nome, apelido, dataNascimento, morada, email, passwordEcryp]
                        )
                except Exception as e:
                    messages.error(request, str(e))
                    return redirect('registar')
                

            # Autenticar o user recém-criado usando o modelo de usuário padrão do Django
            user = authenticate(request, username=email, password=passwordEcryp)
            if user is not None:
                login(request, user)

            # Redirecionar para a página inicial room
            return redirect('room')
        
    else:
        form = formularioRegisto()

    return render(request, 'Registar.html', {'form': form})

# regista um novo Admin
def registarAdmin(request):
    if request.method == 'POST':
        form = formularioRegisto(request.POST)
        if form.is_valid():
            email = form.cleaned_data["email"]
            nome = form.cleaned_data["nome"], 
            apelido = form.cleaned_data["apelido"], 
            dataNascimento = form.cleaned_data["data_nascimento"],
            morada = form.cleaned_data["morada"], 
            passwordEcryp = make_password(form.cleaned_data["password"])

            with connection.cursor() as cursor:
                try:
                    cursor.execute(
                        "CALL registar_Admin(%s, %s, %s, %s,%s, %s)", [nome, apelido, dataNascimento, morada, email, passwordEcryp]
                        )
                except Exception as e:
                    messages.error(request, str(e))
                    return redirect('registar')
                

            # Autenticar o user recém-criado usando o modelo de usuário padrão do Django
            user = authenticate(request, username=email, password=passwordEcryp)
            if user is not None:
                login(request, user)

            # Redirecionar para a página inicial room
            return redirect('dashBoard')
        
    else:
        form = formularioRegisto()

    return render(request, 'registarAdmin.html', {'form': form})

#Login User
def loginUser(request):
    form = formularioLogin()

    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        id = 0

        # Verificar se o user existe na tabela 'users' com SQL direto
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE email = %s", [email])
            user_data = cursor.fetchone()

        if user_data and check_password(password, user_data[6]):  # Supondo que a senha esteja no índice 5
            # Criar ou obter um objeto User do Django
            user, created = User.objects.get_or_create(username=email, email=email)
            
            if created:
                # Se o user foi criado agora, configure a senha
                user.set_password(password)
                user.save()

            # Autenticar manualmente
            user = authenticate(request, username=email, password=password)

            if user is not None:
                login(request, user)

                # Armazenar informações do user na sessão
                request.session['user_id'] = user.id
                request.session['user_email'] = user.email
                request.session['tipo_user'] = user_data[7]
                if user_data[7] == "admin":
                    return redirect('dashBoardAdmin')
                else:
                    return redirect('room')
        else:
            messages.error(request, 'Credenciais inválidas. Tente novamente.')

    # Passar o formulário para o contexto ao renderizar a página
    return render(request, 'login.html', {'form': form})

#Logout
def logout_view(request):
    logout(request)
    return redirect('home') 


@login_required(login_url='/login/') 
def room(request):

    # Aqui, você pode acessar o user autenticado usando request.user
    user = request.user

    print("User ID:", request.user.id)
    print("Is Authenticated:", request.user.is_authenticated)

    # Verifique se o user está autenticado
    if not user.is_authenticated:
        # Redirecione para a página de login
        return redirect('login')

    # Restante da lógica da sua view
    return render(request, 'room.html', {'user': user})

#DashBoard Admin
@login_required(login_url='/login/') 
def dashBoardAdmin(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')
    
    # Consulta ao banco de dados para obter as componentes por validar
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM componentes_em_falta")
        componentes_em_falta = cursor.fetchall()

    # Verificar se existem componentes por validar
    tem_componentes_em_falta = bool(componentes_em_falta)

    # Passar os dados para o template
    return render(request, 'dashboardAdmin.html', {'tem_componentes_em_falta': tem_componentes_em_falta, 'componentes_em_falta': componentes_em_falta})
    






#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarFornecedores(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    nome_filter = request.GET.get('nome', '')  # Obtém o valor do filtro de nome

    # Consulta ao banco de dados para obter fornecedores com base no filtro de nome
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_fornecedores(%s)", [nome_filter])
        fornecedores = cursor.fetchall()

    # Passar os dados para o template
    return render(request, 'listaFornecedores.html', {'fornecedores': fornecedores, 'nome_filter': nome_filter})


# adicionar fornecedor 
@login_required(login_url='/login/') 
def adicionarFornecedor(request):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    elif  tipo_user == 'admin':
        if request.method == 'POST':
            form = formularioAdiconarFornecedor(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                morada = form.cleaned_data["morada"]
                contacto = form.cleaned_data["contacto"]
                email = form.cleaned_data["email"]

                if contacto and not contacto.isdigit() and len(contacto) != 9:
                    raise ValidationError('O contato deve ter exatamente 9 dígitos.')
                
                else:

                    # Continuação do seu código para inserir o usuário na tabela 'users'
                    with connection.cursor() as cursor:
                        # Exemplo de inserção
                        cursor.execute(
                            "INSERT INTO Fornecedores (nome, morada, contacto, email) VALUES (%s, %s, %s, %s)",
                            [nome, morada, contacto,email]
                        )

                    messages.success(request, 'Fornecedor adicionado com sucesso.')
                    # Redirecionar para a página inicial room
                    return redirect('listarFornecedor')

        else:
            form = formularioAdiconarFornecedor()

    return render(request, 'AdicionarFornecedor.html', {'form': form})


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def eleminarFornecedores(request, forn):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Consulta ao banco de dados para obter todos os fornecedores
    with connection.cursor() as cursor:
        cursor.execute("DELETE FROM Fornecedores WHERE fornecedor_id = %s", [forn])

    # Passar os dados para o template
    return redirect('listarFornecedor')


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarMaoDeObra(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    nome_filter = request.GET.get('nome', '')
    order_by = request.GET.get('order_by', '')  # Novo parâmetro para ordenação

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_mao_de_obra(%s, %s)", [nome_filter, order_by])
        maoObra = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listarMaoDeObra.html', {'maoObra': maoObra, 'nome_filter': nome_filter, 'order_by': order_by})



# adicionar fornecedor 
@login_required(login_url='/login/') 
def adicionarMaoObra(request):
    # Verificar se o user é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    elif  tipo_user == 'admin':
        if request.method == 'POST':
            form = formularioAdiconarMaoObra(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                preco = form.cleaned_data["preco"]

                # Continuação do seu código para inserir o usuário na tabela 'users'
                with connection.cursor() as cursor:
                    # Exemplo de inserção
                    cursor.execute(
                        "INSERT INTO maoObra (nome, preco) VALUES (%s, %s)",
                        [nome, preco]
                    )

                    messages.success(request, 'Mão de obra adicionada com sucesso.')
                    # Redirecionar para a página inicial room
                    return redirect('listarMaoDeObra')

        else:
            form = formularioAdiconarMaoObra()

    return render(request, 'AdicionarMaoDeObra.html', {'form': form})


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarComponentes(request):

    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')


    filtro = request.GET.get('filtro', None)

    with connection.cursor() as cursor:
        if filtro == 'em_falta':
            cursor.execute("""
                SELECT c.componentes_id, c.nome, c.referencia, c.quant, c.stockMinimo, f.nome as nome_fornecedor, c.categoria, c.preco
                FROM componentes c
                JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
                WHERE c.stockMinimo > c.quant
            """)
        else:
            cursor.execute("""
                SELECT c.componentes_id, c.nome, c.referencia, c.quant, c.stockMinimo, f.nome as nome_fornecedor, c.categoria, c.preco
                FROM componentes c
                JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
            """)

        componentes = cursor.fetchall()

    return render(request, 'listarComponentes.html', {'componentes': componentes})   


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def adicionarComponentes(request):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
        # Consulta ao banco de dados para obter os fornecedores
    with connection.cursor() as cursor:
        cursor.execute("SELECT fornecedor_id, nome FROM fornecedores")
        lista_fornecedores = cursor.fetchall()

    # Configurar as opções do campo fornecedor
    choices = [(f[0], f[1]) for f in lista_fornecedores]
    if request.method == 'POST':
        form = formularioAdicionarComponentes(request.POST)
        form.fields['fornecedor'].choices = choices  # Atualizar as opções do fornecedor no caso de falha na validação
        if form.is_valid():
            nome = form.cleaned_data["nome"]
            referencia = form.cleaned_data["referencia"]
            quant = form.cleaned_data["quant"]
            stockMin = form.cleaned_data["stockMin"]
            fornecedor_id = form.cleaned_data["fornecedor"]
            categoria = form.cleaned_data["categoria"]
            preco = form.cleaned_data["preco"]

            # Continuação do seu código para inserir o componente na tabela 'componentes'
            with connection.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO componentes (nome, referencia, quant, stockMinimo, fornecedor_id, categoria, preco) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    [nome, referencia, quant, stockMin, fornecedor_id, categoria, preco]
                )

            messages.success(request, 'Componente adicionado com sucesso.')
            # Redirecionar para a página inicial room
            return redirect('listarComponentes')

    else:
        form = formularioAdicionarComponentes()
        form.fields['fornecedor'].choices = choices  # Configurar as opções do fornecedor no carregamento inicial


    return render(request, 'AdicionarComponentes.html', {'form': form})   


# adicionar fornecedor 
@login_required(login_url='/login/') 
def enomendarComponentes(request, id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')
    
    elif tipo_user == 'admin':
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM obter_dados_componente(%s)", [id])
            resultado = cursor.fetchone()

        if resultado:
            form = formularioAdiconarEncomenda(initial={'referencia': resultado[0], 'precoPeca': resultado[1]})
            
            if request.method == 'POST':
                form = formularioAdiconarEncomenda(request.POST)
                if form.is_valid():
                    quantidade = int(form.cleaned_data["quantidade"])
                    
                    # Extrair a parte numérica da string e substituir ',' por '.'
                    precoPeca_str = re.sub(r'[^0-9,]', '', resultado[1]).replace(',', '.')

                    precoPeca = float(precoPeca_str)

                    precoTotal = precoPeca * quantidade

                    # Remover o símbolo "€" do preço por peça
                    precoPeca_formatado = resultado[1].replace('€', '').strip()

                    with connection.cursor() as cursor:
                        cursor.execute(
                            "CALL inserir_encomenda(%s, %s, %s::MONEY, %s::MONEY)", [id, quantidade, precoPeca_formatado, precoTotal]
                        )

                    # Configurar a resposta HTTP para download do arquivo JSON
                    with connection.cursor() as cursor:
                        cursor.execute("SELECT dados_json FROM guias_encomenda WHERE id_encomenda = LASTVAL()")
                        dados_encomenda = cursor.fetchall()

                    if dados_encomenda:
                        dados_encomenda = dados_encomenda[0][0]

                    response = HttpResponse(dados_encomenda, content_type='application/json')
                    response['Content-Disposition'] = f'attachment; filename=guia_encomenda_{id}.json'

                    messages.success(request, 'Componente adicionado com sucesso.')

                    return redirect('listarComponentes')
                
                return render(request, 'AdicionarEncomendas.html', {'form': form})
            
            return render(request, 'AdicionarEncomendas.html', {'form': form})
        
        else:
            form = formularioAdiconarEncomenda()

    return render(request, 'AdicionarEncomendas.html', {'form': form})



@login_required(login_url='/login/') 
def listarEncomendas(request):

    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')


    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM vista_encomendas")
        encomendas = cursor.fetchall()

    return render(request, 'listaEncomendas.html', {'encomendas': encomendas})   


@login_required(login_url='/login/') 
def download_json(request, id_encomenda):

    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Aqui você coloca a lógica para obter os dados do banco de dados
    with connection.cursor() as cursor:
        cursor.execute("SELECT dados_json FROM guias_encomenda WHERE id_encomenda = %s", [id_encomenda])
        dados_json = cursor.fetchone()

    # Verificar se encontrou dados para a encomenda específica
    if dados_json:
        # Convertendo os dados para string JSON
        json_content = dados_json[0]
        
        # Configurar a resposta HTTP para download do arquivo JSON
        response = HttpResponse(json_content, content_type='application/json')
        response['Content-Disposition'] = f'attachment; filename=encomenda_{id_encomenda}.json'

        return response
    else:
        # Se não encontrar dados, pode retornar uma resposta indicando isso
        return HttpResponse("Dados da encomenda não encontrados.")

import logging

def importar_json_upload(request):
    if request.method == 'POST':
        try:
            json_file = request.FILES.get('json_file')
            json_data = json.load(json_file)

            id_encomenda = json_data.get('id_encomenda')
            guia_encomenda = json_data.get('guia_encomenda')

            logging.info(f'Recebido JSON: {json_data}')
            logging.info(f"Resultado da função: {result}")

            # Restante do código...
        except json.JSONDecodeError:
            logging.error('Erro ao decodificar JSON')

            # Chama a função PL/pgSQL para alterar o estado para entregue
            with connection.cursor() as cursor:
                cursor.callproc('alterar_estado_entregue', [json.dumps(json_data)])

                # Captura o resultado da função (pode ser ajustado conforme necessário)
                result = cursor.fetchone()

            # Verifica o resultado
            if result and result[0] == '{"status": "success", "message": "Encomenda entregue com sucesso."}':
                return JsonResponse({'status': 'success', 'message': 'Encomenda entregue com sucesso.'})
            else:
                return JsonResponse({'status': 'error', 'message': 'A guia de encomenda não corresponde à encomenda.'})

        except json.JSONDecodeError:
            return JsonResponse({'status': 'error', 'message': 'Formato JSON inválido.'})

    return JsonResponse({'status': 'error', 'message': 'Método não permitido.'})


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarEquipamentos(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT * FROM equipamentos"
        )
        equipamentos = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listaEquipamentos.html', {'equipamentos': equipamentos})


# regista um novo utilizador
@login_required(login_url='/login/') 
def RegistarEquipamentos(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')
    elif tipo_user == 'admin':
        if request.method == 'POST':
            form = formualarioRegistoEquipamentos(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                descricao = form.cleaned_data["descricao"]
                modelo = form.cleaned_data["modelo"]
                desconto = form.cleaned_data["desconto"]

                if desconto and not desconto.isdigit() and len(desconto) > 3:
                    raise ValidationError('O desconto deve ser um número com até 3 dígitos.')

                else:
                    with connection.cursor() as cursor:
                        # Chama a stored procedure com um parâmetro OUT
                        cursor.execute('CALL adicionar_equipamento(%s, %s, %s, %s)', [nome, descricao, modelo, desconto])

                    messages.success(request, 'Equipamento adicionado com sucesso.')
                    return redirect('listarEquipamentos')

        else:
            form = formualarioRegistoEquipamentos()

    return render(request, 'AdicionarEquipamentos.html', {'form': form})





@login_required(login_url='/login/') 
def associarCompEquip(request, id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    if request.method == 'POST':
        componente_id = request.POST.get('componente_id')

        # Chama o procedimento de associação
        with connection.cursor() as cursor:
            cursor.execute('CALL associar_equipamento_componente(%s, %s)', [id, componente_id])
        
        messages.success(request, 'Componente associado com sucesso.')

    # Consulta para obter a lista de componentes
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT c.componentes_id, c.nome, c.referencia, f.nome as nome_fornecedor, c.categoria
            FROM componentes c
            JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
        """)
        componentes = cursor.fetchall()

    # Consulta para obter os componentes associados ao equipamento
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT c.componentes_id, c.nome, ec.quantidade
            FROM componentes c
            JOIN equipamentos_componentes ec ON c.componentes_id = ec.id_componente
            WHERE ec.id_equipamento = %s
        """, [id])
        componentes_associados = cursor.fetchall()

    return render(request, 'AssociarCompEquip.html', {'id_equipamento': id, 'componentes': componentes, 'componentes_associados': componentes_associados})



@login_required(login_url='/login/') 
def desassociarComponente(request, id_equipamento, id_componente):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desassociar_equipamento_componente(%s, %s)', [id_equipamento, id_componente])

    messages.success(request, 'Componente desassociado com sucesso.')
    
    # Redirecione de volta à página de associação
    return redirect('associarCompEquip', id=id_equipamento)



# regista um novo Admin
def criarOrdemProducao(request, id_equipamento):
        # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
        # Consulta ao banco de dados para obter os fornecedores
    with connection.cursor() as cursor:
        cursor.execute("SELECT maoobra_id, nome, preco FROM maoobra")
        lista_maoObra = cursor.fetchall()

    # Configurar as opções do campo fornecedor
    choices = [(f[0], f[1] + ' - Preço: ' + str(f[2])) for f in lista_maoObra]
    if request.method == 'POST':
        form = formularioCriarOrdemPorducao(request.POST)
        form.fields['maoDeObra'].choices = choices  # Atualizar as opções do fornecedor no caso de falha na validação
        if form.is_valid():
            quant = form.cleaned_data["quant"]
            maoDeObra_id = form.cleaned_data["maoDeObra"]

             # Lógica para desassociar o componente
            with connection.cursor() as cursor:
                cursor.execute('CALL inserir_ordemproducao(%s, %s, %s)', [id_equipamento, maoDeObra_id, quant])

            messages.success(request, 'Componente adicionado com sucesso.')
            # Redirecionar para a página inicial room
            return redirect('listarEquipamentos')

    else:
        form = formularioCriarOrdemPorducao()
        form.fields['maoDeObra'].choices = choices  # Configurar as opções do fornecedor no carregamento inicial


    return render(request, 'criarOrdemProducao.html', {'form': form})   



#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarOrdensProducao(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
    status_filter = request.GET.get('status', None)

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        if status_filter == 'producao':
            cursor.execute(
                "SELECT * FROM ordensproducao_view WHERE estado = 'Produção'"
            )
        elif status_filter == 'concluído':
            cursor.execute(
                "SELECT * FROM ordensproducao_view WHERE estado = 'Concluído'"
            )
        else:
            cursor.execute(
                "SELECT * FROM ordensproducao_view"
            )
        ordensProducao = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listarOrdensProducao.html', {'ordensProducao': ordensProducao})




@login_required(login_url='/login/') 
def concluir_ordem(request, ordem_id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL concluir_ordem_producao(%s)', [ordem_id])

    messages.success(request, 'Ordem de produção concluída.')
    
    # Redirecione de volta à página de associação
    return redirect('listarOrdensProducao')


@login_required(login_url='/login/') 
def cancelar_ordem(request, ordem_id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL cancelar_ordem_producao(%s)', [ordem_id])

    messages.success(request, 'Ordem de produção concluída.')
    
    # Redirecione de volta à página de associação
    return redirect('listarOrdensProducao')


