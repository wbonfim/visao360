#!/bin/bash
# Script para migração em servidores existentes

echo "1. Parando serviços..."
sudo systemctl stop gunicorn nginx

echo "2. Atualizando Gunicorn..."
sudo /opt/visao360/venv/bin/pip install --upgrade gunicorn

echo "3. Aplicando novas configurações..."
sudo mkdir -p /run/gunicorn
sudo chown www-data:www-data /run/gunicorn

echo "4. Atualizando service file..."
sudo tee -a /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Service]
Restart=always
RestartSec=5s
Environment="PATH=/opt/visao360/venv/bin"
EOF

echo "5. Coletando arquivos estáticos..."
sudo -u www-data /opt/visao360/venv/bin/python /opt/visao360/visao360/manage.py collectstatic --noinput

echo "6. Reiniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn nginx

echo "Migração concluída com sucesso!"
echo "Verifique o status com: sudo systemctl status gunicorn"
