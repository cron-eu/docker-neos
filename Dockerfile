ARG IMAGE_VERSION="latest"
ARG PHP_VERSION="7.2"
ARG ALPINE_VERSION="3.7"

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

MAINTAINER Remus Lazar <rl@cron.eu>

ARG PHP_REDIS_VERSION="3.1.6"
ARG PHP_YAML_VERSION="2.0.2"
ARG PHP_XDEBUG_VERSION="2.9.4"
ARG S6_VERSION="1.21.2.2"
# allowed values: 1,2
ARG COMPOSER_MAJOR_VERSION="2"

ENV \
	 COMPOSER_HOME=/composer \
   COMPOSER_MAJOR_VERSION=${COMPOSER_MAJOR_VERSION} \
	 PATH=/composer/vendor/bin:$PATH \
	 COMPOSER_ALLOW_SUPERUSER=1 \
	 COMPOSER_INSTALL_PARAMS=--prefer-source

# Set default values for env vars used in init scripts, override them if needed
ENV \
  WWW_PORT=80 \
	DB_DATABASE=db \
	DB_HOST=db \
	DB_USER=admin \
	DB_PASS=pass \
	VERSION=master

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.docker.dockerfile="/Dockerfile" \
	org.label-schema.license="MIT" \
	org.label-schema.name="cron Development Neos Docker Image" \
	org.label-schema.url="https://github.com/cron-eu/neos" \
	org.label-schema.vcs-url="https://github.com/cron-eu/neos" \
	org.label-schema.vcs-type="Git"

RUN set -x \
	&& apk update \
	&& apk add tar rsync curl sed bash yaml py3-pip py-setuptools groff less mysql-client git nginx optipng freetype libjpeg-turbo-utils icu-dev openssh pwgen sudo s6 \
	&& pip install awscli \
	&& apk del py3-pip py-setuptools \
	&& apk add --virtual .phpize-deps $PHPIZE_DEPS libtool freetype-dev libpng-dev libjpeg-turbo-dev yaml-dev \
	&& docker-php-ext-configure gd \
		--with-gd \
		--with-freetype-dir=/usr/include/ \
		--with-png-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install \
		gd \
		pdo \
		pdo_mysql \
		mbstring \
		opcache \
		intl \
		exif \
		json \
		tokenizer \
		zip \
	&& pecl install redis-${PHP_REDIS_VERSION} yaml-${PHP_YAML_VERSION} xdebug-${PHP_XDEBUG_VERSION} \
	&& docker-php-ext-enable xdebug \
	&& docker-php-ext-enable redis \
	&& docker-php-ext-enable yaml \
	&& docker-php-ext-enable zip \
	&& apk del .phpize-deps \
	&& curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
	&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --${COMPOSER_MAJOR_VERSION} && rm -rf /tmp/composer-setup.php \
	&& curl -s http://beard.famelo.com/ > /usr/local/bin/beard \
	&& chmod +x /usr/local/bin/beard \
	&& git config --global user.email "server@server.com" \
	&& git config --global user.name "Server" \
	&& rm -rf /var/cache/apk/*

# Download s6
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz /tmp/

RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && rm /tmp/s6-overlay-amd64.tar.gz \
	&& echo "xdebug.remote_enable=1" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_connect_back=0" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.max_nesting_level=512" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.idekey=\"PHPSTORM\"" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_host=debugproxy" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_port=9010" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& sed -i -r 's/.?UseDNS\syes/UseDNS no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?PasswordAuthentication.+/PasswordAuthentication no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?ChallengeResponseAuthentication.+/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?PermitRootLogin.+/PermitRootLogin no/' /etc/ssh/sshd_config \
	&& sed -i '/secure_path/d' /etc/sudoers

# Imagick support
# needed if Neos.Imagine.driver: Imagick
RUN apk --no-cache add php7-imagick imagemagick autoconf gcc g++ imagemagick-dev libtool make \
	&& echo '' | pecl install imagick \
	&& docker-php-ext-enable imagick \
	&& apk del autoconf gcc g++ imagemagick-dev libtool

# Install jq utility (used to parse JSON in e.g. Makefiles)
RUN apk --no-cache add jq

# Copy container-files
COPY container-files /

RUN deluser www-data \
	&& delgroup cdrw \
	&& addgroup -g 80 www-data \
	&& adduser -u 80 -G www-data -s /bin/bash -D www-data -h /data -k /etc/skel_www \
	&& echo 'www-data ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/www \
	&& rm -Rf /home/www-data \
	&& sed -i -e "s#listen = 9000#listen = /var/run/php-fpm.sock#" /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "clear_env = no" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.group = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "access.log = /dev/null" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& chown 80:80 -R /var/lib/nginx \
	&& chmod +x /github-keys.sh \
	&& chmod +x /gitlab-keys.sh \
	&& /bin/bash -c "source /init-php-conf.sh"

# Expose ports
EXPOSE 80 22

# Define working directory
WORKDIR /data

# Define entrypoint and command
ENTRYPOINT ["/init"]
