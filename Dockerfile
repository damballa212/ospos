FROM php:8.1-apache

RUN apt-get update && apt-get install -y \
    git unzip libicu-dev libpng-dev libzip-dev zlib1g-dev libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install intl gd zip mbstring bcmath pdo_mysql mysqli \
 && a2enmod rewrite headers \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!<Directory /var/www/>!<Directory ${APACHE_DOCUMENT_ROOT}/>!g' /etc/apache2/apache2.conf && \
    sed -ri -e 's!<Directory /var/www/html/>!<Directory ${APACHE_DOCUMENT_ROOT}/>!g' /etc/apache2/apache2.conf

WORKDIR /var/www/html

RUN git clone --depth 1 https://github.com/opensourcepos/opensourcepos.git . \
 && composer install --no-dev --optimize-autoloader \
 && mkdir -p application/logs public/uploads \
 && chown -R www-data:www-data application public \
 && chmod -R 775 application/logs public/uploads

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
