#!/bin/bash

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

rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt
git checkout 989b12999c5b7c35ec310d26ac6f01eb9567be6e
cd -

git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout cc0de566eb90309e997d66ed1095579eb3b30751
cd -

echo cc0de56"" > mtk-openwrt-feeds/autobuild/unified/feed_revision

\cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

### remove mtk strongswan uci support patch
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 

### adds a frequency match check to ensure the noise value corresponds to the interface's actual frequency for multiple radios under a single wiphy
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches

### tx_power patch - by dan pawlik
\cp -r my_files/99999_tx_power_check_by_dan_pawlik.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

### required & thermal zone 
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt

bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

exit 0

########### After successful end of build #############

cd openwrt
# Basic config
\cp -r ../configs/rc1_ext_mm_config .config

###### Then you can add all required additional feeds/packages ######### 

# qmi modems extension for example
\cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
\cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
\cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

# ===> LÍNEA CLAVE: Instala luci-app-fakemesh desde x-wrt feed
./scripts/feeds update -a
./scripts/feeds install -a -f
./scripts/feeds install luci-app-fakemesh

# ===> (OPCIONAL) Si quieres sobreescribir con tu versión personalizada:
# \cp -r ../my_files/luci-app-fakemesh/ feeds/xwrt/luci-app-fakemesh

make menuconfig
make -j$(nproc)
