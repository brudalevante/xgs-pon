include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for fakemesh
LUCI_DEPENDS:=
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/description
A LuCI application for configuring and managing fakemesh.
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
