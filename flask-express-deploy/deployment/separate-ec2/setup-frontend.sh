#!/bin/bash
# =============================================================
# Scenario 2: Express Frontend EC2 setup
# Run this on the FRONTEND EC2 instance (Ubuntu 22.04)
# Usage: FLASK_IP=<backend-ec2-public-ip> bash setup-frontend.sh
# =============================================================

set -e

FLASK_IP=${FLASK_IP:-"REPLACE_WITH_BACKEND_EC2_IP"}

echo ">>> Updating system..."
sudo apt-get update -y

echo ">>> Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo ">>> Installing Nginx..."
sudo apt-get install -y nginx

echo ">>> Cloning repo..."
cd /home/ubuntu
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1/flask-express-deploy/frontend
npm install --production

echo ">>> Creating Express systemd service..."
sudo tee /etc/systemd/system/express-frontend.service > /dev/null <<EOF
[Unit]
Description=Express Frontend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend
Environment="PORT=3000"
Environment="FLASK_URL=http://${FLASK_IP}:5000"
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Configuring Nginx..."
sudo tee /etc/nginx/sites-available/express-frontend > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/express-frontend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

sudo systemctl daemon-reload
sudo systemctl enable express-frontend nginx
sudo systemctl start express-frontend nginx

echo ""
echo "=== Express Frontend Ready ==="
echo "Public URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
