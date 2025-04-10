#!/bin/bash
# Script de instalação completo para Visao360 no Ubuntu

# 1. Atualizar sistema
echo "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências
echo "Instalando dependências..."
sudo apt install -y \
    git python3-pip python3-venv python3-dev \
    libpq-dev nginx postgresql postgresql-contrib \
    redis-server

# 3. Configurar PostgreSQL
echo "Configurando banco de dados..."
sudo -u postgres psql -c "CREATE DATABASE visao360;"
sudo -u postgres psql -c "CREATE USER visao360user WITH PASSWORD 'senha_segura';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE visao360 TO visao360user;"

# 4. Criar estrutura de diretórios
echo "Preparando ambiente..."
sudo mkdir -p /opt/visao360
sudo cp /var/www/visao360/requirements.txt /opt/visao360/
sudo chown -R www-data:www-data /opt/visao360

# 5. Configurar ambiente virtual
echo "Configurando Python..."
sudo python3 -m venv /opt/visao360/venv
sudo /opt/visao360/venv/bin/pip install --upgrade pip
sudo /opt/visao360/venv/bin/pip install gunicorn psycopg2-binary
sudo /opt/visao360/venv/bin/pip install -r /opt/visao360/requirements.txt

# 6. Configurar Gunicorn
echo "Configurando Gunicorn..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/visao360
ExecStart=/opt/visao360/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/opt/visao360/visao360.sock visao360.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# 7. Configurar Nginx
echo "Configurando Nginx..."
sudo tee /etc/nginx/sites-available/visao360 > /dev/null <<EOF
server {
    listen 80;
    server_name seu_dominio.com;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /opt/visao360;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/visao360/visao360.sock;
    }
}
EOF

# 8. Finalizar instalação
echo "Finalizando instalação..."
sudo ln -s /etc/nginx/sites-available/visao360 /etc/nginx/sites-enabled
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl start gunicorn && sudo systemctl enable gunicorn

echo "Instalação completa!"
echo "Acesse: http://seu_dominio.com"
echo "Configure o domínio real no arquivo /etc/nginx/sites-available/visao360"
