-- Gully MVP database schema for Supabase (PostgreSQL).
-- Run once in Supabase Dashboard → SQL Editor. Never expose a service_role key in the browser.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Gully member' check (char_length(display_name) between 1 and 50),
  campus text not null default '' check (char_length(campus) <= 120),
  bio text not null default '' check (char_length(bio) <= 180),
  role text not null default 'user' check (role in ('user','moderator')),
  created_at timestamptz not null default now()
);

create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 36),
  description text not null default '' check (char_length(description) <= 140),
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.channel_members (
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (channel_id,user_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  body varchar(500) not null check (char_length(trim(body)) between 1 and 500),
  channel_id uuid references public.channels(id) on delete set null,
  is_removed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body varchar(500) not null check (char_length(trim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);

create table if not exists public.likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id,user_id)
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id,followed_id),
  check (follower_id <> followed_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('Harassment or bullying','Hate or identity-based attack','Threats or violence','Spam or scam','Sharing private information','Other')),
  details text not null default '' check (char_length(details) <= 500),
  status text not null default 'open' check (status in ('open','removed','dismissed')),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.reports(id) on delete cascade,
  moderator_id uuid not null references public.profiles(id),
  decision text not null check (decision in ('removed','dismissed')),
  created_at timestamptz not null default now()
);

create index if not exists posts_created_at_idx on public.posts(created_at desc);
create index if not exists posts_channel_created_idx on public.posts(channel_id,created_at desc);
create index if not exists comments_post_created_idx on public.comments(post_id,created_at);
create index if not exists reports_status_created_idx on public.reports(status,created_at desc);
create index if not exists follows_followed_idx on public.follows(followed_id);

-- Trusted role check. SECURITY DEFINER avoids recursive profile RLS checks.
create or replace function public.is_gully_moderator()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id = auth.uid() and role = 'moderator'); $$;
revoke all on function public.is_gully_moderator() from public;
grant execute on function public.is_gully_moderator() to authenticated;

-- Create a profile automatically after Supabase Auth creates a user.
create or replace function public.handle_new_gully_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id,display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'name',''), split_part(new.email,'@',1), 'Gully member'))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_gully on auth.users;
create trigger on_auth_user_created_gully after insert on auth.users
for each row execute procedure public.handle_new_gully_user();

-- A normal user cannot promote themselves by changing their profile row.
create or replace function public.protect_gully_profile_role()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.role is distinct from old.role and auth.uid() is not null and not public.is_gully_moderator() then
    raise exception 'Only an existing moderator can change a role';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_gully_role on public.profiles;
create trigger protect_gully_role before update on public.profiles
for each row execute procedure public.protect_gully_profile_role();

-- Moderation decisions are performed on the server after checking the caller's role.
create or replace function public.review_report(p_report_id uuid, p_decision text)
returns void language plpgsql security definer set search_path = public
as $$
declare target_post uuid;
begin
  if not public.is_gully_moderator() then raise exception 'Moderator permission required'; end if;
  if p_decision not in ('removed','dismissed') then raise exception 'Invalid moderation decision'; end if;
  select post_id into target_post from public.reports where id = p_report_id and status = 'open' for update;
  if target_post is null then raise exception 'Open report not found'; end if;
  update public.reports set status = p_decision, reviewed_by = auth.uid(), reviewed_at = now() where id = p_report_id;
  if p_decision = 'removed' then update public.posts set is_removed = true where id = target_post; end if;
  insert into public.moderation_actions(report_id,moderator_id,decision) values (p_report_id,auth.uid(),p_decision);
end;
$$;
revoke all on function public.review_report(uuid,text) from public;
grant execute on function public.review_report(uuid,text) to authenticated;

-- Enable row-level security on every application table.
alter table public.profiles enable row level security;
alter table public.channels enable row level security;
alter table public.channel_members enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;
alter table public.follows enable row level security;
alter table public.reports enable row level security;
alter table public.moderation_actions enable row level security;

-- Profiles
 drop policy if exists "profiles readable by signed-in users" on public.profiles;
