ARG PHP_VERSION=8.3
FROM jakzal/phpqa:php${PHP_VERSION}

LABEL maintainer="Florent Morselli <florent.morselli@spomky-labs.com>"

RUN curl -sSL https://castor.jolicode.com/install | bash && \
    chmod +x ~/.local/bin/castor && \
    mv ~/.local/bin/castor /usr/local/bin/castor

ENV PATH="/root/.composer/vendor/bin:$PATH"

COPY castor.php /ci/castor.php
WORKDIR /ci

ENTRYPOINT ["castor"]
