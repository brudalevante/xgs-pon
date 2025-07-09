include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Chen Minqiang <ptpt52@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fakemesh
	CATEGORY:=X
	SUBMENU:=Configuration Fake Mesh Support
	TITLE:=LuCI Support for fakemesh
	PKGARCH:=all
	DEPENDS:=+jsonfilter +umdns +firewall4
endef

define Package/luci-app-fakemesh/description
	LuCI Support for fakemesh.
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-fakemesh/conffiles
/etc/config/fakemesh
endef

define Package/luci-app-fakemesh/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/fakemesh.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/fakemesh
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/fakemesh/* $(1)/www/luci-static/resources/view/fakemesh/
	$(CP) -a ./root/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-fakemesh))
