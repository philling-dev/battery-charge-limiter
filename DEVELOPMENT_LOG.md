
# Log de Desenvolvimento - Battery Charge Limiter

## Fase 1: Pesquisa e Ambiente Simulado

- **Objetivo:** Entender como o limite de carga de bateria funciona no Linux e criar um ambiente de teste seguro em uma máquina desktop.
- **Ações:**
    1.  Pesquisa na web revelou que o controle é feito via arquivos no diretório `/sys/class/power_supply/BAT*/`.
    2.  Os nomes de arquivo mais comuns são `charge_control_end_threshold` e `charge_stop_threshold`.
    3.  Criamos um ambiente simulado em `mock_sys/` para replicar essa estrutura, permitindo o desenvolvimento sem o hardware real.

## Fase 2: Desenvolvimento do Script Principal (`bcl.py`)

- **Objetivo:** Criar um script Python robusto para definir o limite de carga.
- **Ações:**
    1.  Inicialmente, o script tinha um caminho fixo para o arquivo de controle.
    2.  Refatorado para detectar dinamicamente o dispositivo de bateria (`BAT*`) e o arquivo de controle (`charge_control_end_threshold`, etc.).
    3.  Adicionado um argumento `--mock` para facilitar o teste no ambiente simulado, forçando o script a ignorar o sistema de arquivos real.
    4.  Utilizada a biblioteca `argparse` para um tratamento de argumentos de linha de comando limpo e com mensagens de ajuda.

## Fase 3: Empacotamento e Instalação

- **Objetivo:** Transformar o script em uma ferramenta de sistema profissional e fácil de instalar.
- **Componentes Criados:**
    1.  **`bcl.py`**: O script principal que contém a lógica.
    2.  **`bcl.conf`**: Um arquivo de configuração em `/etc/` para armazenar o valor do limite de carga (padrão: 80).
    3.  **`bcl-apply`**: Um script shell auxiliar que lê o valor de `bcl.conf` e o passa para `bcl.py`.
    4.  **`bcl.service`**: Um serviço `systemd` do tipo `oneshot` que executa `bcl-apply` na inicialização do sistema para garantir a persistência.
    5.  **`install.sh`**: Um script de instalação que:
        - Copia todos os arquivos para os locais corretos (`/usr/local/bin/`, `/etc/systemd/system/`, `/etc/`).
        - Define as permissões de execução.
        - Recarrega o `systemd` e habilita/inicia o serviço `bcl`.

## Dependências

- **Python 3:** O script é escrito em Python 3.
- **systemd:** O sistema de instalação e persistência depende do `systemd`.

## Próximos Passos

- Criar um `README.md` amigável para o usuário final.
- Criar um script de desinstalação (`uninstall.sh`).
- Testar em um laptop real.
- Publicar no GitHub.
