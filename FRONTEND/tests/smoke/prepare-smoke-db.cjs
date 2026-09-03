const path = require('node:path');
const fs = require('node:fs');

const projectRoot = path.resolve(__dirname, '..', '..', '..');
const backendRoot = path.join(projectRoot, 'BACKEND');
const backendEnvPath = path.join(backendRoot, '.env');
const smokeDatabase =
  process.env.SMOKE_DB_DATABASE ||
  process.env.INTEGRATION_DB_DATABASE ||
  'logistica_integracion1';

function readEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  return fs
    .readFileSync(filePath, 'utf8')
    .split(/\r?\n/)
    .reduce((env, line) => {
      const match = line.match(/^([A-Za-z0-9_]+)=(.*)$/);
      if (match) {
        env[match[1]] = match[2];
      }
      return env;
    }, {});
}

function assertSafeSmokeDatabase(database, operationalDatabase) {
  const db = String(database || '').trim();
  const normal = String(operationalDatabase || '').trim();
  const lower = db.toLowerCase();
  const forbidden = new Set([
    'insumos',
    'mineria',
    'porvenir',
    'logamina',
    'postgres',
    'database',
    'template0',
    'template1',
  ]);

  if (!db) {
    throw new Error('SMOKE_DB_DATABASE/DB_DATABASE is required.');
  }

  if (!/(smoke|integracion|integration|test)/i.test(db)) {
    throw new Error(
      `Unsafe smoke database name: ${db}. Use a dedicated smoke/integration/test database.`,
    );
  }

  if (normal && lower === normal.toLowerCase()) {
    throw new Error(`Smoke database ${db} matches the operational database.`);
  }

  if (forbidden.has(lower)) {
    throw new Error(`Refusing to prepare smoke tests against ${db}.`);
  }
}

async function main() {
  const envFile = readEnvFile(backendEnvPath);
  const operationalDatabase =
    process.env.OPERATIONAL_DB_DATABASE || envFile.DB_DATABASE || 'insumos';

  for (const [key, value] of Object.entries(envFile)) {
    if (process.env[key] === undefined && key !== 'DB_DATABASE') {
      process.env[key] = value;
    }
  }

  process.env.OPERATIONAL_DB_DATABASE = operationalDatabase;
  process.env.NODE_ENV = 'test';
  process.env.DB_DATABASE = smokeDatabase;
  process.env.DB_SCHEMA = process.env.DB_SCHEMA || 'public';
  process.env.JWT_SECRET =
    process.env.SMOKE_JWT_SECRET ||
    process.env.INTEGRATION_JWT_SECRET ||
    'integration-test-jwt-secret';
  process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

  assertSafeSmokeDatabase(process.env.DB_DATABASE, operationalDatabase);

  const setupIntegrationDatabase = require(path.join(
    backendRoot,
    'test',
    'integration',
    'global-setup.cjs',
  ));

  await setupIntegrationDatabase();
  console.log(`[smoke] Base controlada preparada: ${process.env.DB_DATABASE}`);
}

module.exports = {
  main,
};

if (require.main === module) {
  main().catch((error) => {
    console.error(`[smoke] No se pudo preparar la base controlada: ${error.message}`);
    process.exit(1);
  });
}
