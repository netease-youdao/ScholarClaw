/**
 * ScholarClaw - Configuration
 *
 * Configuration settings for the ScholarClaw skill.
 * Supports multiple configuration sources with priority:
 * 1. Explicit overrides passed to createConfig()
 * 2. Environment variables
 * 3. OpenClaw skill config (passed via config object)
 * 4. Configuration file (~/.scholarclaw/config.json)
 * 5. Default values
 */

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

export interface ScholarClawConfig {
  /** Base URL for the ScholarClaw server */
  serverUrl: string;

  /** API Key for authentication (optional, empty if not configured) */
  apiKey: string;

  /** Default timeout for API requests (in milliseconds) */
  timeout: number;

  /** Maximum retries for failed requests */
  maxRetries: number;

  /** Whether to enable debug logging */
  debug: boolean;
}

/**
 * Get the path to the configuration file
 */
export function getConfigFilePath(): string {
  return path.join(os.homedir(), '.scholarclaw', 'config.json');
}

/**
 * Default configuration
 */
export const defaultConfig: ScholarClawConfig = {
  serverUrl: 'https://scholarclaw.youdao.com',
  apiKey: '',
  timeout: 30000,
  maxRetries: 3,
  debug: false,
};

/**
 * Read configuration from file (~/.scholarclaw/config.json)
 */
function getConfigFromFile(): Partial<ScholarClawConfig> {
  const configPath = getConfigFilePath();
  try {
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, 'utf-8');
      const parsed = JSON.parse(content);
      return {
        ...(parsed.serverUrl && { serverUrl: parsed.serverUrl }),
        ...(parsed.apiKey && { apiKey: parsed.apiKey }),
        ...(typeof parsed.timeout === 'number' && { timeout: parsed.timeout }),
        ...(typeof parsed.maxRetries === 'number' && { maxRetries: parsed.maxRetries }),
        ...(typeof parsed.debug === 'boolean' && { debug: parsed.debug }),
      };
    }
  } catch (error) {
    // Silently ignore file read errors
    if (process.env.SCHOLARCLAW_DEBUG === 'true') {
      console.warn(`Failed to read config file: ${error}`);
    }
  }
  return {};
}

/**
 * Read configuration from environment variables
 */
function getConfigFromEnv(): Partial<ScholarClawConfig> {
  const envConfig: Partial<ScholarClawConfig> = {};

  if (process.env.SCHOLARCLAW_SERVER_URL) {
    envConfig.serverUrl = process.env.SCHOLARCLAW_SERVER_URL;
  }

  if (process.env.SCHOLARCLAW_API_KEY) {
    envConfig.apiKey = process.env.SCHOLARCLAW_API_KEY;
  }

  if (process.env.SCHOLARCLAW_TIMEOUT) {
    const timeout = parseInt(process.env.SCHOLARCLAW_TIMEOUT, 10);
    if (!isNaN(timeout)) {
      envConfig.timeout = timeout;
    }
  }

  if (process.env.SCHOLARCLAW_MAX_RETRIES) {
    const maxRetries = parseInt(process.env.SCHOLARCLAW_MAX_RETRIES, 10);
    if (!isNaN(maxRetries)) {
      envConfig.maxRetries = maxRetries;
    }
  }

  if (process.env.SCHOLARCLAW_DEBUG === 'true') {
    envConfig.debug = true;
  }

  return envConfig;
}

/**
 * Create a configuration with custom overrides
 *
 * Priority (highest to lowest):
 * 1. Explicit overrides passed to this function
 * 2. Environment variables
 * 3. OpenClaw skill config (via overrides.config)
 * 4. Configuration file (~/.scholarclaw/config.json)
 * 5. Default values
 *
 * @param overrides - Custom configuration overrides
 * @param openclawConfig - Optional OpenClaw skill config object
 */
export function createConfig(
  overrides?: Partial<ScholarClawConfig>,
  openclawConfig?: Record<string, unknown>
): ScholarClawConfig {
  // Start with defaults
  let config = { ...defaultConfig };

  // 1. Apply configuration file (lowest priority)
  const fileConfig = getConfigFromFile();
  config = { ...config, ...fileConfig };

  // 2. Apply OpenClaw config if provided
  if (openclawConfig) {
    if (typeof openclawConfig.serverUrl === 'string') {
      config.serverUrl = openclawConfig.serverUrl;
    }
    if (typeof openclawConfig.apiKey === 'string') {
      config.apiKey = openclawConfig.apiKey;
    }
    if (typeof openclawConfig.timeout === 'number') {
      config.timeout = openclawConfig.timeout;
    }
    if (typeof openclawConfig.maxRetries === 'number') {
      config.maxRetries = openclawConfig.maxRetries;
    }
    if (typeof openclawConfig.debug === 'boolean') {
      config.debug = openclawConfig.debug;
    }
  }

  // 3. Apply environment variables (higher priority)
  const envConfig = getConfigFromEnv();
  config = { ...config, ...envConfig };

  // 4. Apply explicit overrides (highest priority)
  if (overrides) {
    config = { ...config, ...overrides };
  }

  return config;
}

/**
 * Validate configuration
 */
export function validateConfig(config: ScholarClawConfig): void {
  if (!config.serverUrl) {
    throw new Error('ScholarClaw serverUrl is required');
  }

  try {
    new URL(config.serverUrl);
  } catch {
    throw new Error(`Invalid serverUrl: ${config.serverUrl}`);
  }

  if (config.timeout < 1000) {
    console.warn('ScholarClaw: timeout is very low, may cause request failures');
  }
}

/**
 * Available search engines
 */
export const SEARCH_ENGINES = {
  ARXIV: 'arxiv',
  PUBMED: 'pubmed',
  GOOGLE: 'google',
  KUAKE: 'kuake',
  BOCHA: 'bocha',
  CACHE: 'cache',
  NIPS: 'nips',
  THECVF: 'thecvf',
  MLR_PRESS: 'mlr_press',
} as const;

export type SearchEngine = typeof SEARCH_ENGINES[keyof typeof SEARCH_ENGINES];

/**
 * Search modes
 */
export const SEARCH_MODES = {
  SIMPLE: 'simple',
  AI: 'ai',
} as const;

export type SearchMode = typeof SEARCH_MODES[keyof typeof SEARCH_MODES];

/**
 * Sort options
 */
export const SORT_OPTIONS = {
  RELEVANCE: 'relevance',
  DATE: 'date',
  CITATION_COUNT: 'citation_count',
} as const;

export type SortOption = typeof SORT_OPTIONS[keyof typeof SORT_OPTIONS];

/**
 * Blog task statuses
 */
export const BLOG_STATUSES = {
  PENDING: 'pending',
  RUNNING: 'running',
  COMPLETED: 'completed',
  FAILED: 'failed',
} as const;

export type BlogStatus = typeof BLOG_STATUSES[keyof typeof BLOG_STATUSES];

/**
 * Benchmark task statuses
 */
export const BENCHMARK_STATUSES = {
  PENDING: 'pending',
  RUNNING: 'running',
  COMPLETED: 'completed',
  FAILED: 'failed',
} as const;

export type BenchmarkStatus = typeof BENCHMARK_STATUSES[keyof typeof BENCHMARK_STATUSES];
