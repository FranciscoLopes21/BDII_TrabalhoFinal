from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.db import connection
from .forms import formularioRegisto, formualarioRegistoEquipamentos, formularioLogin, formularioAdiconarFornecedor, formularioAdiconarMaoObra, formularioAdicionarComponentes, formularioAdiconarEncomenda, formularioCriarOrdemPorducao, formualarioAdicionarPreco
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
import pymongo
from django.http import JsonResponse, HttpResponse
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from django.db import IntegrityError, InternalError 


from django.db import connection


conexaomongo = pymongo.MongoClient('mongodb+srv://bd2:bd2@bd2.sciijcj.mongodb.net/')["BDII"]

# Create your views here.
def home(request):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    equipamentos = colecaoEquipamentos.find({"estado": "Ativo", "disponivel": True}, {"_id": 0})
    return render(request, 'home.html', {'equipamentos': equipamentos})



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
            return redirect('listarEquipamentosMongo')
        
    else:
        form = formularioRegisto()

    return render(request, 'Registar.html', {'form': form})

# regista um novo Admin
def registarAdmin(request):
    if request.method == 'POST':
        form = formularioRegisto(request.POST)
        if form.is_valid():
            email = form.cleaned_data["email"]
            nome = form.cleaned_data["nome"]
            apelido = form.cleaned_data["apelido"]
            dataNascimento = form.cleaned_data["data_nascimento"]
            morada = form.cleaned_data["morada"]
            passwordEncrypted = make_password(form.cleaned_data["password"])

            with connection.cursor() as cursor:
                try:
                    cursor.execute(
                        "CALL registar_Admin(%s, %s, %s, %s, %s, %s)",
                        [nome, apelido, dataNascimento, morada, email, passwordEncrypted]
                    )
                except Exception as e:
                    messages.error(request, str(e))
                    return redirect('registarAdmin')

            # Autenticar o usuário manualmente após o registro bem-sucedido
            user = User(username=email, email=email)
            user.set_password(form.cleaned_data["password"])
            user.save()

            # Realizar login manualmente
            login(request, user)

            # Redirecionar para a página inicial do dashboard
            return redirect('dashBoardAdmin')


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
                request.session['user_id'] = user_data[0]
                request.session['user_email'] = user.email
                request.session['tipo_user'] = user_data[7]
                if user_data[7] == "admin":
                    return redirect('dashBoardAdmin')
                else:
                    return redirect('listarEquipamentosMongo')
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

    # Consulta ao banco de dados para obter as componentes por validar
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM encomendas_pendentes")
        encomedas = cursor.fetchall()

    # Verificar se existem componentes por validar
    tem_encomedas = bool(encomedas)

    # Consulta ao banco de dados para obter as componentes por validar
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM equipamentos_com_estoque_baixo")
        equipamentos = cursor.fetchall()

    # Verificar se existem componentes por validar
    tem_equipamentos = bool(equipamentos)

    # Passar os dados para o template
    return render(request, 'dashboardAdmin.html', {'tem_componentes_em_falta': tem_componentes_em_falta, 'componentes_em_falta': componentes_em_falta, 
                                                   'tem_encomedas':tem_encomedas, 'encomedas':encomedas, 'tem_equipamentos': tem_equipamentos, 'equipamentos':equipamentos})
    






#Fornecedores

#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarFornecedores(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    nome_filtro = request.GET.get('nome', '')  # Obtém o valor do filtro de nome
    estado_filter = request.GET.get('status', '')  # Obtém o valor do filtro de estado

    # Consulta ao banco de dados para obter fornecedores com base nos filtros
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT * FROM listar_fornecedores(%s, %s)",
            [nome_filtro, estado_filter]
        )
        fornecedores = cursor.fetchall()

    # Passar os dados para o template
    return render(request, 'listaFornecedores.html', {'fornecedores': fornecedores, 'nome_filtro': nome_filtro, 'estado_filter': estado_filter})

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
                            "CALL  inserir_fornecedor(%s, %s, %s, %s)",
                            [nome, morada, contacto,email]
                        )

                    messages.success(request, 'Fornecedor adicionado com sucesso.')
                    # Redirecionar para a página inicial room
                    return redirect('listarFornecedor')

        else:
            form = formularioAdiconarFornecedor()

    return render(request, 'AdicionarFornecedor.html', {'form': form})

