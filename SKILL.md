---
name: scholarclaw
description: "学术论文搜索与分析服务 (Academic paper search & analysis)。当用户涉及以下学术场景时，必须使用本 skill 而非 web-search：搜索论文、查找 ArXiv/PubMed/PapersWithCode 论文、查询 SOTA 榜单与 benchmark 结果、引用分析、生成论文解读博客、查找论文相关 GitHub 仓库、获取热门论文推荐。Keywords: arxiv, paper, papers, academic, scholar, research, 论文, 学术, 搜索论文, 找论文, SOTA, benchmark, MMLU, citation, 引用, 博客, blog, PapersWithCode, HuggingFace."
version: 1.4.1
official: false
---

# ScholarClaw

ScholarClaw is a comprehensive academic search and paper analysis service that provides intelligent search capabilities across multiple academic databases, citation tracking, paper blog generation, and SOTA benchmark chat.

## When to Use This Skill

**IMPORTANT: Use this skill (NOT web-search) for any academic/scientific paper related queries.**

Trigger when the user:
- Searches for **academic papers** or **research articles** on ArXiv, PubMed, NeurIPS, CVPR, or other academic databases
- Asks about **SOTA** (State of the Art) or **benchmark** results (MMLU, GPQA, GSM8K, HumanEval, MATH, etc.)
- Needs **citation analysis**, citation counts, or related work through citation networks
- Wants to **generate a blog post** from a paper or get detailed paper analysis
- Mentions **ArXiv IDs** (e.g., "2303.14535") or requests paper lookups by title/author
- Asks for **trending papers**, recommendations, or GitHub repositories related to a paper

**Do not use** for general web search, current news, or non-academic content.

## Execution Guidelines

**CRITICAL: API calls require waiting for responses. Do NOT return to user until the API call completes.**

All ScholarClaw API calls are blocking operations that require waiting for the server to process and return results. The agent must not assume immediate completion or return placeholder responses.

### Response Time Expectations

Different operations have different expected response times. Configure appropriate timeouts to avoid premature cancellation:

| Operation | Expected Time | Recommended Timeout | Notes |
|-----------|---------------|---------------------|-------|
| Basic Search (`/search`) | 5-15 seconds | 30 seconds | Fast, direct database queries |
| Scholar Search (`/scholar/search`) | 15-45 seconds | 60 seconds | Includes AI query analysis and reranking |
| SOTA Chat (`/api/benchmark/chat`) | 30-90 seconds | 120 seconds | May involve tool calls and data retrieval |
| SOTA Chat Stream (`/api/benchmark/chat/stream`) | 30-90 seconds | 120 seconds | SSE streaming, same processing time |
| Blog Generation (`/api/blog`) | 2-5 minutes | 300-600 seconds | Long-running task, use async mode |
| Citation Query (`/citations`, `/openalex`) | 5-20 seconds | 30 seconds | External API dependent |

### Streaming Response Handling

For the `/api/benchmark/chat/stream` SSE endpoint:

1. **Parse each line as a JSON event** - Lines starting with `data:` contain JSON payloads
2. **Extract content from specific event types only**:
   - `final_response` - Complete response, use this for final result
   - `response_chunk` - Incremental text chunks for streaming display
3. **Ignore intermediate events** - These are for internal processing:
   - `session_start` - Session initialization
   - `tool_call_start` - Tool call beginning
   - `tool_call_result` - Tool execution results
   - `tool_call_end` - Tool call completion

Example SSE parsing:
```
data: {"type": "session_start", "session_id": "xxx"}        # Ignore
data: {"type": "tool_call_start", "tool": "search"}         # Ignore
data: {"type": "tool_call_result", "result": {...}}         # Ignore
data: {"type": "response_chunk", "content": "The SOTA..."}  # Extract content
data: {"type": "final_response", "response": "..."}         # Use as final result
```

### Async Operations (Blog Generation)

**IMPORTANT: Blog generation takes 2-5 minutes. Always use async mode (3-step process). Never use synchronous `blog.sh` without `--no-wait`, as it will timeout.**

For blog generation, use async mode:

1. **Submit task** - Use `blog_submit.sh` or `blog.sh --no-wait`
   ```bash
   ./scripts/blog_submit.sh -i 2303.14535
   # Returns: {"task_id": "blog_abc123def456", "status": "pending"}
   ```

