#!/bin/bash
set -euo pipefail
# 获取脚本绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 目录定义
DIST_DIR="${SCRIPT_DIR}/dist"
CLS_DIR="${DIST_DIR}/classes"
LIB_DIR="${SCRIPT_DIR}/libs"
SRC_SIGNAPK="${SCRIPT_DIR}/src"
SRC_APKSIG="${SCRIPT_DIR}/../../apksig/src"

echo "=== Start build signapk.jar ==="
echo "SignApk Source: ${SRC_SIGNAPK}"
echo "Apksig Source: ${SRC_APKSIG}"
echo "Output Dist: ${DIST_DIR}"

# 1. 清理旧产物
rm -rf "${DIST_DIR}"
mkdir -p "${CLS_DIR}"

# 2. 校验源码目录完整性
if [[ ! -d "${SRC_SIGNAPK}" ]]; then
  echo "[FATAL] Missing signapk source folder"
  exit 1
fi
if [[ ! -d "${SRC_APKSIG}" ]]; then
  echo "[FATAL] Missing apksig source folder (required dependency)"
  exit 1
fi
if [[ ! -d "${LIB_DIR}" ]]; then
  echo "[FATAL] Missing libs folder for BC jars"
  exit 1
fi

# 3. 读取BouncyCastle依赖
BC_PROV=$(ls "${LIB_DIR}/bcprov-"*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "${LIB_DIR}/bcpkix-"*.jar 2>/dev/null | head -1)
if [[ -z "${BC_PROV}" || -z "${BC_PKIX}" ]]; then
  echo "[FATAL] BouncyCastle jars not found in libs/"
  ls -la "${LIB_DIR}" || true
  exit 1
fi
echo "BC Provider: $(basename "${BC_PROV}")"
echo "BC PKIX:     $(basename "${BC_PKIX}")"
CP="${BC_PROV}:${BC_PKIX}"

# 4. 收集全部Java源码（signapk + apksig）
find "${SRC_SIGNAPK}" "${SRC_APKSIG}" -type f -name "*.java" > sources.list

# 5. 编译，强制UTF8编码
javac \
  -encoding UTF-8 \
  -cp "${CP}" \
  -d "${CLS_DIR}" \
  @sources.list
rm -f sources.list

# 6. 生成Jar清单文件（指定入口类）
cat > "${DIST_DIR}/MANIFEST.MF" << 'MANIFEST_CONTENT'
Manifest-Version: 1.0
Created-By: GitHub Actions CI Build
Main-Class: com.android.signapk.SignApk
MANIFEST_CONTENT

# 7. 打包成品jar
jar cfm "${DIST_DIR}/signapk.jar" "${DIST_DIR}/MANIFEST.MF" -C "${CLS_DIR}" .

# 8. 输出结果校验
echo -e "\n=== Build Completed ==="
ls -lh "${DIST_DIR}/signapk.jar"
# 校验主类是否写入jar
jar xf "${DIST_DIR}/signapk.jar" META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
rm -rf META-INF