# editar fornecedor 
@login_required(login_url='/login/') 
def editar_fornecedor(request, id_fornecedor):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    elif  tipo_user == 'admin':

        # Buscar o fornecedor com base no ID fornecido
        with connection.cursor() as cursor:
            cursor.execute('SELECT * FROM fornecedores WHERE fornecedor_id = %s', [id_fornecedor])
            fornecedor_data = cursor.fetchone()

        if request.method == 'POST':
            form = formularioAdiconarFornecedor(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                morada = form.cleaned_data["morada"]
                contacto = form.cleaned_data["contacto"]
                email = form.cleaned_data["email"]

                # Lógica para desassociar o componente
                with connection.cursor() as cursor:
                    cursor.execute('CALL editar_fornecedor(%s, %s, %s, %s, %s)', [
                        id_fornecedor, nome, morada, contacto, email]
                        )
                    
                messages.success(request, 'Fornecedor Editado.')

                # Passar os dados para o template
                return redirect('listarFornecedor')

        else:
            form = formularioAdiconarFornecedor(initial={
            'nome': fornecedor_data[1],
            'morada': fornecedor_data[2],
            'contacto': fornecedor_data[3],
            'email': fornecedor_data[4]
        })

    return render(request, 'AdicionarFornecedor.html', {'form': form})

#Mostrar Fornecedores
@login_required(login_url='/login/') 
def desativarFornecedores(request, id_fornecedor):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desativarFornecedores(%s)', [id_fornecedor])

    messages.success(request, 'Fornecedor Desativado.')

    # Passar os dados para o template
    return redirect('listarFornecedor')

#Ativar fornecedor
@login_required(login_url='/login/') 
def ativarFornecedores(request, id_fornecedor):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL ativarFornecedores(%s)', [id_fornecedor])

    messages.success(request, 'Fornecedor Desativado.')

    # Passar os dados para o template
    return redirect('listarFornecedor')





#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarComponentes(request):

    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')


    filtro = request.GET.get('filtro', '')
    nome_filtro = request.GET.get('referencia', '')  # Obtém o valor do filtro de nome

    # Consulta ao banco de dados para obter fornecedores com base nos filtros
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT * FROM listar_componentes(%s, %s)",
            [filtro, nome_filtro]
        )
        componentes = cursor.fetchall()

    return render(request, 'listarComponentes.html', {'componentes': componentes, 'filtro': filtro, 'nome_filtro': nome_filtro}) 



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
        cursor.execute("SELECT fornecedor_id, nome FROM fornecedores where estado like 'Ativo' ")
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
                    "CALL adicionar_componente(%s, %s, %s::INTEGER, %s::INTEGER, %s::INTEGER, %s, %s::MONEY)",
                    [nome, referencia, quant, stockMin, fornecedor_id, categoria, preco]
                )

            messages.success(request, 'Componente adicionado com sucesso.')
            # Redirecionar para a página inicial room
            return redirect('listarComponentes')

    else:
        form = formularioAdicionarComponentes()
        form.fields['fornecedor'].choices = choices  # Configurar as opções do fornecedor no carregamento inicial


    return render(request, 'AdicionarComponentes.html', {'form': form})   


