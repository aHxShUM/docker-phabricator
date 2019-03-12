FROM php:fpm-alpine

# Download source code from GitHub
RUN mkdir /phapp \
  && cd /phapp \
  && apk add --no-cache --virtual .install-deps git \
  && git clone https://github.com/phacility/libphutil.git \
  && git clone https://github.com/phacility/arcanist.git \
  && git clone https://github.com/phacility/phabricator.git \
  && apk del .install-deps

# Install php ext
RUN apk add --no-cache --virtual .php-ext-deps \
      $PHPIZE_DEPS \
      curl-dev \
      pcre-dev \
  && docker-php-ext-install \
      mysqli \
      pdo \
      pdo_mysql \
      mbstring \
      iconv \
      curl \
      pcntl \
      opcache \
  && pecl install apcu \
  && docker-php-ext-enable pdo_mysql apcu \
  && apk del .php-ext-deps

# Install ext-gd
RUN apk add --no-cache --virtual .ext-gd-deps \
      libpng-dev \
      libjpeg-turbo-dev \
      freetype-dev \
  && docker-php-ext-install -j$(nproc) iconv \
  && docker-php-ext-configure gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd

# Install nodejs
RUN apk add --no-cache --virtual .aphlict-deps \
      nodejs \
      npm \
  && cd /phapp/phabricator/support/aphlict/server \
  && npm install ws

# Entrypoint
COPY docker-entrypoint.sh /phapp/docker-entrypoint.sh
RUN chmod +x /phapp/docker-entrypoint.sh
ENTRYPOINT ["/phapp/docker-entrypoint.sh"]
CMD ["ph-start"]

WORKDIR /phapp
