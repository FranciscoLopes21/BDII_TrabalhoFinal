from django import forms
from django.forms.widgets import NumberInput

DATE_INPUT_FORMATS = ['%Y-%m-%d']

class formularioRegisto(forms.Form):
    nome = forms.CharField(max_length=100, required=True)
    apelido = forms.CharField(max_length=100, required=True)
    data_nascimento = forms.CharField(max_length=100, widget=NumberInput(attrs={'type': 'date'}), required=True)
    morada = forms.CharField(max_length=100, required=True)
    email = forms.EmailField(required=True)
    password = forms.CharField(widget=forms.PasswordInput(), max_length=16, required=True)


class formularioLogin(forms.Form):
    email = forms.EmailField(required=True)
    password = forms.CharField(widget=forms.PasswordInput(), max_length=160, required=True)


class formularioAdiconarFornecedor(forms.Form):
    nome = forms.CharField(max_length=100, required=True)
    contacto = forms.CharField(
        max_length=9,
        min_length=9,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=True,
        error_messages={
            'max_length': 'O contacto deve ter 9 digitos.',
            'min_length': 'O contacto deve ter 9 digitos.'
        }
    )
    morada = forms.CharField(max_length=100, required=True)
    email = forms.EmailField(required=True)


class formularioAdiconarMaoObra(forms.Form):
    nome = forms.CharField(max_length=100, required=True)
    preco = forms.DecimalField(
        max_digits=10,  # Define o número máximo de dígitos no preço
        decimal_places=2,  # Define o número de casas decimais
        required=True,
        error_messages={
            'max_length': 'O preço deve ter no maximo 10 digitos.'
        },
    )


class formularioAdicionarComponentes(forms.Form):
    nome = forms.CharField(max_length=100, required=True)
    referencia = forms.CharField(max_length=100, required=True)
    quant = forms.IntegerField(
        min_value=1,
        required=True,
        error_messages={
            'min_value': 'A quantidade deve ser pelo menos 1.',
        },
        label='Quantidade'
    )
    stockMin = forms.IntegerField(
        min_value=1,
        required=True,
        error_messages={
            'min_value': 'O stock mínimo deve ser pelo menos 1.',
        },
        label='Stock Mínimo'
    )
    fornecedor = forms.ChoiceField(choices=[], required=True)
    categoria = forms.CharField(required=True)
    preco = forms.DecimalField(
        max_digits=10,  
        decimal_places=2,
        required=True,
        error_messages={
            'max_digits': 'O preço deve ter no máximo 10 dígitos.',
        },
    )



class formularioAdiconarEncomenda(forms.Form):
    quantidade = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=True,
        error_messages={
            'max_length': 'A quantidade deve ter no minimo 5 digitos.',
            'min_length': 'A quantidade deve ter no minimo 1 digito.'
        },
        label='Quantidade'
    )


class formualarioRegistoEquipamentos(forms.Form):
    nome = forms.CharField(max_length=100, required=True)
    descricao = forms.CharField(max_length=100, required=True)
    modelo = forms.CharField(max_length=100, required=True)#choices=tiposProdutos,

class formualarioAdicionarPreco(forms.Form):
    preco = forms.DecimalField(
        max_digits=10,  # Define o número máximo de dígitos no preço
        decimal_places=2,  # Define o número de casas decimais
        required=True,
        error_messages={
            'max_length': 'O preço deve ter no maximo 10 digitos.'
        },
    )
    

class formularioCriarOrdemPorducao(forms.Form):
    quant = forms.CharField(
        max_length=5,
        min_length=1,
        widget=forms.NumberInput(attrs={'type': 'number'}),
        required=True,
        error_messages={
            'max_length': 'A quantidade deve ter no minimo 5 digitos.',
            'min_length': 'A quantidade deve ter no minimo 1 digito.'
        },
        label='Quantidade'
    )
    maoDeObra = forms.ChoiceField(
        choices=[], required=True,
        label='Mão de obra'
    )#choices=fornecedor,