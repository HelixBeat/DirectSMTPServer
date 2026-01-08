#!/bin/bash
# Monitoring and Logging Setup

# Install monitoring tools
install_monitoring() {
    # Install Prometheus Node Exporter
    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
    sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
    
    # Create systemd service for node_exporter
    sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    sudo useradd -rs /bin/false node_exporter
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
}

# Setup log rotation
setup_logging() {
    sudo tee /etc/logrotate.d/directsmtp > /dev/null <<EOF
/var/log/directsmtp/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 directsmtp directsmtp
    postrotate
        systemctl reload directsmtp
    endscript
}
EOF
}

# Create log directory
sudo mkdir -p /var/log/directsmtp
sudo chown directsmtp:directsmtp /var/log/directsmtp

install_monitoring
setup_logging

echo "Monitoring setup complete!"
echo "Node Exporter running on port 9100"
echo "Logs will be rotated daily in /var/log/directsmtp/"