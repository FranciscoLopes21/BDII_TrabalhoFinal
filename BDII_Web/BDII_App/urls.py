from django.urls import path
from . import views
from .views import logout_view
#from .views import CustomLoginView

urlpatterns = [
    
    path('', views.home, name="home"),
    path('room/', views.room, name="room"),
    path('registar/', views.registarUtilizador, name="registar"),
    path('RegistarEquipamentos/', views.RegistarEquipamentos, name="RegistarEquipamentos"),
    path('login/', views.loginClient, name='login'),
    path('logout/', logout_view, name='logout'),
    path('adicionarFornecedor/', views.adicionarFornecedor, name='adicionarFornecedor'),

]

