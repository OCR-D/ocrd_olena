PREFIX ?= $(PWD)/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/ocrd_olena

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
	@echo "    PREFIX         directory to to install ('$(PREFIX)')"

# END-EVAL

# Olena version to use ('$(OLENA_VERSION)')
OLENA_VERSION = 2.1

OLENA_DIR = olena-$(OLENA_VERSION)
OLENA_TARBALL = $(OLENA_DIR).tar.gz

$(OLENA_DIR).tar.gz:
	wget https://www.lrde.epita.fr/dload/olena/$(OLENA_VERSION)/$(OLENA_TARBALL)

$(OLENA_DIR): $(OLENA_TARBALL)
	tar xf $(OLENA_TARBALL)
	cd $(OLENA_DIR) && patch < ../olena-configure-boost.patch
	cd $(OLENA_DIR) && patch -p1 < ../olena-fix-magick-load-catch-exceptions.patch

olena-git:
	git clone git://git.lrde.epita.fr/olena olena-git

deps-ubuntu:
	apt install libmagick++-dev libgraphicsmagick++1-dev libboost-dev \
	`grep -q 18.04 /etc/*release || echo libtesseract-dev` graphviz xmlstarlet

deps: #deps-ubuntu
	test -x $(BINDIR)/scribo-cli && \
	$(BINDIR)/scribo-cli sauvola --help >/dev/null 2>&1 || \
	$(MAKE) build-olena
	pip3 install --pre ocrd # needed for ocrd CLI (and bashlib)

# Install
install: deps
	@mkdir -p $(SHAREDIR) $(BINDIR)
	cp -t $(SHAREDIR) ocrd-tool.json 
	for tool in $(TOOLS);do \
		sed 's,^SHAREDIR=.*,SHAREDIR="$(SHAREDIR)",' $$tool > $(BINDIR)/$$tool ;\
		chmod a+x $(BINDIR)/$$tool ;\
	done
	@echo "you might want to add '$(BINDIR)' to your path"

# Build olena and scribo
build-olena: $(OLENA_DIR)
	cd $(OLENA_DIR) ;\
		./configure \
			--prefix=$(PREFIX) \
			--enable-scribo \
			--enable-apps \
			--enable-tools
	$(MAKE) -C $(OLENA_DIR) install

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

.PHONY: build-olena deps deps-ubuntu help install test olena-git
