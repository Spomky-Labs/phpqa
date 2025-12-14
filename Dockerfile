ARG PHP_VERSION=8.4
ARG WITH_CHROMIUM=false
ARG WITH_FIREFOX=false

FROM jakzal/phpqa:php${PHP_VERSION} AS base

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

USER root

ARG WITH_CHROMIUM
ARG WITH_FIREFOX

# Install all dependencies in a single layer to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	autoconf \
	librabbitmq-dev \
	git \
	curl \
	tar \
	wget \
 && if [ "$WITH_CHROMIUM" = "true" ]; then \
		apt-get install -y --no-install-recommends chromium chromium-driver; \
	fi \
 && if [ "$WITH_FIREFOX" = "true" ]; then \
		apt-get install -y --no-install-recommends firefox-esr; \
	fi \
 && docker-php-source extract \
 # Add install-php-extensions
 && curl -fsSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
	-o /usr/local/bin/install-php-extensions \
 && chmod +x /usr/local/bin/install-php-extensions \
 # Install PHP extensions
 && install-php-extensions \
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
		zstd \
 # Install Xdebug
 && pecl install xdebug \
 && docker-php-ext-enable xdebug \
 # Clean up build dependencies and caches
 && docker-php-source delete \
 && apt-get purge -y --auto-remove build-essential autoconf librabbitmq-dev \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/local/bin/install-php-extensions

# Install global PHPStan tools (clear cache after)
RUN composer global bin phpstan require \
	php-static-analysis/phpstan-extension \
	staabm/phpstan-todo-by \
	struggle-for-php/sfp-phpstan-psr-log \
	phpstan/phpstan-deprecation-rules \
	phpstan/phpstan-strict-rules \
    --no-scripts --no-interaction --no-suggest \
 && composer global clear-cache

# Install phpunit plugins (clear cache after)
RUN composer global bin phpunit require \
    ergebnis/phpunit-slow-test-detector \
    digitalrevolution/phpunit-extensions \
    symfony/browser-kit:"^6.4|^7.0|^8.0" \
    symfony/css-selector:"^6.4|^7.0|^8.0" \
    zenstruck/foundry:"^2.8" \
    --no-scripts --no-interaction --no-suggest \
 && composer global clear-cache

# Install standalone tools in a single layer
RUN curl -sSL https://castor.jolicode.com/install | bash \
 && chmod +x ~/.local/bin/castor \
 && mv ~/.local/bin/castor /usr/local/bin/castor \
 # Install PIE
 && curl -fsSL https://github.com/php/pie/releases/latest/download/pie.phar \
	-o /usr/local/bin/pie \
 && chmod +x /usr/local/bin/pie \
 && rm -rf /tmp/* /var/tmp/*

# Fix permissions for /tools directory to allow cache operations
RUN chown -R 1001:1001 /tools \
 && chmod -R 755 /tools

# Reset permissions to default non-root user (1001 as per your workflow)
USER 1001
