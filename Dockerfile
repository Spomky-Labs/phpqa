ARG PHP_VERSION=8.4
FROM jakzal/phpqa:php${PHP_VERSION} AS base

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

USER root

# Build deps and sources for native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	autoconf \
	librabbitmq-dev \
	git \
	curl \
	tar \
 && docker-php-source extract

# Add install-php-extensions
RUN curl -fsSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
	-o /usr/local/bin/install-php-extensions \
 && chmod +x /usr/local/bin/install-php-extensions

# Install PHP extensions
RUN set -eux; \
	install-php-extensions \
		@composer \
		apcu \
		intl \
		zip \
		pdo_pgsql \
		gmp \
		gd \
		imagick \
		amqp \
		fileinfo \
		ftp \
		iconv \
		exif \
		gettext \
		sodium \
		opcache \
		redis \
		uuid \
		xsl \
		xml \
		brotli \
		zstd

# Install Xdebug
RUN pecl install xdebug \
 && docker-php-ext-enable xdebug

# Clean up
RUN docker-php-source delete \
 && apt-get purge -y --auto-remove build-essential autoconf librabbitmq-dev \
 && apt-get install -y --no-install-recommends tar curl \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install global PHPStan tools
RUN composer global bin phpstan require \
	php-static-analysis/phpstan-extension \
	staabm/phpstan-todo-by \
	struggle-for-php/sfp-phpstan-psr-log \
    --no-scripts --no-interaction --no-suggest

# Install phpunit plugins
RUN composer global bin phpunit require \
    ergebnis/phpunit-slow-test-detector \
    symfony/browser-kit:"7.3.*" \
    symfony/css-selector:"7.3.*" \
    zenstruck/foundry:"^2.6" \
    --no-scripts --no-interaction --no-suggest

# Install Castor
RUN curl -sSL https://castor.jolicode.com/install | bash \
 && chmod +x ~/.local/bin/castor \
 && mv ~/.local/bin/castor /usr/local/bin/castor

# Reset permissions to default non-root user (1001 as per your workflow)
USER 1001
