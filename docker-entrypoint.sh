#!/usr/bin/env bash
set -e

# --- Ruta de trabajo ---
cd /var/www/html || { echo "No existe /var/www/html"; exit 1; }

# --- Estructura necesaria ---
mkdir -p application/config application/logs public/uploads

# --- Variables requeridas ---
: "${MYSQL_HOST:?Missing MYSQL_HOST}"
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${ENCRYPTION_KEY:?Missing ENCRYPTION_KEY}"

# --- Escribir database.php ---
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

# --- Inyectar encryption_key (sin pelear con comillas) ---
cat > /tmp/setkey.php <<'PHP'
<?php
$f = "application/config/config.php";
$c = file_get_contents($f);
if ($c === false) { fwrite(STDERR, "No se pudo leer $f\n"); exit(1); }
$k = getenv("ENCRYPTION_KEY");

// Reemplaza la línea de la clave (comillas simples) si existe; si no, la agrega.
if (preg_match("/\\\$config\\['encryption_key'\\]\\s*=\\s*'.*?';/", $c)) {
  $c = preg_replace("/\\\$config\\['encryption_key'\\]\\s*=\\s*'.*?';/",
                   "\$config['encryption_key']='" . addslashes($k) . "';", $c, 1);
} else {
  $c = str_replace("\$config['base_url'] = '';", "\$config['base_url'] = '';\n\$config['encryption_key']='" . addslashes($k) . "';", $c);
}
file_put_contents($f, $c);
PHP

php /tmp/setkey.php

# --- Permisos ---
chown -R www-data:www-data application public
chmod -R 775 application/logs public/uploads || true

# --- Arrancar Apache ---
exec apache2-foreground
