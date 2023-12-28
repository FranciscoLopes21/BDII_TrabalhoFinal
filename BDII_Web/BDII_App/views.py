from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.db import connection
from .forms import formularioRegisto, formualarioRegistoEquipamentos
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from django.contrib.auth import login, authenticate


# Create your views here.


def home(request):
    return render(request, 'home.html')

def room(request):
    return render(request, 'room.html')

# regista um novo utilizador
def registarUtilizador(request):
    if request.method == 'POST':
        form = formularioRegisto(request.POST)
        if form.is_valid():
            nome = form.cleaned_data["nome"]
            apelido = form.cleaned_data["apelido"]
            data_nascimento = form.cleaned_data["data_nascimento"]
            morada = form.cleaned_data["morada"]
            email = form.cleaned_data["email"]
            password = make_password(form.cleaned_data["password"])
            tipo_user = "Client"

            with connection.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO users (nome, apelido, data_nascimento, morada, email, password, tipo_user) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    [nome, apelido, data_nascimento, morada, email, password, tipo_user]
                )

                # Autenticar o usuário recém-criado
                user = authenticate(request, username=email, password=password)
                if user is not None:
                    login(request, user)

                # Redirecionar para a página inicial ou outra página desejada
                return redirect('room')

    else:
        form = formularioRegisto()

    return render(request, 'Registar.html', {'form': form})   

# regista um novo utilizador
def RegistarEquipamentos(request):
    form = formualarioRegistoEquipamentos()
    return render(request, 'RegistarEquipamentos.html', {'form': form})   

