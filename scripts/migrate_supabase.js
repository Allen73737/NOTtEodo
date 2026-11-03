const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function migrate() {
  console.log("Connecting to Supabase PostgreSQL 17 instance...");
  const client = new Client({
    host: 'aws-0-ap-northeast-2.pooler.supabase.com',
    port: 6543,
    user: 'postgres.zjmxwttdkvhiuampirwa',
    password: 'Notteodo@123',
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 15000,
  });

  await client.connect();
  console.log("Connected successfully!");

  const migrationFiles = [
    "backend/supabase/migrations/20260905000000_full_schema.sql",
    "backend/supabase/migrations/20260905000001_hardened_rls.sql",
    "backend/supabase/migrations/20260905000002_security_functions.sql",
    "backend/supabase/migrations/20261101000000_user_collections_sync.sql",
    "backend/supabase/migrations/20261102000000_security_hardening.sql"
  ];

  for (const relPath of migrationFiles) {
    const fullPath = path.resolve(relPath);
    console.log(`\n========================================`);
    console.log(`Applying: ${path.basename(relPath)}`);
    console.log(`========================================`);
    const sql = fs.readFileSync(fullPath, 'utf8');

    try {
      await client.query(sql);
      console.log(`✓ Successfully applied ${path.basename(relPath)}`);
    } catch (err) {
      console.error(`✗ Error applying ${path.basename(relPath)}:`, err.message);
      if (err.position) {
        console.error(`Position: ${err.position}`);
      }
      throw err;
    }
  }

  console.log("\n========================================");
  console.log("Verifying created tables in public schema:");
  console.log("========================================");
  const tablesRes = await client.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name;
  `);

  console.log(`Found ${tablesRes.rows.length} public tables:`);
  for (const row of tablesRes.rows) {
    console.log(` - ${row.table_name}`);
  }

  await client.end();
  console.log("\nAll migrations successfully applied!");
}

migrate().catch(err => {
  console.error("Migration failed:", err);
  process.exit(1);
});

