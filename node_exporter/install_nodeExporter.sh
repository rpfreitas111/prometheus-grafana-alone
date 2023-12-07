# Go to https://github.com/prometheus/node_exporter/releases to get the latest version number.
echo "Script para instalar node exporter em vm linux"
echo "--------------------------------------------------------------------------"
echo "Verificar se dependências foram instaladas com sucesso"
list=`apt -qq list jq apache2-utils |grep installed`
if [ -z "${list}" ]
  then
    echo "Instalar dependências para o node exporter"
    sudo apt update -yq && sudo apt install apache2-utils jq -yq
    clear
  else
    echo "Dependências já estão instaladas"
    sleep 2
    clear
fi
echo "--------------------------------------------------------------------------"
echo "Listar as ultimas 5 versões disponíveis de node-exporter"
curl -sL https://api.github.com/repos/prometheus/node_exporter/tags |jq -r ".[].name" |head -n 5|sed 's/v//g'
export node_exporter_version="1.7.0"
export node_exporter_release="linux-amd64"
echo $node_exporter_version
read -p "insira versão desejada ou pressione enter para utilizar versão default 1.7.0: " nodeVersion
if [ ! -z "${nodeVersion}" ]
  then
    export node_exporter_version=$nodeVersion
    echo "Será instalado o node exporter na versão $node_exporter_version"
    sleep 2
fi
# Download and install node_exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz
tar xvfa node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz
sudo mv node_exporter-${node_exporter_version}.${node_exporter_release}/node_exporter /usr/local/bin/
rm -fr node_exporter-${node_exporter_version}.${node_exporter_release} node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz

# Create a user "node_exporter"
sudo useradd -rs /bin/false node_exporter

# Create a systemd service to start node_exporter automatically on boot
sudo cat << 'EOF' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/prometheus_node_exporter/configuration.yml

[Install]
WantedBy=multi-user.target
EOF

# Create a configuration directory and file
sudo mkdir -p /etc/prometheus_node_exporter/
sudo touch /etc/prometheus_node_exporter/configuration.yml
sudo chmod 700 /etc/prometheus_node_exporter
sudo chmod 600 /etc/prometheus_node_exporter/*
sudo chown -R node_exporter:node_exporter /etc/prometheus_node_exporter


sudo systemctl daemon-reload
sudo systemctl enable node_exporter

#  Include username and password to access node_exporter
export password=`openssl rand -base64 32`
export passwordHashed=`echo ${password} | htpasswd -inBC 10 "" | tr -d ':\n'`

sudo cat << EOF > /etc/prometheus_node_exporter/configuration.yml
basic_auth_users:
  prometheus: ${passwordHashed}

EOF
# Send password to user home
echo "Clear password to keep for Prometheus Server: ${password}" > ~/password_access.txt

# Start the node_exporter daemon and check its status
sudo systemctl stop node_exporter
sudo systemctl start node_exporter
activeNode=`ss -ltn |grep 9100 |cut -d ':' -f 2 |cut -d ' ' -f 1`
if [ -z "${activeNode}" ]
  then
    echo "NODE EXPORTER ESTÁ RODANDO NA PORTA 9100"
    echo "sudo systemctl restart node_exporter"
    read -p "Node exporter reiniciado pressione enter para continuar"
  else
    echo "NODE EXPORTER ESTÁ ATIVO E RODANDO NA PORTA 9100"
    sudo systemctl status node_exporter
    read -p "Pressione enter para continuar"
fi
clear
hostIP=`ip a s eth0 | grep -E -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2`
pubIP=`curl -s ifconfig.me`
echo "--------------------------------------------------------------------------"
echo "para ter mais informações sobre a versão instalada acesse"
echo "https://github.com/prometheus/node_exporter/releases"
echo "--------------------------------------------------------------------------"
echo "Para validar acesse local http://$hostIP:9100/metrics"
echo "utilizando o usuário prometheus com a senha criada no usuário root"
echo "Para validar o acesso publico acesse http://$pubIP:9100/metrics com o mesmo usuário e senha"