#!/bin/bash

set -e

# 1. Limpiar entornos previos
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# 2. Clonar OpenWrt y feeds de MediaTek
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..
echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 3. Copiar archivos de configuración y reglas personalizados
cp -rf configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -rf my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -f mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

# 4. Copiar parches personalizados
cp -rf my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -rf my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -rf my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

# 5. Limpiar configuración de perf innecesaria
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config || true

# 6. Preparar feeds y paquetes personalizados
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a

mkdir -p feeds/packages/utils
mkdir -p feeds/packages/net
mkdir -p feeds/luci/applications

cp -rf ../my_files/luci-app-3ginfo-lite-main/sms-tool feeds/packages/utils/sms-tool || true
cp -rf ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite feeds/luci/applications/luci-app-3ginfo-lite || true
cp -rf ../my_files/luci-app-modemband-main/luci-app-modemband feeds/luci/applications/luci-app-modemband || true
cp -rf ../my_files/luci-app-modemband-main/modemband feeds/packages/net/modemband || true
cp -rf ../my_files/luci-app-at-socat feeds/luci/applications/luci-app-at-socat || true
cp -rf ../my_files/luci-app-fakemesh feeds/luci/applications/luci-app-fakemesh || true

./scripts/feeds install -a

# 7. Copiar configuración predefinida (.config)
cp -f ../configs/rc1_ext_mm_config .config

# 8. Asegurar que la configuración es válida para el árbol actual
yes "" | make olddefconfig

# 9. Compilar con todos los núcleos disponibles
make -j$(nproc)

# 10. Al terminar, mostrar resumen de módulos MediaTek y kmods incluidos
echo ""
echo "==== Resumen de kernel y kmods incluidos ===="
grep -i KERNEL_PATCHVER .config || true
grep -i mtk .config || true
grep -i kmod- .config || true
echo "Build terminada. Puedes encontrar los binarios en openwrt/bin/targets/"
