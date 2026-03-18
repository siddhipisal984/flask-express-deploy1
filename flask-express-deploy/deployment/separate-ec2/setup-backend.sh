#!/bin/bash
# =============================================================
# Scenario 2: Flask Backend EC2 setup
# Run this on the BACKEND EC2 instance (Ubuntu 22.04)
# =============================================================

set -e

echo ">>> Updating system..."
sudo apt-get update -y

echo ">>> Installing Python..."
sudo apt-get install -y python3 python3-pip python3-venv

echo ">>> Cloning repo..."
cd /home/ubuntu
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1/backend

echo ">>> Setting up virtualenv..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

echo ">>> Creating Flask systemd service..."
sudo tee /etc/systemd/system/flask-backend.service > /dev/null <<EOF
[Unit]
Description=Flask Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-express-deploy1/backend
Environment="PATH=/home/ubuntu/flask-express-deploy1/backend/venv/bin"
ExecStart=/home/ubuntu/flask-express-deploy1/backend/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable flask-backend
sudo systemctl start flask-backend

echo ""
echo "=== Flask Backend Ready ==="
echo "Running on port 5000"
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "NOTE: Copy this IP — you need it for the frontend setup!"
