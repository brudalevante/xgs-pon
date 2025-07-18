#!/bin/bash
set -e

echo "==== 0. LIMPIEZA PREVIA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 1. CLONAR OPENWRT ===="
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

echo "==== 2. CLONAR FEEDS MTK ===="
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
cd mtk-openwrt-feeds
git checkout f737b2f5f33d611f9e96f91ffccd0531700b6282
cd ..
echo "f737b2f" > mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 3. COPIAR CONFIG Y REGLAS ===="
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

echo "==== 4. COPIAR PARCHES WIFI Y THERMAL ===="
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches/
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

[ -f mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch ] && \
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 5. COPIAR ETC (LUZ/LEDS Y OTRAS CONFIGS) ===="
if [ -d my_files/etc ]; then
    cp -rv my_files/etc openwrt/package/
fi

echo "==== 6. COPIAR XGSPON (SI EXISTE) Y SU PARCHE ===="
if [ -d my_files/xgspon ]; then
    cp -rv my_files/xgspon openwrt/package/
fi
if [ -f my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch ]; then
    mkdir -p openwrt/package/xgspon/patches
    cp my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/package/xgspon/patches/
fi

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

echo "==== 9. ACTIVAR PAQUETES MESH EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status dawn; do
    grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config || echo "CONFIG_PACKAGE_luci-app-$pkg=y" >> .config
done

make defconfig

echo "==== 10. VERIFICAR PAQUETES EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status dawn; do
    if grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config; then
        echo "OK: $pkg activado en .config"
    else
        echo "ERROR: $pkg NO está en .config"
        exit 1
    fi
done

echo "==== 11. DESCARGAR FUENTES ===="
make download -j$(nproc)

echo "==== 12. EJECUTAR AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== QUITAR WARNING EN ROJO DEL MAKEFILE ====
if grep -q "ERROR_MESSAGE,WARNING: Applying padding" package/Makefile; then
    sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile
fi

echo "==== 13. COMPILAR OPENWRT ===="
if ! make -j$(nproc); then
    echo -e "\033[0;31m"
    echo "==========================================="
    echo "====   ERROR EN LA COMPILACIÓN (MAKE)  ===="
    echo "==========================================="
    echo -e "\033[0m"
    echo "Revisa el log de errores anterior ↑ para ver el problema exacto."
    exit 1
fi

echo "==== 14. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo -e "\033[0;32m==== ¡Script finalizado correctamente! ====\033[0m"
