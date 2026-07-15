#!/bin/bash
# build-signapk.sh - 构建 signapk.jar 的辅助脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
LIB_DIR="$SCRIPT_DIR/libs"
SRC_DIR="$SCRIPT_DIR/src"

echo "🔧 Setting up build environment..."

# 清理旧构建
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 检查必要文件
if [[ ! -d "$SRC_DIR" ]]; then
    echo "❌ Source directory not found: $SRC_DIR"
    exit 1
fi

if [[ ! -f "$LIB_DIR/bcprov-"*".jar" ]] || [[ ! -f "$LIB_DIR/bcpkix-"*".jar" ]]; then
    echo "❌ BouncyCastle libraries not found in $LIB_DIR"
    ls -la "$LIB_DIR/" || true
    exit 1
fi

# 获取 BouncyCastle 版本信息
BC_PROV_JAR=$(ls "$LIB_DIR"/bcprov-*.jar | head -1)
BC_PKIX_JAR=$(ls "$LIB_DIR"/bcpkix-*.jar | head -1)

echo "📦 Using libraries:"
echo "  - $(basename "$BC_PROV_JAR")"
echo "  - $(basename "$BC_PKIX_JAR")"

# 编译 signapk
echo "🔨 Compiling signapk..."
find "$SRC_DIR" -name "*.java" > sources.txt

javac -cp "$BC_PROV_JAR:$BC_PKIX_JAR" \
      -d "$DIST_DIR/classes" \
      @sources.txt

if [[ $? -ne 0 ]]; then
    echo "❌ Compilation failed"
    exit 1
fi

# 创建 Manifest
cat > "$DIST_DIR/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: GitHub Actions Build Script
Main-Class: com.android.signapk.SignApk
EOF

# 打包 JAR
echo "📦 Creating signapk.jar..."
jar cfm "$DIST_DIR/signapk.jar" \
    "$DIST_DIR/MANIFEST.MF" \
    -C "$DIST_DIR/classes" .

# 验证 JAR
echo "✅ Build completed:"
ls -lh "$DIST_DIR/signapk.jar"

# 显示主类信息
echo "🔍 JAR manifest:"
jar xf "$DIST_DIR/signapk.jar" META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
rm -rf META-INF

echo "🎉 signapk.jar build successful!"
