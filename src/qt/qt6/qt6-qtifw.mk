# This file is part of MXE. See LICENSE.md for licensing information.

include src/qt/qt6/qt6-conf.mk

PKG             := qt6-qtifw
$(PKG)_WEBSITE  := https://doc.qt.io/qtinstallerframework/index.html
$(PKG)_DESCR    := Qt Installer Framework (Qt6)
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 4.11.0
$(PKG)_CHECKSUM := 4abdad903a52b1c20bb46c715d7d12c65905791a3e366e574212fdd74cc47629
$(PKG)_SUBDIR   := installer-framework-everywhere-src-dev
$(PKG)_FILE     := installer-framework-everywhere-src-$($(PKG)_VERSION).tar.xz
$(PKG)_URL      := https://download.qt.io/official_releases/qt-installer-framework/$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_TARGETS  := $(BUILD) $(MXE_TARGETS)

# The host build provides the tools that create installers and
# repositories (binarycreator, repogen, archivegen, devtool). The target
# build provides installerbase, the installer stub that binarycreator
# embeds the payload into. installerbase must be self-contained, so it is
# only built for static targets.
$(PKG)_DEPS_$(BUILD) := qt6-conf qt6-qtbase qt6-qtdeclarative qt6-qttools qt6-qt5compat \
                        zlib bzip2 xz libiconv
$(PKG)_DEPS          :=
# installerbase skips every language that has no Qt translation
$(PKG)_DEPS_STATIC   := cc qt6-conf qt6-qtbase qt6-qtdeclarative qt6-qttools qt6-qt5compat \
                        qt6-qttranslations zlib bzip2 xz $(BUILD)~$(PKG)

QT6_PREFIX   = '$(PREFIX)/$(TARGET)/$(MXE_QT6_ID)'
QT6_QMAKE    = '$(TARGET)-$(MXE_QT6_ID)-qmake'

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://download.qt.io/official_releases/qt-installer-framework/' | \
    $(SED) -n 's,.*<a href="*\([0-9][^"]*\)/.*,\1,p' | \
    $(SORT) -V | \
    tail -1
endef

# the compression libraries for the bundled libarchive
$(PKG)_QMAKE_OPTS = \
    IFW_ZLIB_LIBRARY=-lz \
    IFW_BZIP2_LIBRARY=-lbz2 \
    'INCLUDEPATH+=$(PREFIX)/$(TARGET)/include' \
    'LIBS+=-L$(PREFIX)/$(TARGET)/lib'

define $(PKG)_BUILD_$(BUILD)
    # libarchive picks up the iconv.h of MXE's native libiconv, which
    # renames the iconv functions, so link that library after it
    cd '$(BUILD_DIR)' && '$(QT6_PREFIX)/bin/qmake' $($(PKG)_QMAKE_OPTS) \
        'IFW_LZMA_LIBRARY=-llzma -liconv' \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    for tool in binarycreator repogen archivegen devtool; do \
        $(INSTALL) -m755 "$(BUILD_DIR)/bin/$$tool" "$(PREFIX)/bin/$(BUILD)-$(MXE_QT6_ID)-$$tool" || exit 1; \
    done
endef

define $(PKG)_BUILD_STATIC
    # the *.rc file can't take the version string macro with its embedded \0
    $(SED) -i 's,IFW_VERSION_STR_WIN32,"$($(PKG)_VERSION)",g' '$(SOURCE_DIR)/src/sdk/installerbase.rc'
    cd '$(BUILD_DIR)' && $(QT6_QMAKE) $($(PKG)_QMAKE_OPTS) \
        IFW_LZMA_LIBRARY=-llzma \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install

    # build the tutorial installer; binarycreator renames its output from
    # the temp dir, so keep the temp dir on the same filesystem
    cd '$(SOURCE_DIR)/examples/tutorial' && \
    TMPDIR='$(BUILD_DIR)' '$(PREFIX)/bin/$(BUILD)-$(MXE_QT6_ID)-binarycreator' \
        -c config/config.xml \
        -p packages \
        -t '$(QT6_PREFIX)/bin/installerbase.exe' \
        '$(BUILD_DIR)/test-$(PKG)-tutorialinstaller.exe'
    $(INSTALL) -m755 '$(BUILD_DIR)/test-$(PKG)-tutorialinstaller.exe' '$(PREFIX)/$(TARGET)/bin/'
endef
