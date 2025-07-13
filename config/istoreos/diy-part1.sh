#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (Before Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/istoreos/istoreos / Branch: master
#========================================================================================================================

# Add a feed source
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
sed -i '$a src-git third_party https://github.com/linkease/istore-packages.git;main' feeds.conf.default
sed -i '$a src-git diskman https://github.com/jjm2473/luci-app-diskman.git;dev' feeds.conf.default
sed -i '$a src-git oaf https://github.com/jjm2473/OpenAppFilter.git;dev6' feeds.conf.default
sed -i '$a src-git linkease_nas https://github.com/linkease/nas-packages.git;master' feeds.conf.default
sed -i '$a src-git linkease_nas_luci https://github.com/linkease/nas-packages-luci.git;main' feeds.conf.default
sed -i '$a src-git jjm2473_apps https://github.com/jjm2473/openwrt-apps.git;main' feeds.conf.default

# 添加 晶晨宝盒
rm -rf package/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
# 添加 lucky
rm -rf package/lucky
git clone https://github.com/sirpdboy/luci-app-lucky.git package/lucky
# 添加 homeproxy
rm -rf package/homeproxy
git clone https://github.com/immortalwrt/homeproxy package/homeproxy
 
 
# other
# rm -rf package/emortal/{autosamba,ipv6-helper}
