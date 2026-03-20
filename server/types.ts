/**
 * ScholarClaw - Type Definitions
 *
 * TypeScript type definitions for ScholarClaw API requests and responses.
 */

// ============================================================================
// Common Types
// ============================================================================

/**
 * Pagination parameters
 */
export interface PaginationParams {
  page?: number;
  page_size?: number;
  limit?: number;
  offset?: number;
}

/**
 * Paginated response wrapper
 */
export interface PaginatedResponse<T> {
  results: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}

// ============================================================================
// Search Types
// ============================================================================

/**
 * Search request parameters
 */
export interface SearchRequest extends PaginationParams {
  q: string;
  engine?: string;
  freshness?: 'day' | 'week' | 'month';
  with_citations?: boolean;
  mode?: 'simple' | 'ai';
  sort_by?: 'relevance' | 'date';
  return_all?: boolean;
}

/**
 * Search result item
 */
export interface SearchResult {
  id: string;
  arxiv_id?: string;
  pmid?: string;
  title: string;
  abstract: string;
  snippet?: string;
  authors?: string;
  year?: number;
  pub_month?: number;
  published_date?: string;
  source: string;
  url: string;
  pdf_url?: string;
  thumbnail?: string;
  citation_count?: number;
  rerank_score?: number;
  ai_summary?: string;
  ai_keywords?: string[];
}

/**
 * AI mode search response
 */
export interface ScholarClawResponse {
  mode: 'ai';
  results: SearchResult[];
  report?: {
    summary?: string;
    key_findings?: string[];
  };
}

// ============================================================================
// Scholar Search Types
// ============================================================================

/**
 * Scholar search request
 */
export interface ScholarSearchRequest {
  query: string;
  messages?: Array<{ role: string; content: string }>;
  caller_id?: string;
  max_results?: number;
  search_engine?: string;
  enable_citation_expansion?: boolean;
  enable_rerank?: boolean;
}

/**
 * Query analysis result
 */
export interface QueryAnalysis {
  core_question: string;
  keyword_queries: string[];
  semantic_queries: string[];
  required_criteria: string[];
  nice_to_have_criteria: string[];
  time_range: {
    start: string | null;
    end: string | null;
  };
  search_engine: string;
}

/**
 * Scholar search result
 */
export interface ScholarSearchResult extends SearchResult {
  content?: string;
}

/**
 * Scholar search response
 */
export interface ScholarSearchResponse {
  query: string;
  results: ScholarSearchResult[];
  summary: string;
  analysis: QueryAnalysis;
  usage: Record<string, unknown>;
  total_results: number;
}

// ============================================================================
// Citation Types
// ============================================================================

/**
 * Citation statistics
 */
export interface CitationStats {
  arxiv_id: string;
  total_citations: number;
  recent_citations?: number;
  citations_by_year?: Record<string, number>;
}

/**
 * Citation list item
 */
export interface CitationItem extends SearchResult {
  citing_paper_id?: string;
  citation_date?: string;
}

// ============================================================================
// OpenAlex Types
// ============================================================================

/**
 * OpenAlex cited by request
 */
export interface OpenAlexCitedByRequest extends PaginationParams {
  work_id: string;
  sort_by?: 'citation_count' | 'date';
}

/**
 * OpenAlex find and cited by request
 */
export interface OpenAlexFindAndCitedByRequest extends PaginationParams {
  title: string;
  author_name?: string;
  sort_by?: 'citation_count' | 'date';
  fetch_citing_works?: boolean;
}

/**
 * OpenAlex work
 */
export interface OpenAlexWork {
  id: string;
  title: string;
  authors?: string[];
  year?: number;
  citation_count?: number;
  url?: string;
  doi?: string;
}

/**
 * OpenAlex find and cited by response
 */
export interface OpenAlexFindAndCitedByResponse {
  found: boolean;
  paper?: OpenAlexWork;
  work_id?: string;
  total_citations?: number;
  citing_works?: OpenAlexWork[];
}

// ============================================================================
// Blog Types
// ============================================================================

/**
 * Blog submit request
 */
export interface BlogSubmitRequest {
  arxiv_ids?: string;
  files?: File[];
  views_content?: string;
}

/**
 * Blog task
 */
export interface BlogTask {
  id: number;
  task_id: string;
  arxiv_id?: string;
  file_name?: string;
  source_type?: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  title?: string;
  slug?: string;
  created_at: string;
  completed_at?: string;
  progress?: {
    step?: string;
    stage?: string;
    message?: string;
    extra?: Record<string, unknown>;
  };
  outline?: Record<string, unknown>;
  error_message?: string;
}

/**
 * Blog result
 */
export interface BlogResult extends BlogTask {
  markdown_content?: string;
  blog_content?: string;
}

// ============================================================================
// Benchmark Types
// ============================================================================

/**
 * Benchmark submit request
 */
export interface BenchmarkSubmitRequest {
  arxiv_id: string;
  benchmark_name?: string;
  use_llm?: boolean;
  model_name?: string;
  enrich?: boolean;
  max_citations?: number;
  max_papers?: number;
}

/**
 * Benchmark task
 */
export interface BenchmarkTask {
  task_id: string;
  benchmark_name?: string;
  arxiv_id: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  created_at: string;
  started_at?: string;
  completed_at?: string;
  progress?: Record<string, unknown>;
  error?: string;
}

/**
 * Benchmark result
 */
export interface BenchmarkResult {
  benchmark_name: string;
  arxiv_id: string;
  paper_abstract?: string;
  description?: string;
  statistics: {
    total_papers: number;
    total_tasks_checked: number;
    matched_tasks: number;
    papers_with_matches: number;
  };
  all_results: Array<{
    arxiv_id?: string;
    paper_name?: string;
    paper_metadata?: Record<string, unknown>;
    overall_method_summary?: string;
    benchmark_tasks: Array<{
      task_name?: string;
      model_name?: string;
      score?: number;
      model_performance?: Record<string, unknown>;
      supporting_evidence?: string[];
    }>;
  }>;
  benchmark_intro?: {
    title: string;
    subtitle?: string;
    source_url?: string;
    sections: Array<{
      heading: string;
      markdown: string;
    }>;
  };
}

// ============================================================================
// Recommendation Types
// ============================================================================

/**
 * Recommended paper
 */
export interface RecommendedPaper extends SearchResult {
  upvotes?: number;
  github_links?: string[];
  rank?: number;
}

/**
 * GitHub repository
 */
export interface GitHubRepo {
  id: number;
  full_name: string;
  name: string;
  description?: string;
  stars: number;
  forks?: number;
  language?: string;
  url: string;
  topics?: string[];
  updated_at?: string;
}

/**
 * Recommended blog
 */
export interface RecommendedBlog {
  id: number;
  task_id: string;
  title?: string;
  slug?: string;
  status: string;
  created_at: string;
  view_count?: number;
}

// ============================================================================
// Health Check Types
// ============================================================================

/**
 * Health check response
 */
export interface HealthCheckResponse {
  status: 'ok' | 'error';
  service: string;
  version: string;
}

/**
 * Detailed health check response
 */
export interface DetailedHealthCheckResponse extends HealthCheckResponse {
  services: Record<string, 'up' | 'down' | string>;
}
