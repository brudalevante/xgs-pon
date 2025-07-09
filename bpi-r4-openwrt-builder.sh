#!/bin/bash
set -e

#----------------------------------------
# Build environment - Ubuntu 24.04.2 LTS
#----------------------------------------
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang-dev

#----------------------------------------
# Limpieza previa
rm -rf openwrt
rm -rf mtk-openwrt-feeds

#----------------------------------------
# Clona OpenWrt y MTK feeds
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout e876f7bc62592ca8bc3125e55936cd0f761f4d5a
cd ..

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 7ab016b920ee13c0c099ab8b57b1774c95609deb
cd ..
echo "7ab016b" > mtk-openwrt-feeds/autobuild/unified/feed_revision

#----------------------------------------
# Configuración y parches
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

#----------------------------------------
# Ejecuta autobuild de MTK
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make
cd ..

#----------------------------------------
# Fase post-autobuild: feeds y paquetes personalizados
cd openwrt

# 1. Copia feeds.conf.default personalizado si existe
if [ -f ../my_files/w-feeds.conf.default ]; then
    echo "Usando feeds.conf.default personalizado."
    cp ../my_files/w-feeds.conf.default feeds.conf.default
fi

# 2. Copia tus paquetes personalizados antes de los feeds
cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool || true
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications || true
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications || true
cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband || true
cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications || true
cp -r ../my_files/luci-app-fakemesh feeds/luci/applications/ || true

echo ""
echo "====================="
echo "Comprobando existencia del paquete luci-app-fakemesh en feeds..."
if [ -d feeds/luci/applications/luci-app-fakemesh ] || [ -d feeds/*/luci-app-fakemesh ]; then
    echo "OK: luci-app-fakemesh está presente en los feeds."
else
    echo "ERROR: luci-app-fakemesh NO está en los feeds. Revisa tu copia o feed personalizado."
    exit 1
fi

# 3. Actualiza e instala feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. Restaura configuración previa si existe
if [ -f .config.old ]; then
    echo "Restaurando configuración previa (.config.old)..."
    cp .config.old .config
else
    echo "No existe .config.old, se mantiene la configuración actual"
fi

# 5. Prepara la configuración para la build
make defconfig

# 6. Verifica que el paquete sigue activado en .config
if grep -q "CONFIG_PACKAGE_luci-app-fakemesh=y" .config; then
    echo "OK: luci-app-fakemesh está activado en .config"
else
    echo "ERROR: luci-app-fakemesh NO está activado en .config"
    echo "Posibles causas:"
    echo " - El paquete no está correctamente instalado en feeds."
    echo " - El nombre del paquete en .config es incorrecto."
    echo " - El paquete tiene errores en su Makefile y no se reconoce."
    exit 2
fi

# 7. Compila
make -j$(nproc) V=s

echo "--------------------------------------"
echo "Compilación finalizada correctamente."
