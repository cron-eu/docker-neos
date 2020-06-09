all: build

build: build-neos build-neos-behat
build-7.3: build-neos-7.3 build-neos-behat-7.3

build-neos:
	docker build -t croneu/neos:latest .

build-neos-behat:
	docker build -t croneu/neos-behat:latest -f Dockerfile-behat .

build-neos-7.3:
	# use the latest available (compatible) alpine version
	docker build \
	 --build-arg PHP_YAML_VERSION="2.1.0" \
	 --build-arg PHP_REDIS_VERSION="5.2.2" \
	 --build-arg ALPINE_VERSION="" \
	 --build-arg PHP_VERSION="7.3" \
	 -t croneu/neos:7.3 .

build-neos-behat-7.3:
	docker build \
	 --build-arg IMAGE_VERSION="7.3" \
	 -t croneu/neos-behat:7.3 -f Dockerfile-behat .

push-7.3:
	docker push croneu/neos:7.3
	docker push croneu/neos-behat:7.3
