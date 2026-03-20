#!/bin/bash
# ScholarClaw 安装脚本
# 将 skill 安装到系统或指定位置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 默认安装位置
DEFAULT_INSTALL_DIR="$HOME/.scholarclaw"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================"
echo "ScholarClaw 安装工具"
echo -e "========================================${NC}"
echo ""

# 解析参数
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
ADD_TO_PATH=true
CREATE_ALIASES=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --dir|-d)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --no-path)
            ADD_TO_PATH=false
            shift
            ;;
        --no-aliases)
            CREATE_ALIASES=false
            shift
            ;;
        --help|-h)
            cat << EOF
用法: $(basename "$0") [选项]

选项:
    -d, --dir DIR      安装目录 (默认: $DEFAULT_INSTALL_DIR)
    --no-path          不添加到 PATH
    --no-aliases       不创建命令别名
    -h, --help         显示帮助信息

示例:
    $(basename "$0")                    # 使用默认设置安装
    $(basename "$0") -d /opt/scholarclaw  # 安装到指定目录
    $(basename "$0") --no-aliases       # 不创建别名
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            exit 1
            ;;
    esac
done

echo "安装目录: $INSTALL_DIR"
echo "添加到 PATH: $ADD_TO_PATH"
echo "创建别名: $CREATE_ALIASES"
echo ""

# 检查是否已安装
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}警告: 安装目录已存在，将被覆盖${NC}"
    read -p "是否继续? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

