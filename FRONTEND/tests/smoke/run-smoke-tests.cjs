const { spawn } = require('node:child_process');
const http = require('node:http');
const path = require('node:path');

const { main: prepareSmokeDatabase } = require('./prepare-smoke-db.cjs');

const frontendRoot = path.resolve(__dirname, '..', '..');
const projectRoot = path.resolve(frontendRoot, '..');
const backendRoot = path.join(projectRoot, 'BACKEND');

const frontendUrl = process.env.SMOKE_FRONTEND_URL || 'http://127.0.0.1:4200';
const backendUrl = process.env.SMOKE_BACKEND_URL || 'http://127.0.0.1:3000/api';
const smokeDatabase =
  process.env.SMOKE_DB_DATABASE ||
  process.env.INTEGRATION_DB_DATABASE ||
  'logistica_integracion1';

const children = [];

function httpGet(url, timeoutMs = 3_000) {
  return new Promise((resolve) => {
    const request = http.get(url, { timeout: timeoutMs }, (response) => {
      response.resume();
      response.on('end', () => resolve(response.statusCode || 0));
    });

    request.on('timeout', () => {
      request.destroy();
      resolve(0);
    });
    request.on('error', () => resolve(0));
  });
}

async function assertUrlFree(name, url) {
  const status = await httpGet(url, 1_000);
  if (status > 0) {
    throw new Error(
      `${name} ya responde en ${url}. Detenga servidores existentes antes de ejecutar smoke.`,
    );
  }
}

async function waitForUrl(name, url, timeoutMs = 120_000) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    const status = await httpGet(url);
    if (status >= 200 && status < 500) {
      console.log(`[smoke] ${name} disponible: ${url}`);
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }

  throw new Error(`${name} no estuvo disponible en ${url} dentro de ${timeoutMs} ms.`);
}

function shouldLogLine(label, line) {
  if (label !== 'backend') {
    return true;
  }

  return (
    line.includes('Starting Nest application') ||
    line.includes('Nest application successfully started') ||
    line.includes('Backend ejecut') ||
    line.includes('Swagger disponible') ||
    line.includes('ERROR') ||
    line.includes('Exception') ||
    line.includes('Error:')
  );
}

function pipeStream(stream, label, target) {
  let buffer = '';

  stream?.on('data', (chunk) => {
    buffer += chunk.toString();
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (shouldLogLine(label, line)) {
        target.write(`[${label}] ${line}\n`);
      }
    }
  });

  stream?.on('end', () => {
    if (buffer && shouldLogLine(label, buffer)) {
      target.write(`[${label}] ${buffer}\n`);
    }
  });
}

function pipeOutput(child, label) {
  pipeStream(child.stdout, label, process.stdout);
  pipeStream(child.stderr, label, process.stderr);
}

function spawnProcess(label, command, args, options) {
  const child = spawn(command, args, {
    ...options,
    stdio: ['ignore', 'pipe', 'pipe'],
    windowsHide: true,
  });

  children.push({ label, child });
  pipeOutput(child, label);

  child.on('exit', (code, signal) => {
    if (code !== null && code !== 0) {
      console.error(`[smoke] ${label} finalizo con codigo ${code}.`);
    }
    if (signal) {
      console.error(`[smoke] ${label} finalizo por senal ${signal}.`);
    }
  });

  child.on('error', (error) => {
    console.error(`[smoke] No se pudo iniciar ${label}: ${error.message}`);
  });

  return child;
}

function killChild(label, child) {
  if (!child || child.killed || child.exitCode !== null) {
    return Promise.resolve();
  }

  return new Promise((resolve) => {
    if (process.platform === 'win32') {
      const killer = spawn('taskkill', ['/pid', String(child.pid), '/T', '/F'], {
        stdio: 'ignore',
        windowsHide: true,
      });
      killer.on('exit', () => resolve());
      killer.on('error', () => {
        child.kill();
        resolve();
      });
      return;
    }

    child.kill('SIGTERM');
    setTimeout(resolve, 500);
  }).then(() => {
    console.log(`[smoke] ${label} detenido.`);
  });
}

async function cleanup() {
  await Promise.all(children.reverse().map(({ label, child }) => killChild(label, child)));
}

function runPlaywright() {
  const playwrightCli = path.join(
    frontendRoot,
    'node_modules',
    '@playwright',
    'test',
    'cli.js',
  );

  return new Promise((resolve) => {
    const child = spawn(
      process.execPath,
      [playwrightCli, 'test', '--config=playwright.smoke.config.ts'],
      {
        cwd: frontendRoot,
        env: {
          ...process.env,
          SMOKE_FRONTEND_URL: frontendUrl,
          SMOKE_BACKEND_URL: backendUrl,
        },
        stdio: 'inherit',
        windowsHide: true,
      },
    );

    child.on('exit', (code) => resolve(code || 0));
    child.on('error', (error) => {
      console.error(`[smoke] No se pudo ejecutar Playwright: ${error.message}`);
      resolve(1);
    });
  });
}

async function main() {
  const backendCli = path.join(
    backendRoot,
    'node_modules',
    '@nestjs',
    'cli',
    'bin',
    'nest.js',
  );
  const angularCli = path.join(
    frontendRoot,
    'node_modules',
    '@angular',
    'cli',
    'bin',
    'ng.js',
  );

  await assertUrlFree('Backend', backendUrl);
  await assertUrlFree('Frontend', frontendUrl);
  await prepareSmokeDatabase();

  spawnProcess('backend', process.execPath, [backendCli, 'start'], {
    cwd: backendRoot,
    env: {
      ...process.env,
      NODE_ENV: 'test',
      DB_DATABASE: smokeDatabase,
      DB_SCHEMA: process.env.DB_SCHEMA || 'public',
      JWT_SECRET:
        process.env.SMOKE_JWT_SECRET ||
        process.env.INTEGRATION_JWT_SECRET ||
        'integration-test-jwt-secret',
      JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '1h',
      APP_PORT: process.env.SMOKE_BACKEND_PORT || '3000',
      PORT: process.env.SMOKE_BACKEND_PORT || '3000',
      CORS_ORIGIN: frontendUrl,
    },
  });

  spawnProcess(
    'frontend',
    process.execPath,
    [angularCli, 'serve', '--host', '127.0.0.1', '--port', '4200'],
    {
      cwd: frontendRoot,
      env: process.env,
    },
  );

  try {
    await waitForUrl('Backend', backendUrl);
    await waitForUrl('Frontend', frontendUrl);
    const exitCode = await runPlaywright();
    await cleanup();
    process.exit(exitCode);
  } catch (error) {
    console.error(`[smoke] ${error.message}`);
    await cleanup();
    process.exit(1);
  }
}

process.on('SIGINT', async () => {
  await cleanup();
  process.exit(130);
});

process.on('SIGTERM', async () => {
  await cleanup();
  process.exit(143);
});

main();
