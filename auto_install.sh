#!/bin/bash

# Script de auto-instalação para Visao360 em Ubuntu 22.04 (formato Unix)

# Verificar se é root
if [ "$(id -u)" -ne 0 ]; then
    echo "Execute este script como root ou com sudo"
    exit 1
fi

# Atualizar sistema
echo "Atualizando pacotes do sistema..."
apt update && apt upgrade -y

# Instalar dependências básicas
echo "Instalando dependências do sistema..."
apt install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    libpq-dev \
    nginx \
    git \
    postgresql \
    postgresql-contrib \
    redis-server

# Configurar PostgreSQL
echo "Configurando banco de dados..."
systemctl start postgresql
sudo -u postgres psql -c "CREATE DATABASE visao360;"
sudo -u postgres psql -c "CREATE USER visao360user WITH PASSWORD 'senha_segura';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE visao360 TO visao360user;"

# Criar ambiente virtual
echo "Configurando ambiente Python..."
python3 -m venv /opt/visao360env
source /opt/visao360env/bin/activate

# Instalar dependências Python
echo "Instalando requirements..."
pip install --upgrade pip
pip install gunicorn psycopg2-binary
pip install -r /opt/visao360/requirements.txt

# Configurar Gunicorn
echo "Configurando Gunicorn..."
cat > /etc/systemd/system/gunicorn.service << EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/visao360/visao360
ExecStart=/opt/visao360env/bin/gunicorn --access-logfile - --workers 3 --bind unix:/opt/visao360/visao360.sock visao360.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Configurar Nginx
echo "Configurando Nginx..."
cat > /etc/nginx/sites-available/visao360 << EOF
server {
    listen 80;
    server_name seu_dominio.com;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /opt/visao360/visao360;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/visao360/visao360.sock;
    }
}
EOF

# Habilitar configuração
ln -s /etc/nginx/sites-available/visao360 /etc/nginx/sites-enabled
nginx -t
systemctl restart nginx
systemctl enable gunicorn
systemctl start gunicorn

echo "Instalação completa!"
echo "Acesse http://seu_dominio.com"
