-- ============================================
-- 09: Notification setup for Telegram and Webhook
-- Run this after 00-08.
-- This script is safe to run multiple times.
-- ============================================

create extension if not exists pg_net;

-- 1. Add notification config columns to settings.
alter table public.settings
add column if not exists notify_telegram_bot_token text,
add column if not exists notify_telegram_chat_id text,
add column if not exists notify_webhook_url text,
add column if not exists notify_webhook_secret text,
add column if not exists notify_only_telegram boolean default false,
add column if not exists notify_only_webhook boolean default false;

-- 2. Helper functions for friendly notification content.

create or replace function public.love_trim_text(p_text text, p_limit int)
returns text
language sql
immutable
as $$
    select case
        when p_text is null or btrim(p_text) = '' then ''
        when char_length(p_text) <= p_limit then p_text
        else left(p_text, greatest(p_limit - 3, 0)) || '...'
    end;
$$;

create or replace function public.love_person_name(p_key text, p_name1 text, p_name2 text)
returns text
language sql
immutable
as $$
    select case p_key
        when 'name1' then coalesce(nullif(p_name1, ''), 'Person 1')
        when 'name2' then coalesce(nullif(p_name2, ''), 'Person 2')
        else coalesce(nullif(p_key, ''), 'Unknown')
    end;
$$;

create or replace function public.love_changed_fields(p_old jsonb, p_new jsonb)
returns text[]
language sql
immutable
as $$
    with keys as (
        select key from jsonb_object_keys(coalesce(p_old, '{}'::jsonb)) as k(key)
        union
        select key from jsonb_object_keys(coalesce(p_new, '{}'::jsonb)) as k(key)
    )
    select coalesce(array_agg(key order by key), array[]::text[])
    from keys
    where coalesce(p_old -> key, 'null'::jsonb) is distinct from coalesce(p_new -> key, 'null'::jsonb);
$$;

create or replace function public.love_build_telegram_message(
    p_table text,
    p_operation text,
    p_old jsonb,
    p_new jsonb,
    p_name1 text,
    p_name2 text
)
returns text
language plpgsql
stable
as $$
declare
    v_sender text;
    v_title text;
    v_artist text;
    v_description text;
    v_count int;
    v_old_count int;
    v_new_count int;
    v_text text;
    v_name text;
    v_icon text;
    v_date text;
