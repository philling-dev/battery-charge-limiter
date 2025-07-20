import os
import sys
import pytest
from unittest.mock import patch, mock_open

# Adiciona o diretório pai ao sys.path para que bcl.py possa ser importado
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import bcl

# Define o caminho base para o ambiente simulado para os testes
MOCK_SYS_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../mock_sys'))

@pytest.fixture(autouse=True)
def setup_mock_sys():
    """
    Fixture para garantir que o ambiente simulado esteja limpo antes de cada teste.
    """
    # Garante que o arquivo simulado esteja vazio ou com um valor padrão
    mock_file_path = os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')
    os.makedirs(os.path.dirname(mock_file_path), exist_ok=True)
    with open(mock_file_path, 'w') as f:
        f.write('')

@patch('bcl.glob.glob')
@patch('bcl.os.path.exists')
def test_find_control_file_found(mock_exists, mock_glob):
    """
    Testa se find_control_file encontra o arquivo de controle corretamente.
    """
    # Simula a existência de BAT0 e do arquivo de controle
    mock_glob.return_value = [os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0')]
    mock_exists.side_effect = lambda path: path == os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')

    bcl.BASE_PATH = os.path.join(MOCK_SYS_PATH, 'class/power_supply/')
    found_path = bcl.find_control_file(bcl.BASE_PATH)
    assert found_path == os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')

@patch('bcl.glob.glob')
@patch('bcl.os.path.exists')
def test_find_control_file_not_found(mock_exists, mock_glob):
    """
    Testa se find_control_file retorna None quando nenhum arquivo é encontrado.
    """
    # Simula que não há diretórios BAT* ou arquivos de controle
    mock_glob.return_value = []
    mock_exists.return_value = False

    bcl.BASE_PATH = os.path.join(MOCK_SYS_PATH, 'class/power_supply/')
    found_path = bcl.find_control_file(bcl.BASE_PATH)
    assert found_path is None

@patch('builtins.open', new_callable=mock_open)
@patch('sys.stdout')
def test_set_charge_limit_success(mock_stdout, mock_file):
    """
    Testa se set_charge_limit escreve o valor correto e imprime sucesso.
    """
    test_path = os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')
    bcl.set_charge_limit(85, test_path)
    mock_file.assert_called_once_with(test_path, 'w')
    mock_file().write.assert_called_once_with('85')
    # Verifica se a string esperada está em alguma das chamadas de write
    assert any("Sucesso: Limite de carga da bateria definido para 85%." in call[0][0] for call in mock_stdout.write.call_args_list)

@patch('builtins.open', new_callable=mock_open)
@patch('sys.stdout')
def test_set_charge_limit_invalid_value(mock_stdout, mock_file):
    """
    Testa se set_charge_limit lida com valores inválidos.
    """
    test_path = os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')
    bcl.set_charge_limit(101, test_path)
    mock_file.assert_not_called()
    assert any("Erro: O limite de carga deve ser um número entre 1 e 100." in call[0][0] for call in mock_stdout.write.call_args_list)

@patch('builtins.open', new_callable=mock_open)
@patch('sys.stdout')
def test_set_charge_limit_io_error(mock_stdout, mock_file):
    """
    Testa se set_charge_limit lida com erros de I/O (permissão).
    """
    mock_file.side_effect = IOError("Permissão negada")
    test_path = os.path.join(MOCK_SYS_PATH, 'class/power_supply/BAT0/charge_control_end_threshold')
    bcl.set_charge_limit(70, test_path)
    mock_file.assert_called_once_with(test_path, 'w')
    assert any("Erro ao escrever no arquivo de controle da bateria: Permissão negada" in call[0][0] for call in mock_stdout.write.call_args_list)
    assert any("Verifique se você executou o script com permissões de superusuário (sudo)." in call[0][0] for call in mock_stdout.write.call_args_list)