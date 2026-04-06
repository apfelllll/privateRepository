-- DoorDesk: Firmen & Nutzer (öffentliche Tabelle `users` verknüpft mit auth.users)
-- Im Supabase-Dashboard: SQL Editor → New query → einfügen → Run

-- Firma
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid (),
  name text not null,
  created_at timestamptz not null default now()
);

-- App-Nutzerprofil (id = gleiche UUID wie in Authentication → Users)
create table if not exists public.users (
  id uuid not null primary key references auth.users (id) on delete cascade,
  company_id uuid not null references public.companies (id) on delete restrict,
  role text not null check (role in ('mitarbeiter', 'admin', 'superadmin')),
  name text not null,
  email text not null
);

create index if not exists users_company_id_idx on public.users (company_id);

-- Row Level Security
alter table public.companies enable row level security;
alter table public.users enable row level security;

drop policy if exists "Lesen eigene Firma" on public.companies;
create policy "Lesen eigene Firma" on public.companies for select using (
  id in (
    select u.company_id
    from public.users u
    where u.id = (select auth.uid())
  )
);

drop policy if exists "Lesen eigenes Profil" on public.users;
create policy "Lesen eigenes Profil" on public.users for select using (id = (select auth.uid()));
