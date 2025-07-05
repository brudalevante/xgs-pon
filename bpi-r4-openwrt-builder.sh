#!/bin/bash

#*****************************************************************************
#
# Build environment - Ubuntu 64-bit Server 24.04.2
#
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang-dev
#
#*****************************************************************************

# 0. Limpieza de cualquier build anterior
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# 1. Clona OpenWrt y el feed de MediaTek
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..

echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# 2. Aplica configuraciones y parches de MediaTek
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

# Elimina parches innecesarios
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 

# Parches adicionales
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

# Desactiva perf en los defconfig de MediaTek
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# 3. Ejecuta el autobuild de MediaTek para preparar estructura y parches
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

# 4. Actualiza e instala los feeds oficiales (NO xwrt)
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a

# 5. COPIA SOLO luci-app-fakemesh DE x-wrt (sin añadir el feed entero)
mkdir -p package/extra
cd package/extra
git clone --depth=1 --single-branch --branch main https://github.com/x-wrt/com.x-wrt.git fakemesh-tmp
mv fakemesh-tmp/luci-app-fakemesh ./
rm -rf fakemesh-tmp
cd ../..

# 6. Copia tu .config base si tienes uno, o crea uno nuevo mínimo
if [ -f ../configs/rc1_ext_mm_config ]; then
    cp ../configs/rc1_ext_mm_config .config
else
    touch .config
fi

# 7. Añade a .config la selección automática de luci-app-fakemesh y tus otros paquetes
grep -q '^CONFIG_PACKAGE_luci-app-fakemesh=y' .config || echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
grep -q '^CONFIG_PACKAGE_luci-app-3ginfo-lite=y' .config || echo "CONFIG_PACKAGE_luci-app-3ginfo-lite=y" >> .config
grep -q '^CONFIG_PACKAGE_luci-app-modemband=y' .config || echo "CONFIG_PACKAGE_luci-app-modemband=y" >> .config
grep -q '^CONFIG_PACKAGE_sms-tool=y' .config || echo "CONFIG_PACKAGE_sms-tool=y" >> .config
grep -q '^CONFIG_PACKAGE_luci-app-at-socat=y' .config || echo "CONFIG_PACKAGE_luci-app-at-socat=y" >> .config

# 8. Copia otros paquetes personalizados  
cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

# 9. Preconfigura dependencias y opciones (opcional)
make defconfig

# 10. Compilación completa (sin menú interactivo)
make -j$(nproc)
