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
	@echo "    install      Install"
	@echo "    build-olena  Build olena and scribo"
	@echo "    repo/assets  Clone OCR-D/assets to ./repo/assets"
	@echo "    assets       Setup test assets"
	@echo "    test         Run tests"
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
	wget https://www.lrde.epita.fr/dload/olena/$(OLENA_VERSION)/$(OLENA_TARBALL)

ifeq ($(OLENA_VERSION),git)
$(OLENA_DIR):
	git clone https://gitlab.lrde.epita.fr/olena/olena.git $@
else
$(OLENA_DIR): $(OLENA_TARBALL)
	tar zxf $(OLENA_TARBALL)
endif
	cd $(OLENA_DIR) && patch -p0 < ../olena-configure-python3.patch
	cd $(OLENA_DIR) && patch -p0 < ../olena-configure-boost.patch
	cd $(OLENA_DIR) && patch -p0 < ../olena-fix-magick-load-catch-exceptions.patch
	cd $(OLENA_DIR) && patch -p0 < ../olena-disable-doc.patch
	cd $(OLENA_DIR) && autoreconf -i

deps-ubuntu:
	apt install libmagick++-dev libgraphicsmagick++1-dev libboost-dev \
		xmlstarlet

deps: #deps-ubuntu
	test -x $(BINDIR)/scribo-cli && \
	$(BINDIR)/scribo-cli sauvola --help >/dev/null 2>&1 || \
		$(MAKE) build-olena
	$(PIP) install --pre ocrd # needed for ocrd CLI (and bashlib)

# Install
install: deps
	@mkdir -p $(SHAREDIR) $(BINDIR)
	cp -t $(SHAREDIR) ocrd-tool.json 
	for tool in $(TOOLS);do \
		sed 's,^SHAREDIR=.*,SHAREDIR="$(SHAREDIR)",' $$tool > $(BINDIR)/$$tool ;\
		chmod a+x $(BINDIR)/$$tool ;\
	done
	@if ! [[ "$PATH" =~ $(BINDIR) ]]; then \
		echo "you need to add '$(BINDIR)' to your path"; \
		fi

uninstall:
	-rm -f $(SHAREDIR)/ocrd-tool.json
	-for tool in $(TOOLS);do rm -f $(BINDIR)/$$tool; done
	-$(MAKE) -C $(OLENA_DIR)/build uninstall

#$(MAKE) -s -C swilena/python \
#		--eval='get-pyexecdir: Makefile ; @echo $$(pyexecdir)' \
#		get-pyexecdir

# Build olena with scribo (document analysis) and swilena (Python bindings)
# but without tools/apps and without generating documentation.
# Furthermore, futurize (Py2/3-port) Python code if possible.
CWD = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
build-olena: $(OLENA_DIR)
	cd $(OLENA_DIR) && \
		mkdir -p build && \
		cd build && \
		../configure \
			--prefix=$(PREFIX) \
			--enable-scribo \
			--enable-swilena \
			PYTHON=$(PYTHON)
	$(MAKE) -C $(OLENA_DIR)/build INSTALL_DATA=$(CWD)/install-futurize.sh install

clean-olena:
	-$(RM) $(OLENA_DIR)/build

#
# Assets
#

# Clone OCR-D/assets to ./repo/assets
repo/assets:
	mkdir -p $(dir $@)
	git clone https://github.com/OCR-D/assets "$@"


# Setup test assets
assets: repo/assets
	mkdir -p test/assets
	cp -r -t test/assets repo/assets/data/*

# Run tests
test: assets install
	cd test && bash test.sh

.PHONY: build-olena clean-olena deps deps-ubuntu help install test

# do not search for implicit rules here:
Makefile: ;
