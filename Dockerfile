ARG PHP_VERSION=8.4
FROM jakzal/phpqa:php${PHP_VERSION}

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

RUN composer global bin phpstan require php-static-analysis/phpstan-extension;
RUN composer global bin phpstan require staabm/phpstan-todo-by;
RUN composer global bin phpstan require struggle-for-php/sfp-phpstan-psr-log;

RUN curl -sSL https://castor.jolicode.com/install | bash && \
    chmod +x ~/.local/bin/castor && \
    mv ~/.local/bin/castor /usr/local/bin/castor
