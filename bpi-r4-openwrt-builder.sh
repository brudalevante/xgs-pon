#!/bin/bash

set -e

echo "==== 1. LIMPIEZA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 2. CLONA TUS REPOS PERSONALES ===="
git clone --branch openwrt-24.10 https://github.com/brudalevante/openwrt.git openwrt || true
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..
git clone https://github.com/brudalevante/mtk-openwrt-feeds.git || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd ..

echo "==== ELIMINA TODOS LOS PARCHES CONFLICTIVOS DE cryptsetup ===="
find mtk-openwrt-feeds -type f -name 'cryptsetup-*.patch' -delete

echo "==== 3. PREPARA FEEDS Y CONFIGURACIONES BASE ===="
echo "cc0de56" > mtk-openwrt-feeds/autobuild/unified/feed_revision
cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig

# Desactiva perf en los defconfig base
sed -i '/^CONFIG_PACKAGE_perf=y/d' mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
sed -i '/^CONFIG_PACKAGE_perf=y/d' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i '/^CONFIG_PACKAGE_perf=y/d' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA PARCHES ===="
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/
# Si quieres el de Dan Pawlik, descomenta:
# cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

echo "==== 4b. COPIA TU rpcd.config PERSONALIZADO ===="
cp -v my_files/rpcd.config/rpcd.config openwrt/package/system/rpcd/files/rpcd.config

echo "==== 5. COPIA PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/

echo "==== 6. ENTRA EN OPENWRT Y USA feeds.conf.default OFICIAL ===="
cd openwrt

echo "==== LIMPIANDO feeds/ previos ===="
rm -rf feeds/

echo "==== USANDO feeds.conf.default DEL REPO (OFICIAL) ===="
cat feeds.conf.default

cp -r ../configs/rc1_ext_mm_config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, omitiendo"

# Limpia perf en .config ANTES de feeds/install
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 7. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-usteer2=y" >> .config

# Limpia perf OTRA VEZ antes de make defconfig
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

make defconfig

# Limpia perf DESPUÉS de make defconfig (por si acaso)
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== VERIFICACIÓN PERF FINAL ===="
grep perf .config || echo "perf NO está en .config"

echo "==== 8. VERIFICA PAQUETES EN .CONFIG ===="
grep fakemesh .config      || echo "NO aparece fakemesh en .config"
grep autoreboot .config    || echo "NO aparece autoreboot en .config"
grep cpu-status .config    || echo "NO aparece cpu-status en .config"
grep temp-status .config   || echo "NO aparece temp-status en .config"
grep dawn2 .config         || echo "NO aparece dawn en .config"
grep usteer2 .config       || echo "NO aparece usteer en .config"

echo "==== 9. AÑADE SEGURIDAD: DESACTIVA PERF EN EL .CONFIG FINAL (por si acaso) ===="
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 10. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ====
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== ELIMINA WARNING SHA-512 DE scripts/ipkg-make-index.sh ===="
if grep -q "WARNING: Applying padding" scripts/ipkg-make-index.sh; then
    sed -i '/WARNING: Applying padding/d' scripts/ipkg-make-index.sh
fi

echo "==== 11. COMPILA ===="
make -j$(nproc)

echo "==== 12. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
