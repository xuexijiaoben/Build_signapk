#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
CLS_DIR="${DIST_DIR}/classes"
LIB_DIR="${SCRIPT_DIR}/libs"
# 完整AOSP目录下apksig固定相对路径
APKSIG_SRC="${SCRIPT_DIR}/../../tools/apksig/src"
SRC_SIGNAPK="${SCRIPT_DIR}/src"

echo "=== Start build signapk.jar ==="
echo "SignApk Source: $SRC_SIGNAPK"
echo "Apksig Source: $APKSIG_SRC"
rm -rf "$DIST_DIR"
mkdir -p "$CLS_DIR"

# 校验两套源码（彻底解决Missing apksig src）
[[ ! -d "$SRC_SIGNAPK" ]] && echo "[ERROR] Missing signapk src" && exit 1
[[ ! -d "$APKSIG_SRC" ]] && echo "[ERROR] Missing apksig src" && exit 1
[[ ! -d "$LIB_DIR" ]] && echo "[ERROR] Missing libs folder" && exit 1

# 获取BC classpath
BC_PROV=$(ls "$LIB_DIR"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB_DIR"/bcpkix-*.jar 2>/dev/null | head -1)
[[ -z "$BC_PROV" || -z "$BC_PKIX" ]] && echo "[ERROR] BC jars missing" && exit 1
CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename $BC_PROV)"
echo "BC PKIX: $(basename $BC_PKIX)"

# 收集 signapk + apksig 全部java文件
find "$SRC_SIGNAPK" "$APKSIG_SRC" -type f -name "*.java" > source.list

# UTF8编译
javac -encoding UTF-8 -cp "$CP" -d "$CLS_DIR" @source.list
rm -f source.list

# Jar清单
cat > "${DIST_DIR}/MANIFEST.MF" <<'MANIFEST'
Manifest-Version: 1.0
Created-By CI Build
Main-Class: com.android.signapk.SignApk
MANIFEST

# 打包成品
jar cfm "${DIST_DIR}/signapk.jar" "${DIST_DIR}/MANIFEST.MF" -C "$CLS_DIR" .
echo "Build success, output: ${DIST_DIR}/signapk.jar"
ls -lh "${DIST_DIR}/signapk.jar"
