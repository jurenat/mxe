# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := protobuf
$(PKG)_WEBSITE  := https://github.com/protocolbuffers/protobuf
$(PKG)_IGNORE   :=
# 21.x (C++ library 3.21) is the last release line that does not need abseil.
$(PKG)_VERSION  := 21.12
$(PKG)_CHECKSUM := 22fdaf641b31655d4b2297f9981fa5203b2866f8332d3c6333f6b0107bb320de
$(PKG)_GH_CONF  := protocolbuffers/protobuf/tags,v
$(PKG)_DEPS     := cc zlib $(BUILD)~$(PKG)
$(PKG)_TARGETS  := $(BUILD) $(MXE_TARGETS)
$(PKG)_DEPS_$(BUILD) := zlib

# CMAKE_SHARED_BOOL is OFF for the build machine, so the host protoc and the
# protoc plugins linking libprotoc (e.g. qt6-qtgrpc's generators) need no
# library path to run.
define $(PKG)_BUILD_$(BUILD)
    '$(TARGET)-cmake' -S '$(SOURCE_DIR)' -B '$(BUILD_DIR)' \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_WITH_ZLIB=ON \
        -Dprotobuf_BUILD_SHARED_LIBS=$(CMAKE_SHARED_BOOL)
    '$(TARGET)-cmake' --build '$(BUILD_DIR)' -j '$(JOBS)'
    '$(TARGET)-cmake' --install '$(BUILD_DIR)'
endef

define $(PKG)_BUILD
    $($(PKG)_BUILD_$(BUILD))

    '$(TARGET)-g++' \
        -W -Wall -Werror -ansi -pedantic -std=c++14 \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-protobuf.exe' \
        `'$(TARGET)-pkg-config' protobuf --cflags --libs`
endef
