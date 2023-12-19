from django import forms
from django.forms.widgets import NumberInput

DATE_INPUT_FORMATS = ['%Y-%m-%d']

class formularioRegisto(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    apelido = forms.CharField(max_length=100, required=False)
    data_nascimento = forms.CharField(max_length=100, widget=NumberInput(attrs={'type': 'date'}), required=False)
    morada = forms.CharField(max_length=100, required=False)
    email = forms.EmailField(required=False)
    password = forms.CharField(widget=forms.PasswordInput(), max_length=16, required=False)


class formualarioRegistoEquipamentos(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    tipo = forms.ChoiceField( required=False)#choices=tiposProdutos,
    quantidade = forms.IntegerField(required=False)
    preço = forms.FloatField(required=False)
    desconto = forms.FloatField(required=False)
