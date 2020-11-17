ARG IMAGE_VERSION="latest"
ARG PHP_VERSION="7.2"
ARG ALPINE_VERSION=""

# ALPINE_VERSION defines the Firefox version.
# PHP maintaners only build PHP images for a couple variants of "selected" ALPINE_VERSION's.
#
# See list here:
# PHP 7.2: https://hub.docker.com/_/php?tab=tags&page=1&name=7.2-fpm-alpine
# PHP 7.3: https://hub.docker.com/_/php?tab=tags&page=1&name=7.3-fpm-alpine
#
# Check out Firefox Versions in Alpine releases:
# https://pkgs.alpinelinux.org/packages?name=firefox-esr&branch=v3.5
#
# Alpine 3.5 - firefox-esr 45 - works with selenium 2.53
# Alpine 3.6 - firefox-esr 52.5 - works with selenium 2.53
# Alpine 3.7 - firefox-esr 52.8 - works with selenium 2.53
# Alpine 3.8 - firefox-esr 52.9 - works with selenium 2.53
# Alpine 3.9 - firefox-esr 52.9 - works with selenium 2.53
# Alpine 3.10 - firefox-esr 60
# Alpine 3.12 - firefox-esr 78

# -------------------------------------------------------------------------

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} as base

MAINTAINER Remus Lazar <rl@cron.eu>

ARG S6_VERSION="1.21.2.2"
# allowed values: 1,2
ARG COMPOSER_MAJOR_VERSION="2"

ENV \
	COMPOSER_MAJOR_VERSION=${COMPOSER_MAJOR_VERSION} \
	COMPOSER_ALLOW_SUPERUSER=1 \
	COMPOSER_INSTALL_PARAMS=--prefer-source

# User / Group for www-data user. Keep 1000:50 for being able to mount local volumes and having access to it
ARG UID="1000"
ARG GID="50"

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

# Install awscli
RUN set -x \
	&& apk add --no-cache python3 py3-pip \
	&& python3 -m pip install awscli

# Install needed tools
RUN set -x \
	&& apk add --no-cache make tar rsync curl jq sed bash yaml less mysql-client git nginx openssh openssh-server-pam pwgen sudo s6

# Install required PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions \
	gd \
	pdo \
	pdo_mysql \
	mbstring \
	opcache \
	intl \
	imagick \
	exif \
	json \
	tokenizer \
	zip \
	redis \
	yaml \
	xdebug

# Install composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
	&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --${COMPOSER_MAJOR_VERSION} \
	&& rm -rf /tmp/composer-setup.php \
	&& git config --global user.email "server@server.com" \
	&& git config --global user.name "Server"

# Install s6
RUN curl -L https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz | tar xzf - -C /

RUN echo "xdebug.remote_enable=1" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_connect_back=0" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.max_nesting_level=512" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_host=debugproxy" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.remote_port=9010" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
	&& sed -i -r 's/.?UseDNS\syes/UseDNS no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?PasswordAuthentication.+/PasswordAuthentication no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?ChallengeResponseAuthentication.+/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config \
	&& sed -i -r 's/.?PermitRootLogin.+/PermitRootLogin no/' /etc/ssh/sshd_config \
	# we use PAM to make ssh daemon to load the /etc/environment (see "00-init-ssh") \
	&& sed -i -r 's/.?UsePAM.+/UsePAM yes/' /etc/ssh/sshd_config \
	&& sed -i '/secure_path/d' /etc/sudoers

# Copy container-files
COPY container-files /

RUN deluser www-data \
	&& delgroup cdrw \
	&& addgroup -g ${GID} www-data \
	&& adduser -u ${UID} -G www-data -s /bin/bash -D www-data -h /data -k /etc/skel_www \
	&& echo 'www-data ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/www \
	&& rm -Rf /home/www-data \
	&& sed -i -e "s#listen = 9000#listen = /var/run/php-fpm.sock#" /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "clear_env = no" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.group = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "access.log = /dev/null" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& chown ${UID}:${GID} -R /var/lib/nginx \
	&& chmod +x /github-keys.sh \
	&& chmod +x /gitlab-keys.sh \
	&& /bin/bash -c "source /init-php-conf.sh"

# Expose ports
EXPOSE 80 22

# Define working directory
WORKDIR /data

# Define entrypoint and command
ENTRYPOINT ["/init"]

# -------------------------------------------------------------------------

FROM base as behat

# install jre, selenium, firefox and xvfb
RUN apk add --no-cache openjdk8 xorg-server xvfb firefox-esr curl libvncserver openssl dbus \
  && curl -sSL -o /usr/bin/selenium-server-standalone.jar http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar

# we do compile x11vnc from sources (unfortunately there is no binary package available..)
RUN apk add --no-cache --virtual=.x11vncdeps gcc g++ automake autoconf make openssl-dev libx11-dev libvncserver-dev \
  && mkdir -p /src && cd /src \
  && git clone https://github.com/LibVNC/x11vnc \
  && cd x11vnc \
  && ./autogen.sh \
  && make \
  && make install \
  && apk del .x11vncdeps \
  && cd / && rm -rf /src

# required for the xvfb notifyoncheck script
RUN apk add --no-cache xdpyinfo

ENV \
  DISPLAY=:99 \
  SCREEN_DIMENSION=1600x1000x24 \
  VNC_PASSWORD=password

COPY container-files-behat /

EXPOSE 4444 5900

ENV FLOW_CONTEXT Development/Behat
ENV DB_DATABASE db_behat
