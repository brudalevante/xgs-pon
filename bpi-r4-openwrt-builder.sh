#!/bin/bash

# 1. Limpieza de builds previos
rm -rf openwrt

# 2. Clona OpenWrt
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

# 3. (No clonar mtk-openwrt-feeds, ya está en tu repo)
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

# 5. Ejecuta el autobuild MediaTek
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

# 6. Actualiza e instala feeds oficiales
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a

# 7. COPIA SOLO luci-app-fakemesh después de feeds/autobuild
mkdir -p package/extra
cd package/extra
git clone --depth=1 --single-branch --branch master https://github.com/x-wrt/com.x-wrt.git fakemesh-tmp
mv fakemesh-tmp/luci-app-fakemesh ./
rm -rf fakemesh-tmp
cd ../..

# 8. (Opcional) Copia tus otros paquetes personalizados si los tienes
# [ -d ../my_files/luci-app-3ginfo-lite-main/sms-tool/ ] && cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
# [ -d ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ ] && cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
# [ -d ../my_files/luci-app-modemband-main/luci-app-modemband/ ] && cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
# [ -d ../my_files/luci-app-modemband-main/modemband/ ] && cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
# [ -d ../my_files/luci-app-at-socat/ ] && cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

# 9. Usa tu .config base si existe, o crea uno mínimo
if [ -f ../configs/rc1_ext_mm_config ]; then
    cp ../configs/rc1_ext_mm_config .config
else
    touch .config
fi

# 10. Asegura la selección de luci-app-fakemesh en .config
grep -q '^CONFIG_PACKAGE_luci-app-fakemesh=y' .config || echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config

# 11. Compila (sin menú)
make defconfig
make -j$(nproc)
