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
    path('editar_fornecedor/<int:id_fornecedor>/', views.editar_fornecedor, name='editar_fornecedor'),
    path('desativarFornecedores/<int:id_fornecedor>/', views.desativarFornecedores, name='desativarFornecedores'),
    path('ativarFornecedores/<int:id_fornecedor>/', views.ativarFornecedores, name='ativarFornecedores'),


    path('listarComponentes/', views.listarComponentes, name='listarComponentes'),
    path('adicionarComponentes/', views.adicionarComponentes, name='adicionarComponentes'),
    path('editar_componentes/<int:id_componente>/', views.editar_componentes, name='editar_componentes'),
    path('enomendarComponentes/<int:id>/', views.enomendarComponentes, name='enomendarComponentes'),
    path('desativarComponente/<int:id_componente>/', views.desativarComponente, name='desativarComponente'),
    path('ativarComponente/<int:id_componente>/', views.ativarComponente, name='ativarComponente'),

    #path('listarFornecedor/Delete/<str:forn>/', views.eleminarFornecedores, name='apagarFornecedor'),

    path('listarMaoDeObra/', views.listarMaoDeObra, name='listarMaoDeObra'),
    path('adicionarMaoObra/', views.adicionarMaoObra, name='adicionarMaoObra'),
    path('editar_maoObra/<int:maoobra_id>/', views.editar_maoObra, name='editar_maoObra'),
    path('desativarMaoObra/<int:maoobra_id>/', views.desativarMaoObra, name='desativarMaoObra'),
    path('ativarMaoObra/<int:maoobra_id>/', views.ativarMaoObra, name='ativarMaoObra'),
    
    
    path('listarEncomendas/', views.listarEncomendas, name='listarEncomendas'),
    path('download_json/<int:id_encomenda>/', views.download_json, name='download_json'),
    path('entregarEncomenda/<int:id_encomenda>/', views.entregarEncomenda, name='entregarEncomenda'),
    path('cancelarEncomenda/<int:id_encomenda>/', views.cancelarEncomenda, name='cancelarEncomenda'),

    path('listarEquipamentos/', views.listarEquipamentos, name='listarEquipamentos'),
    path('RegistarEquipamentos/', views.RegistarEquipamentos, name="RegistarEquipamentos"),
    path('associarCompEquip/<int:id>/', views.associarCompEquip, name="associarCompEquip"),
    path('desassociarComponente/<int:id_equipamento>/<int:id_componente>/', views.desassociarComponente, name='desassociarComponente'),
    path('desativarEquipamento/<int:id_equipamento>/', views.desativarEquipamento, name="desativarEquipamento"),
    path('ativarEquipamento/<int:id_equipamento>/', views.ativarEquipamento, name="ativarEquipamento"),
    path('indisponivelEquipamento/<int:id_equipamento>/', views.indisponivelEquipamento, name="indisponivelEquipamento"),
    path('disponivelEquipamento/<int:id_equipamento>/', views.disponivelEquipamento, name="disponivelEquipamento"),
    path('adicionarPreco/<int:id_equipamento>/', views.adicionarPreco, name="adicionarPreco"),



    path('criarOrdemProducao/<int:id_equipamento>/', views.criarOrdemProducao, name='criarOrdemProducao'),
    path('listarOrdensProducao/', views.listarOrdensProducao, name='listarOrdensProducao'),
    path('concluir_ordem/<int:ordem_id>/', views.concluir_ordem, name='concluir_ordem'),
    path('cancelar_ordem/<int:ordem_id>/', views.cancelar_ordem, name='cancelar_ordem'),



    #Cliente
    path('listarEquipamentosMongo/', views.listarEquipamentosMongo, name='listarEquipamentosMongo'),

]

