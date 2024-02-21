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

# Check if this GO tools version used is at least the version of go specified in
# the go.mod file. The version in go.mod should be in sync with other repos.
GO_VERSION := $(shell go version | awk '{print substr($$3, 3, 4)}')
MOD_VERSION := $(shell cat .go_version) 

GM := $(word 1,$(subst ., ,$(GO_VERSION)))
MM := $(word 1,$(subst ., ,$(MOD_VERSION)))
FAIL := $(shell if [ $(GM) -lt $(MM) ]; then echo MAJOR; fi)
ifdef FAIL
$(error Build should be run with at least go $(MOD_VERSION) or later, found $(GO_VERSION))
endif
GM := $(word 2,$(subst ., ,$(GO_VERSION)))
MM := $(word 2,$(subst ., ,$(MOD_VERSION)))
FAIL := $(shell if [ $(GM) -lt $(MM) ]; then echo MINOR; fi)
ifdef FAIL
$(error Build should be run with at least go $(MOD_VERSION) or later, found $(GO_VERSION))
endif

# Retrieve the protobuf version defined in the go module, and download the same version of binary for the build
# This variable will be exported and accessed from lib/go/Makefile
PROTOBUF_VERSION := $(shell go list -m 'google.golang.org/protobuf' | cut -d' ' -f 2)
ifndef PROTOBUF_VERSION
$(error Build requires to set a proper version of google.golang.org/protobuf in go.mod file)
endif
export PROTOBUF_VERSION

# Make sure we are in the same directory as the Makefile
BASE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

SI_SPEC := scheduler-interface-spec.md
SI_PROTO := si.proto

LIB_DIR := lib/go
COMMON_LIB := $(LIB_DIR)/common
CONSTANTS_GO := $(COMMON_LIB)/constants.go
CONSTANTS_TMP := $(COMMON_LIB)/tmp_constants.go
API_LIB := $(LIB_DIR)/api
INTERFACE_GO := $(API_LIB)/interface.go
INTERFACE_TMP := $(API_LIB)/tmp_interface.go

OUTPUT=build
TOOLS_DIR=tools

GO_LICENSES_VERSION=v1.6.0
GO_LICENSES_BIN=$(TOOLS_DIR)/go-licenses

define GENERATED_HEADER
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by make build. DO NOT EDIT

endef
export GENERATED_HEADER

define PACKAGE_DEF
package common

endef
export PACKAGE_DEF

all:
	$(MAKE) -C $(dir $(BASE_DIR)) build

# Generate the proto file from the spec, leave proto untouched if there are no changes
$(SI_PROTO).tmp: $(SI_SPEC)
	@echo "$$GENERATED_HEADER" > $@
	cat $< | sed -n -e '/```protobuf$$/,/^```$$/ p' | sed '/^```/d' >> $@
	awk '{ if (length > 200) print NR, $$0 }' $@ | diff - /dev/null
	(diff $@ $(SI_PROTO) > /dev/null 2>&1 || mv -f $@ $(SI_PROTO)) && \
		rm -f $@

$(CONSTANTS_TMP): $(SI_SPEC)
	test -d $(COMMON_LIB) || mkdir -p $(COMMON_LIB)
	@echo "$$GENERATED_HEADER" > $@
	@echo "$$PACKAGE_DEF" >> $@
	cat $< | sed -n -e '/```constants$$/,/^```$$/ p' | sed '/^```/ s/.*//g' >> $@
	go fmt $@
	(diff $@ $(CONSTANTS_GO) > /dev/null 2>&1 || mv -f $@ $(CONSTANTS_GO)) && \
		rm -f $@

$(INTERFACE_TMP): $(SI_SPEC)
	test -d $(API_LIB) || mkdir -p $(API_LIB)
	@echo "$$GENERATED_HEADER" > $@
	cat $< | sed -n -e '/```golang$$/,/^```$$/ p' | sed '/^```/ s/.*//g' >> $@
	go fmt $@
	(diff $@ $(INTERFACE_GO) > /dev/null 2>&1 || mv -f $@ $(INTERFACE_GO)) && \
		rm -f $@

# Install go-licenses
$(GO_LICENSES_BIN):
	@echo "installing go-licenses $(GO_LICENSES_VERSION)"
	@mkdir -p "$(TOOLS_DIR)"
	@GOBIN="$(BASE_DIR)/$(TOOLS_DIR)" go install "github.com/google/go-licenses@$(GO_LICENSES_VERSION)"

# Build the go language bindings from the spec via a generated proto
.PHONY: build
build: $(SI_PROTO).tmp $(CONSTANTS_TMP) $(INTERFACE_TMP)
	$(MAKE) -C $(LIB_DIR)

# Set a empty recipe
.PHONY: test
test:
	@echo ""

# Check that the updates are made in the source file: scheduler-interface.md
# The check is run as part of the pre-commit and a build should not update any files.
.PHONY: check
check: build
	@echo "Check for changes by build"
	@if ! git diff --quiet; then \
		echo "'make build' updated the following files:\n" ; \
		git status --untracked-files=no --porcelain ; \
		echo "\nUpdates must be made in scheduler-interface.md" ; \
		echo "Run 'make build' before committing PR changes" ; \
		exit 1; \
	fi
	@echo "  all OK"

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
# Check for missing license headers
.PHONY: license-check
license-check:
	@echo "checking license headers:"
ifeq (darwin,$(OS))
	$(shell find -E . -not -path "./.git*" -not -path "*lib*" -regex ".*\.(go|sh|md|yaml|yml|mod)" -exec grep -L "Licensed to the Apache Software Foundation" {} \; > LICRES)
else
	$(shell find . -not -path "./.git*" -not -path "*lib*" -regex ".*\.\(go\|sh\|md\|yaml\|yml\|mod\)" -exec grep -L "Licensed to the Apache Software Foundation" {} \; > LICRES)
endif
	@if [ -s LICRES ]; then \
		echo "following files are missing license header:" ; \
		cat LICRES ; \
		rm -f LICRES ; \
		exit 1; \
	fi ; \
	rm -f LICRES
	@echo "  all OK"

# Check licenses of go dependencies
.PHONY: go-license-check
go-license-check: $(GO_LICENSES_BIN)
	@echo "Checking third-party licenses"
	@"$(GO_LICENSES_BIN)" check ./lib/go/... --include_tests --disallowed_types=forbidden,permissive,reciprocal,restricted,unknown
	@echo "License checks OK"

# Save licenses of go dependencies
.PHONY: go-license-save
go-license-save: $(GO_LICENSES_BIN)
	@echo "Saving third-party license files"
	@rm -rf "$(OUTPUT)/third-party-licenses"
	@"$(GO_LICENSES_BIN)" \
		save ./lib/go/... \
		--save_path="$(OUTPUT)/third-party-licenses" \
		--ignore github.com/apache/yunikorn-scheduler-interface
	@rm -rf third-party-licenses
	@mv -f "$(OUTPUT)/third-party-licenses" third-party-licenses

# Simple clean of generated files only (no local cleanup).
.PHONY: clean
clean:
	rm -rf $(CONSTANTS_GO)
	rm -rf $(INTERFACE_GO)
	cd $(BASE_DIR) && \
	$(MAKE) -C $(LIB_DIR) $@

.PHONY: distclean
distclean: clean
	rm -rf $(TOOLS_DIR)

# Remove all non versioned files,
# Running this target will trigger a re-install of protoc etc in te next build cycle.
.PHONY: clobber
clobber: clean
	cd $(BASE_DIR) && \
	$(MAKE) -C $(LIB_DIR) $@
