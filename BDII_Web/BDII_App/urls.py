from django.urls import path
from . import views
from .views import logout_view, listarFornecedores
#from .views import CustomLoginView

urlpatterns = [
    
    path('', views.home, name="home"),
    path('room/', views.room, name="room"),
    path('dashBoard/', views.dashBoardAdmin, name="dashBoardAdmin"),
    path('registar/', views.registarUtilizador, name="registar"),
    path('RegistarEquipamentos/', views.RegistarEquipamentos, name="RegistarEquipamentos"),
    path('login/', views.loginClient, name='login'),
    path('logout/', logout_view, name='logout'),
    path('listarFornecedor/', listarFornecedores, name='listarFornecedor'),
    path('adicionarFornecedor/', views.adicionarFornecedor, name='adicionarFornecedor'),
    path('listarFornecedor/Delete/<str:forn>/', views.eleminarFornecedores, name='apagarFornecedor'),
    path('listarMaoDeObra/', views.listarMaoDeObra, name='listarMaoDeObra'),
    path('adicionarMaoObra/', views.adicionarMaoObra, name='adicionarMaoObra'),


]

