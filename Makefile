## ----- Variables -----
PKG_NAME = $(shell basename "$$(pwd)")
ifeq ($(shell ls -1 go.mod 2> /dev/null),go.mod) # use module name from go.mod, if applicable
	PKG_NAME = $(shell basename "$$(cat go.mod | grep module | awk '{print $$2}')")
endif

SECRETS = false
MAINDIR = "."
OUTDIR  = "."


## Source configs:
SRC_FILES = $(shell find . -type f -name '*.go' -not -path "./vendor/*")
SRC_PKGS = $(shell go list ./... | grep -v /vendor/)

## Testing configs:
TEST_TIMEOUT = 20
COVER_OUT = coverage.out



## ------ Commands (targets) -----
.PHONY: default setup

## Default target when no arguments are given to make (build and run program).
default: build-run

## Sets up this project on a new device.
setup: setup-hooks dl
	@if [ "$(SECRETS)" == true ]; then $(REVEAL_SECRETS_CMD); fi


## [Git setup / configuration commands]
.PHONY: setup-hooks hide-secrets reveal-secrets

## Configure Git to use .githooks (for shared githooks).
setup-hooks:
	@echo "Configuring githooks..."
	@git config core.hooksPath .githooks && echo "done"

## Initialize git-secret
init-secrets:
	@git secret init

## Hide modified secret files using git-secret.
hide-secrets:
	@echo "Hiding modified secret files..."
	@git secret hide -m

## Reveal files hidden by git-secret.
REVEAL_SECRETS_CMD = git secret reveal
reveal-secrets:
	@echo "Revealing secret files..."
	@$(REVEAL_SECRETS_CMD)


## [Go setup / configuration commands]
.PHONY: init verify dl vendor tidy update fix

## Initializes a Go module in the current directory.
## Variables: MODPATH (module source path)
MODPATH =
init:
	@echo "Initializing Go module..."
	@go mod init $(MODPATH)

## Verifies that Go module dependencies are satisfied.
VERIFY_CMD = echo "Verifying Go module dependencies..."; go mod verify
verify:
	@$(VERIFY_CMD)

## Downloads Go module dependencies.
dl:
	@echo "Downloading Go module dependencies..."
	@go mod download && echo "done"

## Vendors Go module dependencies.
vendor:
	@echo "Vendoring Go module dependencies..."
	@go mod vendor && echo "done"

## Tidies Go module dependencies.
tidy:
	@echo "Tidying Go module dependencies..."
	@go mod tidy && echo "done"

## Installs and updates package dependencies.
## Variables: UMODE (Update Mode, choose between patch and minor)
UMODE =
update:
	@echo 'Updating module dependencies with "go get -u"...'
	@go get -u $(UMODE) && echo "done"

## Fixes deprecated Go code using "go fix", by rewriting old APIS to use
## newer ones.
fix:
	@echo 'Fixing deprecated Go code with "go fix"... '
	@go fix && echo "done"


## [Legacy setup / configuration commands]
.PHONY: get

## Downloads and installs all subpackages (legacy).
get:
	@echo "Installing dependencies... "
	@go get ./... && echo "done"


## [Execution / installation commands]
.PHONY: build build-all build-run run clean install

## Runs the built program.
## Sources .env.sh if it exists.
## Variables: SRCENV (boolean which determines whether or not to check and
##            source .env.sh)
SRCENV = true
OUTPATH = $(OUTDIR)/$(PKG_NAME)
RUN_CMD = if [ -f ".env.sh" ] && [ "$(SRCENV)" == true ]; then \
	  echo 'Configuring environment variables by sourcing ".env.sh"...'; \
	  . .env.sh; \
	  printf "done\n\n"; \
	fi; \
	if [ -f "$(OUTPATH)" ]; then \
	  echo 'Running "$(PKG_NAME)"...'; \
	  ./$(OUTPATH); \
	else \
	  echo 'run: could not find program "$(OUTPATH)".' >&2; \
	  exit 1; \
	fi
run:
	@$(RUN_CMD)

## Builds (compiles) the program for this system.
## Variables:
##   - OUTDIR (output directory to place built binaries)
##   - MAINDIR (directory of the main package)
##   - BUILDARGS (additional arguments to pass to "go build")
BUILDARGS =
BUILD_CMD = echo 'Building "$(PKG_NAME)" for this system...'; \
	go build -o "$$(echo $(OUTDIR) | tr -s '/')/$(PKG_NAME)" $(BUILDARGS) \
	  $(MAINDIR) && \
	echo "done"
build:
	@$(BUILD_CMD)

