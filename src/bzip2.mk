# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := bzip2
$(PKG)_WEBSITE  := https://en.wikipedia.org/wiki/Bzip2
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.0.8
$(PKG)_CHECKSUM := ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
$(PKG)_SUBDIR   := bzip2-$($(PKG)_VERSION)
$(PKG)_FILE     := bzip2-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://sourceware.org/pub/bzip2/$($(PKG)_FILE)
$(PKG)_DEPS     := cc
$(PKG)_TARGETS  := $(BUILD) $(MXE_TARGETS)
$(PKG)_DEPS_$(BUILD) :=

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://sourceware.org/pub/bzip2/' | \
    grep 'bzip2-' | \
    $(SED) -n 's,.*bzip2-\([0-9][^>]*\)\.tar.*,\1,p' | \
    $(SORT) -Vr | $(SED) 1q
endef

define $(PKG)_BUILD_COMMON
    $(MAKE) -C '$(1)' -j '$(JOBS)' libbz2.a \
        PREFIX='$(PREFIX)/$(TARGET)' \
        CC='$(TARGET)-gcc' \
        AR='$(TARGET)-ar' \
        RANLIB='$(TARGET)-ranlib'
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib'
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/include'
    $(INSTALL) -m644 '$(1)/bzlib.h' '$(PREFIX)/$(TARGET)/include/'
endef

define $(PKG)_BUILD
    $($(PKG)_BUILD_COMMON)
    $(INSTALL) -m644 '$(1)/libbz2.a' '$(PREFIX)/$(TARGET)/lib/'
endef

define $(PKG)_BUILD_SHARED
    $($(PKG)_BUILD_COMMON)
    '$(TARGET)-gcc' '$(1)'/*.o -shared \
        -o '$(PREFIX)/$(TARGET)/bin/libbz2.dll' -Xlinker \
        --out-implib -Xlinker '$(PREFIX)/$(TARGET)/lib/libbz2.dll.a'
endef

# static and position independent, so host shared libraries can link it
define $(PKG)_BUILD_$(BUILD)
    $(MAKE) -C '$(1)' -j '$(JOBS)' libbz2.a \
        CC='$(BUILD_CC)' \
        CFLAGS='-O2 -fPIC -D_FILE_OFFSET_BITS=64'
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib'
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/include'
    $(INSTALL) -m644 '$(1)/bzlib.h' '$(PREFIX)/$(TARGET)/include/'
    $(INSTALL) -m644 '$(1)/libbz2.a' '$(PREFIX)/$(TARGET)/lib/'
endef
