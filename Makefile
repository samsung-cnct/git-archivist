NAME      := git-archivist
VERSION   := 0.1.4
TYPE      := alpha
COMMIT    := $(shell git rev-parse HEAD)
IMAGE     := quay.io/samsung_cnct/git-archivist
TAG       ?= latest
godep=GOPATH=$(shell godep path):${GOPATH}

build:
	go build -ldflags "-X main.MajorMinorPatch=$(VERSION) \
		-X main.ReleaseType=$(TYPE) \
		-X main.GitCommitSha=$(COMMIT)"

compile: deps
	@rm -rf build/
	@$(GODEP) gox -ldflags "-X main.MajorMinorPatch=$(VERSION) \
		-X main.ReleaseType=$(TYPE) \
		-X main.GitCommitSha=$(COMMIT) -w" \
	-osarch="linux/386" \
	-osarch="linux/amd64" \
	-osarch="darwin/amd64" \
	-output "build/{{.OS}}_{{.Arch}}/$(NAME)" \
	./...

install:
	@$(GODEP) go install -ldflags "-X main.MajorMinorPatch=$(VERSION) \
		-X main.ReleaseType=$(TYPE) \
		-X main.GitCommitSha=$(COMMIT) -w"

deps:
	go get github.com/mitchellh/gox
	go get github.com/tools/godep

dist: compile
	$(eval FILES := $(shell ls build))
	@rm -rf dist && mkdir dist
	@for f in $(FILES); do \
		(cd $(shell pwd)/build/$$f && tar -cvzf ../../dist/$$f.tar.gz *); \
		(cd $(shell pwd)/dist && shasum -a 512 $$f.tar.gz > $$f.sha512); \
		echo $$f; \
	done

container:
	@$(GODEP) gox -ldflags "-X main.MajorMinorPatch=$(VERSION) \
		-X main.ReleaseType=$(TYPE) \
		-X main.GitCommitSha=$(COMMIT) -w" \
	-osarch="linux/amd64" \
	-output "build/{{.OS}}_{{.Arch}}/$(NAME)" \
	./...
	docker build --rm --pull --tag $(IMAGE):$(TAG) .

tag: container
	docker tag $(IMAGE):$(TAG) $(IMAGE):$(COMMIT)

push: tag
	docker push $(IMAGE):$(COMMIT)
	docker push $(IMAGE):$(TAG)

release: dist push
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
	comparison="$$latest_tag..HEAD"; \
	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
	changelog=$$(git log $$comparison --oneline --no-merges --reverse); \
	github-release samsung-cnct/$(NAME) $(VERSION) "$$(git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" 'dist/*'; \
	git pull

.PHONY: build compile install deps dist release push tag container