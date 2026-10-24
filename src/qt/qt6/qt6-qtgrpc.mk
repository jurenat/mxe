# This file is part of MXE. See LICENSE.md for licensing information.

include src/qt/qt6/qt6-conf.mk

PKG := qt6-qtgrpc
$(eval $(QT6_METADATA))

$(PKG)_CHECKSUM := 771852c4e5fbeb3d7c3b2a9aacc13db9efe942a46e7d1454ec1f16092ec3ef9c
$(PKG)_TARGETS       := $(BUILD) $(MXE_TARGETS)
$(PKG)_DEPS_$(BUILD) := qt6-conf qt6-qtbase protobuf
$(PKG)_DEPS          := cc qt6-conf qt6-qtbase $(BUILD)~$(PKG)

# The target build provides the Qt6::Protobuf and Qt6::Grpc runtime
# libraries. The host build provides the code generators (qtprotobufgen,
# qtgrpcgen) that qt_add_protobuf/qt_add_grpc run; they are protoc plugins,
# so it needs protobuf, whose protoc they also run.

QT6_PREFIX   = '$(PREFIX)/$(TARGET)/$(MXE_QT6_ID)'
QT6_QT_CMAKE = '$(QT6_PREFIX)/$(if $(findstring mingw,$(TARGET)),bin,libexec)/qt-cmake-private' \
                   -DCMAKE_INSTALL_PREFIX='$(QT6_PREFIX)'

define $(PKG)_BUILD_$(BUILD)
    $(QT6_QT_CMAKE) -S '$(SOURCE_DIR)' -B '$(BUILD_DIR)' \
        -DCMAKE_PREFIX_PATH='$(PREFIX)/$(TARGET)'
    # without protobuf the generators are skipped, not an error
    grep -q 'Qt Protobuf generator .* yes' '$(BUILD_DIR)/config.summary'
    grep -q 'Qt GRPC generator .* yes' '$(BUILD_DIR)/config.summary'
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' --build . -j '$(JOBS)'
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' --install .
endef

define $(PKG)_BUILD
    $(QT6_QT_CMAKE) -S '$(SOURCE_DIR)' -B '$(BUILD_DIR)'
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' --build . -j '$(JOBS)'
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' --install .
endef
