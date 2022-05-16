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
GO := $(shell command -v go 2> /dev/null)
GO111MODULE := on
export GO111MODULE

# Only set PROTOC_VER if it has an empty value.
ifeq (,$(strip $(PROTOC_VER)))
PROTOC_VER := 3.16.0
endif

# Fix OS string for Mac builds.
PROTOC_OS := $(shell uname -s)
PROTOGEN_OS := $(shell uname -s)
ifeq (Darwin,$(PROTOC_OS))
PROTOC_OS := osx
endif

# Allow building on 32 bit machines.
PROTOC_ARCH := $(shell uname -m)
PROTOGEN_ARCH := amd64
ifeq (i386,$(PROTOC_ARCH))
PROTOC_ARCH := x86_32
PROTOGEN_ARCH := 386
else ifeq (arm64, $(PROTOC_ARCH))
PROTOC_ARCH := x86_64
endif

PROTOBUF_VERSION := $(shell $(GO) list -m 'google.golang.org/protobuf' | cut -d' ' -f 2 | cut -d'-' -f1)
ifndef PROTOBUF_VERSION
$(error Build requires to set a proper version of google.golang.org/protobuf in go.mod file)
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
PROTO_GEN_GO_TAR := protoc-gen-go.$(PROTOBUF_VERSION).$(PROTOGEN_OS).$(PROTOGEN_ARCH).tar.gz
PROTO_GEN_URL    := https://github.com/protocolbuffers/protobuf-go/releases/download/$(PROTOBUF_VERSION)/$(PROTO_GEN_GO_TAR)
PROTO_GEN_GO     := $(PROTOC_BIN_DIR)/protoc-gen-go
$(PROTO_GEN_GO):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTO_GEN_URL) -o $(PROTOC_TMP_DIR)/$(PROTO_GEN_GO_TAR) && \
		tar -C $(PROTOC_BIN_DIR) -xzvf $(PROTOC_TMP_DIR)/$(PROTO_GEN_GO_TAR) protoc-gen-go && \
		chmod 0755 $(PROTO_GEN_GO)
	stat $@ > /dev/null 2>&1

# Get and install the go plug-in for protoc rpc.
PROTO_GEN_GRPC_VERSION := v1.1.0
PROTO_GEN_GRPC_TAR     := protoc-gen-go-grpc.$(PROTO_GEN_GRPC_VERSION).$(PROTOGEN_OS).$(PROTOGEN_ARCH).tar.gz
PROTO_GEN_GRPC_TAG     := cmd%2Fprotoc-gen-go-grpc%2F$(PROTO_GEN_GRPC_VERSION)
PROTO_GEN_GRPC_URL     := https://github.com/grpc/grpc-go/releases/download/$(PROTO_GEN_GRPC_TAG)/$(PROTO_GEN_GRPC_TAR)
PROTO_GEN_GRPC_GO      := $(PROTOC_BIN_DIR)/protoc-gen-go-grpc
$(PROTO_GEN_GRPC_GO):
	mkdir -p $(PROTOC_TMP_DIR) && \
		curl -L $(PROTO_GEN_GRPC_URL) -o $(PROTOC_TMP_DIR)/$(PROTO_GEN_GRPC_TAR) && \
		tar -C $(PROTOC_BIN_DIR) -xzvf $(PROTOC_TMP_DIR)/$(PROTO_GEN_GRPC_TAR) ./protoc-gen-go-grpc && \
		chmod 0755 $(PROTO_GEN_GRPC_GO)
	stat $@ > /dev/null 2>&1

# Update PATH with the protoc bin dir which contains protoc and its plug-in
export PATH := $(HERE)/$(PROTOC_BIN_DIR):$(PATH)

# Generate the go language bindings.
# Note: before updating gRPC to later versions (e.g v1.32+), need to use
# --go_out=plugins=grpc option to generate the gRPC code, otherwise
# the generated code will have compile issues. We need to explicitly install
# an older version of protoc-gen-go to make sure the generated code is
# compatible with the current version of gRPC. See more details in
# https://issues.apache.org/jira/browse/YUNIKORN-815.
SI_PROTO := ../../si.proto
SI_PKG_SUB := si
SI_BUILD := $(SI_PKG_SUB)/build
SI_GO := $(SI_PKG_SUB)/si.pb.go
SI_GRPC_GO := $(SI_PKG_SUB)/si_grpc.pb.go
GO_OUT := $(HERE)/$(SI_BUILD)
SI_GO_TMP := $(SI_BUILD)/$(PKG_ROOT)/si.pb.go
$(SI_GO_TMP): $(SI_PROTO) | $(PROTOC) $(PROTO_GEN_GO) $(PROTO_GEN_GRPC_GO)
	ls -al $(PROTOC_BIN_DIR)
	mkdir -p $(SI_BUILD) && \
		(cd $(BASE) && $(HERE)/$(PROTOC) \
		--go_opt=paths=source_relative --go_out=$(GO_OUT) \
		--go-grpc_opt=paths=source_relative --go-grpc_out=$(GO_OUT) \
		$(PKG_ROOT)/$(<F))

# Syntax check constants to make sure it passes
COMMON_DIR := ./common
.PHONY: syntax_check
syntax_check:
	@echo "\nsyntax check for constants code"
	@go build $(COMMON_DIR) > /dev/null

# Build the go language bindings from the generated proto.
build: $(SI_GO_TMP) syntax_check
	cp -f $(SI_GO_TMP) $(SI_GO)
	@echo "\nprotobuf go source generated:\n\t$(HERE)/$(SI_GO)\n"

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
