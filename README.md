# ScholarClaw - Academic Search Skill for LobsterAI

<div align="center">
  <img src="scholarclaw.png" alt="ScholarClaw Logo" width="400">

  [**Try it Online →**](https://scholarclaw.youdao.com/)

  English · [中文](README_CN.md)
</div>

---

**ScholarClaw** is a comprehensive academic search skill for LobsterAI/OpenClaw, providing intelligent search capabilities across multiple academic databases, citation tracking, paper blog generation, and SOTA benchmark analysis.

Built by **NetEase Youdao**, it integrates seamlessly with the LobsterAI agent framework to help researchers and students discover, analyze, and understand academic literature.

## Key Features

- **Unified Search** — Search across ArXiv, PubMed, OpenAlex, NeurIPS, CVF, and more
- **Scholar Search** — AI-powered academic search with query analysis and reranking
- **Citation Analysis** — Track citations and discover related work
- **Blog Generation** — Generate blog articles from academic papers
- **SOTA Chat** — Query benchmark/SOTA results via natural language
- **Recommendations** — Get trending papers and GitHub repositories

## When to Use

| Trigger Phrase | Example |
|----------------|---------|
| Academic Search | "Search papers about transformers on ArXiv" |
| SOTA/Benchmark | "What's the SOTA for MMLU benchmark?" |
| Citations | "Who cited this paper?" |
| Paper Analysis | "Generate a blog from this paper" |
| Recommendations | "Show me trending ML papers" |

## Quick Start

### Prerequisites

- LobsterAI or OpenClaw installed
- Node.js 16+ (for TypeScript client)
- curl & jq (for shell scripts)

### Installation

**Method 1: Natural Language (Recommended)**

```
"Install the skill from https://github.com/netease-youdao/scholarclaw"
```

**Method 2: Manual Installation**

```bash
# Clone the repository
git clone https://github.com/netease-youdao/scholarclaw.git

# Copy skill to LobsterAI skills directory
cp -r scholarclaw/skills/scholarclaw /path/to/lobsterai/SKILLs/
```

### Configuration

```yaml
# In LobsterAI config.yaml
skills:
  - name: scholarclaw
    enabled: true
    config:
      serverUrl: "https://scholarclaw.youdao.com"
      apiKey: "your-api-key"  # Optional, apply at https://scholarclaw.youdao.com/
```

Or via environment variables:

```bash
export SCHOLARCLAW_SERVER_URL="https://scholarclaw.youdao.com"
export SCHOLARCLAW_API_KEY="your-api-key"  # Optional, apply at https://scholarclaw.youdao.com/
```

## Usage Examples

### Search Papers

```bash
# Search ArXiv
./scripts/search.sh -q "transformer attention" -e arxiv -l 20

# Scholar search with AI analysis
./scripts/scholar.sh -q "What are the latest advances in multimodal learning?"
```

### Citation Analysis

```bash
# Get citation statistics
./scripts/citations_stats.sh -i 1706.03762

# List citing papers
./scripts/citations.sh -i 1706.03762 -p 1 -ps 20
```

### Blog Generation

```bash
# Generate blog from paper
./scripts/blog_submit.sh -i 2303.14535

# Check status and get result
./scripts/blog_status.sh -i blog_xxxxxxxxxxxx
./scripts/blog_result.sh -i blog_xxxxxxxxxxxx -o blog.md
```

### SOTA Queries

```bash
# Ask about benchmarks
./scripts/benchmark_chat.sh -m "What is the SOTA for MMLU benchmark?"

# Streaming mode for long responses
./scripts/benchmark_chat.sh -m "Compare GPT-4 and Claude on various benchmarks" -s
```

## Supported Search Engines

| Engine | Description |
|--------|-------------|
| `arxiv` | ArXiv preprint server |
| `pubmed` | PubMed biomedical literature |
| `google` | Google Search (via SerpDev) |
| `kuake` | Kuake search (Chinese) |
| `bocha` | Bocha AI search |
| `nips` | NeurIPS papers |
| `thecvf` | CVF/CVPR papers |
| `mlr_press` | MLR Press papers |
| `openalex` | OpenAlex academic database |

## API Reference

### Search Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/search` | GET | Unified search across engines |
| `/scholar/search` | POST | AI-powered academic search |

### Citation Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/citations` | GET | List citing papers |
| `/citations/stats` | GET | Citation statistics |
| `/openalex/cited_by` | GET | OpenAlex citations |

### Content Generation

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/blog/submit` | POST | Submit blog task |
| `/api/blog/result/{id}` | GET | Get blog result |

### SOTA Chat

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/benchmark/chat` | POST | SOTA chat |
| `/api/benchmark/chat/stream` | POST | SOTA chat (streaming) |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SCHOLARCLAW_SERVER_URL` | `https://scholarclaw.youdao.com` | API server URL |
| `SCHOLARCLAW_API_KEY` | - | API Key (optional, apply at https://scholarclaw.youdao.com/) |
| `SCHOLARCLAW_DEBUG` | `false` | Enable debug logging |

### Configuration Priority

1. Explicit overrides in code
2. Environment variables
3. LobsterAI skill config
4. Default values

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | TypeScript |
| Runtime | Node.js 16+ |
| HTTP | fetch API |
| Config | YAML / Environment |

## Directory Structure

```
skills/scholarclaw/
├── server/                 # TypeScript client
│   ├── index.ts           # Main entry
│   ├── client.ts          # HTTP client
│   ├── config.ts          # Configuration
│   └── types.ts           # Type definitions
├── scripts/               # Shell scripts
│   ├── search.sh          # Unified search
│   ├── scholar.sh         # Scholar search
│   ├── citations.sh       # Citation queries
│   ├── blog_submit.sh     # Blog generation
│   └── ...
├── examples/              # Usage examples
├── SKILL.md               # Skill definition
├── README.md              # English docs
└── README_CN.md           # Chinese docs
```

## Contact

- **Email**: scholarclaw@rd.netease.com
- **WeChat Group**: Scan the QR code below to join the ScholarClaw community

<div align="center">
  <img src="group.jpg" alt="WeChat Group QR Code" width="300">
</div>

## License

MIT License

---

Built and maintained by **NetEase Youdao**.
