# Scholar Search Examples

Scholar Search provides AI-powered academic search with intelligent query analysis, citation expansion, and reranking.

## How It Works

1. **Query Analysis**: AI extracts the core question and generates optimized search queries
2. **Multi-source Search**: Searches across multiple academic databases
3. **Citation Expansion**: Finds related papers through citation networks
4. **Reranking**: Uses semantic similarity to rank results
5. **Summary Generation**: Provides an AI-generated summary of findings

## Basic Usage

### Simple Question

```bash
./scripts/scholar.sh -q "What are the latest advances in multimodal learning?"
```

Response:
```json
{
  "query": "What are the latest advances in multimodal learning?",
  "results": [
    {
      "title": "Paper Title",
      "abstract": "Abstract...",
      "url": "https://arxiv.org/abs/...",
      "authors": "Author 1, Author 2",
      "year": 2024,
      "source": "arxiv",
      "rerank_score": 0.95,
      "citation_count": 150
    }
  ],
  "summary": "Recent advances in multimodal learning include...",
  "analysis": {
    "core_question": "What are the recent developments in multimodal machine learning?",
    "keyword_queries": ["multimodal learning", "vision language models", "cross-modal"],
    "semantic_queries": ["combining different data modalities", "joint representation learning"],
    "required_criteria": ["published after 2022", "peer-reviewed"],
    "search_engine": "arxiv"
  },
  "total_results": 20
}
```

### Specify Search Engine

```bash
# Search PubMed for biomedical questions
./scripts/scholar.sh -q "What are the mechanisms of mRNA vaccines?" -e pubmed
```

### Limit Results

```bash
# Get top 10 results
./scripts/scholar.sh -q "transformer efficiency improvements" -m 10
```

## Query Analysis Only

Get the AI's analysis of your query without executing the search:

```bash
./scripts/scholar.sh -q "How do vision transformers compare to CNNs?" --analyze-only
```

Response:
```json
{
  "core_question": "What is the comparative performance of vision transformers versus convolutional neural networks?",
  "keyword_queries": [
    "vision transformer vs CNN",
    "ViT comparison CNN",
    "transformer convolutional benchmark"
  ],
  "semantic_queries": [
    "comparing self-attention to convolution for image recognition",
    "when to use transformers over CNNs for computer vision"
  ],
  "required_criteria": [
    "comparative study",
    "benchmark results"
  ],
  "nice_to_have_criteria": [
    "ImageNet evaluation",
    "computational cost analysis"
  ],
  "time_range": {
    "start": "2020",
    "end": null
  },
  "search_engine": "arxiv"
}
```

## Conversation Context

Provide conversation history for contextual search:

```bash
./scripts/scholar.sh \
  -q "What about their computational efficiency?" \
  -c '[{"role":"user","content":"Tell me about vision transformers"},{"role":"assistant","content":"Vision Transformers (ViT) apply transformer architecture to image patches..."}]'
```

## TypeScript Client Examples

### Basic Scholar Search

```typescript
import { ScholarClawClient } from './server';

const client = new ScholarClawClient();

const result = await client.scholarSearch({
  query: 'What are the best practices for fine-tuning LLMs?',
  max_results: 15,
  enable_citation_expansion: true,
  enable_rerank: true,
});

console.log('Summary:', result.summary);
console.log('Results:', result.results.length);

result.results.forEach(paper => {
  console.log(`- ${paper.title} (score: ${paper.rerank_score})`);
});
```

### Query Analysis

```typescript
// Analyze query without searching
const analysis = await client.analyzeQuery(
  'How does reinforcement learning from human feedback work?'
);

console.log('Core Question:', analysis.core_question);
console.log('Keywords:', analysis.keyword_queries);
console.log('Semantic:', analysis.semantic_queries);
```

### With Context

```typescript
const result = await client.scholarSearch({
  query: 'What are the scaling laws?',
  messages: [
    { role: 'user', content: 'Tell me about GPT models' },
    { role: 'assistant', content: 'GPT models are large language models...' },
  ],
  max_results: 10,
});
```

## Advanced Options

### Disable Citation Expansion

```bash
# Faster search without citation expansion
./scripts/scholar.sh -q "machine learning" --no-citation-expansion
```

### Disable Reranking

```bash
# Get raw search results without semantic reranking
./scripts/scholar.sh -q "deep learning" --no-rerank
```

## Use Cases

### Literature Review

```bash
# Comprehensive search for literature review
./scripts/scholar.sh -q "What is the state of the art in neural machine translation?" -m 30
```

### Research Question Exploration

```bash
# Explore a research question
./scripts/scholar.sh -q "How do large language models handle reasoning tasks?"
```

### Finding Related Work

```bash
# Use citation expansion to find related papers
./scripts/scholar.sh -q "Papers related to attention mechanisms in transformers"
```

### Quick Topic Overview

```bash
# Get a quick overview with AI summary
./scripts/scholar.sh -q "Explain retrieval-augmented generation (RAG)" -m 10
```