# editar fornecedor 
@login_required(login_url='/login/') 
def editar_componentes(request, id_componente):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    elif tipo_user == 'admin':
        # Buscar o componente com base no ID componente
        with connection.cursor() as cursor:
            cursor.execute('SELECT * FROM componentes WHERE componentes_id = %s', [id_componente])
            componente_data = cursor.fetchone()
        # Buscar a lista de fornecedores ativos
        with connection.cursor() as cursor:
            cursor.execute("SELECT fornecedor_id, nome FROM fornecedores where estado like 'Ativo' ")
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
                # Lógica para editar o componente
                with connection.cursor() as cursor:
                    cursor.execute(
                        'CALL editar_componente(%s::INTEGER, %s, %s, %s::INTEGER, %s::INTEGER, %s::INTEGER, %s, %s::MONEY)',
                        [id_componente, nome, referencia, quant, stockMin, fornecedor_id, categoria, preco]
                    )
                messages.success(request, 'Componente Editado.')
                # Redirecionar para a página de listagem de componentes
                return redirect('listarComponentes')

        else:
            # Inicializar o formulário com os dados do componente e as opções do fornecedor
            form = formularioAdicionarComponentes(initial={
                'nome': componente_data[1],
                'referencia': componente_data[2],
                'quant': componente_data[3],
                'stockMin': componente_data[4],
                'fornecedor': componente_data[5],
                'categoria': componente_data[6],
                'preco': float(componente_data[7].replace('€', '').replace(',', '.'))
            })
            form.fields['fornecedor'].choices = choices

    return render(request, 'AdicionarComponentes.html', {'form': form})


#Mostrar Fornecedores
@login_required(login_url='/login/') 
def desativarComponente(request, id_componente):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desativarComponente(%s)', [id_componente])

    messages.success(request, 'Componente Desativado.')

    # Passar os dados para o template
    return redirect('listarComponentes')

#Ativar fornecedor
@login_required(login_url='/login/') 
def ativarComponente(request, id_componente):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL ativarComponente(%s)', [id_componente])

    messages.success(request, 'Componente Ativado.')

    # Passar os dados para o template
    return redirect('listarComponentes')


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

    id_encomenda_filter = request.GET.get('id_encomenda', '')  # Obtenha o valor do filtro de ID da encomenda
    estado_filter = request.GET.get('status', '')  # Obtenha o valor do filtro de estado

    # Verificar se id_encomenda_filter não está vazio antes de converter para inteiro
    id_encomenda_filter = int(id_encomenda_filter) if id_encomenda_filter else None

    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_encomendas(%s, %s::INTEGER)",
            [estado_filter, id_encomenda_filter]
        )
        encomendas = cursor.fetchall()

    return render(request, 'listaEncomendas.html', {'encomendas': encomendas, 'id_encomenda_filter': id_encomenda_filter, 'estado_filter': estado_filter})




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



@login_required(login_url='/login/') 
def entregarEncomenda(request, id_encomenda):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL  entregar_encomenda(%s)', [id_encomenda])

    messages.success(request, 'Encomenda entregue.')
    
    # Redirecione de volta à página de associação
    return redirect('listarEncomendas')



#Cancelar Encomenda
@login_required(login_url='/login/') 
def cancelarEncomenda(request, id_encomenda):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL  cancelar_encomenda(%s)', [id_encomenda])

    messages.success(request, 'Encomenda cancelada.')
    
    # Redirecione de volta à página de associação
    return redirect('listarEncomendas')






#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarMaoDeObra(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    nome_filtro = request.GET.get('nome', '')
    order_by = request.GET.get('order_by', '')  # Novo parâmetro para ordenação

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_mao_de_obra(%s, %s)", [nome_filtro, order_by])
        maoObra = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listarMaoDeObra.html', {'maoObra': maoObra, 'nome_filtro': nome_filtro, 'order_by': order_by})



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
                preco = float(form.cleaned_data["preco"])

                # Continuação do seu código para inserir o usuário na tabela 'users'
                with connection.cursor() as cursor:
                    # Exemplo de inserção
                    cursor.execute(
                        "CALL adicionar_mao_obra(%s, %s::MONEY)",
                        [nome, preco]
                    )


                    messages.success(request, 'Mão de obra adicionada com sucesso.')
                    # Redirecionar para a página inicial room
                    return redirect('listarMaoDeObra')

        else:
            form = formularioAdiconarMaoObra()

    return render(request, 'AdicionarMaoDeObra.html', {'form': form})




