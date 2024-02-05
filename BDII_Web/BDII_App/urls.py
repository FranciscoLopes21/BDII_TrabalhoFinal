from django.urls import path
from . import views
from .views import logout_view, listarFornecedores
#from .views import CustomLoginView

urlpatterns = [
    
    path('', views.home, name="home"),
    path('room/', views.room, name="room"),
    path('dashBoard/', views.dashBoardAdmin, name="dashBoardAdmin"),
    path('registar/', views.registarUtilizador, name="registar"),
    path('registarAdmin/', views.registarAdmin, name="registarAdmin"),
    path('login/', views.loginUser, name='login'),
    path('logout/', logout_view, name='logout'),
    path('listarFornecedor/', listarFornecedores, name='listarFornecedor'),
    path('adicionarFornecedor/', views.adicionarFornecedor, name='adicionarFornecedor'),
    path('listarFornecedor/Delete/<str:forn>/', views.eleminarFornecedores, name='apagarFornecedor'),
    path('listarMaoDeObra/', views.listarMaoDeObra, name='listarMaoDeObra'),
    path('adicionarMaoObra/', views.adicionarMaoObra, name='adicionarMaoObra'),
    path('listarComponentes/', views.listarComponentes, name='listarComponentes'),
    path('adicionarComponentes/', views.adicionarComponentes, name='adicionarComponentes'),
    path('enomendarComponentes/<int:id>/', views.enomendarComponentes, name='enomendarComponentes'),
    path('listarEncomendas/', views.listarEncomendas, name='listarEncomendas'),
    path('download_json/<int:id_encomenda>/', views.download_json, name='download_json'),
    path('importar_json_upload/', views.importar_json_upload, name='importar_json_upload'),
    path('listarEquipamentos/', views.listarEquipamentos, name='listarEquipamentos'),
    path('RegistarEquipamentos/', views.RegistarEquipamentos, name="RegistarEquipamentos"),
    path('associarCompEquip/<int:id>/', views.associarCompEquip, name="associarCompEquip"),
    path('desassociarComponente/<int:id_equipamento>/<int:id_componente>/', views.desassociarComponente, name='desassociarComponente'),
    path('criarOrdemProducao/<int:id_equipamento>/', views.criarOrdemProducao, name='criarOrdemProducao'),
    path('listarOrdensProducao/', views.listarOrdensProducao, name='listarOrdensProducao'),
    path('concluir_ordem/<int:ordem_id>/', views.concluir_ordem, name='concluir_ordem'),
    path('cancelar_ordem/<int:ordem_id>/', views.cancelar_ordem, name='cancelar_ordem'),



]

