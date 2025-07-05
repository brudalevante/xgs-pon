#!/bin/bash

set -e

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

# Limpieza previa
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# Clona OpenWrt
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd -

# Clona los feeds de MediaTek
git clone  https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd -
echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# Copia archivos de configuración y reglas
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

# Elimina patch innecesario de strongswan
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 

# Aplica parches personalizados
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

# Limpia configuración de perf en defconfigs
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt

# Copia tu configuración base (opcional, puedes comentar si prefieres configurar a mano)
cp -r ../configs/rc1_ext_mm_config .config

# Copia TODOS los paquetes personalizados ANTES de actualizar los feeds
cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications
cp -r ../my_files/luci-app-fakemesh/ feeds/luci/applications

# Actualiza e instala feeds, así los paquetes personalizados se reconocen
./scripts/feeds update -a
./scripts/feeds install -a

# OPCIONAL: Si tu .config ya tiene todo activado, puedes compilar directamente.
# Si quieres añadir o quitar paquetes, ejecuta:
make menuconfig

# Compila (ajusta el número de núcleos si no quieres usar todos)
make -j$(nproc)

# FIN DEL SCRIPT
