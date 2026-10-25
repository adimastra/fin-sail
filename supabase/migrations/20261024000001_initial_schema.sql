-- ==============================================================================
-- FIN SAIL SUPABASE DATABASE SCHEMA & RLS POLICIES (Idempotent & Safe)
-- ==============================================================================

-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  default_currency text default 'IDR',
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Trigger to create profile upon new signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, default_currency, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'IDR',
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.profiles.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. CATEGORIES TABLE
create table if not exists public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade, -- null means global default
  name text not null,
  icon_name text not null default 'tag',
  color_hex text not null default '#111111',
  type text check (type in ('expense', 'income')) default 'expense',
  is_default boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.categories enable row level security;

drop policy if exists "Users can view global categories and their own" on public.categories;
create policy "Users can view global categories and their own"
  on public.categories for select
  using (user_id is null or auth.uid() = user_id);

drop policy if exists "Users can insert their own custom categories" on public.categories;
create policy "Users can insert their own custom categories"
  on public.categories for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own custom categories" on public.categories;
create policy "Users can update their own custom categories"
  on public.categories for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete their own custom categories" on public.categories;
create policy "Users can delete their own custom categories"
  on public.categories for delete
  using (auth.uid() = user_id and is_default = false);

-- Seed global standard categories with signature vibrant colors
insert into public.categories (name, icon_name, color_hex, type, is_default)
select v.name, v.icon_name, v.color_hex, v.type, v.is_default
from (values
  ('Coffee', 'local_cafe', '#F59E0B', 'expense', true),
  ('Pet care', 'pets', '#EC4899', 'expense', true),
  ('Commute', 'directions_car', '#3B82F6', 'expense', true),
  ('House repair', 'build', '#8B5CF6', 'expense', true),
  ('Food & snacks', 'fastfood', '#F97316', 'expense', true),
  ('Groceries', 'shopping_cart', '#10B981', 'expense', true),
  ('Shopping', 'shopping_bag', '#D946EF', 'expense', true),
  ('Bills & utilities', 'bolt', '#EAB308', 'expense', true),
  ('Health', 'medical_services', '#EF4444', 'expense', true),
  ('Other', 'inventory_2', '#06B6D4', 'expense', true)
) as v(name, icon_name, color_hex, type, is_default)
where not exists (
  select 1 from public.categories c where c.name = v.name and c.user_id is null
);

-- 3. TRANSACTIONS TABLE
create table if not exists public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete set null,
  amount numeric(14,2) not null,
  currency text default 'IDR' not null,
  type text check (type in ('expense', 'income')) default 'expense' not null,
  merchant text,
  transaction_date timestamp with time zone default timezone('utc'::text, now()) not null,
  notes text,
  payment_method text default 'card' check (payment_method in ('cash', 'card', 'transfer', 'other')),
  receipt_url text,
  extracted_data jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.transactions enable row level security;

drop policy if exists "Users can view own transactions" on public.transactions;
create policy "Users can view own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own transactions" on public.transactions;
create policy "Users can insert own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own transactions" on public.transactions;
create policy "Users can update own transactions"
  on public.transactions for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own transactions" on public.transactions;
create policy "Users can delete own transactions"
  on public.transactions for delete
  using (auth.uid() = user_id);

create index if not exists idx_transactions_user_date on public.transactions(user_id, transaction_date desc);
create index if not exists idx_transactions_category on public.transactions(category_id);

-- 4. STORAGE BUCKET: Receipts
-- Safely insert bucket into storage.buckets
insert into storage.buckets (id, name, public)
values 
  ('Receipts', 'Receipts', false),
  ('receipts', 'receipts', false)
on conflict (id) do nothing;

-- Storage policies for receipts
drop policy if exists "Authenticated users can upload receipts" on storage.objects;
create policy "Authenticated users can upload receipts"
  on storage.objects for insert
  to authenticated
  with check (bucket_id in ('Receipts', 'receipts'));

drop policy if exists "Authenticated users can view receipts" on storage.objects;
create policy "Authenticated users can view receipts"
  on storage.objects for select
  to authenticated
  using (bucket_id in ('Receipts', 'receipts'));
