all: build

SI_PROTO := si.proto

# main build first check the input then generate
build: check
	$(MAKE) -C lib/go

# simple clean of generated files only
clean:
	$(MAKE) -C lib/go $@

# remove all non versioned files
# will require a re-install of protoc etc in te next cycle
clobber:
	$(MAKE) -C lib/go $@

# check generated files for violation of standards
check: $(SI_PROTO)
	awk '{ if (length > 200) print NR, $$0 }' $? | diff - /dev/null

.PHONY: clean clobber check
