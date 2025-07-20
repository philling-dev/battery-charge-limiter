
#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root. Use sudo."
    exit 1
fi

# Caminhos de origem (dentro do diretório do projeto)
SOURCE_DIR="$(pwd)"

# Caminhos de destino no sistema
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"
CONFIG_PATH="/etc"

# Copiando os arquivos
echo "Copiando arquivos para o sistema..."
cp "$SOURCE_DIR/bcl.py" "$BIN_PATH/bcl"
cp "$SOURCE_DIR/bcl-apply" "$BIN_PATH/bcl-apply"
cp "$SOURCE_DIR/bcl.service" "$SERVICE_PATH/bcl.service"

# Cria o arquivo de configuração se ele não existir
if [ ! -f "$CONFIG_PATH/bcl.conf" ]; then
    cp "$SOURCE_DIR/bcl.conf" "$CONFIG_PATH/bcl.conf"
    echo "Arquivo de configuração criado em $CONFIG_PATH/bcl.conf com o valor padrão de 80."
fi

# Dando permissões de execução
chmod +x "$BIN_PATH/bcl"
chmod +x "$BIN_PATH/bcl-apply"

# Recarregando o systemd e habilitando o serviço
echo "Recarregando o daemon do systemd..."
systemctl daemon-reload

echo "Habilitando o serviço bcl para iniciar no boot..."
systemctl enable bcl.service

echo "Iniciando o serviço pela primeira vez..."
systemctl start bcl.service

echo ""
echo "Instalação concluída com sucesso!"
echo "Para alterar o limite, edite o arquivo /etc/bcl.conf e reinicie o serviço com 'sudo systemctl restart bcl.service'"
echo "Ou, para aplicar imediatamente, execute: sudo bcl-apply"
