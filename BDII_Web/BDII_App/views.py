from django.shortcuts import render
from django.http import HttpResponse

from .forms import formularioRegisto, formualarioRegistoEquipamentos
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password


# Create your views here.


def home(request):
    return render(request, 'home.html')

def room(request):
    return render(request, 'room.html')

# regista um novo utilizador
def registarUtilizador(request):
    form = formularioRegisto()
    return render(request, 'Registar.html', {'form': form})   

# regista um novo utilizador
def RegistarEquipamentos(request):
    form = formualarioRegistoEquipamentos()
    return render(request, 'RegistarEquipamentos.html', {'form': form})   

