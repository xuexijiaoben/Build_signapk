#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="${SCRIPT_DIR}/dist"
CLS="${DIST}/classes"
LIB="${SCRIPT_DIR}/libs"
SRC_SIGN="${SCRIPT_DIR}/src"
SRC_APK="${ROOT}/apksig/src"

echo "=== Start build signapk.jar ==="
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "signapk src: $SRC_SIGN"
echo "apksig src: $SRC_APK"
echo "ROOT: $ROOT"

rm -rf "$DIST"
mkdir -p "$CLS"

# 路径检查
[[ ! -d "$SRC_SIGN" ]] && echo "ERROR: Missing signapk src directory" && exit 1
[[ ! -d "$SRC_APK" ]] && echo "ERROR: Missing apksig src directory" && exit 1
[[ ! -d "$LIB" ]] && echo "ERROR: Missing BC libs directory" && exit 1

# 检查 BouncyCastle
BC_PROV=$(ls "$LIB"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB"/bcpkix-*.jar 2>/dev/null | head -1)
[[ -z "$BC_PROV" || -z "$BC_PKIX" ]] && echo "ERROR: Missing BC jars" && exit 1

CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename $BC_PROV)"
echo "BC PKIX: $(basename $BC_PKIX)"

# 调试源码
echo "=== Source check ==="
find "$SRC_SIGN" -name "*.java" | head -5
find "$SRC_APK" -name "*.java" | head -5

# 编译
find "$SRC_SIGN" "$SRC_APK" -name "*.java" > sources.txt
javac -encoding UTF-8 -cp "$CP" -d "$CLS" @sources.txt
rm -f sources.txt

# 创建 Manifest
cat > "$DIST/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
Main-Class: com.android.signapk
MF

# 打包 JAR
jar cfm "$DIST/signapk.jar" "$DIST/MANIFEST.MF" -C "$CLS" .

echo "=== Build complete ==="
ls -lh "$DIST/signapk.jar"
