# SOTA Chat Examples

ScholarClaw SOTA Chat allows you to query benchmark/SOTA results via natural language.

## Basic Queries

### Query Specific Benchmark

```bash
# What's the SOTA for a specific benchmark?
./scripts/benchmark_chat.sh -m "What is the SOTA for MMLU benchmark?"
```

Response:
```json
{
  "response": "The current SOTA for MMLU is...",
  "tool_calls": [...]
}
```

### Compare Models on Benchmarks

```bash
./scripts/benchmark_chat.sh -m "Compare GPT-4, Claude and Gemini on MMLU, GPQA and HumanEval benchmarks"
```

### Latest Results for a Benchmark

```bash
./scripts/benchmark_chat.sh -m "BrowseComp benchmark latest results, which models perform best?"
```

## Benchmark Discovery

### Find Benchmarks by Topic

```bash
# Multi-document QA benchmarks
./scripts/benchmark_chat.sh -m "最近有哪些多文档问答的benchmark？"

# Reasoning benchmarks
./scripts/benchmark_chat.sh -m "What are the main reasoning benchmarks and their latest SOTA?"

# Code generation benchmarks
./scripts/benchmark_chat.sh -m "List the major code generation benchmarks and top performing models"
```

### Explore a Research Area

```bash
# Multimodal benchmarks
./scripts/benchmark_chat.sh -m "What benchmarks are used to evaluate multimodal LLMs? Which models lead?"

# Math reasoning
./scripts/benchmark_chat.sh -m "MATH和GSM8K这两个数学推理benchmark上，目前哪些模型表现最好？"

# Agent capabilities
./scripts/benchmark_chat.sh -m "有哪些评估AI Agent能力的benchmark？最新的结果如何？"
```

## Conversation with History

### Multi-turn Conversation

```bash
# First question
./scripts/benchmark_chat.sh -m "Tell me about the MMLU benchmark"

# Follow-up with history
./scripts/benchmark_chat.sh -m "How does Claude perform on it?" \
  -H '[{"role":"user","content":"Tell me about the MMLU benchmark"},{"role":"assistant","content":"MMLU (Massive Multitask Language Understanding) is..."}]'

# Further follow-up
./scripts/benchmark_chat.sh -m "What about GPQA?" \
  -H '[{"role":"user","content":"Tell me about MMLU"},{"role":"assistant","content":"MMLU is..."},{"role":"user","content":"How does Claude perform on it?"},{"role":"assistant","content":"Claude scores..."}]'
```

## Streaming Mode

For long or detailed responses, use streaming mode:

```bash
# Streaming mode for comprehensive answers
./scripts/benchmark_chat.sh -m "Give me a comprehensive overview of all major LLM benchmarks in 2024-2025" -s

# Save streaming output to file
./scripts/benchmark_chat.sh -m "List all SOTA results for reasoning benchmarks" -s -o reasoning_sota.json
```

## Example Questions (Chinese)

```bash
# 查询特定 benchmark
./scripts/benchmark_chat.sh -m "MMLU benchmark 的 SOTA 是多少？"

# 发现新 benchmark
./scripts/benchmark_chat.sh -m "最近有哪些多文档问答的benchmark？"

# 模型对比
./scripts/benchmark_chat.sh -m "对比 GPT-4o 和 Claude 在各项 benchmark 上的表现"

# 特定领域
./scripts/benchmark_chat.sh -m "视觉语言模型在哪些benchmark上评测？最新SOTA是什么？"

# 趋势分析
./scripts/benchmark_chat.sh -m "2024-2025年新出的AI benchmark有哪些？主要评估什么能力？"
```

## Example Questions (English)

```bash
# Specific benchmark results
./scripts/benchmark_chat.sh -m "What is the current SOTA on HumanEval and MBPP?"

# Model comparison
./scripts/benchmark_chat.sh -m "How do frontier models compare on GPQA Diamond?"

# Benchmark discovery
./scripts/benchmark_chat.sh -m "What benchmarks exist for evaluating long-context capabilities?"

# Trend analysis
./scripts/benchmark_chat.sh -m "Which models have shown the biggest improvements on math reasoning benchmarks recently?"
```

## Tips

1. **Be specific**: Include benchmark names when possible for more precise answers
2. **Use streaming for long answers**: `-s` flag helps with comprehensive queries
3. **Conversation history**: Use `-H` for multi-turn conversations to maintain context
4. **Bilingual support**: Questions can be asked in both Chinese and English
5. **Timeout**: Default is 120s, increase with `-t 180` for complex queries
