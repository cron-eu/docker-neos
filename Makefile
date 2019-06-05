all: build

build: build-neos build-neos-behat

build-neos:
	docker build -t croneu/neos:latest .

build-neos-behat:
	docker build -t croneu/neos-behat:latest -f Dockerfile-behat .
