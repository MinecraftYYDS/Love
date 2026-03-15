import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

function loadEnvFile(fileName) {
    const envPath = path.resolve(process.cwd(), fileName);
    if (!fs.existsSync(envPath)) {
        return;
    }

    const envContent = fs.readFileSync(envPath, 'utf-8');
    envContent.split('\n').forEach(line => {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) {
            return;
        }

        const match = trimmed.match(/^([^=]+)=(.*)$/);
        if (!match) {
            return;
        }

        const key = match[1].trim();
        const value = match[2].trim().replace(/^"|"$/g, '');
        if (!process.env[key]) {
            process.env[key] = value;
        }
    });
}

loadEnvFile('.env.local');
loadEnvFile('.env');

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials.');
    console.error('   Required: NEXT_PUBLIC_SUPABASE_URL');
    console.error('   And one of: NEXT_PUBLIC_SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
    process.exit(1);
}

console.log(`Testing connection to: ${supabaseUrl}`);

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
    console.log('\n--- 1. Testing Database Connection ---');
    const { data: settings, error: dbError } = await supabase
        .from('settings')
        .select('*')
        .limit(1);

    if (dbError) {
        console.error('❌ Database connection failed:', dbError.message);
    } else {
        console.log('✅ Database connection successful!');
        console.log('   Found settings:', settings ? settings.length : 0, 'rows');
    }

    console.log('\n--- 2. Testing Storage Buckets (Upload Test) ---');
    
    // Try to upload a dummy file to 'photos' to verify access
    const dummyFileName = `test-${Date.now()}.txt`;
    const { data: uploadData, error: uploadError } = await supabase
        .storage
        .from('photos')
        .upload(dummyFileName, 'Test file content', {
            upsert: true
        });

    if (uploadError) {
        console.error('❌ Upload failed:', uploadError.message);
        console.log('   (This might mean the bucket does not exist or policies are wrong)');
    } else {
        console.log('✅ Upload successful to "photos" bucket!');
        console.log('   File:', uploadData.path);
        
        // Clean up
        await supabase.storage.from('photos').remove([dummyFileName]);
        console.log('   (Test file cleaned up)');
    }
}

testConnection();
