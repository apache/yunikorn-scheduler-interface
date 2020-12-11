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
PROTOC_VER := 3.5.1
endif

# Fix OS string for Mac builds.
PROTOC_OS := $(shell uname -s)
ifeq (Darwin,$(PROTOC_OS))
PROTOC_OS := osx
endif

# Allow building on 32 bit machines.
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

# Get and install the go plug-in for protoc.
GIT_NO_ADVICE := "-c advice.detachedHead=false"
PROTOBUF_PKG := github.com/golang/protobuf
PROTOC_GEN_GO := protoc-gen-go
PROTOC_GEN_GO_PKG := $(PROTOBUF_PKG)/$(PROTOC_GEN_GO)
PROTOC_GEN_GO_SRC := src
$(PROTOC_GEN_GO):
	mkdir -p $(dir $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG))
	test -d $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG)/.git || \
		git clone $(GIT_NO_ADVICE) -b $(PROTOBUF_VERSION) --depth 1 https://$(PROTOBUF_PKG) $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG)
	(cd $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG) && \
		(test "$$(git describe --tags | head -1)" = "$(PROTOBUF_VERSION)" || \
		(rm -rf .??* * && git clone $(GIT_NO_ADVICE) -b $(PROTOBUF_VERSION) --depth 1 https://$(PROTOBUF_PKG) .)))
	(cd $(PROTOC_GEN_GO_SRC)/$(PROTOBUF_PKG) && \
		go get -v -d $$(go list -f '{{ .ImportPath }}' ./...)) && \
		go build -o $(PROTOC_BIN_DIR)/$@ $(PROTOC_GEN_GO_PKG)

# Update PATH with the protoc bin dir which contains protoc and its plug-in
export PATH := $(HERE)/$(PROTOC_BIN_DIR):$(PATH)

# Generate the go language bindings.
SI_PROTO := ../../si.proto
SI_PKG_SUB := si
SI_BUILD := $(SI_PKG_SUB)/build
SI_GO := $(SI_PKG_SUB)/si.pb.go
SI_GO_TMP := $(SI_BUILD)/$(PKG_ROOT)/si.pb.go
$(SI_GO_TMP): GO_OUT := plugins=grpc
$(SI_GO_TMP): GO_OUT := $(GO_OUT),Mgoogle/protobuf/descriptor.proto=$(PROTOC_GEN_GO_PKG)/descriptor
$(SI_GO_TMP): GO_OUT := $(GO_OUT):$(HERE)/$(SI_BUILD)
$(SI_GO_TMP): INCLUDE := -I$(BASE) -I$(HERE)/$(PROTOC_TMP_DIR)/include
$(SI_GO_TMP): $(SI_PROTO) | $(PROTOC) $(PROTOC_GEN_GO)
	mkdir -p $(SI_BUILD) && \
		(cd $(BASE) && \
		$(HERE)/$(PROTOC) $(INCLUDE) --go_out=$(GO_OUT) $(PKG_ROOT)/$(<F))

# Syntax check contants to make sure it passes
COMMON_DIR := ./common
.PHONY: syntax_check
syntax_check:
	@echo "\nsyntax check for constants code"
	@go build $(COMMON_DIR) > /dev/null

# Build the go language bindings from the generated proto.
build: $(SI_GO_TMP) syntax_check
	@cp -f $(SI_GO_TMP) $(SI_GO)
	@echo "\nprotobuf go source generated:\n\t$(HERE)/$(SI_GO)\n"

# Simple clean of generated file language binding.
clean:
	rm -rf $(SI_GO)

# Remove all non versioned files (including compiler and cache)
clobber: clean
	rm -rf $(PROTOC_TMP_DIR) $(PROTOC_GEN_GO_SRC) $(SI_BUILD)

.PHONY: clean clobber
