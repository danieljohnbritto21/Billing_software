import fs from 'fs';
import { PrismaClient } from '@prisma/client';

/**
 * Robust PostgreSQL statement parser that respects dollar-quoted function blocks ($$...$$ or $tag$...$tag$)
 * and single-quoted strings ('...').
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

    // Handle single-line comments
    if (!inSingleQuote && !inDollarQuote && char === '-' && nextChar === '-') {
      const lineEnd = sql.indexOf('\n', i);
      if (lineEnd === -1) break;
      i = lineEnd + 1;
      continue;
    }

    // Handle psql slash commands (\restrict, \unrestrict, etc.)
    if (!inSingleQuote && !inDollarQuote && (i === 0 || sql[i - 1] === '\n') && char === '\\') {
      const lineEnd = sql.indexOf('\n', i);
      if (lineEnd === -1) break;
      i = lineEnd + 1;
      continue;
    }

    // Handle single quotes
    if (!inDollarQuote && char === "'") {
      if (inSingleQuote && nextChar === "'") {
        // Escaped single quote ''
        current += "''";
        i += 2;
        continue;
      }
      inSingleQuote = !inSingleQuote;
      current += char;
      i++;
      continue;
    }

    // Handle dollar quotes ($$...$$ or $tag$...$tag$)
    if (!inSingleQuote && char === '$') {
      if (!inDollarQuote) {
        // Check if starting a dollar tag
        const match = sql.slice(i).match(/^(\$[a-zA-Z0-9_]*\$)/);
        if (match) {
          dollarTag = match[1];
          inDollarQuote = true;
          current += dollarTag;
          i += dollarTag.length;
          continue;
        }
      } else {
        // Check if ending current dollar tag
        if (sql.startsWith(dollarTag, i)) {
          inDollarQuote = false;
          current += dollarTag;
          i += dollarTag.length;
          dollarTag = '';
          continue;
        }
      }
    }

    // Handle statement delimiter ;
    if (!inSingleQuote && !inDollarQuote && char === ';') {
      current += ';';
      const trimmed = current.trim();
      if (trimmed.length > 0 && !trimmed.includes('foodbill_app')) {
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
  if (remainder.length > 0 && !remainder.includes('foodbill_app')) {
    statements.push(remainder);
  }

  return statements;
}

async function main() {
  const sqlPath = '/mnt/d/foodbill_backups/database/render_migration/foodbill_render_inserts_20261105.sql';
  console.log('Reading INSERT SQL dump from', sqlPath);
  const rawSql = fs.readFileSync(sqlPath, 'utf8');

  console.log('Parsing PostgreSQL statements with dollar-quoting awareness...');
  const stmts = parsePgStatements(rawSql);
  console.log(`Successfully parsed ${stmts.length} exact SQL statements.`);

  const prisma = new PrismaClient();
  try {
    console.log('Executing statements on Render PostgreSQL...');
    let executed = 0;
    let errors = 0;

    for (let idx = 0; idx < stmts.length; idx++) {
      const stmt = stmts[idx];
      try {
        await prisma.$executeRawUnsafe(stmt);
        executed++;
        if (executed % 50 === 0 || executed === stmts.length) {
          console.log(`  Progress: ${executed}/${stmts.length} statements executed.`);
        }
      } catch (err: any) {
        // Ignore DROP errors if objects don't exist yet
        if (stmt.startsWith('DROP ') || (stmt.startsWith('ALTER TABLE') && stmt.includes('DROP CONSTRAINT'))) {
          // Expected on initial clean run
        } else {
          errors++;
          console.error(`Error on stmt #${idx} [${stmt.slice(0, 60)}...]:`, err.message);
        }
      }
    }
    console.log(`✔ Finished execution: ${executed} succeeded, ${errors} non-drop errors.`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
