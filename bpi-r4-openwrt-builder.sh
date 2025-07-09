#!/bin/bash
set -e

#*****************************************************************************
# Build environment - Ubuntu 64-bit Server 24.04.2
#
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang-dev
#*****************************************************************************

# Limpieza previa
rm -rf openwrt
rm -rf mtk-openwrt-feeds

# Clona OpenWrt y el feed de Mediatek
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout e876f7bc62592ca8bc3125e55936cd0f761f4d5a
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 7ab016b920ee13c0c099ab8b57b1774c95609deb
cd ..
echo "7ab016b" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# Configuración y parches
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

# Parches adicionales
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

# Desactiva perf en varias configuraciones
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# Ejecuta autobuild de MTK
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

# --- FASE POST-AUTOBUILD: Copia de paquetes personalizados y feeds ---

cd openwrt

# Copia todos tus paquetes personalizados (asegúrate de que existan antes de instalar feeds)
cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications
cp -r ../my_files/luci-app-fakemesh feeds/luci/applications/

# Restaurar automáticamente .config.old si existe (¡antes de tocar feeds o defconfig!)
if [ -f .config.old ]; then
    echo "Restaurando configuración previa (.config.old)..."
    cp .config.old .config
else
    echo "No existe .config.old, se mantiene la configuración actual"
fi

# Actualiza feeds (debe ir después de copiar tus paquetes personalizados)
./scripts/feeds update -a
./scripts/feeds install -a

# Prepara la configuración para la build
make defconfig

# (Opcional) Abre menú de configuración
# make menuconfig

# Comprueba que tu paquete está activado
grep "CONFIG_PACKAGE_luci-app-fakemesh=y" .config || echo "¡ADVERTENCIA: luci-app-fakemesh NO está activado en .config!"

# Compila con todos los núcleos disponibles
make -j$(nproc) V=s

echo "--------------------------------------"
echo "Compilación finalizada correctamente."
