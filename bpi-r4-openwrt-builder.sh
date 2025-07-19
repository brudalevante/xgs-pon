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
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

echo "==== 2. CAMBIA KERNEL A 6.6.98 ===="
TARGET_MK="openwrt/target/linux/mediatek/Makefile"
if [ -f "$TARGET_MK" ]; then
    echo "Cambiando LINUX_VERSION a 6.6.98 en $TARGET_MK"
    sed -i 's/^\(LINUX_VERSION:=\).*$/\1 6.6.98/' "$TARGET_MK"
else
    echo "No se encontró $TARGET_MK, revisa la ruta del target"
fi

KVER_MK="openwrt/include/kernel-version.mk"
HASH_LINE="LINUX_KERNEL_HASH-6.6.98 := 296a34c500abc22c434b967d471d75568891f06a98f11fc31c5e79b037f45de5"
if grep -q '^LINUX_KERNEL_HASH-6.6.98' "$KVER_MK"; then
    echo "Hash para kernel 6.6.98 ya existe en $KVER_MK"
else
    echo "Añadiendo hash de kernel 6.6.98 a $KVER_MK"
    echo "$HASH_LINE" >> "$KVER_MK"
fi

echo "==== 3. COPIA CONFIGURACIÓN PERSONALIZADA ETC (network, board.json, etc) ===="
cp -rv my_files/etc/* openwrt/files/etc/

echo "==== 4. CLONA MTK FEEDS ===="
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
cd mtk-openwrt-feeds
git checkout f737b2f5f33d611f9e96f91ffccd0531700b6282
cd ..
echo "f737b2f" > mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 5. COPIA CONFIG Y PARCHES NECESARIOS ===="
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

cp my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches/
cp my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

# Parche xgspon (si lo usas)
if [ -f my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch ]; then
    mkdir -p openwrt/package/xgspon/patches
    cp my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/package/xgspon/patches/
fi

rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 6. ELIMINAR WARNING ROJO DE PADDING ===="
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' openwrt/package/Makefile

echo "==== 7. CLONAR Y COPIAR PAQUETES MESH ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
if [ -d tmp_comxwrt/luci-app-fakemesh ];    then cp -rv tmp_comxwrt/luci-app-fakemesh    openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-autoreboot ];  then cp -rv tmp_comxwrt/luci-app-autoreboot  openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-cpu-status ];  then cp -rv tmp_comxwrt/luci-app-cpu-status  openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-temp-status ]; then cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-dawn ];        then cp -rv tmp_comxwrt/luci-app-dawn        openwrt/package/; fi

echo "==== 8. ENTRAR EN OPENWRT Y ACTUALIZAR FEEDS ===="
cd openwrt
cp -r ../configs/rc1_ext_mm_config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, se omite"
./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 9. PARCHEA CARPETAS PATCHES FALTANTES EN PAQUETES PROBLEMÁTICOS ===="
mkdir -p package/feeds/packages/runc/patches
mkdir -p package/feeds/packages/conmon/patches

echo "==== 10. ACTIVAR PAQUETES MESH EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status dawn; do
    grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config || echo "CONFIG_PACKAGE_luci-app-$pkg=y" >> .config
done

make defconfig

echo "==== 11. VERIFICAR PAQUETES EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status dawn; do
    if grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config; then
        echo "OK: $pkg activado en .config"
    else
        echo "ERROR: $pkg NO está en .config"
        exit 1
    fi
done

echo "==== 12. COMPILA ===="
make -j$(nproc)

echo "==== 13. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
