ARG PHP_VERSION=8.4
FROM jakzal/phpqa:php${PHP_VERSION}

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

# PHPStan extensions
RUN composer global bin phpstan require \
    php-static-analysis/phpstan-extension \
    staabm/phpstan-todo-by \
    struggle-for-php/sfp-phpstan-psr-log

# PHPStan configuration
RUN composer global bin phpunit require ergebnis/phpunit-slow-test-detector

# Castor install
RUN curl -sSL https://castor.jolicode.com/install | bash && \
    chmod +x ~/.local/bin/castor && \
    mv ~/.local/bin/castor /usr/local/bin/castor
