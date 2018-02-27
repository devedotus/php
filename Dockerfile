FROM php:fpm-alpine

# install the PHP extensions we need
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        libjpeg-turbo-dev \
        libpng-dev \
    ; \
    \
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-install gd mysqli opcache; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
    apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/docker-php-opcache.ini; \
  { \
    echo 'post_max_size=13M'; \
    echo 'upload_max_filesize=13M'; \
  } > /usr/local/etc/php/conf.d/docker-php-upload.ini;

# copy default configuration
COPY config /usr/local/etc

RUN set -x \
    && deluser www-data \
    && addgroup -g 500 -S www-data \
    && adduser -u 500 -D -S www-data www-data \
    && chmod -R go+rwx /var/run \
    && rm /usr/local/etc/php-fpm.d/zz-docker.conf \
    && rm /usr/local/etc/php-fpm.d/www.conf.default \
    && rm /usr/local/etc/php-fpm.d/docker.conf

USER www-data
