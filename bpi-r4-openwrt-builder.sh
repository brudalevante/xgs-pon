#!/bin/bash
set -e

# 1. Limpieza inicial
rm -rf openwrt mtk-openwrt-feeds

# 2. Clona OpenWrt y checkout commit concreto
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

# 3. Clona MTK feeds y checkout commit concreto
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..
echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 4. Aplica parches y configuraciones SOLO si existen
[ -e configs/dbg_defconfig_crypto ] && cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
[ -e my_files/w-rules ] && cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch
[ -e my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch ] && cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
[ -e my_files/99999_tx_power_check_by_dan_pawlik.patch ] && cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
[ -e my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch ] && cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config 2>/dev/null || true

# 5. Ejecuta el autobuild de MediaTek
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# 6. Actualiza e instala feeds oficiales
./scripts/feeds update -a
./scripts/feeds install -a

# 7. Clona SIEMPRE luci-app-fakemesh antes de defconfig para que esté disponible
mkdir -p package/extra
cd package/extra
rm -rf luci-app-fakemesh
git clone --depth=1 --single-branch --branch master https://github.com/x-wrt/com.x-wrt.git fakemesh-tmp
mv fakemesh-tmp/luci-app-fakemesh ./
rm -rf fakemesh-tmp
cd ../..

# 8. Copia tu .config personalizado (debe estar actualizado y contener luci-app-fakemesh)
cp ../configs/rc1_ext_mm_config .config

# 9. Refresca dependencias con defconfig
make defconfig

# 10. Compila
make -j$(nproc)