#Editar Mão de Obra
@login_required(login_url='/login/') 
def editar_maoObra(request, maoobra_id):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    elif  tipo_user == 'admin':
        # Buscar o fornecedor com base no ID fornecido
        with connection.cursor() as cursor:
            cursor.execute('SELECT * FROM maoobra WHERE maoobra_id = %s', [maoobra_id])
            maoObra_data = cursor.fetchone()

        if request.method == 'POST':
            form = formularioAdiconarMaoObra(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                preco = float(form.cleaned_data["preco"])

                # Lógica para desassociar o componente
                with connection.cursor() as cursor:
                    cursor.execute('CALL editar_maoObra(%s, %s, %s::MONEY)', [
                        maoobra_id, nome, preco]
                        )
                    
                messages.success(request, 'Mão de obra Editado.')
                # Passar os dados para o template
                return redirect('listarMaoDeObra')
        else:
            form = formularioAdiconarMaoObra(initial={
            'nome': maoObra_data[1],
            'preco': float(maoObra_data[2].replace('€', '').replace(',', '.'))
        })

    return render(request, 'AdicionarMaoDeObra.html', {'form': form}) 


    #Mostrar Fornecedores
@login_required(login_url='/login/') 
def desativarMaoObra(request, maoobra_id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desativarMaoObra(%s)', [maoobra_id])

    messages.success(request, 'Mão de obra Desativado.')

    # Passar os dados para o template
    return redirect('listarMaoDeObra')

#Ativar fornecedor
@login_required(login_url='/login/') 
def ativarMaoObra(request, maoobra_id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL ativarMaoObra(%s)', [maoobra_id])

    messages.success(request, 'Mão de obra Ativado.')

    # Passar os dados para o template
    return redirect('listarMaoDeObra')





#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarEquipamentos(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
    nome_filtro = request.GET.get('nome')
    estado_filter = request.GET.get('status', '')  # Obtém o valor do filtro de estado
    disponibilidade_filter = request.GET.get('disponibilidade', '')  # Obtém o valor do filtro de estado

    if not disponibilidade_filter:
        disponibilidade_filter = None

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT * FROM listar_equipamentos(%s,%s,%s)", [nome_filtro,estado_filter,disponibilidade_filter]
        )
        equipamentos = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listaEquipamentos.html', {'equipamentos': equipamentos, 'nome_filtro':nome_filtro, 'estado_filter':estado_filter, 'disponibilidade_filter':disponibilidade_filter})


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

                
                with connection.cursor() as cursor:
                    # Chama a stored procedure com um parâmetro OUT
                    cursor.execute('CALL adicionar_equipamento(%s, %s, %s)', [nome, descricao, modelo])

                with connection.cursor() as cursorID:
                    # Chama a stored procedure com um parâmetro OUT
                    cursorID.execute('SELECT * FROM equipamentos ORDER BY id_equipamentos DESC LIMIT 1')
                    ultimo_equipamento = cursorID.fetchone()

                    id_equipamento = ultimo_equipamento[0]
                    RegistarEquipamentosMongo(id_equipamento, nome, descricao, modelo)


                messages.success(request, 'Equipamento adicionado com sucesso.')
                return redirect('listarEquipamentos')

        else:
            form = formualarioRegistoEquipamentos()

    return render(request, 'AdicionarEquipamentos.html', {'form': form})


# editar fornecedor 
@login_required(login_url='/login/') 
def editar_equipamento(request, id_equipamento):
    # Verificar se o usuário é do tipo "admin" usando a informação armazenada na sessão
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    elif  tipo_user == 'admin':

        # Buscar o fornecedor com base no ID fornecido
        with connection.cursor() as cursor:
            cursor.execute('SELECT * FROM equipamentos WHERE id_equipamentos = %s', [id_equipamento])
            fornecedor_data = cursor.fetchone()

        if request.method == 'POST':
            form = formualarioRegistoEquipamentos(request.POST)
            if form.is_valid():
                nome = form.cleaned_data["nome"]
                descricao = form.cleaned_data["descricao"]
                modelo = form.cleaned_data["modelo"]

                # Lógica para desassociar o componente
                with connection.cursor() as cursor:
                    cursor.execute('CALL editar_equipamento(%s, %s, %s, %s)', [
                        id_equipamento, nome, descricao, modelo]
                        )
                    
                    EditarEquipamentoMongo(id_equipamento,nome, descricao, modelo)
                    
                messages.success(request, 'Equipamento Editado.')

                # Passar os dados para o template
                return redirect('listarEquipamentos')

        else:
            form = formualarioRegistoEquipamentos(initial={
            'nome': fornecedor_data[1],
            'descricao': fornecedor_data[2],
            'modelo': fornecedor_data[3]
        })

    return render(request, 'AdicionarEquipamentos.html', {'form': form})


# regista Equipamneto Mongo
def RegistarEquipamentosMongo(id_equipamento, nome, descricao, modelo):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    documento = {"idEquipamento": id_equipamento, "nome": nome, "descricao": descricao, "modelo": modelo, "comp": [], "stock": 0, "preco": 0, "estado": 'Ativo', "disponivel": False}
    colecaoEquipamentos.insert_one(documento)

# eidtar Equipamento Mongo
def EditarEquipamentoMongo(id_equipamento, nome, descricao, modelo):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    filtro = {"idEquipamento": id_equipamento}
    novo_valor = {"$set": {"nome": nome, "descricao": descricao, "modelo": modelo}}
    colecaoEquipamentos.update_one(filtro, novo_valor)



@login_required(login_url='/login/') 
def associarCompEquip(request, id):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    if request.method == 'POST':
        componente_id = request.POST.get('componente_id')
        componentes_para_mongo = []

        # Chama o procedimento de associação
        with connection.cursor() as cursor:
            cursor.execute('CALL associar_equipamento_componente(%s, %s)', [id, componente_id])

            # Consulta para obter os componentes associados ao equipamento
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT c.nome, c.referencia, ec.quantidade
                    FROM componentes c
                    JOIN equipamentos_componentes ec ON c.componentes_id = ec.id_componente
                    WHERE ec.id_equipamento = %s
                """, [id])
                componentes_mongo = cursor.fetchall()

                for componente in componentes_mongo:  # Corrige o nome da variável
                    nome, referencia, quantidade = componente
                    componente_info = {
                        'nome': nome,
                        'referencia': referencia,
                        'quantidade': quantidade
                    }
                    componentes_para_mongo.append(componente_info)

                PopularComponenteEquipamentosMongo(id, componentes_para_mongo)
        
        messages.success(request, 'Componente associado com sucesso.')

    # Consulta para obter a lista de componentes
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT c.componentes_id, c.nome, c.referencia, f.nome as nome_fornecedor, c.categoria
            FROM componentes c
            JOIN fornecedores f ON c.fornecedor_id = f.fornecedor_id
                       WHERE c.estado = 'Ativo'
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



def PopularComponenteEquipamentosMongo(id_equipamento, componentes_para_mongo):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    
    # Filtro para encontrar o documento com o id_equipamento correspondente
    filtro = {"idEquipamento": id_equipamento}
    
    # Atualiza o documento, definindo o novo valor para o array comp
    atualizacao = {"$set": {"comp": componentes_para_mongo}}
    
    # Atualiza o documento na coleção de Equipamentos
    colecaoEquipamentos.update_one(filtro, atualizacao)



@login_required(login_url='/login/') 
def desassociarComponente(request, id_equipamento, id_componente):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desassociar_equipamento_componente(%s, %s)', [id_equipamento, id_componente])

        componentes_para_mongo = []
        # Consulta para obter os componentes associados ao equipamento
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT c.nome, c.referencia, ec.quantidade
                FROM componentes c
                JOIN equipamentos_componentes ec ON c.componentes_id = ec.id_componente
                WHERE ec.id_equipamento = %s
            """, [id_equipamento])
            componentes_mongo = cursor.fetchall()

            for componente in componentes_mongo:  # Corrige o nome da variável
                nome, referencia, quantidade = componente
                componente_info = {
                    'nome': nome,
                    'referencia': referencia,
                    'quantidade': quantidade
                }
                componentes_para_mongo.append(componente_info)

        PopularComponenteEquipamentosMongo(id_equipamento, componentes_para_mongo)

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

            try:
                with connection.cursor() as cursor:
                    cursor.execute('CALL inserir_ordemproducao(%s, %s, %s)', [id_equipamento, maoDeObra_id, quant])

                messages.success(request, 'Ordem de produção criada com sucesso.')
                return redirect('listarEquipamentos')
            except InternalError as e:
                if 'Componente insuficiente para produzir a quantidade desejada' in str(e):
                    messages.error(request, 'Erro ao criar ordem de produção: Componente insuficiente para produzir a quantidade desejada')
                else:
                    messages.error(request, 'Erro ao criar ordem de produção: ' + str(e))
    else:
        form = formularioCriarOrdemPorducao()
        form.fields['maoDeObra'].choices = choices  # Configurar as opções do fornecedor no carregamento inicial


    return render(request, 'criarOrdemProducao.html', {'form': form})   




@login_required(login_url='/login/') 
def desativarEquipamento(request, id_equipamento):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL desativarEquipamento(%s)', [id_equipamento])

    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    filtro = {"idEquipamento": id_equipamento}
    atualizacao = {"$set": {"estado":'Inativo', "disponivel": False}}
    colecaoEquipamentos.update_one(filtro, atualizacao)

    messages.success(request, 'Equipamento Desativado.')

    # Passar os dados para o template
    return redirect('listarEquipamentos')


@login_required(login_url='/login/') 
def ativarEquipamento(request, id_equipamento):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL ativarEquipamento(%s)', [id_equipamento])

    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    filtro = {"idEquipamento": id_equipamento}
    atualizacao = {"$set": {"estado":'Ativo'}}
    colecaoEquipamentos.update_one(filtro, atualizacao)

    messages.success(request, 'Equipamento Ativado.')

    # Passar os dados para o template
    return redirect('listarEquipamentos')


def indisponivelEquipamento(request, id_equipamento):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL indisponivelEquipamento(%s)', [id_equipamento])

    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    filtro = {"idEquipamento": id_equipamento}
    atualizacao = {"$set": {"disponivel":False}}
    colecaoEquipamentos.update_one(filtro, atualizacao)

    messages.success(request, 'Equipamento Indisponivel.')

    # Passar os dados para o template
    return redirect('listarEquipamentos')


@login_required(login_url='/login/') 
def disponivelEquipamento(request, id_equipamento):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')

    # Lógica para desassociar o componente
    with connection.cursor() as cursor:
        cursor.execute('CALL disponivelEquipamento(%s)', [id_equipamento])

    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    filtro = {"idEquipamento": id_equipamento}
    atualizacao = {"$set": {"disponivel":True}}
    colecaoEquipamentos.update_one(filtro, atualizacao)

    messages.success(request, 'Equipamento Disponivel.')

    # Passar os dados para o template
    return redirect('listarEquipamentos')


@login_required(login_url='/login/') 
def adicionarPreco(request, id_equipamento):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        return redirect('login')
    elif tipo_user == 'admin':
        if request.method == 'POST':
            form = formualarioAdicionarPreco(request.POST)
            if form.is_valid():
                preco = float(form.cleaned_data["preco"])

                with connection.cursor() as cursor:
                     # Chama a stored procedure com um parâmetro OUT
                    cursor.execute('CALL adicionar_equipamento_preco(%s, %s::MONEY)', [id_equipamento, preco])

                    mongo_db = conexaomongo
                    colecaoEquipamentos = mongo_db["Equipamentos"]
                    filtro = {"idEquipamento": id_equipamento}
                    atualizacao = {"$set": {"preco":preco}}
                    colecaoEquipamentos.update_one(filtro, atualizacao)

                    messages.success(request, 'Preço adicionado com sucesso.')
                    return redirect('listarEquipamentos')

        else:
            form = formualarioAdicionarPreco()

    return render(request, 'AdicionarPrecoEquipamento.html', {'form': form})







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

        with connection.cursor() as cursor:
            cursor.execute("SELECT id_equipamento, quantidade FROM ordemproducao WHERE id_ordem_prod = %s", [ordem_id])
            detalhes_ordem = cursor.fetchall()

            adicionarStockEquipamentoMongo(detalhes_ordem)

    messages.success(request, 'Ordem de produção concluída.')
    
    # Redirecione de volta à página de associação
    return redirect('listarOrdensProducao')

#Adiciona Sotck a equipamento
def adicionarStockEquipamentoMongo(detalhes_ordem):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    for detalhe in detalhes_ordem:
        id_equipamento, quantidade = detalhe[0], detalhe[1]
        filtro = {"idEquipamento": id_equipamento}
        atualizacao = {"$inc": {"stock": quantidade}}
        colecaoEquipamentos.update_one(filtro, atualizacao)


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


    

#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarClientes(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
    nome_filtro = request.GET.get('nome', '')

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_clientes(%s)",[nome_filtro])
        clientes = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listaClientes.html', {'clientes': clientes, 'nome_filtro': nome_filtro})








#Listar Equiapmentos Cliente
@login_required(login_url='/login/') 
def listarEquipamentosMongo(request):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]
    equipamentos = colecaoEquipamentos.find({"estado": "Ativo", "disponivel": True}, {"_id": 0})
    return render(request, 'MostrarEquipamentosMongo.html', {'equipamentos': equipamentos})




