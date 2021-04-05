all: build

build: build-7.2 build-7.3

PLATFORM := linux/amd64,linux/arm/v8

# See also "hooks/build" and update the builds there too
# see https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
build-7.2:
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.2" --build-arg ALPINE_VERSION="3.8" --target base -t croneu/neos:7.2 .
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.2" --build-arg ALPINE_VERSION="3.8" --target behat -t croneu/neos:7.2-behat .

build-7.3:
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.3" --build-arg ALPINE_VERSION="3.8" --target base -t croneu/neos:7.3 .
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.3" --build-arg ALPINE_VERSION="3.8" --target behat -t croneu/neos:7.3-behat .
