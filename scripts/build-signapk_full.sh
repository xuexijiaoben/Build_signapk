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
[[ ! -d "$SRC_SIGN" ]] && echo "ERROR: Missing signapk src" && exit 1
[[ ! -d "$SRC_APK" ]] && echo "ERROR: Missing apksig src" && exit 1
[[ ! -d "$LIB" ]] && echo "ERROR: Missing BC libs" && exit 1

# BC jars
BC_PROV=$(ls "$LIB"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB"/bcpkix-*.jar 2>/dev/null | head -1)
[[ -z "$BC_PROV" || -z "$BC_PKIX" ]] && echo "ERROR: Missing BC jars" && exit 1

CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename $BC_PROV)"
echo "BC PKIX: $(basename $BC_PKIX)"

# 仅编译必要文件（避免 apksig 中多余的 apksigner 工具类导致编译失败）
echo "=== Collecting source files ==="
find "$SRC_SIGN" -name "*.java" > sources.txt
# 只添加 apksig 中核心签名相关包（避免编译爆炸）
find "$SRC_APK" \
  -path "*/com/android/apksig/*" \
  \( -name "*.java" ! -path "*/test/*" ! -path "*/apksigner/*" \) >> sources.txt || true

echo "Total Java files to compile: $(wc -l < sources.txt)"

javac -encoding UTF-8 -cp "$CP" -d "$CLS" @sources.txt
rm -f sources.txt

# Manifest
cat > "$DIST/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
Main-Class: com.android.signapk
MF

jar cfm "$DIST/signapk.jar" "$DIST/MANIFEST.MF" -C "$CLS" .

echo "=== Build completed successfully ==="
ls -lh "$DIST/signapk.jar"
