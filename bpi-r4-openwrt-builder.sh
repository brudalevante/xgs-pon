#!/bin/bash
set -ex

# 1. Limpieza inicial
rm -rf openwrt mtk-openwrt-feeds

# 2. Clona OpenWrt y hace checkout del commit deseado
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

# 3. Clona el feed MTK y hace checkout del commit deseado
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 7ab016b920ee13c0c099ab8b57b1774c95609deb
cd ..
echo "7ab016b" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 4. Aplica defconfigs, reglas y parches WiFi
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# 5. Clona tu luci-app-fakemesh DESPUÉS del autobuild y feeds
echo "=== CLONANDO luci-app-fakemesh ==="
mkdir -p openwrt/package/extra
rm -rf openwrt/package/extra/luci-app-fakemesh
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-2.git openwrt/package/extra/luci-app-fakemesh

echo "=== CONTENIDO DE openwrt/package/extra/luci-app-fakemesh ==="
ls -l openwrt/package/extra/luci-app-fakemesh

echo
echo "==== PAUSA PARA HACER make menuconfig ===="
echo "Abre una terminal, ve a openwrt/, ejecuta 'make menuconfig', selecciona luci-app-fakemesh, guarda y sal, luego vuelve aquí y pulsa ENTER para continuar..."
read

# 6. Ejecuta el autobuild de MTK (esto puede tardar)
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

cd openwrt
# Basic config
\cp -r ../configs/rc1_ext_mm_config .config


###### Then you can add all required additional feeds/packages ######### 

# qmi modems extension for example
\cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
\cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
\cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications
\cp -r ../my_files/luci-app-fakemesh/ feeds/luci/applications/

# 7. Actualiza e instala feeds oficiales de OpenWrt
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
cd ..


# 8. Refresca dependencias tras menuconfig
make defconfig

# 9. Verifica que tu paquete está en el .config
grep fakemesh .config || (echo "NO se encontró luci-app-fakemesh en .config" && exit 1)

# 10. Compila
make -j$(nproc)