@login_required(login_url='/login/') 
def adicionarCarrinho(request, equipamento_id):
    id_user = request.session.get('user_id', None)

    # Lógica para adicionar o equipamento ao carrinho
    with connection.cursor() as cursor:
        cursor.execute('CALL adicionar_equipamento_carrinho(%s, %s)', [id_user, equipamento_id])

        RemoveStockEquipamentoMongo(equipamento_id)

    messages.success(request, 'Equipamento adicionado ao carrinho.')

    # Redireciona para a página desejada após a adição ao carrinho
    return redirect('listarEquipamentosMongo')

def RemoveStockEquipamentoMongo(equipamento_id):
    mongo_db = conexaomongo
    colecaoEquipamentos = mongo_db["Equipamentos"]

    filtro = {"idEquipamento": equipamento_id}
    atualizacao = {"$inc": {"stock": -1}}
    colecaoEquipamentos.update_one(filtro, atualizacao)



#Mostrar Fornecedores
@login_required(login_url='/login/') 
def listarEquipamnetosCarrinho(request):
    id_user = request.session.get('user_id', None)

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_carrinho(%s)",[id_user])
        equipamentos = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'MostrarCarrinhoCliente.html', {'equipamentos': equipamentos})



@login_required(login_url='/login/') 
def remover_equipamento_carrinho(request, equipamento_id, id_carrinho):

    with connection.cursor() as cursor:
            cursor.execute("SELECT id_equipamentos, quantidade_equip FROM carrinho_produtos WHERE id_carrinho = %s AND id_equipamentos = %s", [id_carrinho, equipamento_id])
            detalhes = cursor.fetchall()

            adicionarStockEquipamentoMongo(detalhes)
    # Lógica para adicionar o equipamento ao carrinho
    with connection.cursor() as cursor:
        cursor.execute('CALL remover_equipamento_carrinho(%s, %s)', [id_carrinho, equipamento_id])

        

    messages.success(request, 'Equipamento removido do carrinho.')

    # Redireciona para a página desejada após a adição ao carrinho
    return redirect('listarEquipamnetosCarrinho')


