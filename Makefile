PREFIX ?= $(if $(VIRTUAL_ENV),$(VIRTUAL_ENV),$(PWD)/local)
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/ocrd_olena
PYTHON ?= $(shell which python3)
PIP ?= $(shell which pip3)

DOCKER_TAG ?= ocrd/olena
TOOLS = $(shell ocrd ocrd-tool ocrd-tool.json list-tools 2>/dev/null)

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
		xmlstarlet ca-certificates libmagick++-dev libgraphicsmagick++1-dev libboost-dev

deps: #deps-ubuntu
	test -x $(BINDIR)/scribo-cli && \
	$(BINDIR)/scribo-cli sauvola --help >/dev/null 2>&1 || \
		$(MAKE) build-olena
	which ocrd >/dev/null 2>&1 || \
		$(PIP) install ocrd # needed for ocrd CLI (and bashlib)

# Install
install: deps
install: $(SHAREDIR)/ocrd-tool.json
install: $(TOOLS:%=$(BINDIR)/%)

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
test: test/assets install
	cd test && PATH=$(BINDIR):$$PATH bash test.sh

clean:
	$(MAKE) uninstall
	$(MAKE) clean-olena
	$(RM) -r test/assets

docker: build-olena.dockerfile Dockerfile
	docker build -t $(DOCKER_TAG):build-olena -f build-olena.dockerfile .
	docker build -t $(DOCKER_TAG) .

.PHONY: build-olena clean-olena deps deps-ubuntu help install test clean docker

# do not search for implicit rules here:
Makefile: ;