# 复制文件
echo -e "${GREEN}正在复制文件...${NC}"
mkdir -p "$INSTALL_DIR"
cp -r "$SKILL_DIR"/* "$INSTALL_DIR/"

# 确保脚本可执行
chmod +x "$INSTALL_DIR/scripts/"*.sh
chmod +x "$INSTALL_DIR/"*.sh 2>/dev/null || true

# 创建配置文件
echo -e "${GREEN}创建配置文件...${NC}"
cat > "$INSTALL_DIR/scholarclaw.env" << EOF
# ScholarClaw 配置
# 添加到你的 ~/.bashrc 或 ~/.zshrc:
# source $INSTALL_DIR/scholarclaw.env

export SCHOLARCLAW_SERVER_URL="\${SCHOLARCLAW_SERVER_URL:-https://scholarclaw.youdao.com}"
export SCHOLARCLAW_DEBUG="\${SCHOLARCLAW_DEBUG:-false}"
EOF

# 添加到 PATH
if [[ "$ADD_TO_PATH" == true ]]; then
    echo -e "${GREEN}配置 PATH...${NC}"

    # 检测 shell 配置文件
    SHELL_RC=""
    if [[ -n "$ZSH_VERSION" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        # 检查是否已存在
        if ! grep -q "scholarclaw/scripts" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# ScholarClaw" >> "$SHELL_RC"
            echo "export PATH=\"\$PATH:$INSTALL_DIR/scripts\"" >> "$SHELL_RC"
            echo "source \"$INSTALL_DIR/scholarclaw.env\"" >> "$SHELL_RC"
            echo -e "${GREEN}已添加到 $SHELL_RC${NC}"
        else
            echo -e "${YELLOW}PATH 已配置，跳过${NC}"
        fi
    fi
fi

# 创建别名
if [[ "$CREATE_ALIASES" == true ]]; then
    echo -e "${GREEN}创建命令别名...${NC}"

    ALIAS_FILE="$INSTALL_DIR/aliases.sh"
    cat > "$ALIAS_FILE" << 'EOF'
#!/bin/bash
# ScholarClaw 命令别名
# 使用方法: source /path/to/aliases.sh

alias sc-search='search.sh'
alias sc-scholar='scholar.sh'
alias sc-citations='citations.sh'
alias sc-citations-stats='citations_stats.sh'
alias sc-openalex-cited='openalex_cited.sh'
alias sc-openalex-find='openalex_find.sh'
alias sc-blog='blog.sh'
alias sc-blog-submit='blog_submit.sh'
alias sc-blog-status='blog_status.sh'
alias sc-blog-result='blog_result.sh'
alias sc-benchmark='benchmark.sh'
alias sc-benchmark-submit='benchmark_submit.sh'
alias sc-benchmark-list='benchmark_list.sh'
alias sc-benchmark-result='benchmark_result.sh'
alias sc-recommend-papers='recommend_papers.sh'
alias sc-recommend-blogs='recommend_blogs.sh'
alias sc-paper-repos='paper_repos.sh'
alias sc-health='health.sh'
EOF
    chmod +x "$ALIAS_FILE"

    # 添加到 shell 配置
    if [[ -n "$SHELL_RC" ]]; then
        if ! grep -q "scholarclaw/aliases.sh" "$SHELL_RC" 2>/dev/null; then
            echo "source \"$ALIAS_FILE\"" >> "$SHELL_RC"
        fi
    fi
fi

# 创建快速启动脚本
cat > "$INSTALL_DIR/scholarclaw" << 'SCRIPT'
#!/bin/bash
# ScholarClaw 快速启动脚本

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"

show_help() {
    echo "ScholarClaw - AI 驱动的学术搜索工具"
    echo ""
    echo "用法: scholarclaw <command> [options]"
    echo ""
    echo "命令:"
    echo "  search          统一搜索"
    echo "  scholar         学术搜索"
    echo "  citations       引用分析"
    echo "  blog            博客生成"
    echo "  benchmark       Benchmark分析"
    echo "  recommend       推荐"
    echo "  health          健康检查"
    echo ""
    echo "运行 'scholarclaw <command> --help' 查看详细帮助"
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
    search)
        exec "$SCRIPTS_DIR/search.sh" "$@"
        ;;
    scholar)
        exec "$SCRIPTS_DIR/scholar.sh" "$@"
        ;;
    citations)
        exec "$SCRIPTS_DIR/citations.sh" "$@"
        ;;
    citations-stats)
        exec "$SCRIPTS_DIR/citations_stats.sh" "$@"
        ;;
    openalex-cited)
        exec "$SCRIPTS_DIR/openalex_cited.sh" "$@"
        ;;
    openalex-find)
        exec "$SCRIPTS_DIR/openalex_find.sh" "$@"
        ;;
    blog)
        if [[ $# -lt 1 ]]; then
            # Default: synchronous mode
            exec "$SCRIPTS_DIR/blog.sh" "$@"
        fi
        # Check if first arg is a subcommand or an option
        case "$1" in
            submit) shift; exec "$SCRIPTS_DIR/blog_submit.sh" "$@" ;;
            status) shift; exec "$SCRIPTS_DIR/blog_status.sh" "$@" ;;
            result) shift; exec "$SCRIPTS_DIR/blog_result.sh" "$@" ;;
            -*) exec "$SCRIPTS_DIR/blog.sh" "$@" ;;  # Option: use sync mode
            *) echo "未知命令: blog $1"; exit 1 ;;
        esac
        ;;
    benchmark)
        if [[ $# -lt 1 ]]; then
            # Default: synchronous mode
            exec "$SCRIPTS_DIR/benchmark.sh" "$@"
        fi
        # Check if first arg is a subcommand or an option
        case "$1" in
            submit) shift; exec "$SCRIPTS_DIR/benchmark_submit.sh" "$@" ;;
            list)   shift; exec "$SCRIPTS_DIR/benchmark_list.sh" "$@" ;;
            result) shift; exec "$SCRIPTS_DIR/benchmark_result.sh" "$@" ;;
            -*) exec "$SCRIPTS_DIR/benchmark.sh" "$@" ;;  # Option: use sync mode
            *) echo "未知命令: benchmark $1"; exit 1 ;;
        esac
        ;;
    recommend)
        if [[ $# -lt 1 ]]; then
            echo "用法: scholarclaw recommend <papers|blogs|repos> [options]"
            exit 1
        fi
        REC_CMD="$1"
        shift
        case "$REC_CMD" in
            papers) exec "$SCRIPTS_DIR/recommend_papers.sh" "$@" ;;
            blogs)  exec "$SCRIPTS_DIR/recommend_blogs.sh" "$@" ;;
            repos)  exec "$SCRIPTS_DIR/paper_repos.sh" "$@" ;;
            *) echo "未知命令: recommend $REC_CMD"; exit 1 ;;
        esac
        ;;
    health)
        exec "$SCRIPTS_DIR/health.sh" "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
SCRIPT
chmod +x "$INSTALL_DIR/scholarclaw"

# 完成
echo ""
echo -e "${GREEN}========================================"
echo "安装完成！"
echo -e "========================================${NC}"
echo ""
echo "安装位置: $INSTALL_DIR"
echo ""
echo "使用方法:"
echo ""
echo "  方式1: 直接使用脚本"
echo "    $INSTALL_DIR/scripts/search.sh -q 'query' -e arxiv"
echo ""
echo "  方式2: 使用快速启动脚本"
echo "    $INSTALL_DIR/scholarclaw search -q 'query' -e arxiv"
echo ""
echo "  方式3: 重新加载 shell 后直接使用"
echo "    source ~/.bashrc  # 或 source ~/.zshrc"
echo "    search.sh -q 'query' -e arxiv"
echo "    scholarclaw search -q 'query' -e arxiv"
echo ""
echo "  方式4: 使用别名"
echo "    source $INSTALL_DIR/aliases.sh"
echo "    sc-search -q 'query' -e arxiv"
echo ""
echo "配置:"
echo "  编辑 $INSTALL_DIR/scholarclaw.env 修改服务器地址"
echo ""
echo "验证安装:"
echo "  $INSTALL_DIR/scripts/health.sh"
echo ""
