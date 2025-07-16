#!/bin/bash
set -e

echo "==== 0. LIMPIEZA PREVIA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_fakemesh

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

echo "==== 3. COPIAR CONFIG Y PARCHES ===="
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

[ -f mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch ] && \
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. CLONAR Y COPIAR PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_fakemesh
cp -rv tmp_fakemesh/luci-app-fakemesh openwrt/package/
cp -rv tmp_fakemesh/luci-app-autoreboot openwrt/package/
cp -rv tmp_fakemesh/luci-app-cpu-status openwrt/package/
cp -rv tmp_fakemesh/luci-app-temp-status openwrt/package/

echo "==== 5. ENTRAR EN OPENWRT Y ACTUALIZAR FEEDS ===="
cd openwrt
cp -r ../configs/rc1_ext_mm_config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, se omite"

./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 6. ACTIVAR PAQUETES PERSONALIZADOS EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status; do
    grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config || echo "CONFIG_PACKAGE_luci-app-$pkg=y" >> .config
done

make defconfig

echo "==== 7. VERIFICAR PAQUETES EN .CONFIG ===="
for pkg in fakemesh autoreboot cpu-status temp-status; do
    if grep "CONFIG_PACKAGE_luci-app-$pkg=y" .config; then
        echo "OK: $pkg activado en .config"
    else
        echo "ERROR: $pkg NO está en .config"
        exit 1
    fi
done

echo "==== 8. DESCARGAR FUENTES ===="
make download -j$(nproc)

echo "==== 9. EJECUTAR AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

echo "==== 10. COMPILAR OPENWRT ===="
if ! make -j$(nproc); then
    echo -e "\033[0;31m========== ERROR EN LA COMPILACIÓN ==========\033[0m"
    echo "Revisa el log de errores anterior ↑ para ver el problema exacto."
    exit 1
fi

echo "==== 11. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_fakemesh

echo -e "\033[0;32m==== ¡Script finalizado correctamente! ====\033[0m"
