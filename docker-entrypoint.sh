#!/usr/bin/env bash
set -e

# --- Asegurar ruta de trabajo y código ---
cd /var/www/html || { echo "No existe /var/www/html"; exit 1; }

# Si por algún motivo el build no dejó el código, clónalo en runtime
if [ ! -f "index.php" ] || [ ! -d "application" ]; then
  echo "Código de OSPOS no encontrado, clonando en runtime..."
  git clone --depth 1 https://github.com/opensourcepos/opensourcepos.git . 
  composer install --no-dev --optimize-autoloader
fi

# Crear carpetas requeridas
mkdir -p application/config application/logs public/uploads

# --- Validar variables requeridas ---
: "${MYSQL_HOST:?Missing MYSQL_HOST}"
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${ENCRYPTION_KEY:?Missing ENCRYPTION_KEY}"

# --- Escribir database.php desde variables ---
cat > application/config/database.php <<'PHP'
<?php
defined('BASEPATH') OR exit('No direct script access allowed');
$active_group = 'default';
$query_builder = TRUE;
$db['default'] = array(
    'dsn'      => '',
    'hostname' => getenv('MYSQL_HOST'),
    'username' => getenv('MYSQL_USER'),
    'password' => getenv('MYSQL_PASSWORD'),
    'database' => getenv('MYSQL_DATABASE'),
    'dbdriver' => 'mysqli',
    'dbprefix' => '',
    'pconnect' => FALSE,
    'db_debug' => (ENVIRONMENT !== 'production'),
    'cache_on' => FALSE,
    'cachedir' => '',
    'char_set' => 'utf8',
    'dbcollat' => 'utf8_general_ci',
    'swap_pre' => '',
    'encrypt'  => FALSE,
    'compress' => FALSE,
    'stricton' => FALSE,
    'failover' => array(),
    'save_queries' => TRUE
);
PHP

# --- Inyectar encryption_key en config.php ---
php -r '
$f="application/config/config.php";
$c=file_get_contents($f);
$k=getenv("ENCRYPTION_KEY");
if($c===false){fwrite(STDERR,"No se pudo leer $f\n"); exit(1);}
$c=preg_replace("/\\$config\\[[\"\\\']encryption_key[\"\\\']\\]\\s*=\\s*[\"\\\'].*?[\"\\\'];/",
  "$config[\"encryption_key\"]=\"".$k."\";", $c, 1);
file_put_contents($f,$c);
'

# --- Permisos ---
chown -R www-data:www-data application public
chmod -R 775 application/logs public/uploads || true

# --- Arrancar Apache ---
exec apache2-foreground
