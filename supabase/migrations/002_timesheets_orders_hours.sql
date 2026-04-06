-- DoorDesk: Aufträge, Zuordnung zu Mitarbeitern, Stundenbuchungen
-- Eine Zeile in `hours` ist gleichzeitig persönlicher Eintrag und Auftrags-Stundenzettel (Filter: user_id vs. order_id).

-- Aufträge
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid (),
  company_id uuid not null references public.companies (id) on delete restrict,
  title text not null,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_at timestamptz not null default now()
);

create index if not exists orders_company_id_idx on public.orders (company_id);

-- Wer ist am Auftrag beteiligt ( Dropdown „Auftrag“ nur für zugewiesene Aufträge )
create table if not exists public.order_assignments (
  order_id uuid not null references public.orders (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  primary key (order_id, user_id)
);

create index if not exists order_assignments_user_id_idx on public.order_assignments (user_id);

-- Stundenbuchungen (0,25 h Schritte — Prüfung in App + DB )
create table if not exists public.hours (
  id uuid primary key default gen_random_uuid (),
  company_id uuid not null references public.companies (id) on delete restrict,
  user_id uuid not null references public.users (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete restrict,
  work_date date not null,
  hours numeric(5, 2) not null check (
    hours >= 0.25
    and hours <= 24
    and (round((hours * 4)::numeric) = (hours * 4)::numeric)
  ),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists hours_user_work_date_idx on public.hours (user_id, work_date);
create index if not exists hours_order_id_idx on public.hours (order_id);
create index if not exists hours_company_id_idx on public.hours (company_id);

create or replace function public.set_hours_updated_at ()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists hours_set_updated_at on public.hours;
create trigger hours_set_updated_at
before update on public.hours
for each row
execute function public.set_hours_updated_at ();

-- Realtime ( Admin sieht Änderungen mit passender RLS-Politik )
alter table public.hours replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.hours;
exception
  when duplicate_object then null;
end;
$$;

-- RLS
alter table public.orders enable row level security;
alter table public.order_assignments enable row level security;
alter table public.hours enable row level security;

-- Hilfsbedingung: Nutzer gehört Firma
drop policy if exists "orders_select_company" on public.orders;
create policy "orders_select_company" on public.orders for select using (
  company_id in (select u.company_id from public.users u where u.id = (select auth.uid ()))
  and (
    exists (
      select 1
      from public.users u
      where u.id = (select auth.uid ())
        and u.role in ('admin', 'superadmin')
    )
    or exists (
      select 1
      from public.order_assignments oa
      where oa.order_id = orders.id
        and oa.user_id = (select auth.uid ())
    )
  )
);

drop policy if exists "orders_manage_admin" on public.orders;
create policy "orders_manage_admin" on public.orders for all using (
  exists (
    select 1
    from public.users u
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = orders.company_id
  )
)
with check (
  company_id in (select u.company_id from public.users u where u.id = (select auth.uid ()))
);

-- Mitarbeiter: Zuordnungen nur lesen (eigene Zeilen )
drop policy if exists "order_assignments_select_own" on public.order_assignments;
create policy "order_assignments_select_own" on public.order_assignments for select using (
  user_id = (select auth.uid ())
  or exists (
    select 1
    from public.users u
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = (
        select o.company_id
        from public.orders o
        where o.id = order_assignments.order_id
      )
  )
);

drop policy if exists "order_assignments_manage_admin" on public.order_assignments;
create policy "order_assignments_manage_admin" on public.order_assignments for all using (
  exists (
    select 1
    from public.users u
    join public.orders o on o.id = order_assignments.order_id
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = o.company_id
  )
)
with check (
  exists (
    select 1
    from public.users u
    join public.orders o2 on o2.id = order_assignments.order_id
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = o2.company_id
  )
);

drop policy if exists "hours_select" on public.hours;
create policy "hours_select" on public.hours for select using (
  user_id = (select auth.uid ())
  or exists (
    select 1
    from public.users u
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = hours.company_id
  )
);

drop policy if exists "hours_insert_own" on public.hours;
create policy "hours_insert_own" on public.hours for insert with check (
  user_id = (select auth.uid ())
  and company_id = (select u.company_id from public.users u where u.id = (select auth.uid ()))
  and exists (
    select 1
    from public.orders o
    where o.id = order_id
      and o.company_id = hours.company_id
  )
  and (
    exists (
      select 1
      from public.users u
      where u.id = (select auth.uid ())
        and u.role in ('admin', 'superadmin')
    )
    or exists (
      select 1
      from public.order_assignments oa
      where oa.order_id = hours.order_id
        and oa.user_id = (select auth.uid ())
    )
  )
);

drop policy if exists "hours_update_own" on public.hours;
create policy "hours_update_own" on public.hours for update using (
  user_id = (select auth.uid ())
  or exists (
    select 1
    from public.users u
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = hours.company_id
  )
)
with check (
  company_id = (select u.company_id from public.users u where u.id = (select auth.uid ()))
  and (
    exists (
      select 1
      from public.users u
      where u.id = (select auth.uid ())
        and u.role in ('admin', 'superadmin')
    )
    or exists (
      select 1
      from public.order_assignments oa
      where oa.order_id = hours.order_id
        and oa.user_id = (select auth.uid ())
    )
  )
);

drop policy if exists "hours_delete_own" on public.hours;
create policy "hours_delete_own" on public.hours for delete using (
  user_id = (select auth.uid ())
  or exists (
    select 1
    from public.users u
    where u.id = (select auth.uid ())
      and u.role in ('admin', 'superadmin')
      and u.company_id = hours.company_id
  )
);
