GO=go

# go or dlv mode
GO_DLV=go

SRC = $(shell go list -f '{{.Dir}}' ./...  | grep -v -E 'vendor')

TARGETS := worker
VERSION := v0.5.3
BUILD := `git rev-parse --verify HEAD | cut -c1-10`
TAG := "registry.sensetime.com/finance_cloud/go-workers-kestrel:$(VERSION)-$(BUILD)"
PACKAGE := "go-workers-$(BUILD)"
BASE_IMAGE := "registry.sensetime.com/finance_cloud/golang:1.14.15-cuda10.0-runtime-ubuntu16.04"
PROJECT_PATH := "go/src/gitlab.bj.sensetime.com/finance_cloud/go-workers-kestrel"
GOMOD_PATH := `go list -m all | grep go-sign-verification | sed -r 's/ /@/g'`

# host device setting
export host?=amd64
export device?=none
export nolic?=1

host_libs=${host}
device_libs=${host}_${device}

export CGO_LDFLAGS=-L${PWD}/libs/kestrel -L${PWD}/libs ${DEVICE_CGO_LDFLAGS}
# export LD_LIBRARY_PATH=${DEVICE_LD_LIBRARY_PATH}:${PWD}/libs/app:${PWD}/libs:${PWD}/libs/kestrel:${PWD}/libs/gperf:${PWD}/libs/thirdparty

ifndef MODEL_USER
	export MODEL_USER=model_download_robot
    export MODEL_PASS=downloader
endif

ifndef ADELA_MODEL_USER
	export ADELA_MODEL_USER=kestrel-robot
	export ADELA_MODEL_PASS=602bcdab78074fe0bbffd33262b6d917
endif

# Debug build flags
ifeq ($(nolic), 1)
	TEST_FLAGS = nolic
	IMAGE_FLAGS:=--build-arg nolic=1
	BUILD := ${BUILD}-nolic
endif

# prof build flags
ifeq ($(prof), 1)
	TEST_FLAGS:= ${TEST_FLAGS} gperf
    BUILD := ${BUILD}-prof
endif

TEST_FLAGS:= -tags "${TEST_FLAGS} noface nostruct nocrowd nopoi nocarplate ${GO_BUILD_TAG}"

project = gitlab.bj.sensetime.com/finance_cloud/go-workers-kestrel

TEST_VERS=-v -cover -count=1 ${TEST_FLAGS}
# Dlv mode switch
ifeq (${GO_DLV}, dlv)
	TEST_VERS=
endif

all: check build

build: $(TARGETS)

packages = $(shell go list ./...|grep -v /vendor/)

gomod:
	@GIT_LFS_SKIP_SMUDGE=1 $(GO) mod tidy
	@chmod -R +w $(GOPATH)/pkg/mod/$(GOMOD_PATH)
	@rm -rf $(GOPATH)/pkg/mod/$(GOMOD_PATH)/lib64
	@ln -s $(shell pwd)/lib64_internal $(GOPATH)/pkg/mod/$(GOMOD_PATH)/lib64

test: gomod check
	@env LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(shell pwd)/lib64_internal:$(shell pwd)/libs/kestrel:$(shell pwd)/libs:$(arch_ld_library_path) \
		CGO_CFLAGS="-w -O2" \
		$(GO) test -v -cover -count=1 ${packages} 2>&1

test_service_face: gomod check
	@env LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(shell pwd)/lib64_internal:$(shell pwd)/libs/kestrel:$(shell pwd)/libs:$(arch_ld_library_path) \
		CGO_CFLAGS="-w -O2" \
		$(GO_DLV) test ${TEST_VERS} gitlab.bj.sensetime.com/finance_cloud/go-workers-kestrel/service/faceworker