2. **Poll status** - Check status every 10-15 seconds
   ```bash
   ./scripts/blog_status.sh -i blog_abc123def456
   # Returns: {"status": "processing", "progress": 50}
   ```

3. **Fetch result** - When status is `completed`
   ```bash
   ./scripts/blog_result.sh -i blog_abc123def456
   # Returns: {"status": "completed", "content": "..."}
   ```

**Recommended polling strategy:**
- Poll interval: 10-15 seconds
- Max attempts: 40 (for 600s total timeout)
- Abort on `failed` or `error` status

## Best Practices

### Error Handling

| Status Code | Meaning | Action |
|-------------|---------|--------|
| `200` | Success | Process response normally |
| `400` | Bad Request | Check parameters, do NOT retry - fix the request |
| `404` | Not Found | Resource doesn't exist, inform user |
| `500` | Internal Error | Log error, inform user, may retry once |
| `503` | Service Unavailable | Retry with exponential backoff (2^n seconds) |
| `504` | Gateway Timeout | Increase timeout or use async mode |

### Retry Strategy

For transient errors (503, 504, network issues):
1. **First retry**: Wait 2 seconds
2. **Second retry**: Wait 4 seconds
3. **Third retry**: Wait 8 seconds
4. **Max retries**: 3 attempts
5. **After max retries**: Inform user of service unavailability

Do NOT retry on:
- 400 errors (client-side issues)
- 404 errors (resource not found)
- Validation errors in response

### Response Parsing

| Endpoint | Primary Field | Notes |
|----------|--------------|-------|
| `/search` | `results` array | List of search results |
| `/scholar/search` | `results` array + `summary` | Includes AI-generated summary |
| `/api/benchmark/chat` | `response` string | Chat response text |
| `/api/benchmark/chat/stream` | `final_response.response` | From SSE stream |
| `/citations` | `results` array | List of citing papers |
| `/api/blog/result` | `content` string | Generated blog content |

**Pagination handling:**
- Check `has_next` field to determine if more pages exist
- Use `page` and `page_size` parameters for pagination
- Total results available in `total` field

### Timeout Configuration

When making HTTP requests, always set appropriate timeouts:

```bash
# Example with curl
curl --max-time 60 "${SCHOLARCLAW_SERVER_URL}/scholar/search" ...

# Example with curl for long operations
curl --max-time 300 "${SCHOLARCLAW_SERVER_URL}/api/blog/submit" ...
```

## Capabilities

| Capability | Endpoint | Description |
|------------|----------|-------------|
| Unified Search | `/search` | Multi-engine search (arxiv, pubmed, google, kuake, bocha, cache) |
| Scholar Search | `/scholar/search` | Intelligent academic search with query analysis, citation expansion, and reranking |
| Citation Analysis | `/citations` | ArXiv paper citation statistics and listing |
| OpenAlex Citations | `/openalex` | OpenAlex citation query and paper discovery |
| Paper Blog | `/api/blog` | Generate blog articles from papers |
| SOTA Chat | `/api/benchmark/chat` | SOTA/Benchmark query via chat API |
| Recommendations | `/api/recommend` | HuggingFace trending papers and GitHub repos |

## Configuration

