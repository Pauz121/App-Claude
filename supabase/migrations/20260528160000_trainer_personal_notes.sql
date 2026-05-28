-- trainer_personal_notes: note private del trainer
create table if not exists public.trainer_personal_notes (
    id                 uuid        primary key default gen_random_uuid(),
    trainer_id         uuid        not null references public.trainers(id) on delete cascade,
    title              text        not null,
    body               text,
    note_date          date,
    note_time          text,       -- formato HH:mm
    priority           text        not null default 'medium',
    status             text        not null default 'open',
    source             text        not null default 'manual',
    related_client_id  uuid        references public.clients(id) on delete set null,
    related_payment_id uuid,       -- soft ref, tabella payments aggiunta in migration successiva
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    completed_at       timestamptz
);

alter table public.trainer_personal_notes
    add constraint tnotes_priority_check check (priority in ('low','medium','high','critical')),
    add constraint tnotes_status_check   check (status   in ('open','completed','archived')),
    add constraint tnotes_source_check   check (source   in ('manual','payment','system'));

-- updated_at trigger
create or replace function public.set_tnotes_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger trg_tnotes_updated_at
    before update on public.trainer_personal_notes
    for each row execute function public.set_tnotes_updated_at();

-- RLS: solo il trainer proprietario
alter table public.trainer_personal_notes enable row level security;

create policy "tnotes_select" on public.trainer_personal_notes
    for select using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "tnotes_insert" on public.trainer_personal_notes
    for insert with check (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "tnotes_update" on public.trainer_personal_notes
    for update using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "tnotes_delete" on public.trainer_personal_notes
    for delete using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

-- indexes
create index if not exists idx_tnotes_trainer_id on public.trainer_personal_notes(trainer_id);
create index if not exists idx_tnotes_note_date  on public.trainer_personal_notes(note_date);
create index if not exists idx_tnotes_priority   on public.trainer_personal_notes(priority);
create index if not exists idx_tnotes_status     on public.trainer_personal_notes(status);

grant select, insert, update, delete on public.trainer_personal_notes to authenticated;
