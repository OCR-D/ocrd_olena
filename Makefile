PREFIX = $(PWD)/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/ocrd_olena

TOOLS = $(shell ocrd ocrd-tool ocrd-tool.json list-tools)

# BEGIN-EVAL makefile-parser --make-help Makefile

help:
	@echo ""
	@echo "  Targets"
	@echo ""
	@echo "    build-olena  Build olena and scribo"
	@echo ""
	@echo "  Variables"
	@echo ""
	@echo "    OLENA_VERSION  Olena version to use ('$(OLENA_VERSION)')"

# END-EVAL

# Olena version to use ('$(OLENA_VERSION)')
OLENA_VERSION = 2.1

OLENA_DIR = olena-$(OLENA_VERSION)
OLENA_TARBALL = $(OLENA_DIR).tar.gz

$(OLENA_DIR).tar.gz:
	wget https://www.lrde.epita.fr/dload/olena/$(OLENA_VERSION)/$(OLENA_TARBALL)

$(OLENA_DIR): $(OLENA_TARBALL)
	tar xf $(OLENA_TARBALL)

olena-git:
	git clone git://git.lrde.epita.fr/olena olena-git

deps-ubuntu:
	sudo apt install libmagick++-dev `grep -q 18.04 /etc/*release || libtesseract3-dev`

deps: deps-ubuntu
	which scribo-cli || $(MAKE) build-olena

install:
	@mkdir -p $(SHAREDIR) $(BINDIR)
	cp -t $(SHAREDIR) ocrd-tool.json 
	for tool in $(TOOLS);do \
		sed 's,^SHAREDIR=.*,SHAREDIR="$(SHAREDIR)",' $$tool > $(BINDIR)/$$tool ;\
		chmod a+x $(BINDIR)/$$tool ;\
	done

# Build olena and scribo
build-olena: $(OLENA_DIR)
	cd $(OLENA_DIR) ;\
		./configure \
			--prefix=$(PREFIX) \
			--enable-scribo \
			--enable-apps \
			--enable-tools \
			;\
		make -j4 ;\
		make install
