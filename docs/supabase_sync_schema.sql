create table if not exists public.app_sync_documents (
  user_id uuid not null references auth.users(id) on delete cascade,
  doc_key text not null,
  payload text null,
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false,
  deleted_entities jsonb not null default '{}'::jsonb,
  device_id text not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, doc_key)
);

alter table public.app_sync_documents enable row level security;

create policy "Users read own sync docs"
on public.app_sync_documents
for select
using (auth.uid() = user_id);

create policy "Users insert own sync docs"
on public.app_sync_documents
for insert
with check (auth.uid() = user_id);

create policy "Users update own sync docs"
on public.app_sync_documents
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users delete own sync docs"
on public.app_sync_documents
for delete
using (auth.uid() = user_id);

create index if not exists app_sync_documents_updated_at_idx
on public.app_sync_documents (user_id, updated_at desc);
