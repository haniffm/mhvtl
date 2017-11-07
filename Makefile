#
# This makefile needs to be invoked as follows:
#
#make <options>
#
# Here, options include:
#
# 	all 	to build all utilities
# 	clean	to clean up all intermediate files
# 	kernel	to build kernel module
#

VER = $(shell awk '/Version/ {print $$2}'  mhvtl-utils.spec.in)
REL = $(shell awk '/Release/ {print $$2}'  mhvtl-utils.spec.in | sed s/%{?dist}//g)

VERSION ?= $(VER).$(REL)
EXTRAVERSION = $(if $(shell git show-ref 2>/dev/null),-git-$(shell git rev-parse --short HEAD))
# immediate eval, for consistent across multiple rule invocation
FULL_VERSION := $(VERSION)$(EXTRAVERSION)-$(shell echo `date "+%Y%m%d.%M%S"`)

PREFIX ?= /usr
USR ?= vtl
SUSER ?=root
GROUP ?= vtl
BINGROUP ?= bin
MHVTL_HOME_PATH ?= /opt/mhvtl
MHVTL_CONFIG_PATH ?= /etc/mhvtl
LIBDIR ?= /usr/lib
CHECK_CC = cgcc
CHECK_CC_FLAGS = '$(CHECK_CC) -Wbitwise -Wno-return-void -no-compile $(ARCH)'

# move damage locally, this will also help make it easier to cleanup after the build
RPM_DIR = $(shell pwd)/rpmbuild

export PREFIX DESTDIR

CFLAGS=-Wall -g -O2 -D_LARGEFILE64_SOURCE $(RPM_OPT_FLAGS)
CLFLAGS=-shared

all:	usr etc scripts

scripts:	patch
	$(MAKE) -C scripts MHVTL_HOME_PATH=$(MHVTL_HOME_PATH) MHVTL_CONFIG_PATH=$(MHVTL_CONFIG_PATH)

etc:	patch
	$(MAKE) -C etc USR=$(USR) GROUP=$(GROUP) MHVTL_HOME_PATH=$(MHVTL_HOME_PATH) MHVTL_CONFIG_PATH=$(MHVTL_CONFIG_PATH)

usr:	patch
	$(MAKE) -C usr USR=$(USR) GROUP=$(GROUP) MHVTL_HOME_PATH=$(MHVTL_HOME_PATH) MHVTL_CONFIG_PATH=$(MHVTL_CONFIG_PATH)

kernel: patch
	$(MAKE) -C kernel

.PHONY: check
check:	ARCH=$(shell sh scripts/checkarch.sh)
check:
	CC=$(CHECK_CC_FLAGS) $(MAKE) all

tags:
	$(MAKE) -C usr tags
	$(MAKE) -C kernel tags

patch:

clean:
	$(MAKE) -C usr clean
	$(MAKE) -C etc clean
	$(MAKE) -C scripts clean
	$(MAKE) -C man clean

distclean:
	$(MAKE) -C usr distclean
	$(MAKE) -C etc distclean
	$(MAKE) -C scripts distclean
	$(MAKE) -C kernel distclean
	$(MAKE) -C man clean
	test -f mhvtl-utils.spec && rm mhvtl-utils.spec || true

install:
	$(MAKE) usr
	$(MAKE) -C usr install $(LIBDIR) $(PREFIX) $(DESTDIR)
	$(MAKE) scripts
	$(MAKE) -C scripts install $(PREFIX) $(DESTDIR)
	$(MAKE) etc
	$(MAKE) -i -C etc install $(DESTDIR) USR=$(USR)
	$(MAKE) -C man man
	$(MAKE) -C man install $(PREFIX) $(DESTDIR) USR=$(USR)
	test -d $(DESTDIR)/opt/mhvtl || mkdir -p $(DESTDIR)/opt/mhvtl

# setup depends rules to force creation of targets
.PHONY: .FORCE

.FORCE:

# remake this each time..
$(RPM_DIR): .FORCE
	@echo "## Clean up on isle $(RPM_DIR)..."
	test -d && rm -frv $(RPM_DIR)
	mkdir -p $(RPM_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

#
# rpm build process to be mroe flexible from git
# lifted from https://github.com/git/git/blob/master/Makefile
#
%.spec: %.spec.in .FORCE
	sed -e 's/@@VERSION@@/$(FULL_VERSION)/g' < $< > $@+
	mv $@+ $@

TAR = tar
RM = rm -f
TARFILE = $(RPM_DIR)/SOURCES/mhvtl-$(FULL_VERSION).tar

tar: $(RPM_DIR) mhvtl-utils.spec .FORCE
	git archive --format=tar --prefix mhvtl-$(FULL_VERSION)/ HEAD^{tree} > $(TARFILE)
	@mkdir -p mhvtl-$(FULL_VERSION)
	@cp mhvtl-utils.spec mhvtl-$(FULL_VERSION)
	$(TAR) rf $(TARFILE) mhvtl-$(FULL_VERSION)/mhvtl-utils.spec
	@$(RM) -r mhvtl-$(FULL_VERSION)
	gzip -f -9 $(TARFILE)

rpm: tar
	env FULL_VERSION=$(FULL_VERSION) PKG_NAME=mhvtl-utils bash pkg-linux/mock_rpmbuild.sh $(TARFILE).gz

kmod-tar: distclean $(RPM_DIR) mhvtl-kmod.spec
	git archive --format=tar --prefix mhvtl-$(FULL_VERSION)/ HEAD^{tree} > $(TARFILE)
	@mkdir -p mhvtl-$(FULL_VERSION)
	@cp mhvtl-kmod.spec mhvtl-$(FULL_VERSION)
	$(TAR) rf $(TARFILE) mhvtl-$(FULL_VERSION)/mhvtl-kmod.spec
	@$(RM) -r mhvtl-$(FULL_VERSION)
	gzip -f -9 $(TARFILE)

kmod-rpm: kmod-tar
	env FULL_VERSION=$(FULL_VERSION) PKG_NAME=mhvtl-kmod bash pkg-linux/mock_rpmbuild.sh $(TARFILE).gz
