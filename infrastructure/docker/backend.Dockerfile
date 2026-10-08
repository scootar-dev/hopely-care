FROM php:8.4-cli
RUN apt-get update && apt-get install -y --no-install-recommends git unzip libonig-dev libzip-dev libsqlite3-dev && docker-php-ext-install pdo_mysql pdo_sqlite mbstring zip pcntl && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY backend/ /app/
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
COPY infrastructure/docker/backend-entrypoint.sh /usr/local/bin/hopely-entrypoint
RUN chmod +x /usr/local/bin/hopely-entrypoint
ENTRYPOINT ["hopely-entrypoint"]
