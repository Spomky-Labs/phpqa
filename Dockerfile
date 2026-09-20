ARG PHP_VERSION=8.4
ARG DEBIAN_RELEASE=trixie

# ============================================================
# Stage 1: build PHP extensions and install QA tools
# ============================================================
FROM php:${PHP_VERSION}-cli-${DEBIAN_RELEASE} AS build

ENV COMPOSER_HOME=/tools/.composer \
	COMPOSER_ALLOW_SUPERUSER=1

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends git jdupes unzip; \
	rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# PHP extensions + Composer
# ------------------------------------------------------------
ADD --chmod=755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/install-php-extensions
RUN set -eux; \
	install-php-extensions \
		@composer \
		amqp \
		apcu \
		bcmath \
		brotli \
		bz2 \
		exif \
		gd \
		gettext \
		gmp \
		imagick \
		intl \
		opcache \
		pcntl \
		pcov \
		pdo_pgsql \
		redis \
		uuid \
		xdebug \
		xsl \
		zip \
		zstd

# ------------------------------------------------------------
# QA tools (Composer, isolated per tool with bamarni/composer-bin-plugin)
# Layout kept identical to jakzal/phpqa: projects reference
# /tools/.composer/vendor-bin/{phpunit,phpstan}/vendor/... directly
# (tests/autoload.php, phpstan.neon %rootDir%, rector.php).
# ------------------------------------------------------------
COPY <<EOF /tools/.composer/composer.json
{
    "require": {
        "bamarni/composer-bin-plugin": "^1.9",
        "deptrac/deptrac": "^4.7",
        "ergebnis/composer-normalize": "^2.52"
    },
    "config": {
        "allow-plugins": {
            "bamarni/composer-bin-plugin": true,
            "ergebnis/composer-normalize": true
        }
    },
    "extra": {
        "bamarni-bin": {
            "bin-links": false,
            "forward-command": false
        }
    }
}
EOF

COPY <<EOF /tools/.composer/vendor-bin/phpstan/composer.json
{
    "require": {
        "phpstan/phpstan": "^2.2",
        "phpstan/phpstan-beberlei-assert": "^2.0",
        "phpstan/phpstan-deprecation-rules": "^2.0",
        "phpstan/phpstan-doctrine": "^2.0",
        "phpstan/phpstan-phpunit": "^2.0",
        "phpstan/phpstan-strict-rules": "^2.0",
        "phpstan/phpstan-symfony": "^2.0",
        "phpstan/phpstan-webmozart-assert": "^2.0",
        "ekino/phpstan-banned-code": "^3.2",
        "ergebnis/phpstan-rules": "^2.13",
        "phpat/phpat": "^0.12.4",
        "php-static-analysis/phpstan-extension": "^0.5.0",
        "staabm/phpstan-todo-by": "^0.3.5",
        "struggle-for-php/sfp-phpstan-psr-log": "^1.1"
    }
}
EOF

COPY <<EOF /tools/.composer/vendor-bin/ecs/composer.json
{
    "require": {
        "symplify/easy-coding-standard": "^13.0"
    }
}
EOF

COPY <<EOF /tools/.composer/vendor-bin/rector/composer.json
{
    "require": {
        "rector/rector": "^2.0"
    }
}
EOF

COPY <<EOF /tools/.composer/vendor-bin/infection/composer.json
{
    "require": {
        "infection/infection": "^0.32"
    },
    "config": {
        "allow-plugins": {
            "infection/extension-installer": true
        }
    }
}
EOF

COPY <<EOF /tools/.composer/vendor-bin/phpunit/composer.json
{
    "require": {
        "digitalrevolution/phpunit-extensions": "^1.13",
        "ergebnis/phpunit-slow-test-detector": "^2.24",
        "symfony/browser-kit": "^6.4|^7.0|^8.0",
        "symfony/css-selector": "^6.4|^7.0|^8.0",
        "zenstruck/foundry": "^2.8"
    }
}
EOF

