const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Try to read .env.local
let supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
let supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    try {
        const envPath = path.resolve(__dirname, '../.env.local');
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf8');
            const lines = envContent.split('\n');
            for (const line of lines) {
                if (line.startsWith('NEXT_PUBLIC_SUPABASE_URL=')) {
                    supabaseUrl = line.split('=')[1].replace(/"/g, '').trim();
                }
                if (line.startsWith('NEXT_PUBLIC_SUPABASE_ANON_KEY=')) {
                    supabaseKey = line.split('=')[1].replace(/"/g, '').trim();
                }
                if (line.startsWith('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=')) {
                    supabaseKey = line.split('=')[1].replace(/"/g, '').trim();
                }
            }
        }
    } catch (e) {
        console.log('Could not read .env.local');
    }
}

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials.');
    console.error('   Required: NEXT_PUBLIC_SUPABASE_URL');
    console.error('   And one of: NEXT_PUBLIC_SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
    process.exit(1);
}

console.log('Testing Supabase Connection...');
console.log('URL:', supabaseUrl);
console.log('Key:', supabaseKey ? (supabaseKey.substring(0, 10) + '...') : 'Missing');

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
    try {
        // 1. Test basic connection and table existence
        console.log('\n1. Testing "songs" table access...');
        const { data, error } = await supabase
            .from('songs')
            .select('count', { count: 'exact', head: true });

        if (error) {
            console.error('❌ Error accessing songs table:', error);
            if (error.code === 'PGRST205') {
                console.log('\n💡 TIP: Error PGRST205 means the table exists in DB but PostgREST API cache is stale.');
                console.log('   Please run this SQL in Supabase SQL Editor to reload the cache:');
                console.log("   NOTIFY pgrst, 'reload schema';");
            }
        } else {
            console.log('✅ Successfully accessed "songs" table.');
            console.log('   Row count:', data); // data is null for head:true, count is in count property? No, count is returned in count property of response object
        }

        // 2. Test Insert
        console.log('\n2. Testing Insert into "songs"...');
        const testSong = {
            title: 'Test Song ' + Date.now(),
            artist: 'Test Artist',
            url: 'https://example.com/test.mp3',
            uploader: 'test_script'
        };

        const { data: insertData, error: insertError } = await supabase
            .from('songs')
            .insert([testSong])
            .select();

        if (insertError) {
            console.error('❌ Insert failed:', insertError);
        } else {
            console.log('✅ Insert successful:', insertData);
            
            // Cleanup
            if (insertData && insertData[0] && insertData[0].id) {
                console.log('   Cleaning up test record...');
                await supabase.from('songs').delete().eq('id', insertData[0].id);
                console.log('   Cleanup done.');
            }
        }

    } catch (err) {
        console.error('Unexpected error:', err);
    }
}

testConnection();
