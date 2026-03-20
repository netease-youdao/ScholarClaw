# Implementation Details

This document provides technical details about the ScholarClaw skill implementation.

## Project Structure

```
skills/scholarclaw/
├── SKILL.md              # Skill definition for LobsterAI
├── README.md             # User documentation
├── DEPLOYMENT.md         # Deployment guide
├── IMPLEMENTATION.md     # This file
├── TEST.md               # Test documentation
├── LICENSE.txt           # MIT License
├── package.json          # Node.js package metadata
├── tsconfig.json         # TypeScript configuration
├── scripts/              # Shell script CLI
│   ├── search.sh
│   ├── scholar.sh
│   ├── citations.sh
│   ├── citations_stats.sh
│   ├── openalex_cited.sh
│   ├── openalex_find.sh
│   ├── blog_submit.sh
│   ├── blog_status.sh
│   ├── blog_result.sh
│   ├── benchmark_chat.sh
│   ├── recommend_papers.sh
│   ├── recommend_blogs.sh
│   ├── paper_repos.sh
│   └── health.sh
├── server/               # TypeScript client
│   ├── config.ts
│   ├── types.ts
│   └── index.ts
└── examples/             # Usage examples
    ├── basic-search.md
    ├── scholar-search.md
    └── blog-generation.md
```

## Architecture

### HTTP API Layer

The skill communicates with the `unified_search_server.py` via HTTP. All scripts use `curl` for HTTP requests, and the TypeScript client uses the native `fetch` API.

### Response Formats

#### Paginated Response

```typescript
interface PaginatedResponse<T> {
  results: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}
```

#### AI Mode Response

```typescript
interface ScholarClawResponse {
  mode: 'ai';
  results: SearchResult[];
  report?: {
    summary?: string;
    key_findings?: string[];
  };
}
```

## Key Components

### 1. Search Scripts (scripts/)

Each script follows a consistent pattern:

1. **Argument Parsing**: Using bash `getopts` or manual parsing
2. **Validation**: Check required parameters
3. **URL Building**: Construct API URL with parameters
4. **Request Execution**: Use `curl` with proper error handling
5. **Output Formatting**: Use `jq` if available, otherwise raw JSON

### 2. TypeScript Client (server/)

The client is organized into three files:

- **config.ts**: Configuration types and defaults
- **types.ts**: All TypeScript interfaces
- **index.ts**: Main client class with methods

### Error Handling

The client throws `ScholarClawError` for all API errors:

```typescript
class ScholarClawError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public details: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ScholarClawError';
  }
}
```

## API Endpoints

### Unified Search (`/search`)

Supports multiple engines with different capabilities:

| Engine | Citation Data | AI Mode | Pagination |
|--------|--------------|---------|------------|
| arxiv | Yes | Yes | Yes |
| pubmed | Yes | Yes | Yes |
| google | No | No | Yes |
| bocha | No | No | Yes |
| cache | Yes | Yes | Yes |

### Scholar Search (`/scholar/search`)

Workflow:
1. Analyze query with LLM
2. Generate keyword and semantic queries
3. Execute searches across sources
4. Expand with citations (optional)
5. Rerank results (optional)
6. Generate summary

### Blog Generation (`/api/blog`)

Workflow:
1. Submit task with ArXiv ID or PDF
2. Download/parse PDF
3. Generate blog content via QAnything
4. Store result in SQLite
5. Return task ID for polling

### SOTA Chat (`/api/benchmark/chat`)

Chat API for querying SOTA/Benchmark information:
- Simple chat endpoint for quick queries
- Streaming endpoint for long responses
- Supports conversation history for context-aware queries

## Data Models

### SearchResult

```typescript
interface SearchResult {
  id: string;
  title: string;
  abstract: string;
  authors?: string;
  year?: number;
  source: string;
  url: string;
  pdf_url?: string;
  citation_count?: number;
}
```

### BlogTask

```typescript
interface BlogTask {
  id: number;
  task_id: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  title?: string;
  created_at: string;
  completed_at?: string;
}
```

## Security Considerations

1. **Optional Authentication**: Authentication is optional. Some advanced features may require an API Key. Apply at https://scholarclaw.youdao.com/ if needed.

2. **Input Validation**: The backend validates all inputs. Scripts don't perform additional validation.

3. **Rate Limiting**: Not implemented. Consider adding rate limits for production.

4. **CORS**: The server allows all origins (`allow_origins=["*"]`). Restrict in production.

## Performance

### Caching

The backend services implement caching for:
- Search results (Redis/memory)
- Citation data
- Paper metadata

### Timeouts

Default timeouts:
- Search: 30 seconds
- Scholar: 60 seconds
- Blog generation: 10 minutes
- SOTA Chat: 2 minutes

## Extending the Skill

### Adding a New Command

1. Create a new script in `scripts/`:

```bash
#!/bin/bash
# scripts/new_command.sh
# ... implementation
```

2. Add the command to `package.json`:

```json
{
  "scripts": {
    "new-command": "scripts/new_command.sh"
  }
}
```

3. Add method to TypeScript client:

```typescript
async newCommand(params: NewCommandParams): Promise<NewCommandResult> {
  return this.request('GET', '/new/endpoint', { params });
}
```

4. Document in `SKILL.md` and `README.md`

### Adding a New Search Engine

1. Add engine to `config.ts`:

```typescript
export const SEARCH_ENGINES = {
  // ...
  NEW_ENGINE: 'new_engine',
} as const;
```

2. Update the backend to support the new engine
3. Test with the search script
