/**
 * ScholarClaw - HTTP API Client
 *
 * TypeScript client for the ScholarClaw academic search service.
 */

import type {
  ScholarClawConfig,
  SearchEngine,
  SearchMode,
} from './config';
import { defaultConfig, SEARCH_ENGINES, SEARCH_MODES, SORT_OPTIONS } from './config';
import type {
  SearchResult,
  ScholarClawResponse,
  PaginatedResponse,
  ScholarSearchRequest,
  ScholarSearchResponse,
  QueryAnalysis,
  CitationStats,
  CitationItem,
  OpenAlexCitedByRequest,
  OpenAlexFindAndCitedByRequest,
  OpenAlexFindAndCitedByResponse,
  BlogTask,
  BlogResult,
  BenchmarkTask,
  BenchmarkResult,
  RecommendedPaper,
  GitHubRepo,
  RecommendedBlog,
  HealthCheckResponse,
  DetailedHealthCheckResponse,
} from './types';

/**
 * ScholarClaw API Client
 */
export class ScholarClawClient {
  private config: ScholarClawConfig;

  constructor(config?: Partial<ScholarClawConfig>) {
    this.config = { ...defaultConfig, ...config };
  }

  private get baseUrl(): string {
    return this.config.serverUrl.replace(/\/$/, '');
  }

