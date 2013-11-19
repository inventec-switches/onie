#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of zlib
#

ZLIB_VERSION		= 1.2.8
ZLIB_TARBALL		= zlib-$(ZLIB_VERSION).tar.gz
ZLIB_TARBALL_URLS	= http://zlib.net \
			  http://softlayer-dal.dl.sourceforge.net/project/libpng/zlib/1.2.8
ZLIB_BUILD_DIR		= $(MBUILDDIR)/zlib
ZLIB_DIR		= $(ZLIB_BUILD_DIR)/zlib-$(ZLIB_VERSION)

ZLIB_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/zlib-download
ZLIB_SOURCE_STAMP	= $(STAMPDIR)/zlib-source
ZLIB_CONFIGURE_STAMP	= $(STAMPDIR)/zlib-configure
ZLIB_BUILD_STAMP	= $(STAMPDIR)/zlib-build
ZLIB_INSTALL_STAMP	= $(STAMPDIR)/zlib-install
ZLIB_STAMP		= $(ZLIB_DOWNLOAD_STAMP) \
			  $(ZLIB_SOURCE_STAMP) \
			  $(ZLIB_CONFIGURE_STAMP) \
			  $(ZLIB_BUILD_STAMP) \
			  $(ZLIB_INSTALL_STAMP)

PHONY += zlib zlib-download zlib-source zlib-configure \
	 zlib-build zlib-install zlib-clean zlib-download-clean

ZLIBLIBS = libz.so libz.so.1 libz.so.1.2.8

zlib: $(ZLIB_STAMP)

DOWNLOAD += $(ZLIB_DOWNLOAD_STAMP)
zlib-download: $(ZLIB_DOWNLOAD_STAMP)
$(ZLIB_DOWNLOAD_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream zlib ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(ZLIB_TARBALL) $(ZLIB_TARBALL_URLS)
	$(Q) cd $(DOWNLOADDIR) && sha1sum -c $(UPSTREAMDIR)/$(ZLIB_TARBALL).sha1
	$(Q) touch $@

SOURCE += $(ZLIB_SOURCE_STAMP)
zlib-source: $(ZLIB_SOURCE_STAMP)
$(ZLIB_SOURCE_STAMP): $(ZLIB_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream zlib ===="
	$(Q) $(SCRIPTDIR)/extract-package $(ZLIB_BUILD_DIR) $(DOWNLOADDIR)/$(ZLIB_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
ZLIB_NEW_FILES = $(shell test -d $(ZLIB_DIR) && test -f $(ZLIB_BUILD_STAMP) && \
	              find -L $(ZLIB_DIR) -newer $(ZLIB_BUILD_STAMP) -type f -print -quit)
endif

zlib-configure: $(ZLIB_CONFIGURE_STAMP)
$(ZLIB_CONFIGURE_STAMP): $(ZLIB_SOURCE_STAMP) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure zlib-$(ZLIB_VERSION) ===="
	$(Q) cd $(ZLIB_DIR) &&					\
	    $(ZLIB_DIR)/configure				\
		--prefix=$(UCLIBC_DEV_SYSROOT)/usr
	$(Q) touch $@

zlib-build: $(ZLIB_BUILD_STAMP)
$(ZLIB_BUILD_STAMP): $(ZLIB_CONFIGURE_STAMP) $(ZLIB_NEW_FILES) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building zlib-$(ZLIB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(ZLIB_DIR)				\
		CC=$(CROSSPREFIX)gcc				\
		AR=$(CROSSPREFIX)ar				\
		RANLIB=$(CROSSPREFIX)ranlib			\
		CPP=$(CROSSPREFIX)cpp				\
		LDSHARED="$(CROSSPREFIX)gcc -shared -Wl,-soname,libz.so.1,--version-script,zlib.map -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)" \
		CFLAGS="-Os -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)"
	$(Q) touch $@

zlib-install: $(ZLIB_INSTALL_STAMP)
$(ZLIB_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(ZLIB_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing zlib in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) sudo PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(ZLIB_DIR) install
	$(Q) for file in $(ZLIBLIBS) ; do \
		sudo cp -av $(UCLIBC_DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
		sudo $(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/usr/lib/$$file ; \
	done
	$(Q) touch $@

CLEAN += zlib-clean
zlib-clean:
	$(Q) rm -rf $(ZLIB_BUILD_DIR)
	$(Q) rm -f $(ZLIB_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += zlib-download-clean
zlib-download-clean:
	$(Q) rm -f $(ZLIB_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(ZLIB_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