begin
    case p_table
        when 'messages' then
            v_sender := public.love_person_name(coalesce(p_new ->> 'sender', p_old ->> 'sender', ''), p_name1, p_name2);
            if p_operation = 'INSERT' then
                v_text := public.love_trim_text(coalesce(p_new ->> 'text', ''), 80);
                return format('💬 新留言 | %s: %s', v_sender, v_text);
            elsif p_operation = 'UPDATE' then
                v_text := public.love_trim_text(coalesce(p_new ->> 'text', ''), 80);
                return format('💬 留言已更新 | %s: %s', v_sender, v_text);
            else
                v_text := public.love_trim_text(coalesce(p_old ->> 'text', ''), 80);
                return format('💬 留言已删除 | %s: %s', v_sender, v_text);
            end if;

        when 'photos' then
            v_sender := public.love_person_name(coalesce(p_new ->> 'uploader', p_old ->> 'uploader', ''), p_name1, p_name2);
            v_description := public.love_trim_text(coalesce(p_new ->> 'description', p_old ->> 'description', ''), 80);
            v_count := coalesce(jsonb_array_length(coalesce(p_new -> 'image_urls', p_old -> 'image_urls', '[]'::jsonb)), 0);
            if p_operation = 'INSERT' then
                return format('📷 新照片 | %s 上传了 %s 张照片%s', v_sender, v_count, case when v_description <> '' then format(' | %s', v_description) else '' end);
            elsif p_operation = 'UPDATE' then
                return format('📷 照片已更新 | %s%s', v_sender, case when v_description <> '' then format(' | %s', v_description) else '' end);
            else
                return format('📷 照片已删除 | %s%s', v_sender, case when v_description <> '' then format(' | %s', v_description) else '' end);
            end if;

        when 'songs' then
            v_sender := public.love_person_name(coalesce(p_new ->> 'uploader', p_old ->> 'uploader', ''), p_name1, p_name2);
            v_title := public.love_trim_text(coalesce(p_new ->> 'title', p_old ->> 'title', ''), 60);
            v_artist := public.love_trim_text(coalesce(p_new ->> 'artist', p_old ->> 'artist', ''), 40);
            if p_operation = 'INSERT' then
                return format('🎵 新歌曲 | %s - %s | 上传者: %s', v_title, v_artist, v_sender);
            elsif p_operation = 'UPDATE' then
                return format('🎵 歌曲已更新 | %s - %s | 上传者: %s', v_title, v_artist, v_sender);
            else
                return format('🎵 歌曲已删除 | %s - %s | 上传者: %s', v_title, v_artist, v_sender);
            end if;

        when 'public_messages' then
            v_text := public.love_trim_text(coalesce(p_new ->> 'content', p_old ->> 'content', ''), 80);
            if p_operation = 'INSERT' then
                return format('✨ 路人祝福 | %s', v_text);
            elsif p_operation = 'UPDATE' then
                return format('✨ 祝福已更新 | %s', v_text);
            else
                return format('✨ 祝福已删除 | %s', v_text);
            end if;

        when 'blessing_stats' then
            v_old_count := nullif(p_old ->> 'count', '')::int;
            v_new_count := nullif(p_new ->> 'count', '')::int;
            if p_operation = 'UPDATE' and coalesce(v_new_count, 0) > coalesce(v_old_count, 0) then
                return format('💖 99 +1 | 新增 %s 个祝福，当前共 %s 个', v_new_count - coalesce(v_old_count, 0), v_new_count);
            elsif p_operation = 'INSERT' then
                return format('💖 祝福计数已创建 | 当前共 %s 个', coalesce(v_new_count, 0));
            else
                return format('💖 祝福计数已更新 | 当前共 %s 个', coalesce(v_new_count, v_old_count, 0));
            end if;

        when 'visited_places' then
            v_name := public.love_trim_text(coalesce(p_new ->> 'name', p_old ->> 'name', ''), 40);
            if p_operation = 'INSERT' then
                return format('🗺️ 足迹新增 | %s', v_name);
            elsif p_operation = 'UPDATE' then
                return format('🗺️ 足迹已更新 | %s', v_name);
            else
                return format('🗺️ 足迹已移除 | %s', v_name);
            end if;

        when 'achievements' then
            v_title := public.love_trim_text(coalesce(p_new ->> 'title', p_old ->> 'title', ''), 60);
            v_icon := coalesce(nullif(p_new ->> 'icon', ''), nullif(p_old ->> 'icon', ''), '🏆');
            v_date := coalesce(nullif(p_new ->> 'date', ''), nullif(p_old ->> 'date', ''), '');
            if p_operation = 'INSERT' then
                return format('%s 成就新增 | %s%s', v_icon, v_title, case when v_date <> '' then format(' | %s', v_date) else '' end);
            elsif p_operation = 'UPDATE' then
                return format('%s 成就已更新 | %s%s', v_icon, v_title, case when v_date <> '' then format(' | %s', v_date) else '' end);
            else
                return format('%s 成就已删除 | %s%s', v_icon, v_title, case when v_date <> '' then format(' | %s', v_date) else '' end);
            end if;

        else
            return format('数据库更新 | %s %s', p_table, p_operation);
    end case;
end;
$$;

create or replace function public.love_dispatch_change()
returns trigger
language plpgsql
security definer
set search_path = public, net, pg_temp
as $$
declare
    v_settings record;
    v_old jsonb := coalesce(to_jsonb(old), '{}'::jsonb);
    v_new jsonb := coalesce(to_jsonb(new), '{}'::jsonb);
    v_table text := tg_table_name;
    v_operation text := tg_op;
    v_message text;
    v_payload jsonb;
    v_headers jsonb;
    v_should_send_telegram boolean;
    v_should_send_webhook boolean;
