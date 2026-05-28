-- Migration: exercise_progress_entries
-- Tabella per tracciare i progressi di carico per esercizio/macchinario.
-- Ricca di metadati: nome esercizio testuale, riferimenti opzionali al catalogo.
-- Da usare in futuro in luogo di exercise_weight_history per la visualizzazione trainer.

create table if not exists public.exercise_progress_entries (
    id                uuid primary key default gen_random_uuid(),
    trainer_id        uuid not null references public.trainers(id) on delete cascade,
    client_id         uuid not null references public.clients(id) on delete cascade,
    exercise_name     text not null,
    exercise_id       uuid null references public.exercises(id) on delete set null,
    machine_id        uuid null references public.machines(id) on delete set null,
    workout_plan_id   uuid null references public.workout_plans(id) on delete set null,
    workout_day_id    uuid null,
    entry_date        date not null default current_date,
    weight_used       numeric(6,2) null,
    reps              integer null,
    sets              integer null,
    notes             text null,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now()
);

comment on table public.exercise_progress_entries is
    'Storico dei carichi usati dal cliente su ogni esercizio/macchinario.';

-- Indici per query comuni
create index if not exists idx_ex_progress_client_exercise
    on public.exercise_progress_entries(client_id, exercise_name, entry_date);

create index if not exists idx_ex_progress_trainer_client
    on public.exercise_progress_entries(trainer_id, client_id);

-- RLS
alter table public.exercise_progress_entries enable row level security;

-- Trainer: legge e scrive per i propri clienti
create policy "trainer_read_exercise_progress"
    on public.exercise_progress_entries for select
    using (
        exists (
            select 1 from public.trainers t
            where t.id = trainer_id
              and t.user_id = auth.uid()
        )
    );

create policy "trainer_insert_exercise_progress"
    on public.exercise_progress_entries for insert
    with check (
        exists (
            select 1 from public.trainers t
            where t.id = trainer_id
              and t.user_id = auth.uid()
        )
    );

create policy "trainer_update_exercise_progress"
    on public.exercise_progress_entries for update
    using (
        exists (
            select 1 from public.trainers t
            where t.id = trainer_id
              and t.user_id = auth.uid()
        )
    );

create policy "trainer_delete_exercise_progress"
    on public.exercise_progress_entries for delete
    using (
        exists (
            select 1 from public.trainers t
            where t.id = trainer_id
              and t.user_id = auth.uid()
        )
    );

-- Cliente: legge solo i propri dati
create policy "client_read_own_exercise_progress"
    on public.exercise_progress_entries for select
    using (
        exists (
            select 1 from public.clients c
            where c.id = client_id
              and c.user_id = auth.uid()
        )
    );

-- Cliente: può inserire i propri dati (per auto-registrazione durante allenamento)
create policy "client_insert_own_exercise_progress"
    on public.exercise_progress_entries for insert
    with check (
        exists (
            select 1 from public.clients c
            where c.id = client_id
              and c.user_id = auth.uid()
        )
    );

-- Trigger updated_at
create or replace function public.set_exercise_progress_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger trg_exercise_progress_updated_at
    before update on public.exercise_progress_entries
    for each row execute function public.set_exercise_progress_updated_at();

-- Grant agli utenti autenticati (RLS filtra comunque chi vede cosa)
grant select, insert, update, delete
    on public.exercise_progress_entries to authenticated;
