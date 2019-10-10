PREFIX ?= $(if $(VIRTUAL_ENV),$(VIRTUAL_ENV),$(PWD)/local)
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/ocrd_olena
PYTHON ?= $(shell which python3)
PIP ?= $(shell which pip3)

TOOLS = $(shell ocrd ocrd-tool ocrd-tool.json list-tools)

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
	@echo ""
	@echo "  Variables"
	@echo ""
	@echo "    OLENA_VERSION  Olena version to use ('$(OLENA_VERSION)')"
	@echo "    PREFIX         directory to install to ('$(PREFIX)')"
	@echo "    PYTHON         Python binary to bind to ('$(PYTHON)')"
	@echo "    PIP            Python pip to install with ('$(PIP)')"

# END-EVAL

# Olena version to use
#OLENA_VERSION ?= 2.1
OLENA_VERSION ?= git

OLENA_DIR = olena-$(OLENA_VERSION)
OLENA_TARBALL = $(OLENA_DIR).tar.gz

$(OLENA_TARBALL):
	wget -N https://www.lrde.epita.fr/dload/olena/$(OLENA_VERSION)/$(OLENA_TARBALL)

$(OLENA_DIR): olena-configure-python3.patch
$(OLENA_DIR): olena-configure-boost.patch
$(OLENA_DIR): olena-fix-magick-load-catch-exceptions.patch
$(OLENA_DIR): olena-disable-doc.patch
ifeq ($(OLENA_VERSION),git)
$(OLENA_DIR):
	git clone https://gitlab.lrde.epita.fr/olena/olena.git $@
else
$(OLENA_DIR): $(OLENA_TARBALL)
	tar zxf $(OLENA_TARBALL)
endif
	for patch in $(filter %.patch, $^); do \
		patch -d $(OLENA_DIR) -p0 < $$patch; \
	done
	cd $(OLENA_DIR) && autoreconf -i

deps-ubuntu:
	apt install libmagick++-dev libgraphicsmagick++1-dev libboost-dev \
		swig xmlstarlet

deps: #deps-ubuntu
	test -x $(BINDIR)/scribo-cli && \
	$(BINDIR)/scribo-cli sauvola --help >/dev/null 2>&1 || \
		$(MAKE) build-olena
	which ocrd >/dev/null 2>&1 || \
		$(PIP) install --pre ocrd # needed for ocrd CLI (and bashlib)

# Install
install: deps
install: $(SHAREDIR)/ocrd-tool.json
install: $(TOOLS:%=$(BINDIR)/%)

$(SHAREDIR)/ocrd-tool.json:
	@mkdir -p $(SHAREDIR)
	cp -t $(SHAREDIR) ocrd-tool.json 

$(TOOLS:%=$(BINDIR)/%): $(BINDIR)/%: %
	@mkdir -p $(BINDIR)
	sed 's,^SHAREDIR=.*,SHAREDIR="$(SHAREDIR)",' $< > $@
	chmod a+x $@

ifeq ($(findstring $(BINDIR),$(subst :, ,$(PATH))),)
	@echo "you need to add '$(BINDIR)' to your PATH"
else
	@echo "you already have '$(BINDIR)' in your PATH"
endif

uninstall:
	-$(RM) $(SHAREDIR)/ocrd-tool.json
	-$(RM) $(TOOLS:%=$(BINDIR)/%)
	-$(MAKE) -C $(OLENA_DIR)/build uninstall

# Build olena with scribo (document analysis) and swilena (Python bindings)
# but without tools/apps and without generating documentation.
# Furthermore, futurize (Py2/3-port) Python code if possible.
CWD = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
$(OLENA_DIR)/build/config.status: $(OLENA_DIR)
	cd $(OLENA_DIR) && \
		mkdir -p build && \
		cd build && \
		../configure \
			--prefix=$(PREFIX) \
			--enable-scribo \
			--enable-swilena \
			PYTHON=$(PYTHON)

build-olena: $(OLENA_DIR)/build/config.status
	$(MAKE) -C $(OLENA_DIR)/build INSTALL_DATA=$(CWD)/install-futurize.sh install

clean-olena:
	-$(RM) -r $(OLENA_DIR)/build

#
# Assets
#

# Ensure assets are always on the correct revision:
.PHONY: assets-update

# Checkout OCR-D/assets submodule to ./repo/assets
repo/assets: assets-update
	git submodule init
	git submodule update

# to upgrade, use `git -C repo/assets pull` and commit ...

# Copy index of assets
test/assets: repo/assets
	mkdir -p $@
	git -C repo/assets checkout-index -a -f --prefix=$(abspath $@)/

# Run tests
test: test/assets install
	cd test && bash test.sh

clean:
	$(MAKE) uninstall
	$(MAKE) clean-olena
	$(RM) -r test/assets

.PHONY: build-olena clean-olena deps deps-ubuntu help install test clean

# do not search for implicit rules here:
Makefile: ;
