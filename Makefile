
test: gomod check
	@env LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(shell pwd)/lib64_internal:$(shell pwd)/libs/kestrel:$(shell pwd)/libs:$(arch_ld_library_path) \
		CGO_CFLAGS="-w -O2" \
		$(GO) test -v -cover -count=1 ${packages} 2>&1