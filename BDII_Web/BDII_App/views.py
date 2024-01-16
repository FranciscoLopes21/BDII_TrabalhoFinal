from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.db import connection
from .forms import formularioRegisto, formualarioRegistoEquipamentos, formularioLogin, formularioAdiconarFornecedor
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from django.contrib.auth import login, authenticate
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth import logout
from django.core.exceptions import ValidationError

# Create your views here.


def home(request):
    return render(request, 'home.html')


def logout_view(request):
    logout(request)
    return redirect('home') 

def loginClient(request):
    form = formularioLogin()

    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        id = 0

        # Verificar se o usuário existe na tabela 'users' com SQL direto
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE email = %s", [email])
            user_data = cursor.fetchone()

        if user_data and password == user_data[6]:  # Supondo que a senha esteja no índice 5
            # Criar ou obter um objeto User do Django
            user, created = User.objects.get_or_create(username=email, email=email)
            
            if created:
                # Se o usuário foi criado agora, configure a senha
                user.set_password(password)
                user.save()

            # Autenticar manualmente
            user = authenticate(request, username=email, password=password)

            if user is not None:
                login(request, user)

                # Armazenar informações do usuário na sessão
                request.session['user_id'] = user.id
                request.session['user_email'] = user.email
                request.session['tipo_user'] = user_data[7]

                return redirect('room')
        else:
            messages.error(request, 'Credenciais inválidas. Tente novamente.')

    # Passar o formulário para o contexto ao renderizar a página
    return render(request, 'login.html', {'form': form})

@login_required(login_url='/login/') 
def room(request):

    # Aqui, você pode acessar o usuário autenticado usando request.user
    user = request.user

    print("User ID:", request.user.id)
    print("Is Authenticated:", request.user.is_authenticated)

    # Verifique se o usuário está autenticado
    if not user.is_authenticated:
        # Redirecione para a página de login
        return redirect('login')

    # Restante da lógica da sua view
    return render(request, 'room.html', {'user': user})

# regista um novo utilizador
def registarUtilizador(request):
    if request.method == 'POST':
        form = formularioRegisto(request.POST)
        if form.is_valid():
            email = form.cleaned_data["email"]

            # Verificar se o usuário já existe na tabela 'users' com SQL direto
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1 FROM users WHERE email = %s", [email])
                user_exists = cursor.fetchone()

            if user_exists:
                messages.error(request, 'Este email já está em uso.')
                return redirect('registar')

            # Continuação do seu código para inserir o usuário na tabela 'users'
            with connection.cursor() as cursor:
                # Exemplo de inserção
                cursor.execute(
                    "INSERT INTO users (nome, apelido, data_nascimento, morada, email, password, tipo_user) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    [form.cleaned_data["nome"], form.cleaned_data["apelido"], form.cleaned_data["data_nascimento"],
                     form.cleaned_data["morada"], email, form.cleaned_data["password"], 'Client']
                )

                # Autenticar o usuário recém-criado usando o modelo de usuário padrão do Django
                user = authenticate(request, username=email, password=form.cleaned_data["password"])
                if user is not None:
                    login(request, user)

                # Redirecionar para a página inicial room
                return redirect('room')

    else:
        form = formularioRegisto()

    return render(request, 'Registar.html', {'form': form})


# regista um novo utilizador
def RegistarEquipamentos(request):
    form = formualarioRegistoEquipamentos()
    return render(request, 'RegistarEquipamentos.html', {'form': form})   

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
        if nome_filter:
            cursor.execute("SELECT * FROM Fornecedores WHERE nome LIKE %s", ['%' + nome_filter + '%'])
        else:
            cursor.execute("SELECT * FROM Fornecedores")

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
                    return redirect('room')

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