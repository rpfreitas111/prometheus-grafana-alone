# Go to https://github.com/prometheus/node_exporter/releases to get the latest version number.
node_exporter_version="1.7.0"
node_exporter_release="linux-amd64"

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
sudo systemctl status node_exporter