create policy "profiles readable by signed-in users" on public.profiles for select to authenticated using (true);
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Channels and memberships
 drop policy if exists "channels visible to signed-in users" on public.channels;
create policy "channels visible to signed-in users" on public.channels for select to authenticated using (true);
drop policy if exists "signed-in users create channels" on public.channels;
create policy "signed-in users create channels" on public.channels for insert to authenticated with check (created_by = auth.uid());
drop policy if exists "memberships visible to signed-in users" on public.channel_members;
create policy "memberships visible to signed-in users" on public.channel_members for select to authenticated using (true);
drop policy if exists "users join as themselves" on public.channel_members;
create policy "users join as themselves" on public.channel_members for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "users leave as themselves" on public.channel_members;
create policy "users leave as themselves" on public.channel_members for delete to authenticated using (user_id = auth.uid());

-- Posts: anyone signed in can read active posts; authors and moderators can see removed posts.
drop policy if exists "read active posts" on public.posts;
create policy "read active posts" on public.posts for select to authenticated using (not is_removed or user_id = auth.uid() or public.is_gully_moderator());
drop policy if exists "users create own posts" on public.posts;
create policy "users create own posts" on public.posts for insert to authenticated with check (
  user_id = auth.uid() and (channel_id is null or exists (select 1 from public.channel_members m where m.channel_id = posts.channel_id and m.user_id = auth.uid()))
);
drop policy if exists "authors or moderators delete posts" on public.posts;
create policy "authors or moderators delete posts" on public.posts for delete to authenticated using (user_id = auth.uid() or public.is_gully_moderator());

-- Comments
 drop policy if exists "comments readable by signed-in users" on public.comments;
create policy "comments readable by signed-in users" on public.comments for select to authenticated using (exists (select 1 from public.posts p where p.id = comments.post_id and (not p.is_removed or p.user_id = auth.uid() or public.is_gully_moderator())));
drop policy if exists "users create own comments" on public.comments;
create policy "users create own comments" on public.comments for insert to authenticated with check (user_id = auth.uid() and exists (select 1 from public.posts p where p.id = comments.post_id and not p.is_removed));
drop policy if exists "authors delete own comments" on public.comments;
create policy "authors delete own comments" on public.comments for delete to authenticated using (user_id = auth.uid() or public.is_gully_moderator());

-- Likes and follows
 drop policy if exists "likes readable by signed-in users" on public.likes;
create policy "likes readable by signed-in users" on public.likes for select to authenticated using (true);
drop policy if exists "users like as themselves" on public.likes;
create policy "users like as themselves" on public.likes for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "users unlike as themselves" on public.likes;
create policy "users unlike as themselves" on public.likes for delete to authenticated using (user_id = auth.uid());
drop policy if exists "follows readable by signed-in users" on public.follows;
create policy "follows readable by signed-in users" on public.follows for select to authenticated using (true);
drop policy if exists "users follow as themselves" on public.follows;
create policy "users follow as themselves" on public.follows for insert to authenticated with check (follower_id = auth.uid());
drop policy if exists "users unfollow as themselves" on public.follows;
create policy "users unfollow as themselves" on public.follows for delete to authenticated using (follower_id = auth.uid());

-- Reports and moderation history
 drop policy if exists "reporters and moderators read reports" on public.reports;
create policy "reporters and moderators read reports" on public.reports for select to authenticated using (reporter_id = auth.uid() or public.is_gully_moderator());
drop policy if exists "users submit own reports" on public.reports;
create policy "users submit own reports" on public.reports for insert to authenticated with check (reporter_id = auth.uid());
drop policy if exists "moderators read moderation actions" on public.moderation_actions;
create policy "moderators read moderation actions" on public.moderation_actions for select to authenticated using (public.is_gully_moderator());

-- Moderator bootstrap: after you have signed up with your own account, run this once
-- from the SQL Editor, replacing the email with the account you control:
-- update public.profiles p set role = 'moderator'
-- from auth.users u where p.id = u.id and u.email = 'YOUR_EMAIL@example.com';
