CC = gcc
CLANG = clang
CFLAGS = -ggdb -gdwarf -O2 -Wall -fpie -Wno-unused-variable -Wno-unused-function
GIT = $(shell which git || /bin/false)
BPF_CFLAGS = -target bpf -D__TARGET_ARCH_x86
OUT_DIR ?= _output
BIN_DIR := $(OUT_DIR)/bin

EBPF = .
EBPF_PROGRAM = secsys
EBPF_OUTPUT = $(EBPF)/output
EBPF_LIBBPF = $(EBPF)/libbpf
EBPF_LIBBPF_SRC = $(abspath $(EBPF_LIBBPF)/src)
EBPF_LIBBPF_OBJ = $(abspath $(EBPF_OUTPUT)/libbpf.a)
EBPF_LIBBPF_OBJDIR = $(abspath $(EBPF_OUTPUT)/libbpf)
EBPF_LIBBPF_DESTDIR = $(abspath $(EBPF_OUTPUT))

SED_OPTION = -i
ifeq ($(UNAME_S),Darwin)
	SED_OPTION = -i ''
endif

build: init
	go build -o $(BIN_DIR)/secsys ./cmd

##@ Code generations
generate: get-libbpf generate-libbpf generate-go ## generate ebpf

get-libbpf:
	$(GIT) submodule update --init --recursive

generate-libbpf: $(EBPF_LIBBPF_OBJ) ## generate libbpf
$(EBPF_LIBBPF_OBJ): $(EBPF_LIBBPF_SRC) $(wildcard $(EBPF_LIBBPF_SRC)/*.[ch])
	CC="$(CC)" CFLAGS="$(CFLAGS)" \
		$(MAKE) -C $(EBPF_LIBBPF_SRC) \
		BUILD_STATIC_ONLY=1 \
		OBJDIR=$(EBPF_LIBBPF_OBJDIR) \
		DESTDIR=$(EBPF_LIBBPF_DESTDIR) \
		INCLUDEDIR= LIBDIR= UAPIDIR= prefix= libdir= install
	$(MAKE) -C $(EBPF_LIBBPF_SRC) UAPIDIR=$(EBPF_LIBBPF_DESTDIR) install_uapi_headers

generate-go: ## generate golang codes
	GOPACKAGE=$(EBPF_PROGRAM) bpf2go -cc "$(CLANG)" -cflags "$(BPF_CFLAGS)" bpf $(EBPF)/secsys.bpf.c -- -I$(EBPF) -I$(EBPF)/output

init: ## init for build
	mkdir -p $(BIN_DIR)

clean: ## clean
	rm -rf $(EBPF_OUTPUT)
	rm -rf $(EBPF)/*.o

bpf2go: ## download bpf2go
	go install github.com/cilium/ebpf/cmd/bpf2go