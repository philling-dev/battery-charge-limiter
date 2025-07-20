
import argparse
import os
import glob

# Caminhos base para o ambiente real e o simulado.
REAL_BASE_PATH = '/sys/class/power_supply/'
MOCK_BASE_PATH = os.path.join(os.path.dirname(__file__), 'mock_sys/class/power_supply/')

# Lista de nomes de arquivos de controle conhecidos, em ordem de preferência.
CONTROL_FILES = ['charge_control_end_threshold', 'charge_stop_threshold']

def find_control_file(base_path: str) -> str | None:
    """
    Encontra o primeiro arquivo de controle de carga de bateria disponível no sistema.
    """
    battery_dirs = glob.glob(os.path.join(base_path, 'BAT*'))
    if not battery_dirs:
        return None

    for bat_dir in battery_dirs:
        for control_file in CONTROL_FILES:
            path = os.path.join(bat_dir, control_file)
            if os.path.exists(path):
                return path
    return None

def set_charge_limit(limit: int, control_file_path: str):
    """
    Define o limite de carga da bateria escrevendo no arquivo de controle.
    """
    if not 1 <= limit <= 100:
        print(f"Erro: O limite de carga deve ser um número entre 1 e 100. Valor fornecido: {limit}")
        return

    try:
        with open(control_file_path, 'w') as f:
            f.write(str(limit))
        print(f"Sucesso: Limite de carga da bateria definido para {limit}%.")
        print(f"Arquivo de controle utilizado: {control_file_path}")
    except IOError as e:
        print(f"Erro ao escrever no arquivo de controle da bateria: {e}")
        print("Verifique se você executou o script com permissões de superusuário (sudo).")

def main():
    """
    Função principal para analisar os argumentos da linha de comando.
    """
    parser = argparse.ArgumentParser(
        description="Define um limite de carga para a bateria do laptop.",
        epilog="Exemplo de uso: sudo python bcl.py 80"
    )
    parser.add_argument(
        'limit',
        type=int,
        help="O percentual de carga para definir como limite (1-100)."
    )
    parser.add_argument(
        '--mock',
        action='store_true',
        help="Usar o ambiente simulado para testes."
    )
    args = parser.parse_args()

    base_path_to_use = MOCK_BASE_PATH if args.mock else REAL_BASE_PATH

    control_file = find_control_file(base_path_to_use)

    if not control_file:
        print(f"Erro: Não foi possível encontrar um arquivo de controle de carga de bateria compatível em '{base_path_to_use}'.")
        print("Seu sistema pode não suportar esta funcionalidade.")
        return

    set_charge_limit(args.limit, control_file)

if __name__ == "__main__":
    main()
