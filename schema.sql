-- Run in Supabase: SQL Editor > New query > paste > Run. Safe to run again on top of an earlier version.
create table if not exists public.guests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  party text not null,
  child text not null,                       -- a child id from the invitation content, or 'family'
  label text not null check (char_length(label) between 1 and 120),
  code text not null unique check (code ~ '^[A-Z0-9]{8}$')
);
create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  party text not null,
  child text not null,
  guest_id uuid unique references public.guests(id) on delete cascade,
  parent_name text not null check (char_length(parent_name) between 1 and 120),
  child_name text not null check (char_length(child_name) between 1 and 120),
  status text not null check (status in ('yes','maybe','no')),
  adults int not null default 0 check (adults between 0 and 20),
  kids int not null default 0 check (kids between 0 and 20),
  diet text check (char_length(diet) <= 300),
  phone text check (char_length(phone) <= 40),
  note text check (char_length(note) <= 500),
  source text not null default 'form' check (source in ('form','manual'))
);
-- The words on the invitations live here, one row per party, edited from admin.html
create table if not exists public.party_content (
  party text primary key,
  content jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.guests enable row level security;
alter table public.rsvps enable row level security;
alter table public.party_content enable row level security;
-- No policies for guests (anonymous visitors): they can't touch any table directly.
drop policy if exists "hosts manage guests" on public.guests;
drop policy if exists "hosts manage rsvps" on public.rsvps;
drop policy if exists "hosts manage content" on public.party_content;
create policy "hosts manage guests" on public.guests for all to authenticated using (true) with check (true);
create policy "hosts manage rsvps" on public.rsvps for all to authenticated using (true) with check (true);
create policy "hosts manage content" on public.party_content for all to authenticated using (true) with check (true);

-- Guests only ever use these two functions, and only with a valid code.
create or replace function public.get_invite(p_code text) returns json
language sql security definer set search_path = public as $$
  select json_build_object(
    'label', g.label, 'child', g.child, 'party', g.party,
    'rsvp', (select row_to_json(r) from (select parent_name, child_name, status, adults, kids, diet, phone, note from public.rsvps where guest_id = g.id) r),
    'content', (select pc.content - 'contact' from public.party_content pc where pc.party = g.party),
    -- contact details are only revealed once this guest has replied
    'contact', case when exists (select 1 from public.rsvps where guest_id = g.id)
                    then (select pc.content -> 'contact' from public.party_content pc where pc.party = g.party) end)
  from public.guests g
  where g.code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'))
  limit 1
$$;

create or replace function public.submit_rsvp(p_code text, p_parent text, p_child_name text, p_status text,
  p_adults int, p_kids int, p_diet text, p_phone text, p_note text) returns boolean
language plpgsql security definer set search_path = public as $$
declare g public.guests%rowtype;
begin
  select * into g from public.guests where code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  if not found then return false; end if;
  insert into public.rsvps (party, child, guest_id, parent_name, child_name, status, adults, kids, diet, phone, note, source)
  values (g.party, g.child, g.id, left(p_parent,120), left(p_child_name,120), p_status,
          greatest(0, least(20, coalesce(p_adults,0))), greatest(0, least(20, coalesce(p_kids,0))),
          left(p_diet,300), left(p_phone,40), left(p_note,500), 'form')
  on conflict (guest_id) do update set parent_name = excluded.parent_name, child_name = excluded.child_name,
    status = excluded.status, adults = excluded.adults, kids = excluded.kids, diet = excluded.diet,
    phone = excluded.phone, note = excluded.note, child = excluded.child, updated_at = now();
  return true;
end $$;

revoke all on function public.get_invite(text) from public;
revoke all on function public.submit_rsvp(text,text,text,text,int,int,text,text,text) from public;
grant execute on function public.get_invite(text) to anon, authenticated;
grant execute on function public.submit_rsvp(text,text,text,text,int,int,text,text,text) to anon, authenticated;

do $$ begin alter publication supabase_realtime add table public.rsvps; exception when others then null; end $$;
