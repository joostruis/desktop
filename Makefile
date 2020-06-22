BACKEND?=docker
CONCURRENCY?=1
CI_ARGS?=

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
TARGET?=targets
COMPRESSION?=gzip
CLEAN?=true
TREE?=packages
BUILD_ARGS?=--pull --image-repository mocaccinoos/desktop-cache
SUDO?=sudo

# For ARM image build script
export LUET_CONFIG?=$(ROOT_DIR)/conf/luet-local.yaml
export LUET_BIN?=$(LUET)
export IMAGE_NAME?=luet_os.img

.PHONY: all
all: deps build

.PHONY: deps
deps:
	@echo "Installing luet"
	go get -u github.com/mudler/luet
	go get -u github.com/MottainaiCI/mottainai-cli

.PHONY: clean
clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --clean=$(CLEAN) --tree=$(TREE)  `cat $(ROOT_DIR)/$(TARGET) | xargs echo` --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --clean=$(CLEAN) --tree=$(TREE) --full --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --clean=$(CLEAN) --tree=$(TREE) `cat $(ROOT_DIR)/$(TARGET) | xargs echo` --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --clean=$(CLEAN) --tree=$(TREE) --full --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: validate
validate:
	$(LUET) tree validate --tree $(TREE) -s

.PHONY: create-repo
create-repo:
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(ROOT_DIR)/build \
    --packages $(ROOT_DIR)/build \
    --name "mocaccino-desktop" \
    --descr "Mocaccino desktop Repo" \
    --urls "http://localhost:8000" \
    --tree-compression gzip \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(ROOT_DIR)/build

.PHONY: iso
iso:
	$(SUDO) -E $(LUET) geniso-build