@login_required(login_url='/login/') 
def finalizarCompra(request, id_carrinho):
    id_user = request.session.get('user_id', None)

    with connection.cursor() as cursor:
            cursor.execute(
                "CALL finalizarCompra_criarRecibo(%s, %s)", [id_user, id_carrinho]
            )
    
    # Configurar a resposta HTTP para download do arquivo JSON
    with connection.cursor() as cursor:
        cursor.execute("SELECT dados_json FROM recibos WHERE id_carrinho = LASTVAL()")
        dados_encomenda = cursor.fetchall()

        if dados_encomenda:
            dados_encomenda = dados_encomenda[0][0]
            response = HttpResponse(dados_encomenda, content_type='application/json')
            response['Content-Disposition'] = f'attachment; filename=guia_encomenda_{id}.json'

    messages.success(request, 'Equipamento removido do carrinho.')

    # Redireciona para a página desejada após a adição ao carrinho
    return redirect('listarEquipamnetosCarrinho')


#Listar Compras User
@login_required(login_url='/login/') 
def listaCompras(request):
    id_user = request.session.get('user_id', None)
    id_carrinho_filtro = request.GET.get('id_carrinho')
    order_by = request.GET.get('order_by')

    # Verificar se id_encomenda_filter não está vazio antes de converter para inteiro
    id_carrinho_filtro = int(id_carrinho_filtro) if id_carrinho_filtro else None

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_compras_user(%s, %s, %s)",[id_user, id_carrinho_filtro, order_by])
        compras = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listaCompras.html', {'compras': compras, 'id_carrinho_filtro':id_carrinho_filtro, 'order_by':order_by})