begin
    if v_operation = 'UPDATE' and v_old = v_new then
        return null;
    end if;

    select
        coalesce(name1, 'Person 1') as name1,
        coalesce(name2, 'Person 2') as name2,
        nullif(notify_telegram_bot_token, '') as notify_telegram_bot_token,
        nullif(notify_telegram_chat_id, '') as notify_telegram_chat_id,
        nullif(notify_webhook_url, '') as notify_webhook_url,
        nullif(notify_webhook_secret, '') as notify_webhook_secret,
        coalesce(notify_only_telegram, false) as notify_only_telegram,
        coalesce(notify_only_webhook, false) as notify_only_webhook
    into v_settings
    from public.settings
    order by id desc
    limit 1;

    if not found then
        return null;
    end if;

    v_message := public.love_build_telegram_message(
        v_table,
        v_operation,
        v_old,
        v_new,
        v_settings.name1,
        v_settings.name2
    );

    v_payload := jsonb_build_object(
        'source', 'love-app',
        'schema', tg_table_schema,
        'table', v_table,
        'operation', v_operation,
        'record_id', coalesce(v_new ->> 'id', v_old ->> 'id'),
        'changed_fields', public.love_changed_fields(v_old, v_new),
        'old_row', case when v_operation in ('UPDATE', 'DELETE') then v_old else null end,
        'new_row', case when v_operation in ('INSERT', 'UPDATE') then v_new else null end,
        'occurred_at', timezone('utc'::text, now())
    );

    v_should_send_telegram := v_settings.notify_telegram_bot_token is not null and v_settings.notify_telegram_chat_id is not null;
    v_should_send_webhook := v_settings.notify_webhook_url is not null;

    if v_settings.notify_only_telegram then
        v_should_send_webhook := false;
    elsif v_settings.notify_only_webhook then
        v_should_send_telegram := false;
    end if;

    if v_should_send_telegram then
        perform net.http_post(
            url := format('https://api.telegram.org/bot%s/sendMessage', v_settings.notify_telegram_bot_token),
            headers := jsonb_build_object('Content-Type', 'application/json'),
            body := jsonb_build_object(
                'chat_id', v_settings.notify_telegram_chat_id,
                'text', v_message,
                'disable_web_page_preview', true
            )
        );
    end if;

    if v_should_send_webhook then
        v_headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Love-Source', 'love-app'
        ) || case
            when v_settings.notify_webhook_secret is not null then jsonb_build_object('X-Love-Webhook-Secret', v_settings.notify_webhook_secret)
            else '{}'::jsonb
        end;

        perform net.http_post(
            url := v_settings.notify_webhook_url,
            headers := v_headers,
            body := v_payload
        );
    end if;

    return null;
end;
$$;

-- 3. Rebuild triggers for the tracked business tables.
drop trigger if exists love_notify_messages on public.messages;
create trigger love_notify_messages
after insert or update or delete on public.messages
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_photos on public.photos;
create trigger love_notify_photos
after insert or update or delete on public.photos
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_songs on public.songs;
create trigger love_notify_songs
after insert or update or delete on public.songs
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_public_messages on public.public_messages;
create trigger love_notify_public_messages
after insert or update or delete on public.public_messages
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_visited_places on public.visited_places;
create trigger love_notify_visited_places
after insert or update or delete on public.visited_places
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_achievements on public.achievements;
create trigger love_notify_achievements
after insert or update or delete on public.achievements
for each row execute function public.love_dispatch_change();

drop trigger if exists love_notify_blessing_stats on public.blessing_stats;
create trigger love_notify_blessing_stats
after insert or update or delete on public.blessing_stats
for each row execute function public.love_dispatch_change();

-- 4. Reload PostgREST schema cache.
notify pgrst, 'reload schema';
