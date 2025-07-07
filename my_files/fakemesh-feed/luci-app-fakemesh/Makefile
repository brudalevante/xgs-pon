include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for fakemesh
LUCI_DEPENDS:=+umdns +jsonfilter +firewall4 +mkt
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/fakemesh
	$(CP) ./htdocs/luci-static/resources/view/fakemesh/* $(1)/www/luci-static/resources/view/fakemesh/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/luci/i18n/fakemesh.zh-cn.po $(1)/usr/lib/lua/luci/i18n/fakemesh.zh-cn.po

	$(CP) -a ./root/* $(1)/
endef