RUN set -eux; \
	composer global update --no-interaction --no-progress --prefer-dist --optimize-autoloader; \
	composer global bin all update --no-interaction --no-progress --prefer-dist --optimize-autoloader; \
	composer global clear-cache; \
	jdupes --recurse --link-hard --quiet /tools; \
	ln -s /tools/.composer/vendor/bin/deptrac /tools/deptrac; \
	ln -s /tools/.composer/vendor-bin/phpstan/vendor/bin/phpstan /tools/phpstan; \
	ln -s /tools/.composer/vendor-bin/ecs/vendor/bin/ecs /tools/ecs; \
	ln -s /tools/.composer/vendor-bin/rector/vendor/bin/rector /tools/rector; \
	ln -s /tools/.composer/vendor-bin/infection/vendor/bin/infection /tools/infection

# ------------------------------------------------------------
# PHAR tools + Castor
# ------------------------------------------------------------
ADD --chmod=755 https://phar.phpunit.de/phpunit-10.phar /tools/phpunit-10
ADD --chmod=755 https://phar.phpunit.de/phpunit-11.phar /tools/phpunit-11
ADD --chmod=755 https://phar.phpunit.de/phpunit-12.phar /tools/phpunit-12
ADD --chmod=755 https://phar.phpunit.de/phpunit-13.phar /tools/phpunit-13
ADD --chmod=755 https://github.com/php-parallel-lint/PHP-Parallel-Lint/releases/latest/download/parallel-lint.phar /tools/parallel-lint
RUN set -eux; \
	# "phpunit" -> the newest PHAR that runs on this PHP version
	for v in 13 12 11 10; do \
		if php /tools/phpunit-$v --version >/dev/null 2>&1; then ln -s /tools/phpunit-$v /tools/phpunit; break; fi; \
	done; \
	test -L /tools/phpunit; \
	# Static build (embeds its own PHP): the PHAR requires PHP >= 8.4
	curl -sSL https://castor.jolicode.com/install | bash -s -- --static; \
	mv ~/.local/bin/castor /usr/local/bin/castor; \
	chmod 755 /usr/local/bin/castor

# ------------------------------------------------------------
# Compute the Debian packages providing the shared libraries needed
# at runtime by PHP, its extensions and Castor. The list is consumed
# by the runtime stage so it stays correct for every PHP version.
# ------------------------------------------------------------
RUN set -eux; \
	ldd /usr/local/bin/php /usr/local/bin/castor /usr/local/lib/php/extensions/*/*.so 2>/dev/null \
		| awk '/=> \//{print $3}' | xargs -r readlink -f | sort -u \
		| xargs -r dpkg -S | grep -v '^diversion' | cut -d: -f1 | sort -u > /runtime-deps.txt; \
	cat /runtime-deps.txt

# ============================================================
# Stage 2: runtime image (no compiler, no headers)
# ============================================================
FROM debian:${DEBIAN_RELEASE}-slim

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

ENV COMPOSER_HOME=/tools/.composer \
	COMPOSER_ALLOW_SUPERUSER=1 \
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tools:/tools/.composer/vendor/bin \
	XDEBUG_MODE=off

COPY --from=build /runtime-deps.txt /tmp/runtime-deps.txt
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		git \
		jq \
		openssh-client \
		unzip \
		wget \
		$(cat /tmp/runtime-deps.txt); \
	rm -rf /var/lib/apt/lists/* /tmp/runtime-deps.txt

COPY --from=build /usr/local/bin/php /usr/local/bin/composer /usr/local/bin/castor /usr/local/bin/
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php /usr/local/etc/php
COPY --from=build /tools /tools

COPY <<EOF /usr/local/etc/php/conf.d/phpqa.ini
date.timezone=UTC
memory_limit=-1
phar.readonly=0
pcov.enabled=0
EOF

COPY <<EOF /usr/local/etc/php/conf.d/opcache.ini
opcache.enable=1
opcache.enable_cli=1
EOF

# ------------------------------------------------------------
# Smoke test + permissions for the non-root CI user (1001)
# ------------------------------------------------------------
RUN set -eux; \
	php -m | grep -qi '^xdebug$'; \
	php -m | grep -qi '^imagick$'; \
	composer --version; \
	su -s /bin/sh -c 'HOME=/tmp /usr/local/bin/castor --version' nobody; \
	phpstan --version; \
	ecs --version; \
	rector --version; \
	deptrac --version; \
	infection --version; \
	phpunit --version; \
	parallel-lint --version; \
	find /tmp /var/tmp -mindepth 1 -delete; \
	chown -R 1001:1001 /tools/.composer/cache

USER 1001
