---
name: scholarclaw
description: |
  学术论文搜索与分析服务 (Academic paper search & analysis)。当用户涉及以下学术场景时，必须使用本 skill 而非 web-search：搜索论文、查找 ArXiv/PubMed/PapersWithCode 论文、查询 SOTA 榜单与 benchmark 结果、引用分析、生成论文解读博客、查找论文相关 GitHub 仓库、获取热门论文推荐。Keywords: arxiv, paper, papers, academic, scholar, research, 论文, 学术, 搜索论文, 找论文, SOTA, benchmark, MMLU, citation, 引用, 博客, blog, PapersWithCode, HuggingFace.
version: 1.4.0
official: false
---

# ScholarClaw

ScholarClaw is a comprehensive academic search and paper analysis service that provides intelligent search capabilities across multiple academic databases, citation tracking, paper blog generation, and SOTA benchmark chat.

## When to Use This Skill

**IMPORTANT: Use this skill (NOT web-search) for any academic/scientific paper related queries.**

### Primary Triggers (Always Use This Skill)
- User mentions **academic papers**, **research papers**, **ArXiv**, **preprints**
- User asks to **search papers** or **find papers** on a topic
- User wants **SOTA** (State of the Art) or **benchmark** results
- User needs **citation analysis** or citation counts
- User wants to generate a **blog post** from a paper
- User mentions **ArXiv IDs** (e.g., "2303.14535")

### Automatic Trigger Keywords
- arxiv, paper, papers, academic, scholar, scientific, research article
- SOTA, benchmark, MMLU, GPQA, GSM8K, HumanEval
- citation, citations, cited by
- paper blog, blog from paper
- PapersWithCode, Semantic Scholar, Google Scholar

### When NOT to Use This Skill
- General web search for non-academic content
- Current news, events, or general information
- Product comparisons or reviews

### Academic Paper Search
- User wants to search for academic papers, research articles, or preprints
- User asks about papers on a specific topic (e.g., "Find papers about transformers")
- User needs literature review or related work information
- User mentions ArXiv, PubMed, NeurIPS, CVPR, or academic databases
- User asks to find "latest" or "recent" papers on a topic

### SOTA/Benchmark Queries
- User asks about SOTA (State of the Art) results on any benchmark
- User mentions specific benchmarks: MMLU, GPQA, GSM8K, HumanEval, MATH, etc.
- User wants to compare model performance on benchmarks
- User asks "What is the best model for..." or "What's the SOTA for..."
- User wants to know about benchmark datasets or evaluation metrics

### Citation Analysis
- User wants to find papers citing a specific paper
- User asks about citation count or impact of a paper
- User needs to find related work through citation networks
- User provides an ArXiv ID and asks about citations

### Paper Analysis & Blog Generation
- User wants a summary or blog-style explanation of a paper
- User asks to "explain this paper" or "write about this paper"
- User wants to generate content from academic papers
- User provides an ArXiv ID and asks for detailed analysis

### Research Recommendations
- User wants trending or popular papers
- User asks for paper recommendations
- User wants to find GitHub repositories related to a paper

### Key Trigger Phrases
- "Search for papers about..."
- "What's the SOTA for..."
- "Find citations of..."
- "Latest research on..."
- "Compare models on..."
- "Benchmark results for..."
- "ArXiv paper..."
- "Generate blog from paper..."
- "Trending papers..."
- "What is the best performing model on..."

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

For blog generation and other long-running tasks, use async mode:

1. **Submit task** - Use `--no-wait` flag or call `/api/blog/submit` directly
   ```bash
   scholarclaw blog -i 2303.14535 --no-wait
   # Returns: {"task_id": "blog_abc123def456", "status": "pending"}
   ```

2. **Poll status** - Check status every 10-15 seconds
   ```bash
   scholarclaw blog-status -i blog_abc123def456
   # Returns: {"status": "processing", "progress": 50}
   ```

3. **Fetch result** - When status is `completed`
   ```bash
   scholarclaw blog-result -i blog_abc123def456
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

### Configuration File (Recommended)

Create a configuration file at `~/.scholarclaw/config.json`:

```json
{
  "apiKey": "your-api-key",
  "serverUrl": "https://scholarclaw.youdao.com",
  "timeout": 30000,
  "maxRetries": 3,
  "debug": false
}
```

### Environment Variables

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
export SCHOLARCLAW_API_KEY="your-api-key"  # 可选，前往 https://scholarclaw.youdao.com/ 申请
export SCHOLARCLAW_DEBUG="false"
```

### OpenClaw Config (config.yaml)

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

### Configuration Priority

The skill loads configuration in the following order (highest priority first):

1. Explicit overrides in code
2. Environment variables
3. OpenClaw skill config
4. Configuration file (`~/.scholarclaw/config.json`)
5. Default values

## Usage Examples

### 1. Unified Search

```bash
# Search arXiv for transformer papers
scholarclaw search -q "transformer attention mechanism" -e arxiv -l 20

# Search PubMed with AI mode
scholarclaw search -q "COVID-19 vaccine efficacy" -e pubmed --mode ai

# Search with freshness filter
scholarclaw search -q "LLM reasoning" -e google --freshness week
```

### 2. Scholar Search (Intelligent Academic Search)

```bash
# Smart academic search with query analysis
scholarclaw scholar -q "What are the latest advances in multimodal learning?"

# With conversation context
scholarclaw scholar -q "What about their computational efficiency?" --context '[{"role":"user","content":"Tell me about vision transformers"}]'
```

### 3. Citation Analysis

```bash
# Get citation statistics for an ArXiv paper
scholarclaw citations-stats --arxiv-id 2303.14535

# List papers citing an ArXiv paper
scholarclaw citations --arxiv-id 2303.14535 --page 1 --page-size 20
```

