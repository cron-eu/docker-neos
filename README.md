# docker-neos Docker Image

## Abstract

This is an opinionated Docker Image for [Neos](https://www.neos.io) Development.

## Usage

This image supports following environment variable for automatically configuring Neos at container startup:

| Docker env variable | Description |
|---------|-------------|
|WWW_PORT|TCP port on which the container will serve incoming HTTP requests, defaults to `80`.|
|REPOSITORY_URL|Link to Neos website distribution|
|SITE_INIT_SCRIPT|If set, a path (relative to SITE_PACKAGE folder) to a bash script which will be called (synchronously) after the container is ready but prior to nginx. Note that this script will be executed as user `www-data` (and not root!) |
|VERSION|Git repository branch, commit SHA or release tag, defaults to `master`|
|SITE_PACKAGE|Neos website package with exported website data to be imported, optional|
|ADMIN_PASSWORD|If set, would create a Neos `admin` user with such password, optional|
|AWS_BACKUP_ARN|Automatically import the database from `${AWS_RESOURCES_ARN}db.sql` on the first container launch. Requires `AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY` and `AWS_ENDPOINT` (optional, for S3-compatible storage) to be set in order to work.|
|COMPOSER_INSTALL_PARAMS|composer install parameters, defaults to `--prefer-source`|
|XDEBUG_CONFIG|Pass xdebug config string, e.g. `idekey=PHPSTORM remote_enable=1`. If no config provided the Xdebug extension will be disabled (safe for production), off by default|
|IMPORT_GITHUB_PUB_KEYS|Will pull authorized keys allowed to connect to this image from your Github account(s).|
|DB_DATABASE|Database name, defaults to `db`|
|DB_HOST|Database host, defaults to `db`|
|DB_PASS|Database password, defaults to `pass`|
|DB_USER|Database user, defaults to `admin`|
|AWS_PROFILE|aws profile to use when configuring the aws cli|
|AWS_REGION|aws region|
|AWS_ACCESS_KEY_ID|aws access key|
|AWS_SECRET_ACCESS_KEY|aws secret key|

Example docker-compose.yml configuration:

```
web:
  image: remuslazar/docker-neos-alpine:latest
  ports:
    - '8080:8080'
    - '1122:22'
  links:
    - db:db
  volumes:
    - data:/data
    # needed only for initial provisioning, if REPOSITORY_URL not set
    # - .:/src/
  environment:
    WWW_PORT: 8080
#    AWS_REGION: eu-central-1
#    AWS_ACCESS_KEY_ID: ...
#    AWS_SECRET_ACCESS_KEY: ...
    REPOSITORY_URL: 'https://github.com/neos/neos-development-distribution'
    SITE_PACKAGE: 'Neos.Demo'
    VERSION: '3.3'
    ADMIN_PASSWORD: 'password'
    IMPORT_GITHUB_PUB_KEYS: 'your-github-user-name'
    AWS_RESOURCES_ARN: 's3://some-bucket/sites/demo/'
    COMPOSER_INSTALL_PARAMS: '--no-dev'
db:
  image: mariadb:latest
  expose:
    - 3306
  volumes:
    - /var/lib/data
  environment:
    MYSQL_DATABASE: 'db'
    MYSQL_USER: 'admin'
    MYSQL_PASSWORD: 'pass'
    MYSQL_RANDOM_ROOT_PASSWORD: 'yes'

volumes:
  data:
```

## Provisioning Process

For initial privisioning the container, you can use the `REPOSITORY_URL` ENV var.
If so, the initialization logic will perform a `git clone`.

Another alternative is to use a Docker mount or volume. Mount the source dir to
`/src` and make sure not to set the `REPOSITORY_URL`. Then the init logic will just
`rsync -a` from /src to `/data/www-provisioned` instead.

## Flow/Neos Context

`FLOW_CONTEXT` will be set to `Production` by default. For development use a host name
with a `dev` subdomain, like `dev.mysite.local`, this will use the `Development`
context instead.

## Docker Image Development

```
docker build -t cron-eu/neos:latest .
```