  private async request<T>(
    method: string,
    path: string,
    options?: {
      params?: Record<string, unknown>;
      body?: Record<string, unknown>;
      timeout?: number;
    }
  ): Promise<T> {
    const url = new URL(`${this.baseUrl}${path}`);

    if (options?.params) {
      Object.entries(options.params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          url.searchParams.append(key, String(value));
        }
      });
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };

    if (this.config.apiKey) {
      headers['X-API-Key'] = this.config.apiKey;
    }

    const fetchOptions: RequestInit = {
      method,
      headers,
    };

    if (options?.body) {
      fetchOptions.body = JSON.stringify(options.body);
    }

    const timeout = options?.timeout || this.config.timeout;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    fetchOptions.signal = controller.signal;

    try {
      const response = await fetch(url.toString(), fetchOptions);

      if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: response.statusText }));
        const detail = error.detail || `HTTP ${response.status}`;

        if (ScholarClawClient.isAuthError(response.status, detail)) {
          throw new ScholarClawError(
            '已超出匿名用户使用额度，需要 API Key 才能继续使用。请前往 https://scholarclaw.youdao.com/ 申请 API Key，然后通过以下方式配置：\n' +
            '  1. 设置环境变量: SCHOLARCLAW_API_KEY\n' +
            '  2. 添加到 OpenClaw config.yaml: apiKey\n' +
            '  3. 创建配置文件: ~/.scholarclaw/config.json',
            response.status,
            error
          );
        }

        throw new ScholarClawError(detail, response.status, error);
      }

      return response.json();
    } catch (error) {
      if (error instanceof ScholarClawError) {
        throw error;
      }
      if (error instanceof Error && error.name === 'AbortError') {
        throw new ScholarClawError('Request timeout', 408, {});
      }
      throw new ScholarClawError(
        error instanceof Error ? error.message : 'Unknown error',
        0,
        {}
      );
    } finally {
      clearTimeout(timeoutId);
    }
  }

  // ==========================================================================
  // Health Check
  // ==========================================================================

  /**
   * Check service health
   */
  async health(): Promise<HealthCheckResponse> {
    return this.request<HealthCheckResponse>('GET', '/health');
  }

  /**
   * Detailed health check with backend services status
   */
  async healthDetailed(): Promise<DetailedHealthCheckResponse> {
    return this.request<DetailedHealthCheckResponse>('GET', '/search/health');
  }

  // ==========================================================================
  // Search
  // ==========================================================================

  /**
   * Unified search across multiple engines
   */
  async search(
    query: string,
    options?: {
      engine?: SearchEngine;
      limit?: number;
      page?: number;
      pageSize?: number;
      /** Time range preset: week, month, year, custom */
      timeRange?: 'week' | 'month' | 'year' | 'custom';
      /** Custom start date (YYYY-MM-DD), used with timeRange=custom */
      startDate?: string;
      /** Custom end date (YYYY-MM-DD), used with timeRange=custom */
      endDate?: string;
      /** @deprecated Use timeRange instead */
      freshness?: 'day' | 'week' | 'month';
      mode?: SearchMode;
      sortBy?: 'relevance' | 'date';
      withCitations?: boolean;
      returnAll?: boolean;
    }
  ): Promise<PaginatedResponse<SearchResult> | SearchResult[] | ScholarClawResponse> {
    const params: Record<string, unknown> = {
      q: query,
      engine: options?.engine || SEARCH_ENGINES.BOCHA,
      limit: options?.limit || 100,
      page: options?.page || 1,
      page_size: options?.pageSize || 10,
      mode: options?.mode || SEARCH_MODES.SIMPLE,
      sort_by: options?.sortBy || SORT_OPTIONS.RELEVANCE,
      with_citations: options?.withCitations ?? true,
      return_all: options?.returnAll ?? false,
    };

    // Handle time range parameters
    if (options?.timeRange) {
      params.time_range = options.timeRange;
      if (options.startDate) {
        params.start_date = options.startDate;
      }
      if (options.endDate) {
        params.end_date = options.endDate;
      }
    } else if (options?.freshness) {
      // Backward compatibility: convert freshness to time_range
      // 'day' maps to 'week' as the closest preset
      params.time_range = options.freshness === 'day' ? 'week' : options.freshness;
    }

    return this.request('GET', '/search', { params });
  }

  // ==========================================================================
  // Scholar Search
  // ==========================================================================

  /**
   * Intelligent academic search with query analysis
   */
  async scholarSearch(request: ScholarSearchRequest): Promise<ScholarSearchResponse> {
    return this.request('POST', '/scholar/search', { body: request as unknown as Record<string, unknown> });
  }

  /**
   * Analyze query without searching
   */
  async analyzeQuery(query: string, messages?: Array<{ role: string; content: string }>): Promise<QueryAnalysis> {
    return this.request('POST', '/scholar/analyze', {
      body: { query, messages },
    });
  }

  // ==========================================================================
  // Citations
  // ==========================================================================

  /**
   * Get citation statistics for an ArXiv paper
   */
  async getCitationStats(arxivId: string): Promise<CitationStats> {
    return this.request('GET', '/citations/stats', {
      params: { arxiv_id: arxivId },
    });
  }

  /**
   * List papers citing an ArXiv paper
   */
  async getCitations(
    arxivId: string,
    options?: {
      page?: number;
      pageSize?: number;
      sortBy?: 'citation_count' | 'date';
    }
  ): Promise<CitationItem[]> {
    return this.request('GET', '/citations', {
      params: {
        arxiv_id: arxivId,
        page: options?.page || 1,
        page_size: options?.pageSize || 20,
        sort_by: options?.sortBy || SORT_OPTIONS.CITATION_COUNT,
      },
    });
  }

  // ==========================================================================
  // OpenAlex
  // ==========================================================================

  /**
   * Get papers citing an OpenAlex work
   */
  async getOpenAlexCitedBy(request: OpenAlexCitedByRequest): Promise<unknown> {
    return this.request('GET', '/openalex/cited_by', {
      params: request as unknown as Record<string, unknown>,
    });
  }

  /**
   * Find paper by title and get citations
   */
  async findAndCitedBy(request: OpenAlexFindAndCitedByRequest): Promise<OpenAlexFindAndCitedByResponse> {
    return this.request('GET', '/openalex/find_and_cited_by', {
      params: request as unknown as Record<string, unknown>,
    });
  }

  // ==========================================================================
  // Blog
  // ==========================================================================

  /**
   * Submit blog generation task
   */
  async submitBlog(arxivIds: string | string[], viewsContent?: string): Promise<{ task_id: string; status: string }> {
    const ids = Array.isArray(arxivIds) ? arxivIds.join(',') : arxivIds;

    const formData = new URLSearchParams();
    formData.append('arxiv_ids', ids);
    if (viewsContent) {
      formData.append('views_content', viewsContent);
    }

    const headers: Record<string, string> = {};
    if (this.config.apiKey) {
      headers['X-API-Key'] = this.config.apiKey;
    }

    const response = await fetch(`${this.baseUrl}/api/blog/submit`, {
      method: 'POST',
      headers,
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: response.statusText }));
      const detail = error.detail || `HTTP ${response.status}`;

      if (ScholarClawClient.isAuthError(response.status, detail)) {
        throw new ScholarClawError(
          '需要鉴权才能访问此服务。请前往 https://scholarclaw.youdao.com/ 申请 API Key，然后通过以下方式配置：\n' +
          '  1. 设置环境变量: SCHOLARCLAW_API_KEY\n' +
          '  2. 添加到 OpenClaw config.yaml: apiKey\n' +
          '  3. 创建配置文件: ~/.scholarclaw/config.json',
          response.status,
          error
        );
      }

      throw new ScholarClawError(detail, response.status, error);
    }

    return response.json();
  }

  /**
   * Get blog task status
   */
  async getBlogTask(taskId: string): Promise<BlogTask> {
    return this.request('GET', `/api/blog/task/${taskId}`);
  }

  /**
   * Get blog result
   */
  async getBlogResult(taskId: string): Promise<BlogResult> {
    return this.request('GET', `/api/blog/result/${taskId}`);
  }

  /**
   * List blog tasks
   */
  async listBlogTasks(options?: {
    status?: 'pending' | 'running' | 'completed' | 'failed';
    limit?: number;
    offset?: number;
  }): Promise<{ tasks: BlogTask[]; total: number }> {
    return this.request('GET', '/api/blog/tasks', {
      params: options as unknown as Record<string, unknown>,
    });
  }

  // ==========================================================================
  // Benchmark
  // ==========================================================================

  /**
   * Submit benchmark analysis task
   */
  async submitBenchmark(arxivId: string, options?: {
    benchmarkName?: string;
    useLlm?: boolean;
    modelName?: string;
    enrich?: boolean;
    maxCitations?: number;
    maxPapers?: number;
  }): Promise<{ task_id: string; status: string }> {
    const body: Record<string, unknown> = {
      arxiv_id: arxivId,
      use_llm: options?.useLlm ?? true,
      model_name: options?.modelName || 'deepseek-v3.1-chat-250922',
      enrich: options?.enrich ?? true,
      max_citations: options?.maxCitations || 200,
      max_papers: options?.maxPapers || 100,
    };

    if (options?.benchmarkName) {
      body.benchmark_name = options.benchmarkName;
    }

    return this.request('POST', '/api/benchmark/submit', { body });
  }

  /**
   * Get benchmark result
   */
  async getBenchmarkResult(arxivId: string): Promise<BenchmarkResult> {
    return this.request('GET', `/api/benchmark/result/${arxivId}`, { timeout: 60000 });
  }

  /**
   * Get benchmark task status
   */
  async getBenchmarkTask(taskId: string): Promise<BenchmarkTask> {
    return this.request('GET', `/api/benchmark/task/${taskId}`);
  }

  /**
   * List completed benchmark tasks
   */
  async listBenchmarkTasks(): Promise<{ tasks: BenchmarkTask[]; total: number }> {
    return this.request('GET', '/api/benchmark/completed');
  }

  // ==========================================================================
  // Recommendations
  // ==========================================================================

  /**
   * Get trending papers from HuggingFace
   */
  async getRecommendedPapers(limit: number = 12): Promise<RecommendedPaper[]> {
    return this.request('GET', '/api/recommend/papers', {
      params: { limit },
    });
  }

  /**
   * Get recommended blogs
   */
  async getRecommendedBlogs(limit: number = 10): Promise<{ blogs: RecommendedBlog[]; total: number }> {
    return this.request('GET', '/api/recommend/blogs', {
      params: { limit },
    });
  }

  /**
   * Check if an error response is authentication-related
   */
  private static isAuthError(statusCode: number, detail: string): boolean {
    if (statusCode === 401 || statusCode === 403 || statusCode === 429) {
      return true;
    }
    const lower = detail.toLowerCase();
    return /auth|api.?key|token|credential|permission|forbidden|unauthorized|quota|limit|rate|鉴权|认证|密钥|授权|额度|限额|用量/.test(lower);
  }

  /**
   * Get GitHub repos for a paper
   */
  async getPaperRepos(arxivId: string, minStars: number = 5): Promise<{
    arxiv_id: string;
    total: number;
    repos: GitHubRepo[];
  }> {
    return this.request('GET', `/api/recommend/paper/${arxivId}/detail`, {
      params: { min_stars: minStars },
    });
  }
}

/**
 * Custom error class for ScholarClaw API errors
 */
export class ScholarClawError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public details: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ScholarClawError';
  }
}

// Export default client instance
export const scholarClawClient = new ScholarClawClient();

// Export types
export * from './types';
export * from './config';
