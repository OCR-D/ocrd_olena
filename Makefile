PREFIX ?= $(if $(VIRTUAL_ENV),$(VIRTUAL_ENV),$(PWD)/local)
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/ocrd_olena
PYTHON ?= $(shell which python3)
PIP ?= $(shell which pip3)
export IMAGEMAGICKXX_CFLAGS ?= $(shell pkg-config --cflags Magick++-im6)
export IMAGEMAGICKXX_LIBS ?= $(shell pkg-config --libs Magick++-im6)

DOCKER_TAG ?= ocrd/olena
TOOLS = ocrd-olena-binarize

# BEGIN-EVAL makefile-parser --make-help Makefile

help:
	@echo ""
	@echo "  Targets"
	@echo ""
	@echo "    install      Install binaries into PATH"
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
	@echo "    PREFIX         directory to install to ('$(PREFIX)')"
	@echo "    PYTHON         Python binary to bind to ('$(PYTHON)')"
	@echo "    PIP            Python pip to install with ('$(PIP)')"

# END-EVAL

OLENA_DIR = $(CURDIR)/repo/olena
BUILD_DIR = $(OLENA_DIR)/build

$(OLENA_DIR)/configure: assets-update
	git submodule sync "$(OLENA_DIR)"
	git submodule update --init "$(OLENA_DIR)"
	cd "$(OLENA_DIR)" && autoreconf -i

deps-ubuntu:
	apt-get -y install \
		git g++ make automake \
		xmlstarlet ca-certificates libmagick++-6.q16-dev libgraphicsmagick++1-dev libboost-dev

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
	$(PIP) install -U pip
	$(PIP) install "ocrd>=2.58.1" # needed for ocrd CLI (and bashlib)

# Install
install: deps install-tools
install-tools: $(SHAREDIR)/ocrd-tool.json
install-tools: $(TOOLS:%=$(BINDIR)/%)

$(SHAREDIR)/ocrd-tool.json: ocrd-tool.json
	@mkdir -p $(SHAREDIR)
	cp ocrd-tool.json $(SHAREDIR)

$(TOOLS:%=$(BINDIR)/%): $(BINDIR)/%: %
	@mkdir -p $(BINDIR)
	sed 's|^SHAREDIR=.*|SHAREDIR="$(SHAREDIR)"|;s|^PYTHON=.*|PYTHON="$(PYTHON)"|' $< > $@
	chmod a+x $@

ifeq ($(findstring $(BINDIR),$(subst :, ,$(PATH))),)
	@echo "you need to add '$(BINDIR)' to your PATH"
else
	@echo "you already have '$(BINDIR)' in your PATH"
endif

uninstall:
	-$(RM) $(SHAREDIR)/ocrd-tool.json
	-$(RM) $(TOOLS:%=$(BINDIR)/%)
	-$(RM) $(BINDIR)/scribo-cli
	-$(MAKE) -C $(BUILD_DIR) uninstall

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
.PHONY: assets-update

# Checkout OCR-D/assets submodule to ./repo/assets
repo/assets: assets-update
	git submodule sync "$@"
	git submodule update --init "$@"

# to upgrade, use `git -C repo/assets pull` and commit ...

# Copy index of assets
test/assets: repo/assets
	mkdir -p $@
	git -C repo/assets checkout-index -a -f --prefix=$(abspath $@)/

# Run tests
test: test/assets
	cd test && PATH=$(BINDIR):$$PATH bash test.sh

clean:
	$(MAKE) uninstall
	$(MAKE) clean-olena
	$(RM) -r test/assets

docker: build-olena.dockerfile Dockerfile
	docker build \
	--build-arg VCS_REF=$$(git rev-parse --short HEAD) \
	--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
	-t $(DOCKER_TAG):build-olena -f build-olena.dockerfile .
	docker build \
	--build-arg VCS_REF=$$(git rev-parse --short HEAD) \
	--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
	-t $(DOCKER_TAG) .

.PHONY: build-olena clean-olena deps deps-ubuntu help install install-tools test clean docker

# do not search for implicit rules here:
Makefile: ;
