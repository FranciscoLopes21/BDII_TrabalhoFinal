from django.urls import path
from . import views


urlpatterns = [
    
    path('', views.home, name="home"),
    path('room/', views.room, name="room"),
    path('registar/', views.registarUtilizador, name="registar"),
]