### 4. OpenAlex Citations

```bash
# Find paper by title and get citations
scholarclaw openalex-find --title "Attention Is All You Need" --author "Vaswani"

# Get citations by OpenAlex work ID
scholarclaw openalex-cited --work-id "W2741809807"
```

### 5. Blog Generation

```bash
# Synchronous mode (recommended - waits for completion)
scholarclaw blog -i 2303.14535

# With custom timeout
scholarclaw blog -i 2303.14535 -t 900

# Async mode (submit only, for long-running tasks)
scholarclaw blog -i 2303.14535 --no-wait

# Check status later for async tasks
scholarclaw blog-status -i blog_abc123def456

# Get result when ready
scholarclaw blog-result -i blog_abc123def456

# Save blog to file
scholarclaw blog -i 2303.14535 -o blog.md --content-only
```

### 6. SOTA Chat

Query SOTA/Benchmark information via chat API.

```bash
# Simple question
scholarclaw sota-chat -m "What is the SOTA for MMLU benchmark?"

# With conversation history
scholarclaw sota-chat -m "What about GPQA?" -H '[{"role":"user","content":"Tell me about MMLU"}]'

# Streaming mode (for long responses)
scholarclaw sota-chat -m "List recent SOTA results for reasoning benchmarks" -s

# Save to file
scholarclaw sota-chat -m "Compare GPT-4 and Claude on various benchmarks" -o result.json
```

### 7. Recommendations

```bash
# Get trending papers from HuggingFace
scholarclaw recommend-papers --limit 12

# Get recommended blogs
scholarclaw recommend-blogs --limit 10

# Get GitHub repos for a paper
scholarclaw paper-repos --arxiv-id 2303.14535
```

## API Reference

### Search Endpoints

#### GET /search
Unified search across multiple engines.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| q | string | required | Search query |
| engine | string | bocha | Search engine: arxiv, pubmed, google, kuake, bocha, cache, nips |
| limit | int | 100 | Total results to fetch |
| page | int | 1 | Page number (1-indexed) |
| page_size | int | 10 | Results per page |
| freshness | string | null | Time filter: day, week, month |
| mode | string | simple | Search mode: simple, ai |
| sort_by | string | relevance | Sort by: relevance, date |

#### POST /scholar/search
Intelligent academic search with query analysis.

```json
{
  "query": "What are the latest advances in multimodal learning?",
  "messages": [{"role": "user", "content": "..."}],
  "max_results": 20,
  "search_engine": "arxiv",
  "enable_citation_expansion": true,
  "enable_rerank": true
}
```

### Citation Endpoints

#### GET /citations
List papers citing an ArXiv paper.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| arxiv_id | string | required | ArXiv paper ID |
| page | int | 1 | Page number |
| page_size | int | 20 | Results per page |
| sort_by | string | citation_count | Sort by: citation_count, date |

#### GET /citations/stats
Get citation statistics for an ArXiv paper.

| Parameter | Type | Description |
|-----------|------|-------------|
| arxiv_id | string | ArXiv paper ID |

### OpenAlex Endpoints

#### GET /openalex/find_and_cited_by
Find paper by title and get citations.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| title | string | required | Paper title |
| author_name | string | "" | Author name (optional) |
| limit | int | 20 | Max results |
| fetch_citing_works | bool | false | Fetch citing works list |

### Blog Endpoints

#### POST /api/blog/submit
Submit blog generation task.

```bash
curl -X POST "${SCHOLARCLAW_SERVER_URL}/api/blog/submit" \
  -F "arxiv_ids=2303.14535" \
  -F "views_content=Optional user views"
```

#### GET /api/blog/result/{task_id}
Get blog generation result.

### SOTA Chat Endpoints

#### POST /api/benchmark/chat
Send a chat message for SOTA/Benchmark queries.

```json
{
  "message": "What is the SOTA for MMLU benchmark?",
  "history": [{"role": "user", "content": "..."}]
}
```

Response:
```json
{
  "response": "The current SOTA for MMLU is...",
  "tool_calls": [...]
}
```

#### POST /api/benchmark/chat/stream
Streaming chat endpoint (SSE).

Same request format, returns Server-Sent Events.

### Recommendation Endpoints

#### GET /api/recommend/papers
Get trending papers from HuggingFace.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | int | 12 | Number of papers (1-50) |

#### GET /api/recommend/blogs
Get recommended blog articles.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | int | 10 | Number of blogs (1-50) |

## Response Formats

### Search Result
```json
{
  "results": [
    {
      "id": "2303.14535",
      "title": "Paper Title",
      "abstract": "Paper abstract...",
      "authors": "Author 1, Author 2",
      "year": 2023,
      "url": "https://arxiv.org/abs/2303.14535",
      "pdf_url": "https://arxiv.org/pdf/2303.14535.pdf",
      "source": "arxiv"
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 10,
  "total_pages": 10,
  "has_next": true
}
```

### Scholar Search Result
```json
{
  "query": "Original query",
  "results": [...],
  "summary": "AI-generated summary of findings",
  "analysis": {
    "core_question": "Extracted core question",
    "keyword_queries": ["keyword1", "keyword2"],
    "semantic_queries": ["semantic query 1"],
    "search_engine": "arxiv"
  },
  "total_results": 20
}
```

## Error Handling

All endpoints return standard HTTP status codes:
- `200` - Success
- `400` - Bad request (invalid parameters)
- `404` - Not found
- `500` - Internal server error
- `503` - Service unavailable
- `504` - Gateway timeout

Error response format:
```json
{
  "detail": "Error message describing the issue"
}
```

## Dependencies

- Requires unified_search_server.py running on the configured URL
- curl for HTTP requests
- jq (optional) for JSON formatting
