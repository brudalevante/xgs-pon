#!/bin/bash
set -e

# === REQUISITOS DEL SISTEMA ===
# Ejecuta estos comandos antes de empezar (solo la primera vez)
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang-dev

echo "==== 0. LIMPIEZA PREVIA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 1. CLONA OPENWRT ===="
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt

echo "==== 1.1. COPIA CONFIGURACIÓN PERSONALIZADA ===="
# Crea la carpeta files si no existe
mkdir -p openwrt/files

# Copia TODO el contenido de my_files/etc en su sitio (por ejemplo, network y board.json)
if [ -d my_files/etc ]; then
    echo "Copiando archivos de configuración fija (etc/*) a openwrt/files/etc/"
    mkdir -p openwrt/files/etc
    cp -rv my_files/etc/* openwrt/files/etc/
else
    echo "No se encontró la carpeta my_files/etc/, omitiendo copia de archivos fijos"
fi

# Copia el resto de archivos personalizados si existen (fuera de etc)
find my_files -mindepth 1 -maxdepth 1 ! -name 'etc' -exec cp -rv {} openwrt/files/ \;

echo "==== 2. CLONA MTK FEEDS ===="
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
cd mtk-openwrt-feeds
# Puedes fijar la revisión si quieres estabilidad, o comentar la siguiente línea para siempre usar HEAD
git checkout f737b2f5f33d611f9e96f91ffccd0531700b6282
cd ..
echo "f737b2f" > mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 3. COPIA CONFIG Y PARCHES ===="
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt

if [ -d tmp_comxwrt/luci-app-fakemesh ]; then cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-autoreboot ]; then cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-cpu-status ]; then cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-temp-status ]; then cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-dawn ]; then cp -rv tmp_comxwrt/luci-app-dawn openwrt/package/; echo "Copiada carpeta completa luci-app-dawn"; else echo "No se encontró luci-app-dawn, omitiendo copia."; fi

echo "==== 5. ENTRA EN OPENWRT Y ACTUALIZA FEEDS ===="
cd openwrt
cp -r ../configs/rc1_ext_mm_config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, omitiendo"
./scripts/feeds update -a
./scripts/feeds install -a

# ==== ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ====
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== 6. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn=y" >> .config
make defconfig

echo "==== 7. VERIFICA PAQUETES EN .CONFIG ===="
grep fakemesh .config      || echo "NO aparece fakemesh en .config"
grep autoreboot .config    || echo "NO aparece autoreboot en .config"
grep cpu-status .config    || echo "NO aparece cpu-status en .config"
grep temp-status .config   || echo "NO aparece temp-status en .config"
grep dawn .config          || echo "NO aparece dawn en .config"

echo "==== 8. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

echo "==== 9. COMPILA ===="
make -j$(nproc)

echo "==== 10. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
