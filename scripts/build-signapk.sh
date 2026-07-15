#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
LIB_DIR="$SCRIPT_DIR/libs"
SRC_DIR="$SCRIPT_DIR/src"

echo "=== Start build signapk.jar ==="
# Clean old output
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/classes"

# Check source & BC lib
if [[ ! -d "$SRC_DIR" ]]; then
  echo "[ERROR] Source dir missing: $SRC_DIR"
  exit 1
fi
BC_PROV=$(ls "$LIB_DIR"/bcprov-*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "$LIB_DIR"/bcpkix-*.jar 2>/dev/null | head -1)
if [[ -z "$BC_PROV" || -z "$BC_PKIX" ]]; then
  echo "[ERROR] Missing BouncyCastle jars in $LIB_DIR"
  ls -la "$LIB_DIR" || true
  exit 1
fi
echo "BC Provider: $(basename "$BC_PROV")"
echo "BC PKIX:     $(basename "$BC_PKIX")"

# Collect java sources
find "$SRC_DIR" -type f -name "*.java" > sources.txt
# Compile with UTF-8 encoding fix
javac \
  -encoding UTF-8 \
  -cp "$BC_PROV:$BC_PKIX" \
  -d "$DIST_DIR/classes" \
  @sources.txt
rm -f sources.txt

# Manifest
cat > "$DIST_DIR/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: GitHub Actions Build Script
Main-Class: com.android.signapk.SignApk
EOF

# Package jar
jar cfm "$DIST_DIR/signapk.jar" "$DIST_DIR/MANIFEST.MF" -C "$DIST_DIR/classes" .

# Verify main class
echo "=== Build finished ==="
ls -lh "$DIST_DIR/signapk.jar"
jar xf "$DIST_DIR/signapk.jar" META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
rm -rf META-INF
