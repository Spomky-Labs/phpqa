ARG PHP_VERSION=8.3
FROM jakzal/phpqa:php${PHP_VERSION}

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

RUN composer global require castor/cli

ENV PATH="/root/.composer/vendor/bin:$PATH"

COPY castor.php /ci/castor.php
WORKDIR /ci

ENTRYPOINT ["castor"]
