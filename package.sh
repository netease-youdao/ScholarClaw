#!/bin/bash
# ScholarClaw Skill 打包脚本
# 将 skill 打包为可分发的压缩包

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SKILL_DIR")")"

# 版本号
VERSION=$(grep '"version"' "$SKILL_DIR/package.json" | cut -d'"' -f4)
PACKAGE_NAME="scholarclaw-skill-${VERSION}"

echo "========================================"
echo "ScholarClaw Skill 打包工具"
echo "版本: $VERSION"
echo "========================================"

# 创建临时目录
TEMP_DIR=$(mktemp -d)
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

# 复制文件
echo "复制文件..."
cp -r "$SKILL_DIR" "$TEMP_DIR/$PACKAGE_NAME"

# 清理不需要的文件
cd "$TEMP_DIR/$PACKAGE_NAME"
rm -rf node_modules dist .git *.log

# 确保脚本可执行
chmod +x scripts/*.sh

# 创建压缩包
echo "创建压缩包..."
cd "$TEMP_DIR"
tar -czf "$DIST_DIR/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
zip -r -q "$DIST_DIR/${PACKAGE_NAME}.zip" "$PACKAGE_NAME"

# 计算校验和
cd "$DIST_DIR"
sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
sha256sum "${PACKAGE_NAME}.zip" > "${PACKAGE_NAME}.zip.sha256"

# 清理
rm -rf "$TEMP_DIR"

echo ""
echo "========================================"
echo "打包完成！"
echo "========================================"
echo ""
echo "输出文件:"
echo "  - $DIST_DIR/${PACKAGE_NAME}.tar.gz"
echo "  - $DIST_DIR/${PACKAGE_NAME}.zip"
echo ""
echo "校验文件:"
echo "  - $DIST_DIR/${PACKAGE_NAME}.tar.gz.sha256"
echo "  - $DIST_DIR/${PACKAGE_NAME}.zip.sha256"
echo ""
echo "安装方法:"
echo "  tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "  cd ${PACKAGE_NAME}"
echo "  export SCHOLARCLAW_SERVER_URL=https://scholarclaw.youdao.com"
echo "  ./scripts/health.sh"
echo ""
