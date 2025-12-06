// Script to set up promotions table and mock data
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env file
const rootEnvPath = join(__dirname, '..', '.env');
const localEnvPath = join(__dirname, '.env');

if (existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
} else if (existsSync(localEnvPath)) {
  dotenv.config({ path: localEnvPath });
} else {
  dotenv.config();
}

async function setupPromotions() {
  console.log('🚀 Setting up promotions table and mock data...\n');

  // Create database connection
  let pool;
  if (process.env.DATABASE_URL) {
    pool = mysql.createPool({
      uri: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: true,
        minVersion: 'TLSv1.2'
      }
    });
    console.log('📊 Using DATABASE_URL for MySQL/TiDB connection\n');
  } else {
    pool = mysql.createPool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      database: process.env.DB_NAME || 'ryt_guard',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      ssl: process.env.DB_SSL === 'true' ? {
        rejectUnauthorized: true,
        minVersion: 'TLSv1.2'
      } : undefined
    });
    console.log('📊 Using individual DB config for MySQL connection\n');
  }

  try {
    const connection = await pool.getConnection();
    console.log('✅ Connected to database\n');

    // Read and execute schema file
    console.log('📄 Executing promotions schema...');
    const schemaPath = join(__dirname, '..', 'database_schema', 'MYSQL-promotions_schema.sql');
    const schemaSQL = readFileSync(schemaPath, 'utf-8');
    
    // Split by semicolons and execute each statement
    const schemaStatements = schemaSQL
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of schemaStatements) {
      if (statement.length > 0) {
        await connection.query(statement);
      }
    }
    console.log('✅ Promotions table created\n');

    // Read and execute mock data file
    console.log('📄 Executing promotions mock data...');
    const mockDataPath = join(__dirname, '..', 'database_schema', 'MYSQL-mock_data_promotions.sql');
    const mockDataSQL = readFileSync(mockDataPath, 'utf-8');
    
    // Split by semicolons and execute each statement
    const mockDataStatements = mockDataSQL
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of mockDataStatements) {
      if (statement.length > 0) {
        await connection.query(statement);
      }
    }
    console.log('✅ Mock promotions data inserted\n');

    // Verify data
    console.log('🔍 Verifying promotions data...');
    const [rows] = await connection.query('SELECT COUNT(*) as count FROM promotions WHERE is_active = true');
    const count = rows[0].count;
    console.log(`✅ Found ${count} active promotions\n`);

    // Show sample
    const [samples] = await connection.query('SELECT promotion_id, title, promotion_type FROM promotions LIMIT 5');
    console.log('📋 Sample promotions:');
    samples.forEach((promo: any) => {
      console.log(`   - [${promo.promotion_type}] ${promo.title}`);
    });

    connection.release();
    console.log('\n✅ Promotions setup completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Setup failed!');
    console.error('Error:', error.message);
    if (error instanceof Error && error.stack) {
      console.error('Stack:', error.stack);
    }
    process.exit(1);
  } finally {
    await pool.end();
  }
}

setupPromotions();


