# Basic Search Examples

This document demonstrates basic search usage with the ScholarClaw skill.

## Simple Search

### Search ArXiv

```bash
# Basic arXiv search
./scripts/search.sh -q "attention mechanism" -e arxiv -l 20
```

Response:
```json
{
  "results": [
    {
      "id": "1706.03762",
      "title": "Attention Is All You Need",
      "abstract": "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks...",
      "authors": "Ashish Vaswani, Noam Shazeer, Niki Parmar, Jakob Uszkoreit, Llion Jones, Aidan N. Gomez, Lukasz Kaiser, Illia Polosukhin",
      "year": 2017,
      "source": "arxiv",
      "url": "https://arxiv.org/abs/1706.03762",
      "pdf_url": "https://arxiv.org/pdf/1706.03762.pdf",
      "citation_count": 50000
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 20,
  "total_pages": 5,
  "has_next": true
}
```

### Search PubMed

```bash
# Search biomedical literature
./scripts/search.sh -q "COVID-19 vaccine efficacy" -e pubmed -l 20
```

### Search Google (via SerpDev)

```bash
# Web search
./scripts/search.sh -q "latest AI developments 2024" -e google -l 10
```

## Pagination

```bash
# Get page 2 of results
./scripts/search.sh -q "transformer" -e arxiv -p 2 -ps 10

# Get all results without pagination wrapper
./scripts/search.sh -q "GPT" -e arxiv --return-all
```

## Filters

### Freshness Filter

```bash
# Papers from the last week
./scripts/search.sh -q "large language models" -e google --freshness week

# Papers from the last month
./scripts/search.sh -q "machine learning" -e google --freshness month
```

### Sort Options

```bash
# Sort by date (newest first)
./scripts/search.sh -q "neural networks" -e arxiv --sort-by date

# Sort by relevance (default)
./scripts/search.sh -q "neural networks" -e arxiv --sort-by relevance
```

## AI Mode

AI mode provides enhanced search with:
- Automatic query expansion
- AI-generated summary
- Key findings extraction

```bash
# Search with AI mode
./scripts/search.sh -q "vision transformers for image classification" -e arxiv --mode ai -l 20
```

AI Mode Response:
```json
{
  "mode": "ai",
  "results": [...],
  "report": {
    "summary": "Vision Transformers (ViT) have revolutionized image classification...",
    "key_findings": [
      "ViT achieves state-of-the-art results on ImageNet",
      "Patch-based processing enables handling variable resolution images",
      "Pre-training on large datasets is crucial for performance"
    ]
  }
}
```

## TypeScript Client Examples

### Basic Search

```typescript
import { ScholarClawClient } from './server';

const client = new ScholarClawClient();

// Simple search
const results = await client.search('attention mechanism', {
  engine: 'arxiv',
  limit: 20,
});

console.log(`Found ${results.total} results`);
results.results.forEach(paper => {
  console.log(`- ${paper.title} (${paper.year})`);
});
```

### AI Mode Search

```typescript
// AI mode search
const aiResults = await client.search('vision transformers', {
  engine: 'arxiv',
  mode: 'ai',
  limit: 20,
});

if ('report' in aiResults && aiResults.report) {
  console.log('Summary:', aiResults.report.summary);
  console.log('Key Findings:', aiResults.report.key_findings);
}
```

### Paginated Search

```typescript
// Fetch all pages
let allPapers = [];
let page = 1;
const pageSize = 50;

while (true) {
  const response = await client.search('machine learning', {
    engine: 'arxiv',
    page,
    pageSize,
    limit: 500,
  });

  if ('results' in response) {
    allPapers.push(...response.results);

    if (!response.has_next) break;
    page++;
  } else {
    break;
  }
}

console.log(`Fetched ${allPapers.length} papers`);
```

### Error Handling

```typescript
import { ScholarClawClient, ScholarClawError } from './server';

const client = new ScholarClawClient();

try {
  const results = await client.search('query', { engine: 'arxiv' });
} catch (error) {
  if (error instanceof ScholarClawError) {
    console.error(`API Error (${error.statusCode}): ${error.message}`);
    console.error('Details:', error.details);
  } else {
    console.error('Unknown error:', error);
  }
}
```

## Common Use Cases

### Literature Review

```bash
# Find recent papers on a topic
./scripts/search.sh -q "prompt engineering" -e arxiv --sort-by date -l 50
```

### Author Search

```bash
# Search for papers by author
./scripts/search.sh -q "author:Hinton" -e arxiv -l 20
```

### Topic Exploration

```bash
# Broad search with AI analysis
./scripts/search.sh -q "quantum machine learning applications" -e arxiv --mode ai -l 30
```
