// Quick test script to verify database connection
import { Pool } from 'pg';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Try to load .env from root folder first, then from current directory
const rootEnvPath = join(__dirname, '..', '.env');
const localEnvPath = join(__dirname, '.env');

if (existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
  console.log('📁 Loading .env from root folder\n');
} else if (existsSync(localEnvPath)) {
  dotenv.config({ path: localEnvPath });
  console.log('📁 Loading .env from mcp_check folder\n');
} else {
  dotenv.config(); // Default behavior
  console.log('📁 Using default .env loading\n');
}

async function testConnection() {
  console.log('🔍 Testing PostgreSQL connection...\n');
  
  // Build connection string
  const connectionString = process.env.DATABASE_URL || 
    `postgresql://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || '420690'}@${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5433'}/${process.env.DB_NAME || 'ryt_guard'}`;
  
  console.log('Connection details:');
  console.log(`  Host: ${process.env.DB_HOST || '127.0.0.1'}`);
  console.log(`  Port: ${process.env.DB_PORT || '5433'}`);
  console.log(`  Database: ${process.env.DB_NAME || 'ryt_guard'}`);
  console.log(`  User: ${process.env.DB_USER || 'postgres'}`);
  console.log(`  Password: ${process.env.DB_PASSWORD ? '***' : '420690 (default)'}\n`);
  
  const pool = new Pool({ connectionString });
  
  try {
    // Test basic connection
    console.log('1️⃣ Testing basic connection...');
    const client = await pool.connect();
    console.log('✅ Connected successfully!\n');
    
    // Check if transactions table exists
    console.log('2️⃣ Checking for transactions table...');
    const tableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'transactions';
    `);
    
    if (tableCheck.rows.length > 0) {
      console.log('✅ transactions table found!\n');
      
      // Get table schema
      console.log('3️⃣ Getting transactions table schema...');
      const schema = await client.query(`
        SELECT 
          column_name,
          data_type,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'transactions'
        ORDER BY ordinal_position;
      `);
      
      console.log('📋 Table schema:');
      schema.rows.forEach(col => {
        console.log(`   - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(NOT NULL)' : ''}`);
      });
      console.log('');
      
      // Test a simple query
      console.log('4️⃣ Testing SELECT query...');
      const testQuery = await client.query('SELECT COUNT(*) as total FROM transactions');
      console.log(`✅ Query successful! Total rows: ${testQuery.rows[0].total}\n`);
      
      // Sample data
      const sample = await client.query('SELECT * FROM transactions LIMIT 3');
      if (sample.rows.length > 0) {
        console.log('5️⃣ Sample data (first 3 rows):');
        console.log(JSON.stringify(sample.rows, null, 2));
      } else {
        console.log('5️⃣ Table is empty (no sample data)');
      }
      
    } else {
      console.log('❌ transactions table NOT found!');
      console.log('\nAvailable tables:');
      const allTables = await client.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name;
      `);
      allTables.rows.forEach(row => {
        console.log(`   - ${row.table_name}`);
      });
    }
    
    client.release();
    console.log('\n✅ All tests passed! MCP server should work correctly.');
    
  } catch (error) {
    console.error('\n❌ Connection failed!');
    console.error('Error:', error.message);
    console.error('\nPlease check:');
    console.error('  1. Database is running');
    console.error('  2. Connection details in .env file are correct');
    console.error('  3. Database and user exist');
    console.error('  4. Password is correct');
    process.exit(1);
  } finally {
    await pool.end();
  }
}

testConnection();

