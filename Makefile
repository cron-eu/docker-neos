all: build

build: build-7.2 build-7.3
push: push-7.2 push-7.3

# See also "hooks/build" and update the builds there too
build-7.2:
	docker buildx build --build-arg PHP_VERSION="7.2" --build-arg ALPINE_VERSION="3.8" --target base -t croneu/neos:7.2 .
	docker buildx build --build-arg PHP_VERSION="7.2" --build-arg ALPINE_VERSION="3.8" --target behat -t croneu/neos:7.2-behat .

build-7.3:
	docker buildx build --build-arg PHP_VERSION="7.3" --build-arg ALPINE_VERSION="3.8" --target base -t croneu/neos:7.3 .
	docker buildx build --build-arg PHP_VERSION="7.3" --build-arg ALPINE_VERSION="3.8" --target behat -t croneu/neos:7.3-behat .

# See also "hooks/push" and update the builds there too
push-7.2:
	docker push croneu/neos:7.2
	docker push croneu/neos:7.2-behat

push-7.3:
	docker push croneu/neos:7.3
	docker push croneu/neos:7.3-behat