## Builds (cross-compiles) the program for all systems.
## Variables:
##   - OUTDIR (output path to place built binaries)
##   - MAINDIR (directory of the main package)
##   - BUILDARGS (additional arguments to pass to "go build")
build-all:
	@echo 'Building "$(PKG_NAME)" for all systems:'
	@for GOOS in darwin linux windows; do \
		for GOARCH in amd64 386; do \
		  printf "Building GOOS=$$GOOS GOARCH=$$GOARCH... "; \
		  OUTNAME="$(PKG_NAME)-$$GOOS-$$GOARCH"; \
		  if [ $$GOOS == windows ]; then OUTNAME="$$OUTNAME.exe"; fi; \
		  GOBUILD_OUT="$$(GOOS=$$GOOS GOARCH=$$GOARCH go build \
		    -o "$$(echo $(OUTDIR) | tr -s '/')/$$OUTNAME" $(BUILDARGS) \
		    $(MAINDIR) 2>&1)"; \
		  if [ -n "$$GOBUILD_OUT" ]; then \
		    printf "\nError during build:\n" >&2; \
		    echo "$$GOBUILD_OUT" >&2; \
		    exit 1; \
		  else printf "\tdone\n"; \
		  fi; \
		done; \
	done

## Builds (compiles) the program for this system, and runs it.
## Sources .env.sh before running, if it exists.
build-run:
	@$(BUILD_CMD) && echo "" && $(RUN_CMD)

## Cleans build artifacts (executables, object files, etc.).
clean:
	@echo 'Cleaning build artifacts with "go clean"...'
	@go clean && echo "done"

## Installs the program using "go install".
install:
	@echo 'Installing program using "go install"... '
	@go install && echo "done"


## [Source code inspection commands]
.PHONY: fmt lint vet check

## Formats the source code using "gofmt".
FMT_CMD = if ! which gofmt > /dev/null; then \
	  echo '"gofmt" is required to format source code.'; \
	else \
	  echo 'Formatting source code using "gofmt"...'; \
	  gofmt -l -s -w . && echo "done"; \
	fi
fmt:
	@$(FMT_CMD)

## Lints the source code using "golint".
LINT_CMD = if ! which golint > /dev/null; then \
	  echo '"golint" is required to lint soure code.'; \
	else \
	  echo 'Formatting source code using "golint"...'; \
	  golint ./... && echo "done"; \
	fi
lint:
	@$(LINT_CMD)

## Checking for suspicious code using "go vet".
VET_CMD = echo 'Checking for suspicious code using "go vet"...'; \
	go vet && echo "done"
vet:
	@$(VET_CMD)

## Checks for formatting, linting, and suspicious code.
CHECK_CMD = $(FMT_CMD) && echo "" && $(LINT_CMD) && echo "" && $(VET_CMD)
check:
	@$(CHECK_CMD)


## [Testing commands]
.PHONY: test test-v test-race test-race-v bench bench-v

TEST_CMD = go test ./... -coverprofile=$(COVER_OUT) \
		               -covermode=atomic \
		               -timeout=$(TEST_TIMEOUT)
test:
	@echo "Testing:"
	@$(TEST_CMD)
test-v:
	@echo "Testing (verbose):"
	@$(TEST_CMD) -v

TEST_CMD_RACE = $(TEST_CMD) -race
test-race:
	@echo "Testing (race):"
	@$(TEST_CMD_RACE)
test-race-v:
	@printf "Testing (race, verbose):\n"
	@$(TEST_CMD_RACE) -v

BENCH_CMD = $(TEST_CMD) ./... -run=^$$ -bench=. -benchmem
bench:
	@printf "Benchmarking:\n"
	@$(BENCH_CMD)
bench-v:
	@printf "Benchmarking (verbose):\n"
	@$(BENCH_CMD) -v


## [Reviewing commands]
.PHONY: review review-race review-bench
__review_base:
	@$(VERIFY_CMD) && echo "" && $(CHECK_CMD) && echo ""

## Formats, checks, and tests the code.
review: __review_base test
review-v: __review_base test-v

## Like "review", but tests for race conditions.
review-race: __review_base test-race
review-race-v: __review_base test-race-v

## Like "review-race", but includes benchmarks.
review-bench: review-race bench
review-bench-v: review-race bench-v


## [Custom environments]
.PHONY: env
ENV = dev

## Set ENV to the environment variable 'MAKE_ENV', if it exists
SHELL_ENV = $(shell echo $$MAKE_ENV)
ifneq ($(SHELL_ENV),)
	ENV = $(SHELL_ENV)
endif

env:
	@echo $(ENV)


## [Docker commands]
.PHONY: up down up-logs reload reload-logs compose
DK = docker
DKCMP = $(DK)-compose

DKCMP_FLAGS = -f docker-compose.yml -f docker-compose.dev.yml
ifeq ($(ENV),prod)
	DKCMP_FLAGS = -f docker-compose.yml -f docker-compose.prod.yml
endif

DKCMP_CMD = $(DKCMP) $(DKCMP_FLAGS)

up:
	@$(DKCMP_CMD) up -d $(TARG)
down:
	@$(DKCMP_CMD) down $(TARG)

TARG =
logs:
	@$(DKCMP_CMD) logs -f $(TARG)

## "up" command variants:
up-logs: up logs

reload: down up
reload-logs: down up-logs

CMD =
compose:
	@$(DKCMP_CMD) $(CMD)

dk-build:
	@$(DKCMP_CMD) build

push:
	@$(DKCMP_CMD) push
