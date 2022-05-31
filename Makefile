all: init build

init: init-builder

init-builder:
	docker buildx ls | awk '{print $1}' | grep builder &>/dev/null || docker buildx create --name builder --use && docker buildx use builder

build: build-7.2 build-7.3

#PLATFORM := linux/amd64,linux/arm64
PLATFORM := linux/amd64

# See also "hooks/build" and update the builds there too
# see https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
build-7.2:
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.2" --target base -t croneu/neos:7.2 .
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.2" --target behat -t croneu/neos:7.2-behat .

build-7.3:
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.3" --target base -t croneu/neos:7.3 .
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="7.3" --target behat -t croneu/neos:7.3-behat .

build-8:
	docker buildx build --push --platform ${PLATFORM} --build-arg PHP_VERSION="8" --build-arg ALPINE_VERSION="3.16" --target base -t croneu/neos:8 .
