#!/bin/bash

# 1. Limpieza previa
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# 2. Clona OpenWrt y mtk-openwrt-feeds
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd mtk-openwrt-feeds
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..

echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 3. Parcheos y configuración MediaTek (ajusta aquí tus parches)
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# 4. Ejecuta el autobuild MediaTek (esto reestructura openwrt)
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

# 5. Actualiza e instala feeds oficiales
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
cd ..

# 6. COPIA SOLO luci-app-fakemesh (y cualquier otro paquete suelto)
mkdir -p openwrt/package/extra
cd openwrt/package/extra
git clone --depth=1 --single-branch --branch master https://github.com/x-wrt/com.x-wrt.git fakemesh-tmp
mv fakemesh-tmp/luci-app-fakemesh ./
rm -rf fakemesh-tmp
cd ../../..

# 7. Copia tus otros paquetes personalizados si tienes
cp -r my_files/luci-app-3ginfo-lite-main/sms-tool/ openwrt/feeds/packages/utils/sms-tool
cp -r my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ openwrt/feeds/luci/applications
cp -r my_files/luci-app-modemband-main/luci-app-modemband/ openwrt/feeds/luci/applications
cp -r my_files/luci-app-modemband-main/modemband/ openwrt/feeds/packages/net/modemband
cp -r my_files/luci-app-at-socat/ openwrt/feeds/luci/applications

# 8. Pon tu .config base, o crea uno si no tienes
if [ -f configs/rc1_ext_mm_config ]; then
    cp configs/rc1_ext_mm_config openwrt/.config
else
    touch openwrt/.config
fi

# 9. Fuerza la selección de luci-app-fakemesh en .config
grep -q '^CONFIG_PACKAGE_luci-app-fakemesh=y' openwrt/.config || echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> openwrt/.config

# (Opcional) Fuerza otros paquetes si quieres:
grep -q '^CONFIG_PACKAGE_luci-app-3ginfo-lite=y' openwrt/.config || echo "CONFIG_PACKAGE_luci-app-3ginfo-lite=y" >> openwrt/.config
grep -q '^CONFIG_PACKAGE_luci-app-modemband=y' openwrt/.config || echo "CONFIG_PACKAGE_luci-app-modemband=y" >> openwrt/.config
grep -q '^CONFIG_PACKAGE_sms-tool=y' openwrt/.config || echo "CONFIG_PACKAGE_sms-tool=y" >> openwrt/.config
grep -q '^CONFIG_PACKAGE_luci-app-at-socat=y' openwrt/.config || echo "CONFIG_PACKAGE_luci-app-at-socat=y" >> openwrt/.config

# 10. Compila (sin menú)
cd openwrt
make defconfig
make -j$(nproc)
