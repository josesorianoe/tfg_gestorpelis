FROM php:8.2-fpm-alpine

ARG UID=1000
ARG GID=1000

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    freetype-dev \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    unzip \
    zip

# Install PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        intl \
        mbstring \
        opcache \
        pdo \
        pdo_pgsql \
        pgsql \
        zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy custom php.ini
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Create non-root user matching host UID/GID
RUN addgroup -g ${GID} appgroup \
    && adduser -u ${UID} -G appgroup -s /bin/bash -D appuser

WORKDIR /var/www/html

USER appuser

EXPOSE 9000

CMD ["php-fpm"]