@login_required(login_url='/login/') 
def download_jsonRecibo(request, id_carrinho):

    # Aqui você coloca a lógica para obter os dados do banco de dados
    with connection.cursor() as cursor:
        cursor.execute("SELECT dados_json FROM recibos WHERE id_carrinho = %s", [id_carrinho])
        dados_json = cursor.fetchone()

    # Verificar se encontrou dados para a encomenda específica
    if dados_json:
        # Convertendo os dados para string JSON
        json_content = dados_json[0]
        
        # Configurar a resposta HTTP para download do arquivo JSON
        response = HttpResponse(json_content, content_type='application/json')
        response['Content-Disposition'] = f'attachment; filename=Recibo_{id_carrinho}.json'

        return response
    else:
        # Se não encontrar dados, pode retornar uma resposta indicando isso
        return HttpResponse("Dados da encomenda não encontrados.")
    


@login_required(login_url='/login/') 
def listaVendas(request):
    tipo_user = request.session.get('tipo_user', None)

    if tipo_user != 'admin':
        # Se não for um admin, redirecione para uma página de acesso negado ou outra página desejada
        return redirect('login')
    
    id_carrinho_filtro = request.GET.get('id_carrinho')
    order_by = request.GET.get('order_by')

    # Verificar se id_encomenda_filter não está vazio antes de converter para inteiro
    id_carrinho_filtro = int(id_carrinho_filtro) if id_carrinho_filtro else None

    # Consulta ao banco de dados para obter mão de obra com base no filtro de nome e ordenação
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM listar_vendas(%s, %s)", [id_carrinho_filtro, order_by])
        vendas = cursor.fetchall()
        
    # Passar os dados para o template
    return render(request, 'listaVendas.html', {'vendas': vendas, 'id_carrinho_filtro':id_carrinho_filtro, 'order_by':order_by})

