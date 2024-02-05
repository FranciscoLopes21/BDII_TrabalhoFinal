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


class formularioLogin(forms.Form):
    email = forms.EmailField(required=False)
    password = forms.CharField(widget=forms.PasswordInput(), max_length=160, required=False)


class formularioAdiconarFornecedor(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    contacto = forms.CharField(
        max_length=9,
        min_length=9,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'O contato deve ter no máximo 9 dígitos.',
            'invalid': 'Por favor, insira um número válido.',
        }
    )
    morada = forms.CharField(max_length=100, required=False)
    email = forms.EmailField(required=False)


class formularioAdiconarMaoObra(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    preco = forms.DecimalField(
        max_digits=10,  # Define o número máximo de dígitos no preço
        decimal_places=2,  # Define o número de casas decimais
    )


class formularioAdicionarComponentes(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    referencia = forms.CharField(max_length=100, required=False)
    quant = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'A quantidade deve ter no máximo 5 dígitos.',
            'min_length': 'A quantidade deve ter no minimo 1 dígito.',
            'invalid': 'Por favor, insira um número válido.',
        },
        label='Quantidade'
    )
    stockMin = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'A quantidade deve ter no máximo 5 dígitos.',
            'min_length': 'A quantidade deve ter no minimo 1 dígito.',
            'invalid': 'Por favor, insira um número válido.',
        },
        label='Stock Minimo'
    )
    fornecedor = forms.ChoiceField(choices=[], required=False)#choices=fornecedor,
    categoria = forms.IntegerField(required=False)
    preco = forms.DecimalField(
        max_digits=10,  # Define o número máximo de dígitos no preço
        decimal_places=2,  # Define o número de casas decimais
    )

class formularioAdiconarEncomenda(forms.Form):
    quantidade = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'A quantidade deve ter no máximo 5 dígitos.',
            'min_length': 'A quantidade deve ter no minimo 1 dígito.',
            'invalid': 'Por favor, insira um número válido.',
        },
        label='Quantidade'
    )


class formualarioRegistoEquipamentos(forms.Form):
    nome = forms.CharField(max_length=100, required=False)
    descricao = forms.CharField(max_length=100, required=False)
    modelo = forms.CharField(max_length=100, required=False)#choices=tiposProdutos,
    desconto = forms.CharField(
        max_length=3,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'A quantidade deve ter no máximo 3 dígitos.',
            'min_length': 'A quantidade deve ter no minimo 1 dígito.',
            'invalid': 'Por favor, insira um número válido.',
        },
        label='Desconto %'
    )



class formularioCriarOrdemPorducao(forms.Form):
    quant = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=False,
        error_messages={
            'max_length': 'A quantidade deve ter no máximo 5 dígitos.',
            'min_length': 'A quantidade deve ter no minimo 1 dígito.',
            'invalid': 'Por favor, insira um número válido.',
        },
        label='Quantidade'
    )
    maoDeObra = forms.ChoiceField(
        choices=[], required=False,
        label='Mão de obra'
    )#choices=fornecedor,