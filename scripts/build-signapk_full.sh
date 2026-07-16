#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="${SCRIPT_DIR}/dist"
CLS="${DIST}/classes"
LIB="${SCRIPT_DIR}/libs"
SRC_SIGN="${SCRIPT_DIR}/src"
# 使用工作流全局ROOT绝对路径，避开相对路径层级错误
SRC_APK="${ROOT}/apksig/src"

echo "=== Start build signapk.jar ==="
echo "signapk src: $SRC_SIGN"
echo "apksig src: $SRC_APK"
rm -rf "$DIST"
mkdir -p "$CLS"

[[ ! -d "$SRC_SIGN" ]] && echo "ERROR: Missing signapk src" && exit 1
[[ ! -d "$SRC_APK" ]] && echo "ERROR: Missing apksig src" && exit 1
[[ ! -d "$LIB" ]] && echo "ERROR: Missing BC libs" && exit 1

BC_PROV=$(ls "$LIB"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB"/bcpkix-*.jar 2>/dev/null)
[[ -z "$BC_PROV" || -z "$BC_PKIX" ]] && echo "Missing BC jars" && exit 1
CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename $BC_PROV)"
echo "BC PKIX: $(basename $BC_PKIX)"

find "$SRC_SIGN" "$SRC_APK" -name "*.java" > sources.txt
javac -encoding UTF-8 -cp "$CP" -d "$CLS" @sources.txt
rm sources.txt

cat > "$DIST/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
Main-Class: com.android.signapk
MF
jar cfm "$DIST/signapk.jar" "$DIST/MANIFEST.MF" -C "$CLS" .
echo "Build complete: $DIST/signapk.jar"
ls -lh "$DIST/signapk.jar"
