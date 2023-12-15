from django.shortcuts import render
from django.http import HttpResponse

from .forms import formularioRegisto
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

