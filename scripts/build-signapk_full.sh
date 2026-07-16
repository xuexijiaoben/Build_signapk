#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="${SCRIPT_DIR}/dist"
CLS="${DIST}/classes"
LIB="${SCRIPT_DIR}/libs"
SRC_SIGN="${SCRIPT_DIR}/src"
# apksig同级目录固定相对路径
SRC_APK="${SCRIPT_DIR}/../../apksig/src"

echo "=== Start build signapk.jar ==="
rm -rf "$DIST"
mkdir -p "$CLS"

# 校验双源码目录
[[ ! -d "$SRC_SIGN" ]] && echo "ERROR: Missing signapk src" && exit 1
[[ ! -d "$SRC_APK" ]] && echo "ERROR: Missing apksig src" && exit 1
[[ ! -d "$LIB" ]] && echo "ERROR: Missing BC libs" && exit 1

# 获取BC classpath
BC_PROV=$(ls "$LIB"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB"/bcpkix-*.jar 2>/dev/null)
[[ -z "$BC_PROV" || -z "$BC_PKIX" ]] && echo "Missing BC jars" && exit 1
CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename $BC_PROV)"
echo "BC PKIX: $(basename $BC_PKIX)"

# 收集所有java文件
find "$SRC_SIGN" "$SRC_APK" -name "*.java" > sources.txt
# 编译
javac -encoding UTF-8 -cp "$CP" -d "$CLS" @sources.txt
rm sources.txt

# 打包清单
cat > "$DIST/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
Main-Class: com.android.signapk
MF
# 生成jar
jar cfm "$DIST/signapk.jar" "$DIST/MANIFEST.MF" -C "$CLS" .
echo "Build complete: $DIST/signapk.jar"
ls -lh "$DIST/signapk.jar"
