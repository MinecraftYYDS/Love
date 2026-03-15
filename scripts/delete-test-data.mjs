import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

// Read .env.local manually
const envPath = path.resolve(process.cwd(), '.env.local');
let envContent = '';
try {
    envContent = fs.readFileSync(envPath, 'utf-8');
} catch (e) {
    console.error('❌ Could not read .env.local');
    process.exit(1);
}

const env = {};
envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
        env[match[1]] = match[2].trim();
    }
});

const supabaseUrl = env['NEXT_PUBLIC_SUPABASE_URL'];
const supabaseKey = env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] || env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'];

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials in .env.local');
    console.error('   Required: NEXT_PUBLIC_SUPABASE_URL');
    console.error('   And one of: NEXT_PUBLIC_SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
    process.exit(1);
}

console.log(`Connecting to Supabase at: ${supabaseUrl}`);
const supabase = createClient(supabaseUrl, supabaseKey);

async function cleanStorage(bucketName) {
    console.log(`\n🧹 Cleaning bucket: ${bucketName}...`);
    
    // List all files
    const { data: files, error } = await supabase.storage.from(bucketName).list();
    
    if (error) {
        console.error(`❌ Error listing files in ${bucketName}:`, error.message);
        return;
    }
    
    if (!files || files.length === 0) {
        console.log(`   Bucket ${bucketName} is already empty.`);
        return;
    }

    // Filter out placeholders if any (like .emptyFolderPlaceholder)
    const filesToRemove = files
        .filter(x => x.name !== '.emptyFolderPlaceholder')
        .map(x => x.name);

    if (filesToRemove.length === 0) {
        console.log(`   Bucket ${bucketName} is effectively empty.`);
        return;
    }

    const { error: removeError } = await supabase.storage.from(bucketName).remove(filesToRemove);
    
    if (removeError) {
        console.error(`❌ Error removing files from ${bucketName}:`, removeError.message);
    } else {
        console.log(`✅ Removed ${filesToRemove.length} files from ${bucketName}.`);
    }
}

async function cleanTable(tableName) {
    console.log(`\n🧹 Cleaning table: ${tableName}...`);
    
    // 1. Select all IDs
    const { data: rows, error: selectError } = await supabase
        .from(tableName)
        .select('id');
        
    if (selectError) {
        console.error(`❌ Error selecting from ${tableName}:`, selectError.message);
        return;
    }
    
    if (!rows || rows.length === 0) {
        console.log(`   Table ${tableName} is already empty.`);
        return;
    }
    
    const ids = rows.map(r => r.id);
    
    // 2. Delete by IDs
    const { error: deleteError } = await supabase
        .from(tableName)
        .delete()
        .in('id', ids);
        
    if (deleteError) {
        console.error(`❌ Error deleting from ${tableName}:`, deleteError.message);
    } else {
        console.log(`✅ Deleted ${rows.length} rows from ${tableName}.`);
    }
}

async function main() {
    console.log('🚀 Starting cleanup of remote data...');
    
    // Clean Tables
    // We delete settings last, though order doesn't strictly matter without FK constraints
    await cleanTable('messages');
    await cleanTable('photos');
    await cleanTable('blessings');
    await cleanTable('settings');
    
    // Clean Storage
    await cleanStorage('photos');
    await cleanStorage('avatars');
    
    console.log('\n✨ Cleanup finished. Database tables are now empty (structure preserved).');
}

main();