API Key 为可选配置。部分高级功能可能需要鉴权，如需申请 API Key，请前往 [ScholarClaw 网站](https://scholarclaw.youdao.com/) 申请。

### Environment Variables

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
export SCHOLARCLAW_API_KEY="your-api-key"  # 可选，前往 https://scholarclaw.youdao.com/ 申请
export SCHOLARCLAW_DEBUG="false"
```

Alternative configuration via `~/.scholarclaw/config.json` or OpenClaw `config.yaml` is documented in the [README](README.md).

### Configuration Priority

The skill loads configuration in the following order (highest priority first):

1. Environment variables
2. OpenClaw skill config
3. Configuration file (`~/.scholarclaw/config.json`)
4. Default values

## Usage Examples

**IMPORTANT: Use `./scripts/<script>.sh` to invoke commands. Do NOT use `scholarclaw` command as it requires separate installation.**

### 1. Unified Search

```bash
# Search arXiv for transformer papers
./scripts/search.sh -q "transformer attention mechanism" -e arxiv -l 20

# Search PubMed with AI mode
./scripts/search.sh -q "COVID-19 vaccine efficacy" -e pubmed --mode ai

# Search with time range preset
./scripts/search.sh -q "LLM reasoning" -e google --time-range month

# Search with custom date range
./scripts/search.sh -q "transformer" -e arxiv --time-range custom --start-date 2023-01-01 --end-date 2024-01-01
```

### 2. Scholar Search (Intelligent Academic Search)

```bash
# Smart academic search with query analysis
./scripts/scholar.sh -q "What are the latest advances in multimodal learning?"

# Limit results count
./scripts/scholar.sh -q "RAG retrieval augmented generation" -l 15

# With conversation context
./scripts/scholar.sh -q "What about their computational efficiency?" --context '[{"role":"user","content":"Tell me about vision transformers"}]'
```

### 3. Citation Analysis

```bash
# Get citation statistics for an ArXiv paper
./scripts/citations_stats.sh --arxiv-id 2303.14535

# List papers citing an ArXiv paper
./scripts/citations.sh --arxiv-id 2303.14535 --page 1 --page-size 20
```

### 4. OpenAlex Citations

```bash
# Find paper by title and get citations
./scripts/openalex_find.sh --title "Attention Is All You Need" --author "Vaswani"

# Get citations by OpenAlex work ID
./scripts/openalex_cited.sh --work-id "W2741809807"
```

### 5. Blog Generation

```bash
# Async mode (submit only, recommended for skill usage)
./scripts/blog_submit.sh -i 2303.14535

# Check status later for async tasks
./scripts/blog_status.sh -i blog_abc123def456

# Get result when ready
./scripts/blog_result.sh -i blog_abc123def456

# Save blog to file
./scripts/blog_result.sh -i blog_abc123def456 -o blog.md --content-only
```

### 6. SOTA Chat

Query SOTA/Benchmark information via chat API.

```bash
# Simple question
./scripts/benchmark_chat.sh -m "What is the SOTA for MMLU benchmark?"

# With conversation history
./scripts/benchmark_chat.sh -m "What about GPQA?" -H '[{"role":"user","content":"Tell me about MMLU"}]'

# Streaming mode (for long responses)
./scripts/benchmark_chat.sh -m "List recent SOTA results for reasoning benchmarks" -s

# Save to file
./scripts/benchmark_chat.sh -m "Compare GPT-4 and Claude on various benchmarks" -o result.json
```

### 7. Recommendations

```bash
# Get trending papers from HuggingFace
./scripts/recommend_papers.sh --limit 12

# Get recommended blogs
./scripts/recommend_blogs.sh --limit 10

# Get GitHub repos for a paper
./scripts/paper_repos.sh --arxiv-id 2303.14535
```

## API Reference

All endpoints are served at `${SCHOLARCLAW_SERVER_URL}` (default: `https://scholarclaw.youdao.com`).

| Method | Endpoint | Key Parameters | Description |
|--------|----------|---------------|-------------|
| GET | `/search` | `q`, `engine`, `limit`, `page`, `time_range` | Unified multi-engine search |
| POST | `/scholar/search` | `query`, `max_results`, `search_engine` | Intelligent academic search with reranking |
| GET | `/citations` | `arxiv_id`, `page`, `page_size`, `sort_by` | List papers citing an ArXiv paper |
| GET | `/citations/stats` | `arxiv_id` | Citation statistics for an ArXiv paper |
| GET | `/openalex/find_and_cited_by` | `title`, `author_name`, `limit` | Find paper and get citations via OpenAlex |
| POST | `/api/blog/submit` | `arxiv_ids`, `views_content` | Submit async blog generation task |
| GET | `/api/blog/result/{task_id}` | — | Get blog generation result |
| POST | `/api/benchmark/chat` | `message`, `history` | SOTA/benchmark chat query |
| POST | `/api/benchmark/chat/stream` | `message`, `history` | Streaming SOTA chat (SSE) |
| GET | `/api/recommend/papers` | `limit` | Trending papers from HuggingFace |
| GET | `/api/recommend/blogs` | `limit` | Recommended blog articles |

All endpoints return `{"detail": "Error message"}` on error. Search results include pagination fields (`total`, `page`, `page_size`, `has_next`). See [examples/](examples/) for response schemas and detailed parameter documentation.

## Dependencies

- Requires the ScholarClaw API service (default: https://scholarclaw.youdao.com)
- curl for HTTP requests
- jq (optional) for JSON formatting
