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
	wget \
	chromium \
	chromium-driver \
	firefox-esr \
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
	phpstan/phpstan-deprecation-rules \
	phpstan/phpstan-strict-rules \
    --no-scripts --no-interaction --no-suggest

# Install phpunit plugins
RUN composer global bin phpunit require \
    ergebnis/phpunit-slow-test-detector \
    digitalrevolution/phpunit-extensions \
    symfony/browser-kit:"^6.4|^7.0|^8.0" \
    symfony/css-selector:"^6.4|^7.0|^8.0" \
    symfony/panther:"^2.0" \
    zenstruck/foundry:"^2.8" \
    --no-scripts --no-interaction --no-suggest

# Install Castor
RUN curl -sSL https://castor.jolicode.com/install | bash \
 && chmod +x ~/.local/bin/castor \
 && mv ~/.local/bin/castor /usr/local/bin/castor

# Install PIE (PHP Installer for Extensions)
RUN curl -fsSL https://github.com/php/pie/releases/latest/download/pie.phar \
	-o /usr/local/bin/pie \
 && chmod +x /usr/local/bin/pie

# Install GeckoDriver for Firefox
ARG GECKODRIVER_VERSION=0.36.0
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz \
 && tar -zxf geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz -C /usr/local/bin \
 && chmod +x /usr/local/bin/geckodriver \
 && rm geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz

# Configure Panther environment for Docker
ENV PANTHER_NO_SANDBOX=1
ENV PANTHER_CHROME_ARGUMENTS='--disable-dev-shm-usage --no-sandbox --disable-gpu --headless --window-size=1920,1080'
ENV PANTHER_CHROME_DRIVER_BINARY=/usr/bin/chromedriver
ENV PANTHER_FIREFOX_ARGUMENTS='-headless'

# Reset permissions to default non-root user (1001 as per your workflow)
USER 1001
