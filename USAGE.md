# ScholarClaw 使用指南

本文档介绍如何打包和使用 ScholarClaw。

## 目录

- [快速开始](#快速开始)
- [安装方式](#安装方式)
- [配置说明](#配置说明)
- [功能使用](#功能使用)
- [TypeScript SDK](#typescript-sdk)
- [集成到 LobsterAI](#集成到-lobsterai)
- [常见问题](#常见问题)

---

## 快速开始

### 1. 启动后端服务

```bash
# 进入项目目录
cd /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers

# 启动统一搜索服务（默认端口 8090）
python unified_search_server.py
```

### 2. 设置环境变量

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
```

### 3. 测试服务

```bash
cd skills/scholarclaw

# 健康检查
./scripts/health.sh

# 搜索测试
./scripts/search.sh -q "transformer" -e arxiv -l 5
```

---

## 安装方式

### 方式一：直接使用（推荐）

无需安装，直接运行脚本：

```bash
cd /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw

# 使用任意脚本
./scripts/search.sh -q "machine learning" -e arxiv
./scripts/scholar.sh -q "What is RAG?"
```

### 方式二：添加到 PATH

```bash
# 添加到 PATH（临时）
export PATH="/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts:$PATH"

# 现在可以直接使用
search.sh -q "test" -e arxiv
scholar.sh -q "question?"
```

永久添加（添加到 `~/.bashrc` 或 `~/.zshrc`）：

```bash
echo 'export PATH="/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 方式三：创建命令别名

```bash
# 添加别名到 shell 配置
cat >> ~/.bashrc << 'EOF'

# ScholarClaw aliases
alias sc-search='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/search.sh'
alias sc-scholar='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/scholar.sh'
alias sc-citations='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/citations.sh'
alias sc-blog='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/blog_submit.sh'
alias sc-sota-chat='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/benchmark_chat.sh'
alias sc-recommend='/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/scripts/recommend_papers.sh'
EOF

source ~/.bashrc
```

### 方式四：TypeScript/Node.js 项目集成

```bash
cd your-project

# 复制 server 目录
cp -r /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/server ./scholarclaw-client

# 安装依赖（如果需要编译）
npm install typescript --save-dev
```

---

## 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SCHOLARCLAW_SERVER_URL` | `https://scholarclaw.youdao.com` | 后端服务地址 |
| `SCHOLARCLAW_API_KEY` | - | API Key（可选，前往 https://scholarclaw.youdao.com/ 申请） |
| `SCHOLARCLAW_DEBUG` | `false` | 启用调试模式 |
| `SCHOLARCLAW_TIMEOUT` | `30000` | 请求超时时间（毫秒） |
| `SCHOLARCLAW_MAX_RETRIES` | `3` | 最大重试次数 |

### 配置文件

创建配置文件 `~/.scholarclaw/config.json`：

```json
{
  "serverUrl": "https://scholarclaw.youdao.com",
  "apiKey": "your-api-key",
  "timeout": 30000,
  "maxRetries": 3,
  "debug": false
}
```

或通过环境变量配置（可写入 `~/.bashrc` 或 `~/.zshrc`）：

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
export SCHOLARCLAW_API_KEY="your-api-key"  # 可选，前往 https://scholarclaw.youdao.com/ 申请
export SCHOLARCLAW_DEBUG="false"
```

### OpenClaw 配置 (config.yaml)

在 OpenClaw 中使用时，可通过 config.yaml 配置：

```yaml
skills:
  - name: scholarclaw
    enabled: true
    config:
      serverUrl: "https://scholarclaw.youdao.com"
      apiKey: "your-api-key"  # 可选，前往 https://scholarclaw.youdao.com/ 申请
      timeout: 30000
      maxRetries: 3
      debug: false
```

### 配置优先级

1. 代码中的显式配置
2. 环境变量
3. OpenClaw skill 配置
4. 默认值

---

## 功能使用

### 1. 统一搜索 (search.sh)

跨多个学术搜索引擎搜索。

**支持的搜索引擎**：
- `arxiv` - ArXiv 预印本
- `pubmed` - PubMed 生物医学文献
- `google` - Google 搜索（需要 SerpDev）
- `kuake` - 夸克搜索
- `bocha` - Bocha AI 搜索
- `cache` - 缓存搜索
- `nips` - NeurIPS 论文

**基本用法**：

```bash
# ArXiv 搜索
./scripts/search.sh -q "attention mechanism" -e arxiv -l 20

# PubMed 搜索
./scripts/search.sh -q "COVID-19 vaccine efficacy" -e pubmed -l 20

# AI 模式（带摘要）
./scripts/search.sh -q "vision transformers" -e arxiv --mode ai -l 20

# 分页
./scripts/search.sh -q "deep learning" -e arxiv -p 1 -ps 10

# 时间过滤
./scripts/search.sh -q "LLM" -e google --freshness week

# 按日期排序
./scripts/search.sh -q "GPT" -e arxiv --sort-by date
```

**参数说明**：

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--query` | `-q` | 搜索查询（必填） | - |
| `--engine` | `-e` | 搜索引擎 | bocha |
| `--limit` | `-l` | 最大结果数 | 100 |
| `--page` | `-p` | 页码 | 1 |
| `--page-size` | `-ps` | 每页数量 | 10 |
| `--freshness` | `-f` | 时间过滤 | - |
| `--mode` | `-m` | 搜索模式 | simple |
| `--sort-by` | `-s` | 排序方式 | relevance |

### 2. 学术搜索 (scholar.sh)

AI 驱动的智能学术搜索，包含查询分析、引用扩展和重排序。

**基本用法**：

```bash
# 智能搜索
./scripts/scholar.sh -q "What are the latest advances in multimodal learning?"

# 指定搜索引擎
./scripts/scholar.sh -q "transformer efficiency" -e arxiv -m 30

# 仅分析查询（不搜索）
./scripts/scholar.sh -q "How do vision transformers work?" --analyze-only

# 带对话上下文
./scripts/scholar.sh -q "What about computational cost?" \
  -c '[{"role":"user","content":"Tell me about ViT"}]'
```

**输出包含**：
- `results` - 搜索结果
- `summary` - AI 生成的摘要
- `analysis` - 查询分析结果

### 3. 引用分析 (citations.sh / citations_stats.sh)

查询 ArXiv 论文的引用信息。

```bash
# 获取引用统计
./scripts/citations_stats.sh -i 1706.03762

# 获取引用列表
./scripts/citations.sh -i 1706.03762 -p 1 -ps 20

# 按日期排序
./scripts/citations.sh -i 1706.03762 --sort-by date
```

### 4. OpenAlex 引用 (openalex_cited.sh / openalex_find.sh)

使用 OpenAlex 数据库查询引用。

```bash
# 通过标题查找论文并获取引用
./scripts/openalex_find.sh -t "Attention Is All You Need" --fetch-works

# 通过 OpenAlex ID 查询引用
./scripts/openalex_cited.sh -w W2741809807 -l 50
```

### 5. 博客生成 (blog_submit.sh / blog_status.sh / blog_result.sh)

从论文生成博客文章。

```bash
# 提交任务
./scripts/blog_submit.sh -i 2303.14535

# 带用户观点
./scripts/blog_submit.sh -i 2303.14535 -v "Focus on methodology"

# 查看任务状态
./scripts/blog_status.sh -i blog_xxxxxxxxxxxx

# 列出所有任务
./scripts/blog_status.sh -s completed -l 20

# 获取结果
./scripts/blog_result.sh -i blog_xxxxxxxxxxxx

# 保存到文件
./scripts/blog_result.sh -i blog_xxxxxxxxxxxx -o blog.md

# 仅获取内容
./scripts/blog_result.sh -i blog_xxxxxxxxxxxx --content-only
```

### 6. SOTA Chat (benchmark_chat.sh)

通过聊天API查询SOTA/Benchmark信息。

```bash
# 简单问答
./scripts/benchmark_chat.sh -m "What is the SOTA for MMLU benchmark?"

# 带对话历史
./scripts/benchmark_chat.sh -m "What about GPQA?" -H '[{"role":"user","content":"Tell me about MMLU"}]'

# 流式模式（适用于长回复）
./scripts/benchmark_chat.sh -m "List recent SOTA results for reasoning benchmarks" -s

# 保存到文件
./scripts/benchmark_chat.sh -m "Compare GPT-4 and Claude on various benchmarks" -o result.json
```

**参数说明**：

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--message` | `-m` | 问题/消息（必填） | - |
| `--history` | `-H` | 对话历史(JSON数组) | [] |
| `--stream` | `-s` | 启用流式模式 | false |
| `--timeout` | `-t` | 超时时间(秒) | 120 |
| `--output` | `-o` | 保存到文件 | - |

### 7. 推荐功能 (recommend_papers.sh / recommend_blogs.sh / paper_repos.sh)

获取推荐内容和 GitHub 仓库。

```bash
# HuggingFace 热门论文
./scripts/recommend_papers.sh -l 12

# 推荐博客
./scripts/recommend_blogs.sh -l 10

# 论文相关 GitHub 仓库
./scripts/paper_repos.sh -i 2303.14535 --min-stars 10
```

### 8. 健康检查 (health.sh)

```bash
# 基本检查
./scripts/health.sh

# 详细检查（显示后端服务状态）
./scripts/health.sh -v
```

---

## TypeScript SDK

### 安装

```bash
# 复制 SDK 文件到项目
cp -r /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw/server ./src/scholarclaw
```

### 基本使用

```typescript
import { ScholarClawClient } from './src/scholarclaw';

// 创建客户端
const client = new ScholarClawClient({
  serverUrl: 'https://scholarclaw.youdao.com',
  timeout: 30000,
});

// 搜索
async function search() {
  const results = await client.search('transformer', {
    engine: 'arxiv',
    limit: 20,
  });

  if ('results' in results) {
    console.log(`Found ${results.total} papers`);
    results.results.forEach(paper => {
      console.log(`- ${paper.title}`);
    });
  }
}

// Scholar 搜索
async function scholarSearch() {
  const result = await client.scholarSearch({
    query: 'What are vision transformers?',
    max_results: 15,
  });

  console.log('Summary:', result.summary);
  console.log('Papers:', result.results.length);
}

// 获取引用
async function getCitations() {
  const stats = await client.getCitationStats('1706.03762');
  console.log('Citations:', stats.total_citations);

  const citations = await client.getCitations('1706.03762', {
    page: 1,
    pageSize: 20,
  });
  console.log('Citing papers:', citations.length);
}

// 博客生成
async function generateBlog() {
  // 提交任务
  const { task_id } = await client.submitBlog('2303.14535');

  // 等待完成
  let task = await client.getBlogTask(task_id);
  while (task.status === 'pending' || task.status === 'running') {
    await new Promise(r => setTimeout(r, 5000));
    task = await client.getBlogTask(task_id);
  }

  // 获取结果
  if (task.status === 'completed') {
    const result = await client.getBlogResult(task_id);
    console.log('Blog:', result.blog_content);
  }
}
```

### 错误处理

```typescript
import { ScholarClawClient, ScholarClawError } from './src/scholarclaw';

const client = new ScholarClawClient();

try {
  const results = await client.search('query');
} catch (error) {
  if (error instanceof ScholarClawError) {
    console.error(`API Error (${error.statusCode}): ${error.message}`);
    console.error('Details:', error.details);
  } else {
    console.error('Unknown error:', error);
  }
}
```

---

## 集成到 LobsterAI

### 作为 Skill 集成

1. **复制 Skill 目录**：

```bash
cp -r /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers/skills/scholarclaw \
  /path/to/lobsterai/skills/
```

2. **配置 LobsterAI**：

在 LobsterAI 的配置中添加 skill 路径：

```yaml
skills:
  - name: scholarclaw
    path: ./skills/scholarclaw
    enabled: true
```

3. **设置环境变量**：

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
```

### 使用 SKILL.md

`SKILL.md` 文件定义了 skill 的元数据和能力：

```yaml
---
name: scholarclaw
description: ScholarClaw - AI-powered academic search and paper analysis service
version: 1.3.0
official: false
---
```

LobsterAI 会自动解析这个文件并注册 skill。

### 调用示例

在 LobsterAI 中使用：

```
User: 帮我搜索一下 transformer 相关的最新论文

AI: [调用 ScholarClaw skill]
./scripts/search.sh -q "transformer" -e arxiv --sort-by date -l 10

找到以下相关论文：
1. Attention Is All You Need (2017)
2. BERT: Pre-training of Deep Bidirectional Transformers...
...
```

---

## 常见问题

### Q: 服务连接失败怎么办？

```bash
# 检查服务是否运行
curl https://scholarclaw.youdao.com/health

# 检查端口是否被占用
lsof -i :8090

# 检查环境变量
echo $SCHOLARCLAW_SERVER_URL
```

### Q: 搜索结果为空？

1. 检查搜索引擎是否正确
2. 尝试简化查询词
3. 检查网络连接（对于需要外部 API 的引擎）

### Q: 博客生成时间过长？

博客生成通常需要 2-5 分钟，取决于：
- 论文长度
- 图片/表格数量
- 服务器负载

### Q: 如何查看详细日志？

```bash
# 启用调试模式
export SCHOLARCLAW_DEBUG=true

# 查看后端日志
tail -f /path/to/unified_search_server.log
```

### Q: 如何更新 ScholarClaw？

```bash
# 拉取最新代码
cd /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers
git pull

# 重新启动服务
python unified_search_server.py
```

---

## 脚本速查表

| 脚本 | 用途 | 示例 |
|------|------|------|
| `search.sh` | 统一搜索 | `./scripts/search.sh -q "query" -e arxiv` |
| `scholar.sh` | 学术搜索 | `./scripts/scholar.sh -q "question?"` |
| `citations.sh` | 引用列表 | `./scripts/citations.sh -i 1706.03762` |
| `citations_stats.sh` | 引用统计 | `./scripts/citations_stats.sh -i 1706.03762` |
| `openalex_cited.sh` | OpenAlex引用 | `./scripts/openalex_cited.sh -w W123` |
| `openalex_find.sh` | 查找论文 | `./scripts/openalex_find.sh -t "title"` |
| `blog_submit.sh` | 提交博客 | `./scripts/blog_submit.sh -i 2303.14535` |
| `blog_status.sh` | 博客状态 | `./scripts/blog_status.sh -i task_id` |
| `blog_result.sh` | 博客结果 | `./scripts/blog_result.sh -i task_id` |
| `benchmark_chat.sh` | SOTA聊天 | `./scripts/benchmark_chat.sh -m "question"` |
| `recommend_papers.sh` | 推荐论文 | `./scripts/recommend_papers.sh -l 12` |
| `recommend_blogs.sh` | 推荐博客 | `./scripts/recommend_blogs.sh -l 10` |
| `paper_repos.sh` | GitHub仓库 | `./scripts/paper_repos.sh -i arxiv_id` |
| `health.sh` | 健康检查 | `./scripts/health.sh -v` |

---

## 更多资源

- [README.md](README.md) - 项目概述
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署指南
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - 实现细节
- [TEST.md](TEST.md) - 测试文档
- [examples/](examples/) - 更多示例
