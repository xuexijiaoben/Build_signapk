#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
CLS_DIR="${DIST_DIR}/classes"
LIB_DIR="${SCRIPT_DIR}/libs"
SRC_SIGNAPK="${SCRIPT_DIR}/src"
SRC_APKSIG="${SCRIPT_DIR}/../../apksig"

echo "=== Start build signapk.jar ==="
rm -rf "${DIST_DIR}"
mkdir -p "${CLS_DIR}"

# 校验源码
[[ ! -d "${SRC_SIGNAPK}" ]] && echo "Missing signapk src" && exit 1
[[ ! -d "${SRC_APKSIG}" ]] && echo "Missing apksig src" && exit 1
[[ ! -d "${LIB_DIR}" ]] && echo "Missing libs" && exit 1

# 获取BC依赖
BC_PROV=$(ls "${LIB_DIR}/bcprov-"*.jar 2>/dev/null | head -1)
BC_PKIX=$(ls "${LIB_DIR}/bcpkix-"*.jar 2>/dev/null | head -1)
[[ -z "${BC_PROV}" || -z "${BC_PKIX}" ]] && echo "BC jars missing" && exit 1
CP="${BC_PROV}:${BC_PKIX}"
echo "BC Provider: $(basename "$BC_PROV")"
echo "BC PKIX: $(basename "$BC_PKIX")"

# 收集全部源码
find "${SRC_SIGNAPK}" "${SRC_APKSIG}" -name "*.java" > source_list
# 编译
javac -encoding UTF-8 -cp "$CP" -d "${CLS_DIR}" @source_list
rm -f source_list

# 生成清单
cat > "${DIST_DIR}/MANIFEST.MF" <<'MANIFEST'
Manifest-Version: 1.0
Main-Class: com.android.signapk.SignApk
MANIFEST
# 打包
jar cfm "${DIST_DIR}/signapk.jar" "${DIST_DIR}/MANIFEST.MF" -C "${CLS_DIR}" .
echo "Build success: ${DIST_DIR}/signapk.jar"
ls -lh "${DIST_DIR}/signapk.jar"
