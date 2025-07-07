include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fakemesh
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for fakemesh
  PKGARCH:=all
  DEPENDS:=+umdns +jsonfilter +firewall4 +mkt
endef

define Package/luci-app-fakemesh/description
LuCI interface for configuring and managing fakemesh hybrid mesh networks.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-fakemesh/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/fakemesh
	$(CP) ./htdocs/luci-static/resources/view/fakemesh/* $(1)/www/luci-static/resources/view/fakemesh/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/luci/i18n/fakemesh.zh-cn.po $(1)/usr/lib/lua/luci/i18n/fakemesh.zh-cn.po

	$(CP) -a ./root/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-fakemesh))
