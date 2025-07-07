#!/bin/bash
set -e

# 1. Limpieza inicial
rm -rf openwrt

# 2. Clona OpenWrt y checkout commit concreto
git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git checkout 2a348bdbef52adb99280f01ac285d4415e91f4d6
cd ..

# 3. (Opcional) Actualiza e instala feeds oficiales
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
cd ..

# 4. Clona luci-app-fakemesh
echo "=== CLONANDO luci-app-fakemesh ==="
mkdir -p openwrt/package/extra
rm -rf openwrt/package/extra/luci-app-fakemesh
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh.git openwrt/package/extra/luci-app-fakemesh

echo "=== CONTENIDO DE openwrt/package/extra ==="
ls -l openwrt/package/extra

echo "=== CONTENIDO DE openwrt/package/extra/luci-app-fakemesh ==="
ls -l openwrt/package/extra/luci-app-fakemesh

echo "=== Mostrando Makefile de luci-app-fakemesh ==="
cat openwrt/package/extra/luci-app-fakemesh/Makefile

echo
echo "==== PAUSA PARA COMPROBAR ===="
echo "Verifica en otra terminal que la carpeta y el contenido existen:"
echo "    - openwrt/package/extra/luci-app-fakemesh"
echo "    - Makefile y ficheros dentro"
echo "Pulsa ENTER para continuar con la build..."
read

cd openwrt

# 5. make menuconfig para depuración visual
make menuconfig

# (Opcional: puedes buscar tu paquete en el menú y guardarlo)

echo "Fin de la prueba rápida."
