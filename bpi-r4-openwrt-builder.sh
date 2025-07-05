#!/bin/bash

set -e

# 1. Preparación
rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..
echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig || true
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules || true
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches || true
cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/ || true
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/ || true

sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config || true

cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a

mkdir -p feeds/packages/utils
mkdir -p feeds/packages/net
mkdir -p feeds/luci/applications

cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool feeds/packages/utils/sms-tool || true
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite feeds/luci/applications/luci-app-3ginfo-lite || true
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband feeds/luci/applications/luci-app-modemband || true
cp -r ../my_files/luci-app-modemband-main/modemband feeds/packages/net/modemband || true
cp -r ../my_files/luci-app-at-socat feeds/luci/applications/luci-app-at-socat || true
cp -r ../my_files/luci-app-fakemesh feeds/luci/applications/luci-app-fakemesh || true

./scripts/feeds install -a

# COPIAR .config preparado (¡aquí defines lo que quieres construir!)
cp -f ../configs/rc1_ext_mm_config .config

# Opcional: actualiza la configuración automáticamente para que sea válida
yes "" | make olddefconfig

# Compilar directamente sin intervención
make -j$(nproc)
