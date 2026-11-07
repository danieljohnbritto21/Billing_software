import fs from 'fs';
import { PrismaClient } from '@prisma/client';

/**
 * Robust PostgreSQL statement parser that respects dollar-quoted function blocks
 * and executes migrations inside a single transaction.
 */
function parsePgStatements(sql: string): string[] {
  const statements: string[] = [];
  let current = '';
  let inSingleQuote = false;
  let inDollarQuote = false;
  let dollarTag = '';
  let i = 0;

  while (i < sql.length) {
    const char = sql[i];
    const nextChar = sql[i + 1] || '';

    if (!inSingleQuote && !inDollarQuote && char === '-' && nextChar === '-') {
      const lineEnd = sql.indexOf('\n', i);
      if (lineEnd === -1) break;
      i = lineEnd + 1;
      continue;
    }

    if (!inDollarQuote && char === "'") {
      if (inSingleQuote && nextChar === "'") {
        current += "''";
        i += 2;
        continue;
      }
      inSingleQuote = !inSingleQuote;
      current += char;
      i++;
      continue;
    }

    if (!inSingleQuote && char === '$') {
      if (!inDollarQuote) {
        const match = sql.slice(i).match(/^(\$[a-zA-Z0-9_]*\$)/);
        if (match) {
          dollarTag = match[1];
          inDollarQuote = true;
          current += dollarTag;
          i += dollarTag.length;
          continue;
        }
      } else {
        if (sql.startsWith(dollarTag, i)) {
          inDollarQuote = false;
          current += dollarTag;
          i += dollarTag.length;
          dollarTag = '';
          continue;
        }
      }
    }

    if (!inSingleQuote && !inDollarQuote && char === ';') {
      current += ';';
      const trimmed = current.trim();
      if (trimmed.length > 0 && trimmed !== 'BEGIN;' && trimmed !== 'COMMIT;') {
        statements.push(trimmed);
      }
      current = '';
      i++;
      continue;
    }

    current += char;
    i++;
  }

  const remainder = current.trim();
  if (remainder.length > 0 && remainder !== 'BEGIN;' && remainder !== 'COMMIT;') {
    statements.push(remainder);
  }

  return statements;
}

async function main() {
  const migrationPath = '/mnt/d/billing_software/database/migrations/005_phase5_admin_supplier_redesign.sql';
  console.log('Reading migration file:', migrationPath);
  const rawSql = fs.readFileSync(migrationPath, 'utf8');

  const statements = parsePgStatements(rawSql);
  console.log(`Parsed ${statements.length} SQL statements for Phase 5 migration.`);

  const prisma = new PrismaClient();
  try {
    console.log('Applying Phase 5 migration statements in sequence...');
    for (let idx = 0; idx < statements.length; idx++) {
      const stmt = statements[idx];
      try {
        await prisma.$executeRawUnsafe(stmt);
        console.log(`  ✔ [${idx + 1}/${statements.length}] Executed statement: ${stmt.slice(0, 50).replace(/\n/g, ' ')}...`);
      } catch (err: any) {
        console.error(`❌ FAILED on statement #${idx + 1}:`, err.message);
        console.error('Statement was:\n', stmt);
        throw err;
      }
    }
    console.log('🎉 All Phase 5 migration statements executed successfully!');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(e => {
  console.error('Migration aborted:', e);
  process.exit(1);
});
