#!/bin/bash

# 1. Limpieza de builds anteriores
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# 2. Clona OpenWrt y mtk-openwrt-feeds
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..

echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 3. COPIA SOLO luci-app-fakemesh ANTES DE NADA
mkdir -p openwrt/package/extra
cd openwrt/package/extra
git clone --depth=1 --single-branch --branch master https://github.com/x-wrt/com.x-wrt.git fakemesh-tmp
mv fakemesh-tmp/luci-app-fakemesh ./
rm -rf fakemesh-tmp
cd ../../..

# 4. Parches y configuración MediaTek (igual que siempre)
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# 5. Ejecuta el autobuild para preparar estructura y parches
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

# 6. AHORA actualiza e instala feeds 
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a

# 7. Copia tu .config predefinido si lo tienes
cp -r ../configs/rc1_ext_mm_config .config

# 8. Añade a .config la selección automática de luci-app-fakemesh
grep -q '^CONFIG_PACKAGE_luci-app-fakemesh=y' .config || echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config

# 9. Compila sin menú
make defconfig
make -j$(nproc)
