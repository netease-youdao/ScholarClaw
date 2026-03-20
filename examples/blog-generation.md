# Blog Generation Examples

The ScholarClaw skill can generate blog articles from academic papers.

## How It Works

1. **Submit**: Provide an ArXiv ID or upload a PDF
2. **Process**: The system parses the paper and generates a blog article
3. **Poll**: Check the task status until completion
4. **Retrieve**: Get the generated blog content

## Basic Usage

### Submit by ArXiv ID

```bash
# Submit a paper by ArXiv ID
./scripts/blog_submit.sh -i 2303.14535
```

Response:
```json
{
  "task_id": "blog_abc123def456",
  "status": "pending",
  "message": "任务已提交，正在后台处理中"
}
```

### Submit with User Views

Add your own perspectives or focus areas:

```bash
./scripts/blog_submit.sh -i 2303.14535 -v "Focus on the practical applications and limitations"
```

### Submit Multiple Papers

```bash
# Multiple ArXiv IDs (comma-separated)
./scripts/blog_submit.sh -i "2303.14535,1706.03762"
```

### Upload PDF

```bash
# Upload a local PDF file
./scripts/blog_submit.sh -f paper.pdf

# Upload multiple files
./scripts/blog_submit.sh -f paper.pdf -f supplementary.pdf
```

## Check Status

### Check Single Task

```bash
./scripts/blog_status.sh -i blog_abc123def456
```

Response:
```json
{
  "task_id": "blog_abc123def456",
  "status": "running",
  "progress": {
    "step": "generate",
    "stage": "processing",
    "message": "正在生成报告..."
  },
  "created_at": "2024-01-15T10:30:00"
}
```

### List All Tasks

```bash
# List all tasks
./scripts/blog_status.sh

# Filter by status
./scripts/blog_status.sh -s completed -l 20
```

## Get Result

### Get Full Result

```bash
./scripts/blog_result.sh -i blog_abc123def456
```

Response:
```json
{
  "task_id": "blog_abc123def456",
  "status": "completed",
  "title": "Understanding the Paper Title",
  "blog_content": "# Paper Title\n\n## Introduction\n...",
  "created_at": "2024-01-15T10:30:00",
  "completed_at": "2024-01-15T10:35:00"
}
```

### Get Content Only

```bash
# Output only the blog content
./scripts/blog_result.sh -i blog_abc123def456 --content-only
```

### Save to File

```bash
# Save blog to a file
./scripts/blog_result.sh -i blog_abc123def456 -o blog.md
```

## TypeScript Client Examples

### Submit and Wait for Completion

```typescript
import { ScholarClawClient } from './server';

const client = new ScholarClawClient();

// Submit blog task
const { task_id } = await client.submitBlog('2303.14535');
console.log(`Task submitted: ${task_id}`);

// Poll for completion
let task = await client.getBlogTask(task_id);
while (task.status === 'pending' || task.status === 'running') {
  console.log(`Status: ${task.status} - ${task.progress?.message}`);
  await new Promise(resolve => setTimeout(resolve, 5000));
  task = await client.getBlogTask(task_id);
}

if (task.status === 'completed') {
  const result = await client.getBlogResult(task_id);
  console.log('Title:', result.title);
  console.log('Content length:', result.blog_content?.length);
}
```

### With Custom Views

```typescript
const { task_id } = await client.submitBlog(
  '2303.14535',
  'Focus on the methodology and experimental results. Include practical implications.'
);
```

### List and Process Completed Blogs

```typescript
const { tasks } = await client.listBlogTasks({ status: 'completed', limit: 10 });

for (const task of tasks) {
  const result = await client.getBlogResult(task.task_id);
  console.log(`${task.title}: ${result.blog_content?.length} characters`);
}
```

## Task Statuses

| Status | Description |
|--------|-------------|
| `pending` | Task is queued |
| `running` | Task is being processed |
| `completed` | Blog is ready |
| `failed` | Task failed (check error_message) |

## Processing Time

Blog generation typically takes 2-5 minutes depending on:
- Paper length
- Number of figures/tables
- Server load

## Example Workflow

```bash
# 1. Submit the task
TASK_ID=$(./scripts/blog_submit.sh -i 2303.14535 | jq -r '.task_id')
echo "Task ID: $TASK_ID"

# 2. Wait for completion
while true; do
  STATUS=$(./scripts/blog_status.sh -i "$TASK_ID" | jq -r '.status')
  echo "Status: $STATUS"

  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
    break
  fi

  sleep 10
done

# 3. Get the result
if [ "$STATUS" = "completed" ]; then
  ./scripts/blog_result.sh -i "$TASK_ID" -o blog.md
  echo "Blog saved to blog.md"
fi
```

## Supported Paper Formats

- ArXiv papers (via ID or URL)
- PDF files (uploaded)
- Multiple papers (combined into one blog)

## Tips

1. **Provide context**: Use `--views` to guide the blog focus
2. **Check progress**: Use the status endpoint to monitor progress
3. **Be patient**: Large papers take longer to process
4. **Review output**: The AI-generated content may need editing
