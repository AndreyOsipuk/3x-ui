#!/bin/sh
set -e
case $1 in
    amd64)
        ARCH="64"
        FNAME="amd64"
        ;;
    i386)
        ARCH="32"
        FNAME="i386"
        ;;
    armv8 | arm64 | aarch64)
        ARCH="arm64-v8a"
        FNAME="arm64"
        ;;
    armv7 | arm | arm32)
        ARCH="arm32-v7a"
        FNAME="arm32"
        ;;
    armv6)
        ARCH="arm32-v6"
        FNAME="armv6"
        ;;
    *)
        ARCH="64"
        FNAME="amd64"
        ;;
esac
MTG_MULTI_VER=$(curl -sfL "https://api.github.com/repos/mhsanaei/mtg-multi/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
if [ -z "$MTG_MULTI_VER" ]; then
    echo "DockerInit: could not resolve the latest mtg-multi release tag" >&2
    exit 1
fi
mkdir -p build/bin
cd build/bin
curl -sfLRO "https://github.com/XTLS/Xray-core/releases/download/v26.10.10/Xray-linux-${ARCH}.zip"
unzip "Xray-linux-${ARCH}.zip"
rm -f "Xray-linux-${ARCH}.zip" geoip.dat geosite.dat
mv xray "xray-linux-${FNAME}"
# mtg-multi (MTProto sidecar) ships prebuilt release binaries for every target
# we package, so download and unpack the matching one instead of compiling.
case $FNAME in
    i386) MTGARCH="386" ;;
    arm32) MTGARCH="armv7" ;;
    *) MTGARCH="$FNAME" ;;
esac
MTG_PKG="mtg-multi-${MTG_MULTI_VER#v}-linux-${MTGARCH}"
curl -sfLRO "https://github.com/mhsanaei/mtg-multi/releases/download/${MTG_MULTI_VER}/${MTG_PKG}.tar.gz"
tar -xzf "${MTG_PKG}.tar.gz"
mv "${MTG_PKG}/mtg-multi" "mtg-linux-${FNAME}"
rm -rf "${MTG_PKG}" "${MTG_PKG}.tar.gz"
chmod +x "mtg-linux-${FNAME}"
# telemt (the second MTProto backend) publishes static musl builds for amd64
# and arm64 only; elsewhere the panel refuses telemt inbounds on save.
# Pinned with checksums: it is a third-party binary, and the panel relies on its
# config keys, /v1/config/state and metric names.
TELEMT_VER="3.5.17"
case $FNAME in
    amd64) TELEMT_ARCH="x86_64"; TELEMT_SHA256="f1591635849e0aad31f147692b21726da2f49499aae3ece79f8760c92925133a" ;;
    arm64) TELEMT_ARCH="aarch64"; TELEMT_SHA256="c80b0159b41cf410b2a87cf62676d67a16a537bd7207602b60dd9ce56e14d1f6" ;;
    *) TELEMT_ARCH="" ;;
esac
if [ -n "$TELEMT_ARCH" ]; then
    curl -sfLR -o telemt.tar.gz "https://github.com/telemt/telemt/releases/download/${TELEMT_VER}/telemt-${TELEMT_ARCH}-linux-musl.tar.gz"
    echo "${TELEMT_SHA256}  telemt.tar.gz" | sha256sum -c -
    tar -xzf telemt.tar.gz telemt
    mv telemt "telemt-linux-${FNAME}"
    rm -f telemt.tar.gz
    chmod +x "telemt-linux-${FNAME}"
fi
curl -sfLRO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
curl -sfLRO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
curl -sfLRo geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
curl -sfLRo geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
curl -sfLRo geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
curl -sfLRo geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
cd ../../
