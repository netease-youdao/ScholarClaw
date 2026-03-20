# Test Documentation

This document describes how to test ScholarClaw.

## Prerequisites

1. The unified_search_server.py must be running
2. Backend services should be available
3. curl and jq installed

## Quick Health Check

```bash
# Basic health check
./scripts/health.sh

# Detailed health check
./scripts/health.sh -v
```

## Test Cases

### 1. Search Tests

#### Basic Search

```bash
# Test arXiv search
./scripts/search.sh -q "transformer" -e arxiv -l 5

# Expected: JSON array of search results
```

#### AI Mode Search

```bash
# Test AI mode
./scripts/search.sh -q "machine learning" -e arxiv --mode ai -l 5

# Expected: JSON with "mode": "ai", "results", and "report" fields
```

#### Pagination

```bash
# Test pagination
./scripts/search.sh -q "deep learning" -e arxiv -p 1 -ps 5

# Expected: Paginated response with "page", "total_pages", "has_next"
```

### 2. Scholar Search Tests

#### Basic Scholar Search

```bash
./scripts/scholar.sh -q "What are the latest advances in vision transformers?"

# Expected: JSON with "results", "summary", "analysis"
```

#### Query Analysis Only

```bash
./scripts/scholar.sh -q "transformer efficiency" --analyze-only

# Expected: JSON with "core_question", "keyword_queries", etc.
```

### 3. Citation Tests

#### Citation Statistics

```bash
# Test citation stats (use a well-known paper)
./scripts/citations_stats.sh -i 1706.03762

# Expected: JSON with citation count statistics
```

#### Citation List

```bash
# Test citation list
./scripts/citations.sh -i 1706.03762 -p 1 -ps 10

# Expected: Array of citing papers
```

### 4. OpenAlex Tests

#### Find and Cited By

```bash
./scripts/openalex_find.sh -t "Attention Is All You Need" --fetch-works

# Expected: JSON with "found", "paper", "total_citations", "citing_works"
```

### 5. Blog Tests

#### Submit Blog Task

```bash
# Submit a blog task
./scripts/blog_submit.sh -i 2303.14535

# Expected: JSON with "task_id" and "status"
```

#### Check Blog Status

```bash
# Replace with actual task_id from previous step
./scripts/blog_status.sh -i blog_xxxxxxxxxxxx

# Expected: JSON with task status and progress
```

#### List Blog Tasks

```bash
./scripts/blog_status.sh -s completed -l 10

# Expected: JSON with "tasks" array
```

### 6. SOTA Chat Tests

#### Simple Chat

```bash
./scripts/benchmark_chat.sh -m "What is the SOTA for MMLU benchmark?"

# Expected: JSON with "response" and optional "tool_calls"
```

#### Chat with History

```bash
./scripts/benchmark_chat.sh -m "What about GPQA?" -H '[{"role":"user","content":"Tell me about MMLU"}]'

# Expected: JSON with contextual response
```

#### Streaming Chat

```bash
./scripts/benchmark_chat.sh -m "List recent SOTA results" -s

# Expected: SSE stream with events
```

### 7. Recommendation Tests

#### Trending Papers

```bash
./scripts/recommend_papers.sh -l 10

# Expected: Array of trending papers with "upvotes", "github_links"
```

#### Recommended Blogs

```bash
./scripts/recommend_blogs.sh -l 10

# Expected: JSON with "blogs" array
```

#### Paper Repos

```bash
./scripts/paper_repos.sh -i 2303.14535

# Expected: JSON with "repos" array
```

## TypeScript Client Tests

### Setup

```bash
cd skills/scholarclaw
npm install
```

### Test Script

Create a test file `test-client.ts`:

```typescript
import { ScholarClawClient, ScholarClawError } from './server';

const client = new ScholarClawClient({
  serverUrl: process.env.SCHOLARCLAW_SERVER_URL || 'https://scholarclaw.youdao.com',
});

async function runTests() {
  console.log('Running ScholarClaw Client Tests...\n');

  // Test 1: Health check
  console.log('Test 1: Health Check');
  try {
    const health = await client.health();
    console.log('✓ Health check passed:', health);
  } catch (error) {
    console.log('✗ Health check failed:', error);
  }

  // Test 2: Search
  console.log('\nTest 2: Search');
  try {
    const results = await client.search('transformer', {
      engine: 'arxiv',
      limit: 5,
    });
    console.log('✓ Search passed, results:', Array.isArray(results) ? results.length : 'paginated');
  } catch (error) {
    console.log('✗ Search failed:', error);
  }

  // Test 3: Scholar search
  console.log('\nTest 3: Scholar Search');
  try {
    const scholar = await client.scholarSearch({
      query: 'vision transformers',
      max_results: 5,
    });
    console.log('✓ Scholar search passed, results:', scholar.total_results);
  } catch (error) {
    console.log('✗ Scholar search failed:', error);
  }

  // Test 4: Recommendations
  console.log('\nTest 4: Recommendations');
  try {
    const papers = await client.getRecommendedPapers(5);
    console.log('✓ Recommendations passed, papers:', papers.length);
  } catch (error) {
    console.log('✗ Recommendations failed:', error);
  }

  console.log('\nTests completed!');
}

runTests().catch(console.error);
```

Run tests:

```bash
npx ts-node test-client.ts
```

## Error Handling Tests

### Invalid Search Engine

```bash
./scripts/search.sh -q "test" -e invalid_engine

# Expected: Error message about invalid engine
```

### Missing Required Parameters

```bash
./scripts/search.sh

# Expected: Error message about missing query
```

### Invalid ArXiv ID

```bash
./scripts/citations.sh -i invalid_id

# Expected: Error or empty results
```

## Performance Tests

### Response Time

```bash
# Measure search response time
time ./scripts/search.sh -q "machine learning" -e arxiv -l 100

# Measure scholar search response time
time ./scripts/scholar.sh -q "transformer architecture" -m 20
```

### Concurrent Requests

```bash
# Run multiple searches in parallel
for i in {1..10}; do
  ./scripts/search.sh -q "test$i" -e arxiv -l 5 &
done
wait
```

## Continuous Integration

Add to CI pipeline:

```yaml
# .github/workflows/test.yml
name: Test ScholarClaw Skill

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start server
        run: |
          python unified_search_server.py &
          sleep 5

      - name: Run health check
        run: ./skills/scholarclaw/scripts/health.sh

      - name: Run search test
        run: ./skills/scholarclaw/scripts/search.sh -q "test" -e arxiv -l 5
```
