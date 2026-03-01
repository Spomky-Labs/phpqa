ARG PHP_VERSION=8.4

FROM jakzal/phpqa:php${PHP_VERSION} AS base

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

USER root

# ------------------------------------------------------------
# Base system dependencies
# ------------------------------------------------------------
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		build-essential \
		autoconf \
		librabbitmq-dev \
		libmagickwand-dev \
		libmagickcore-dev \
		libbrotli-dev \
		libzstd-dev \
		git \
		curl \
		tar \
		wget

# ------------------------------------------------------------
# PHP source (required for extensions)
# ------------------------------------------------------------
RUN set -eux; \
	docker-php-source extract

# ------------------------------------------------------------
# install-php-extensions helper
# ------------------------------------------------------------
RUN set -eux; \
	curl -fsSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
		-o /usr/local/bin/install-php-extensions; \
	chmod +x /usr/local/bin/install-php-extensions

# ------------------------------------------------------------
# PIE
# ------------------------------------------------------------
RUN set -eux; \
	curl -fsSL https://github.com/php/pie/releases/latest/download/pie.phar \
		-o /usr/local/bin/pie; \
	chmod +x /usr/local/bin/pie

# ------------------------------------------------------------
# Core PHP extensions (non-PIE)
# ------------------------------------------------------------
RUN set -eux; \
	install-php-extensions \
		@composer \
		apcu \
		intl \
		zip \
		pdo_pgsql \
		gmp \
		gd \
		amqp \
		fileinfo \
		ftp \
		iconv \
		exif \
		gettext \
		sodium \
		opcache \
		uuid \
		xsl \
		xml

# ------------------------------------------------------------
# PIE extensions (combined to reduce layers)
# ------------------------------------------------------------
RUN set -eux; \
	pie install imagick/imagick; \
	pie install phpredis/phpredis; \
	pie install kjdev/brotli; \
	pie install kjdev/zstd; \
	pie install xdebug/xdebug

# ------------------------------------------------------------
# Enable extensions
# ------------------------------------------------------------
RUN set -eux; \
	docker-php-ext-enable \
		apcu \
		imagick \
		redis \
		amqp \
		brotli \
		zstd \
		xdebug

# ------------------------------------------------------------
# Cleanup build deps
# ------------------------------------------------------------
RUN set -eux; \
	docker-php-source delete; \
	apt-get purge -y --auto-remove \
		build-essential \
		autoconf \
		librabbitmq-dev \
		libmagickwand-dev \
		libmagickcore-dev \
		libbrotli-dev \
		libzstd-dev; \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/local/bin/install-php-extensions /usr/local/bin/pie /root/.cache

# ------------------------------------------------------------
# Install global Composer packages (combined)
# ------------------------------------------------------------
RUN set -eux; \
	composer global bin phpstan require \
		php-static-analysis/phpstan-extension \
		staabm/phpstan-todo-by \
		struggle-for-php/sfp-phpstan-psr-log \
		phpstan/phpstan-deprecation-rules \
		phpstan/phpstan-strict-rules \
		--no-scripts --no-interaction --no-suggest; \
	composer global bin phpunit require \
		ergebnis/phpunit-slow-test-detector \
		digitalrevolution/phpunit-extensions \
		symfony/browser-kit:"^6.4|^7.0|^8.0" \
		symfony/css-selector:"^6.4|^7.0|^8.0" \
		zenstruck/foundry:"^2.8" \
		--no-scripts --no-interaction --no-suggest; \
	composer global bin infection require \
		infection/infection:"^0.32" \
		--no-scripts --no-interaction --no-suggest; \
	composer global clear-cache; \
	rm -f /tools/infection /tools/.phive/phars/infection-*.phar

# ------------------------------------------------------------
# Install standalone tools
# ------------------------------------------------------------
RUN set -eux; \
	curl -sSL https://castor.jolicode.com/install | bash; \
	chmod +x ~/.local/bin/castor; \
	mv ~/.local/bin/castor /usr/local/bin/castor; \
	rm -rf /tmp/* /var/tmp/* ~/.cache

# ------------------------------------------------------------
# Fix cache directory permissions for user 1001
# ------------------------------------------------------------
RUN set -eux; \
	chown -R 1001:1001 /tools/.composer/cache

# Reset permissions to default non-root user (1001 as per your workflow)
USER 1001

