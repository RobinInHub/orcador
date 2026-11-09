begin;
create table if not exists public.orcador_clientes (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 nome text not null check (length(trim(nome)) between 1 and 200),
 telefone text not null default '', endereco text not null default '',
 version integer not null default 1 check (version > 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique (id,user_id)
);
create table if not exists public.orcador_orcamentos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id), cliente_id uuid not null,
 titulo text not null check (length(trim(titulo)) between 1 and 200),
 payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
 version integer not null default 1 check (version > 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 foreign key (cliente_id,user_id) references public.orcador_clientes(id,user_id) on delete restrict
);
create index if not exists orcador_clientes_owner on public.orcador_clientes(user_id,updated_at desc);
create index if not exists orcador_orcamentos_owner on public.orcador_orcamentos(user_id,cliente_id,updated_at desc);
create or replace function public.orcador_touch() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists orcador_clientes_touch on public.orcador_clientes;
create trigger orcador_clientes_touch before update on public.orcador_clientes for each row execute function public.orcador_touch();
drop trigger if exists orcador_orcamentos_touch on public.orcador_orcamentos;
create trigger orcador_orcamentos_touch before update on public.orcador_orcamentos for each row execute function public.orcador_touch();
alter table public.orcador_clientes enable row level security;
alter table public.orcador_orcamentos enable row level security;
revoke all on public.orcador_clientes, public.orcador_orcamentos from anon;
grant select,insert,update,delete on public.orcador_clientes, public.orcador_orcamentos to authenticated;
drop policy if exists orcador_clientes_owner on public.orcador_clientes;
create policy orcador_clientes_owner on public.orcador_clientes for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists orcador_orcamentos_owner on public.orcador_orcamentos;
create policy orcador_orcamentos_owner on public.orcador_orcamentos for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
commit;
