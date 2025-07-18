#!/bin/bash

# ==== 0. PARÁMETROS Y FUNCIÓN PARA REINTENTOS ====
max_retries=5
delay=30

clone_with_retry() {
    local repo="$1"
    local dir="$2"
    local branch="$3"
    local count=0
    while true; do
        if [ -z "$branch" ]; then
            echo "Intentando clonar $repo en $dir (intento $((count+1))/$max_retries)..."
            git clone --depth=1 --single-branch "$repo" "$dir" && break
        else
            echo "Intentando clonar $repo rama $branch en $dir (intento $((count+1))/$max_retries)..."
            git clone --depth=1 --single-branch --branch "$branch" "$repo" "$dir" && break
        fi
        count=$((count+1))
        if [ "$count" -ge "$max_retries" ]; then
            echo "Fallo crítico: no se pudo clonar $repo tras $max_retries intentos."
            exit 1
        fi
        echo "Error al clonar $repo, reintentando en $delay segundos..."
        sleep $delay
    done
}

# ==== 1. LIMPIEZA PREVIA ====
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

# ==== 2. CLONA OPENWRT ====
echo "==== 1. CLONA OPENWRT ===="
clone_with_retry "https://git.openwrt.org/openwrt/openwrt.git" "openwrt" "openwrt-24.10"
cd openwrt
# Si da error aquí, el commit ya no existe. Comenta la siguiente línea si falla.
git checkout e876f7bc62592ca8bc3125e55936cd0f761f4d5a
cd -

# ==== 3. CLONA FEEDS MTK ====
echo "==== 2. CLONA FEEDS MTK ===="
clone_with_retry "https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds" "mtk-openwrt-feeds" "master"
cd mtk-openwrt-feeds
git checkout 7ab016b920ee13c0c099ab8b57b1774c95609deb
cd -
echo "7ab016b" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# ==== 4. COPIA CONFIG Y PARCHES ====
echo "==== 3. COPIA CONFIG Y PARCHES ===="
\cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
if [ -d my_files/etc ]; then
    echo "Copiando archivos de configuración fija (etc/*) a openwrt/files/etc/"
    mkdir -p openwrt/files/etc
    cp -rv my_files/etc/* openwrt/files/etc/
fi
cp -v my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch mtk-openwrt-feeds/autobuild/unified/filogic/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 

# Quita el warning "en rojo" de perf en todos los defconfig conocidos
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# ==== 5. CLONA Y COPIA PAQUETES PERSONALIZADOS ====
echo "==== 4. CLONA PAQUETES PERSONALIZADOS ===="
clone_with_retry "https://github.com/brudalevante/fakemesh-6g.git" "tmp_comxwrt" "main"
if [ -d tmp_comxwrt/luci-app-fakemesh ];    then cp -rv tmp_comxwrt/luci-app-fakemesh    openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-autoreboot ];  then cp -rv tmp_comxwrt/luci-app-autoreboot  openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-cpu-status ];  then cp -rv tmp_comxwrt/luci-app-cpu-status  openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-temp-status ]; then cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/; fi
if [ -d tmp_comxwrt/luci-app-dawn ];        then cp -rv tmp_comxwrt/luci-app-dawn        openwrt/package/; echo "Copiada carpeta completa luci-app-dawn"; else echo "No se encontró luci-app-dawn, omitiendo copia."; fi

# ==== 6. ENTRA EN OPENWRT Y ACTUALIZA FEEDS ====
echo "==== 5. ENTRA EN OPENWRT Y ACTUALIZA FEEDS ===="
cd openwrt
cp -r ../configs/rc1_ext_mm_config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, omitiendo"
./scripts/feeds update -a
./scripts/feeds install -a

# Elimina el warning en rojo del Makefile (opcional)
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

# ==== 7. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ====
echo "==== 6. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y"    >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y"  >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y"  >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn=y"        >> .config
make defconfig

# ==== 8. VERIFICA PAQUETES EN .CONFIG ====
echo "==== 7. VERIFICA PAQUETES EN .CONFIG ===="
grep fakemesh    .config || echo "NO aparece fakemesh en .config"
grep autoreboot  .config || echo "NO aparece autoreboot en .config"
grep cpu-status  .config || echo "NO aparece cpu-status en .config"
grep temp-status .config || echo "NO aparece temp-status en .config"
grep dawn        .config || echo "NO aparece dawn en .config"

# ==== 9. EJECUTA AUTOBUILD ====
echo "==== 8. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== 10. COMPILA ====
echo "==== 9. COMPILA ===="
make -j$(nproc)

# ==== 11. LIMPIEZA FINAL ====
echo "==== 10. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
