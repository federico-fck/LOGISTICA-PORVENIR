import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';

const frontendUrl = process.env.SMOKE_FRONTEND_URL || 'http://127.0.0.1:4200';
const backendUrl = process.env.SMOKE_BACKEND_URL || 'http://127.0.0.1:3000/api';
const reportsRoot = path.resolve(__dirname, '..', 'reports', 'smoke');

export default defineConfig({
  testDir: './tests/smoke',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  workers: 1,
  retries: 1,
  forbidOnly: !!process.env.CI,
  outputDir: path.join(reportsRoot, 'test-results'),
  reporter: [
    ['list'],
    [
      'html',
      {
        outputFolder: path.join(reportsRoot, 'playwright-report'),
        open: 'never',
      },
    ],
    [
      'json',
      {
        outputFile: path.join(reportsRoot, 'playwright-results.json'),
      },
    ],
  ],
  use: {
    baseURL: frontendUrl,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
  ],
});
