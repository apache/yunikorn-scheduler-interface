#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ifndef PROTOBUF_VERSION
$(error PROTOBUF_VERSION is missing)
endif

all: build

# Build everything under the local directory.
HERE := $(CURDIR)
# compensate for lib/go/<repo>
BASE := $(abspath $(CURDIR)/../../..)
# Find the checked out package details (repo only)
PKG_ROOT := $(patsubst %/lib/go,%,$(patsubst $(BASE)/%,%,$(HERE)))

# Force Go modules even when checked out inside GOPATH
GO111MODULE := on
export GO111MODULE

# Only set PROTOC_VER if it has an empty value.
ifeq (,$(strip $(PROTOC_VER)))
PROTOC_VER := 23.2
endif

# Only set PROTOC_GEN_GO_GRPC_VER if it has an empty value.
ifeq (,$(strip $(PROTOC_GEN_GO_GRPC_VER)))
PROTOC_GEN_GO_GRPC_VER := 1.3.0
endif

PROTOC_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
PROTOGEN_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
# Fix OS string for Mac builds.
ifeq (darwin,$(PROTOC_OS))
PROTOC_OS := osx
endif

# Fix architecture naming.
PROTOC_ARCH := $(shell uname -m)
PROTOGEN_ARCH := amd64
ifeq (i386,$(PROTOC_ARCH))
PROTOC_ARCH := x86_32
PROTOGEN_ARCH := 386
else ifeq (arm64, $(PROTOC_ARCH))
PROTOC_ARCH := aarch_64
PROTOGEN_ARCH := arm64
else ifeq (aarch64, $(PROTOC_ARCH))
PROTOC_ARCH := aarch_64
PROTOGEN_ARCH := arm64
endif

# Get and install the protoc binary.
PROTOC_ZIP := protoc-$(PROTOC_VER)-$(PROTOC_OS)-$(PROTOC_ARCH).zip
PROTOC_URL := https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VER)/$(PROTOC_ZIP)
PROTOC_TMP_DIR := protoc
PROTOC_BIN_DIR := $(PROTOC_TMP_DIR)/bin
PROTOC := $(PROTOC_BIN_DIR)/protoc
$(PROTOC):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTOC_URL) -o $(PROTOC_TMP_DIR)/$(PROTOC_ZIP) && \
		unzip $(PROTOC_TMP_DIR)/$(PROTOC_ZIP) -d $(PROTOC_TMP_DIR) && \
		chmod 0755 $(PROTOC)
	stat $@ > /dev/null 2>&1

# Get and install the go plug-in for protoc.
PROTOC_GEN_GO_TAR := protoc-gen-go.$(PROTOBUF_VERSION).$(PROTOGEN_OS).$(PROTOGEN_ARCH).tar.gz
PROTOC_GEN_GO_URL := https://github.com/protocolbuffers/protobuf-go/releases/download/$(PROTOBUF_VERSION)/$(PROTOC_GEN_GO_TAR)
PROTOC_GEN_GO     := $(PROTOC_BIN_DIR)/protoc-gen-go
$(PROTOC_GEN_GO):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTOC_GEN_GO_URL) -o $(PROTOC_TMP_DIR)/$(PROTOC_GEN_GO_TAR) && \
		tar -C $(PROTOC_BIN_DIR) -xzvf $(PROTOC_TMP_DIR)/$(PROTOC_GEN_GO_TAR) protoc-gen-go && \
		chmod 0755 $(PROTOC_GEN_GO)
	stat $@ > /dev/null 2>&1

# Get and install the protoc-gen-go-grpc for protoc.
PROTOC_GEN_GO_GRPC_TAR := protoc-gen-go-grpc.v$(PROTOC_GEN_GO_GRPC_VER).$(PROTOGEN_OS).$(PROTOGEN_ARCH).tar.gz
PROTOC_GEN_GO_GRPC_URL := https://github.com/grpc/grpc-go/releases/download/cmd/protoc-gen-go-grpc/v$(PROTOC_GEN_GO_GRPC_VER)/$(PROTOC_GEN_GO_GRPC_TAR)
PROTOC_GEN_GO_GRPC     := $(PROTOC_BIN_DIR)/protoc-gen-go-grpc
$(PROTOC_GEN_GO_GRPC):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTOC_GEN_GO_GRPC_URL) -o $(PROTOC_TMP_DIR)/$(PROTOC_GEN_GO_GRPC_TAR) && \
		tar -C $(PROTOC_BIN_DIR) -xzvf $(PROTOC_TMP_DIR)/$(PROTOC_GEN_GO_GRPC_TAR) ./protoc-gen-go-grpc && \
		chmod 0755 $(PROTOC_GEN_GO_GRPC)
	stat $@ > /dev/null 2>&1

# Update PATH with the protoc bin dir which contains protoc and its plug-in
export PATH := $(HERE)/$(PROTOC_BIN_DIR):$(PATH)

# Generate the go language bindings.
SI_PROTO := ../../si.proto
SI_PKG_SUB := si
SI_BUILD := $(SI_PKG_SUB)/build
SI_GO := $(SI_PKG_SUB)/si.pb.go
SI_GRPC_GO := $(SI_PKG_SUB)/si_grpc.pb.go
GO_OUT := $(HERE)/$(SI_BUILD)
SI_GO_TMP := $(SI_BUILD)/$(PKG_ROOT)/si.pb.go
SI_GRPC_GO_TMP := $(SI_BUILD)/$(PKG_ROOT)/si_grpc.pb.go
$(SI_GO_TMP): $(SI_PROTO) | $(PROTOC) $(PROTOC_GEN_GO) $(PROTOC_GEN_GO_GRPC)
	ls -al $(PROTOC_BIN_DIR)
	mkdir -p $(SI_BUILD) && \
		(cd $(BASE) && $(HERE)/$(PROTOC) \
		--go_out=$(GO_OUT) --go_opt=paths=source_relative \
		--go-grpc_out=$(GO_OUT) --go-grpc_opt=paths=source_relative \
		$(PKG_ROOT)/$(<F))

# Syntax check constants to make sure it passes
COMMON_DIR := ./common
.PHONY: syntax_check
syntax_check:
	@echo "\nsyntax check for constants code"
	@go build $(COMMON_DIR) > /dev/null

# Build the go language bindings from the generated proto.
build: $(SI_GO_TMP) syntax_check
	@cp -f $(SI_GO_TMP) $(SI_GO)
	@cp -f $(SI_GRPC_GO_TMP) $(SI_GRPC_GO)
	@echo "\nprotobuf go source generated:\n\t$(HERE)/$(SI_GO)\n\t$(HERE)/$(SI_GRPC_GO)\n"

# Simple clean of generated file language binding.
.PHONY: clean
clean:
	rm -rf $(SI_GO) $(SI_GO_TMP)
	rm -rf $(PROTOC_TMP_DIR)
	rm -rf $(GO_OUT)

# Remove all non versioned files (including compiler and cache)
.PHONY: clobber
clobber: clean
	rm -rf $(PROTOC_TMP_DIR) $(PROTOC_GEN_GO_SRC) $(SI_BUILD)
