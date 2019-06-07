all: build

# build everything under the local directory.
HERE := $(CURDIR)
BASE := $(abspath $(CURDIR)/../../../../..)
GOPATH := $(HERE)
export GOPATH

# Only set PROTOC_VER if it has an empty value.
ifeq (,$(strip $(PROTOC_VER)))
PROTOC_VER := 3.5.1
endif

# fix OS string for Mac builds.
PROTOC_OS := $(shell uname -s)
ifeq (Darwin,$(PROTOC_OS))
PROTOC_OS := osx
endif

# allow building on 32 bit machines.
PROTOC_ARCH := $(shell uname -m)
ifeq (i386,$(PROTOC_ARCH))
PROTOC_ARCH := x86_32
endif

# Get and install the protoc binary.
PROTOC_ZIP := protoc-$(PROTOC_VER)-$(PROTOC_OS)-$(PROTOC_ARCH).zip
PROTOC_URL := https://github.com/google/protobuf/releases/download/v$(PROTOC_VER)/$(PROTOC_ZIP)
PROTOC_TMP_DIR := protoc
PROTOC_BIN_DIR := $(PROTOC_TMP_DIR)/bin
PROTOC := $(PROTOC_BIN_DIR)/protoc
$(PROTOC):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTOC_URL) -o $(PROTOC_TMP_DIR)/$(PROTOC_ZIP) && \
		unzip $(PROTOC_TMP_DIR)/$(PROTOC_ZIP) -d $(PROTOC_TMP_DIR) && \
		chmod 0755 $(PROTOC)
	stat $@ > /dev/null 2>&1

# Get and install the go plug-in for protoc
PROTOBUF_PKG := github.com/golang/protobuf
PROTOBUF_VERSION := v1.3.1
PROTOC_GEN_GO := protoc-gen-go
PROTOC_GEN_GO_PKG := $(PROTOBUF_PKG)/$(PROTOC_GEN_GO)
PROTOC_GEN_GO_SRC := src
$(PROTOC_GEN_GO):
	mkdir -p $(dir $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG))
	test -d $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG)/.git || \
		git clone https://$(PROTOBUF_PKG) $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG)
	(cd $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG) && \
		(test "$$(git describe --tags | head -1)" = "$(PROTOBUF_VERSION)" || \
		(git fetch && git checkout tags/$(PROTOBUF_VERSION))))
	(cd $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG) && \
		go get -v -d $$(go list -f '{{ .ImportPath }}' ./...)) && \
		go build -o $(PROTOC_BIN_DIR)/$@ $(PROTOC_GEN_GO_PKG)

# Update PATH with the protoc bin dir which contains protoc and its plug-in
export PATH := $(HERE)/$(PROTOC_BIN_DIR):$(PATH)

# Generate the go language bindings.
SI_PROTO := ../../si.proto
SI_PKG_ROOT := github.infra.cloudera.com/yunikorn/scheduler-interface
SI_PKG_SUB := si
SI_BUILD := $(SI_PKG_SUB)/build
SI_GO := $(SI_PKG_SUB)/si.pb.go
SI_GO_TMP := $(SI_BUILD)/$(SI_PKG_ROOT)/si.pb.go
$(SI_GO): GO_OUT := plugins=grpc
$(SI_GO): GO_OUT := $(GO_OUT),Mgoogle/protobuf/descriptor.proto=$(PROTOC_GEN_GO_PKG)/descriptor
$(SI_GO): GO_OUT := $(GO_OUT):$(HERE)/$(SI_BUILD)
$(SI_GO): INCLUDE := -I$(BASE) -I$(HERE)/$(PROTOC_TMP_DIR)/include
$(SI_GO): $(SI_PROTO) | $(PROTOC) $(PROTOC_GEN_GO)
	mkdir -p $(SI_BUILD) && \
		(cd $(BASE) && \
		$(HERE)/$(PROTOC) $(INCLUDE) --go_out=$(GO_OUT) $(SI_PKG_ROOT)/$(<F))

build: $(SI_GO)
	cp -f $(SI_GO_TMP) $(SI_GO) && \
	echo "\nprotobuf go source generated:\n\t$(HERE)/$(SI_GO)\n"

clean:
	rm -rf $(SI_GO)

clobber: clean
	rm -rf $(PROTOC_TMP_DIR) $(PROTOC_GEN_GO_SRC) $(SI_BUILD)

.PHONY: clean clobber
