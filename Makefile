PREFIX ?= $(if $(VIRTUAL_ENV),$(VIRTUAL_ENV),$(PWD)/local)
PYTHON ?= python3
PIP ?= pip3
GIT_SUBMODULE = git submodule
PYTEST_ARGS ?= -vv

export IMAGEMAGICKXX_CFLAGS ?= $(shell pkg-config --cflags Magick++-im6)
export IMAGEMAGICKXX_LIBS ?= $(shell pkg-config --libs Magick++-im6)

DOCKER_BASE_IMAGE = docker.io/ocrd/core:latest
DOCKER_TAG ?= ocrd/olena
DOCKER_STAGE ?= ocrd
DOCKER ?= docker

# BEGIN-EVAL makefile-parser --make-help Makefile

help:
	@echo ""
	@echo "  Targets"
	@echo ""
	@echo "    install      Install Python package via pip"
	@echo "    install-dev  Install in editable mode"
	@echo "    build        Build source and binary distribution"
	@echo "    build-olena  Build olena and scribo"
	@echo "    clean-olena  Clean olena including config"
	@echo "    repo/assets  Clone OCR-D/assets to ./repo/assets"
	@echo "    assets       Setup test assets"
	@echo "    test         Run basic tests"
	@echo "    clean        Uninstall, then remove assets and build"
	@echo "    docker       Build docker images"
	@echo ""
	@echo "  Variables"
	@echo ""
	@echo "    PREFIX         directory to install to ['$(PREFIX)']"
	@echo "    PYTHON         Python binary to bind to ['$(PYTHON)']"
	@echo "    PIP            Python pip to install with ['$(PIP)']"
	@echo "    PYTEST_ARGS    extra options for test ['$(PYTEST_ARGS)']"

# END-EVAL

OLENA_DIR = $(CURDIR)/repo/olena
BUILD_DIR = $(OLENA_DIR)/build

$(OLENA_DIR)/configure: repo/olena
	cd "$(OLENA_DIR)" && autoreconf -i

deps-ubuntu:
	apt-get update
	apt-get -y install --no-install-recommends \
		git libmagick++-dev libgraphicsmagick++1-dev libboost-dev

check_pkg_config = \
	if ! pkg-config --modversion $(1) >/dev/null 2>/dev/null;then\
		echo "$(1) not installed. 'make deps-ubuntu' or 'sudo apt install $(2)'"; exit 1 ;\
	fi

check_config_status = \
	if test "$(3)" = "alternative";then predicate='["HAVE_$(1)_TRUE"]="\#"' ;\
	else predicate='["HAVE_$(1)"]=" 1"'; fi;\
	if ! grep -Fq "$$predicate" $(BUILD_DIR)/config.status;then \
		echo "$(2) not installed. 'make deps-ubuntu' or 'sudo apt install $(2)'"; \
		exit 1 ; \
	fi;

deps-check:
	$(call check_pkg_config,Magick++-im6,libmagick++-6.q16-dev)
	$(call check_pkg_config,GraphicsMagick++,libgraphicsmagick++1-dev)
	$(call check_config_status,BOOST,libboost-dev)

deps: #deps-ubuntu
	command -v scribo-cli >/dev/null 2>&1 && \
	scribo-cli sauvola --help >/dev/null 2>&1 || \
		$(MAKE) build-olena

install: deps
	$(PIP) install .

install-dev: deps
	$(PIP) install -e .

uninstall:
	-$(PIP) uninstall ocrd_olena
	-$(MAKE) -C $(BUILD_DIR) uninstall

build:
	$(PIP) install build wheel
	$(PYTHON) -m build .

# Build olena with scribo (document analysis) and swilena (Python bindings)
# but without tools/apps and without generating documentation.
# Furthermore, futurize (Py2/3-port) Python code if possible.
# Note that olena fails to configure the dependency tracking, so disable it.
# Note that olena fails to compile scribo with recent compilers
# which abort with an error unless SCRIBO_NDEBUG is defined.
CWD = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
$(BUILD_DIR)/config.status: $(OLENA_DIR)/configure
	mkdir -p $(BUILD_DIR) && \
		cd $(BUILD_DIR) && \
		$(OLENA_DIR)/configure \
			--prefix=$(PREFIX) \
			--disable-doc \
			--disable-dependency-tracking \
			--with-qt=no \
			--with-tesseract=no \
			--enable-scribo SCRIBO_CXXFLAGS="-DNDEBUG -DSCRIBO_NDEBUG -O2"
	$(MAKE) deps-check

build-olena: $(BUILD_DIR)/config.status
	cd $(OLENA_DIR)/milena/mln && touch -r version.hh.in version.hh
	$(MAKE) -C $(BUILD_DIR) install

clean-olena:
	-$(RM) -r $(BUILD_DIR)

#
# Assets
#

# Ensure assets and olena git repos are always on the correct revision:
.PHONY: always-update

# Checkout OCR-D/assets submodule to ./repo/assets
repo/olena repo/assets: always-update
	$(GIT_SUBMODULE) sync "$@"
	$(GIT_SUBMODULE) update --init "$@"

# to upgrade, use `git -C repo/assets pull` and commit ...

deps-test:
	$(PIP) install -r requirements-test.txt

# Copy index of assets
test/assets: repo/assets
	mkdir -p $@
	git -C repo/assets checkout-index -a -f --prefix=$(abspath $@)/
	touch $@/__init__.py

# Run tests
test: test/assets deps-test
	$(PYTHON) -m pytest test --durations=0 --continue-on-collection-errors $(PYTEST_ARGS)

coverage: deps-test
	coverage erase
	$(MAKE) test PYTHON="coverage run"
	coverage combine
	coverage report -m

clean:
	$(MAKE) uninstall
	$(MAKE) clean-olena
	$(RM) -r test/assets

docker: Dockerfile repo/olena
	$(DOCKER) build --progress=plain \
	--build-arg DOCKER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
	--build-arg VCS_REF=$$(git rev-parse --short HEAD) \
	--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
	-t $(DOCKER_TAG) --target=$(DOCKER_STAGE) .

.PHONY: build build-olena clean-olena deps deps-test deps-ubuntu help install install-dev test uninstall clean docker

# do not search for implicit rules here:
Makefile: ;
