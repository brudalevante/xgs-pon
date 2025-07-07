include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fakemesh
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for fakemesh
  PKGARCH:=all
  DEPENDS:=+luci-base
endef

define Package/luci-app-fakemesh/description
LuCI interface for configuring and managing fakemesh hybrid mesh networks.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-fakemesh/install
$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
$(INSTALL_DATA) ./root/usr/lib/lua/luci/controller/fakemesh.lua $(1)/usr/lib/lua/luci/controller/fakemesh.lua
$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
$(INSTALL_DATA) ./root/usr/lib/lua/luci/model/cbi/fakemesh.lua $(1)/usr/lib/lua/luci/model/cbi/fakemesh.lua
endef

$(eval $(call BuildPackage,luci-app-fakemesh))
