# [croneu/neos](https://hub.docker.com/r/croneu/neos)

[![](https://images.microbadger.com/badges/image/croneu/neos.svg)](https://microbadger.com/images/croneu/neos "croneu/neos")
[![](https://images.microbadger.com/badges/version/croneu/neos.svg)](https://microbadger.com/images/croneu/neos "Neos Dev Docker Image")
[![](https://circleci.com/gh/cron-eu/docker-neos.svg?style=shield)](https://circleci.com/gh/cron-eu/docker-neos/)

## Abstract

Opinionated Docker Images for [Neos](https://www.neos.io) Development.

## Compatibility

_Currently_ the included images do support only newer Neos Versions, basically all
versions which run with `PHP 7.2` or `PHP 7.3`.

## Docker Images included

This repository builds two distinct Docker Images:

| Tag | Description |
| ----------------- | ----------- |
| 7.2 | PHP 7.2 based docker image, useful to run a Neos project in docker for development purposes.|
| 7.2-behat | PHP 7.2 based image with some add-ons for behat tests (supports also unattended use for e.g. circleCI/Travis) |
| 7.3 | PHP 7.3 based docker image, useful to run a Neos project in docker for development purposes.|
| 7.3-behat | PHP 7.3 based image with some add-ons for behat tests (supports also unattended use for e.g. circleCI/Travis) |

## Usage in a nutshell

Checkout your Neos Project in `./` and use a `docker-compose.yml`:

Note: make sure to put your GitHub Username (instead of `your-github-user-name`)
using the `IMPORT_GITHUB_PUB_KEYS` env var in your `docker-compose.yml` file.

```yaml
---
version: '3.7'

services:
  web:
    image: croneu/neos:7.3
    ports:
      - '8080:8080'
      - '1122:22'
    links:
      - db:db
    volumes:
      - data:/data
      # needed only for initial provisioning, if REPOSITORY_URL not set
      - .:/src/
    environment:
      WWW_PORT: 8080
      ADMIN_PASSWORD: 'password'
      IMPORT_GITHUB_PUB_KEYS: 'my-github-username'
      #IMPORT_GITLAB_PUB_KEYS: 'my-gitlab-username'
      #GITLAB_URL: 'https://gitlab.my-company.org'
  db:
    image: mariadb:10
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

networks:
  default:
```

Run `docker-compose up`:

```bash
docker-compose up -d
```

You can monitor the container logs, for example for the web container, where
interesting things happen, with:

```
docker-compose logs -f web
```

### Web Server

The `web` container will start a web-server listening on `WWW_PORT`.
To access the web-server, make sure you have a DNS entry in your local `/etc/hosts`
or local DNS server, e.g. (when using docker-machine):

`/etc/hosts:`
```
192.168.99.100 dev.neos-playground.docker neos-playground.docker
```

Then you can access the web-server using:

```bash
open http://dev.neos-playground.docker:8080/
```

To use the `Production` `FLOW_CONTEXT`, use the second hostname (without `dev.``):

```bash
open http://neos-playground.docker:8080/
```

### FLOW_CONTEXT magic

`FLOW_CONTEXT` will be set to `Production` by default. For development purposes,
use a host name with a `dev` subdomain, like `dev.`, this will use the `Development`
context instead:

| Hostname Pattern | FLOW_CONTEXT |
| -------- | ------------ |
| dev.*    | Development  |
| dev.behat.* | Development/Behat |
| _else_   | Production   |

### SSH Access

You can then SSH into the container using for example:

```bash
ssh -A -p 1122 www-data@$(docker-compose ip $DOCKER_MACHINE_NAME)
```

Then you can run the flow CLI and do stuff:

```
$ flow
Neos 3.3.21 ("Development" context)
usage: ./flow <command identifier>

See "./flow help" for a list of all available commands.
```

## Behat Support

To run Behat Tests, an additional Docker Image is provided. To use this additional
image, use a `docker-compose` overlay, e.g. `docker-compose.behat.yml`:

```yaml
version: '3.7'

services:
  web:
    # use the neos-alpine behat image instead of the default one
    image: croneu/neos:7.3-behat
    hostname: behat-runner
    ports:
      - '5900:5900'
    environment:
      # use a separate DB container for testing
      DB_HOST: db-test
      DB_DATABASE: db

  db-test:
    image: mariadb:10
    expose:
      - 3306
    volumes:
      - /var/lib/data
    environment:
      MYSQL_DATABASE: 'db'
      MYSQL_USER: 'admin'
      MYSQL_PASSWORD: 'pass'
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'
```

Then you can use this overlay to run `docker-compose`, e.g.:

```bash
alias docker-compose="docker-compose -f docker-compose.yml -f docker-compose.behat.yml"
docker-compose up -d
```

This will tweak the (existing) web container to use the Behat Image and also create
a separate DB instance for testing purposes.

Docker-Compose will also setup behat correctly and also create `behat.yml` configuration
files based on existing `behat.yml.dist` found in the codebase (see `/setup-behat-yml.sh`
shell script for technical details).

To run Behat Tests, SSH into the web container as usual and run behat, e.g.:

```
$ behat Features/EventLog/Entities/AccountsUsers.feature
Feature: Accounts / User Entity Monitoring
  As an API user of the history
  I expect that adding/updating/deleting an account or party triggers history updates

  Background:                                                   # Features/EventLog/Entities/AccountsUsers.feature:5
    Given I have an empty history                               # FeatureContext::iHaveAnEmptyHistory()
    Given I have the following "monitorEntities" configuration: # FeatureContext::iHaveTheFollowingMonitorEntitiesConfiguration()
      """
      'Neos\Flow\Security\Account':
        events:
          created: ACCOUNT_CREATED
        data:
          accountIdentifier: '${entity.accountIdentifier}'
          authenticationProviderName: '${entity.authenticationProviderName}'
          expirationDate: '${entity.expirationDate}'
          party: '${entity.party.name.fullName}'
      'Neos\Neos\Domain\Model\User':
        events:
          created: PERSON_CREATED
        data:
          name: '${entity.name.fullName}'
          primaryElectronicAddress: '${entity.primaryElectronicAddress}'
      """

  @fixtures
  Scenario: Creating an account is monitored                    # Features/EventLog/Entities/AccountsUsers.feature:27
    When I create the following accounts:                       # FeatureContext::iCreateTheFollowingAccounts()
      | User  | Password | First Name | Last Name | Roles                   |
      | admin | password | Sebastian  | Kurfuerst | Neos.Neos:Administrator |
    Then I should have the following history entries:           # FeatureContext::iShouldHaveTheFollowingHistoryEntries()
      | Event Type      |
      | PERSON_CREATED  |
      | ACCOUNT_CREATED |

1 scenario (1 passed)
4 steps (4 passed)
0m1.796s
```

### Behat unattended use

You can also supply a command for the web container and the container will do
its initialization, run this command and exits. Useful to run behat from circleCI.

See the `.circleci/config.yml` file for how we did that for our tests.

## Advanced Configuration Options

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
|COMPOSER_INSTALL_PARAMS|composer install parameters, defaults to `--prefer-dist --no-progress`|
|COMPOSER_MAJOR_VERSION|default will use the latest (2), but you can use "1" to use the older version|
|XDEBUG_ENABLED|`0` to disable the Xdebug extension (default, if XDEBUG_CONFIG is also not defined), `1` to enabled it|
|XDEBUG_CONFIG|Pass Xdebug config string, e.g. `idekey=PHPSTORM remote_enable=1`|
|IMPORT_GITHUB_PUB_KEYS|Will pull authorized keys allowed to connect to this image from your Github account(s).|
|IMPORT_GITLAB_PUB_KEYS|Will pull authorized keys allowed to connect to this image from your Gitlab account(s). Note: please also setup the GITLAB_URL ENV var, else this will throw an error.|
|GITLAB_URL| Your HTTPS Gitlab Server URL, e.g. https://gitlab.my-company.com (without the trailing /)|
|DB_DATABASE|Database name, defaults to `db`|
|DB_HOST|Database host, defaults to `db`|
|DB_PASS|Database password, defaults to `pass`|
|DB_USER|Database user, defaults to `admin`|
|AWS_PROFILE|aws profile to use when configuring the aws cli|
|AWS_REGION|aws region|
|AWS_ACCESS_KEY_ID|aws access key|
|AWS_SECRET_ACCESS_KEY|aws secret key|

## Provisioning Process

For initial provisioning the container, you can use the `REPOSITORY_URL` ENV var.
If so, the initialization logic will perform a `git clone`.

Another alternative is to use a Docker mount or volume. Mount the source dir to
`/src` and make sure not to set the `REPOSITORY_URL`. Then the init logic will just
`rsync -a` from /src to `/data/www` instead.

## Using Xdebug with Flow / Neos

Use the [flow-debugproxy](https://github.com/dfeyer/flow-debugproxy) to be able to set breakpoints
in PhpStorm in the original files, while the real process inside the container uses the flow generated
"proxy classes".

Add this to your projects `docker-compose.yml`:

```
services:

  # this is your application container
  web:
    environment:
      XDEBUG_ENABLED: "1"
      XDEBUG_CONFIG: "remote_host=debugproxy"
    links:
      - debugproxy

  # this is the additional proxy where xdebug will connect to
  debugproxy:
    image: dfeyer/flow-debugproxy:latest
    volumes:
      # make sure the proxy has access to the same files as the web container:
      - data:/data
    environment:
      # the IP of your local host (i.e. Mac) - see also https://github.com/devilbox/xdebug
      #- "IDE_IP=172.18.0.1"
      - "IDE_IP=10.254.254.254"

      # This is the default value, need to match the xdebug.remote_port on your php.ini
      - "XDEBUG_PORT=9010"

      # Use this to enable verbose debugging on the proxy
      #- "ADDITIONAL_ARGS=--vv --debug"
```

## Docker Image Development

```
make build
```

This will create both images from scratch

### Create a build for a specific PHP Version

Use the available targets in the `Makefile`, e.g.

```
make build-7.3
```

Important note: There is no automation on Docker Hub to build Docker Images other than `latest`.
Use the `push-*` targets in the Makefile to push the images to Docker Hub.

```
docker login
make push-7.3
```

### Test the Docker Image

To test the image you can use the supplied docker-compose files in the `example` directory. For example, to run a behat enabled environment using the official Neos Distribution Package, do:

```shell
cd example
docker-compose -f docker-compose.yml -f docker-compose.behat.yml up -d
# ssh-keygen -R \[$(docker-machine ip $DOCKER_MACHINE_NAME)\]:1122
ssh www-data@$(docker-machine ip $DOCKER_MACHINE_NAME) -p 1122
```

Inside the docker container, run this simple behat test:

```
cd Packages/Neos/Neos.Neos/Tests/Behavior
behat Features/ExportImport.feature
```

## MIT Licence

See the [LICENSE](LICENSE) file.

## Author

Remus Lazar (rl@cron at eu)
