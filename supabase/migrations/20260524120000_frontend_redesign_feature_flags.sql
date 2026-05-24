alter table public.clients
  add column if not exists is_registered boolean not null default false,
  add column if not exists access_code text;

update public.clients
set is_registered = (user_id is not null)
where is_registered is distinct from (user_id is not null);

alter table public.workout_plans
  add column if not exists published boolean not null default false;

alter table public.nutrition_plans
  add column if not exists published boolean not null default false;

create table if not exists public.exercise_weight_history (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  session_date date not null default current_date,
  weight_kg numeric(7,2) not null,
  effective_from_session_id uuid,
  created_at timestamptz not null default now(),
  created_by_user_id uuid references public.profiles(id) on delete set null,
  check (weight_kg >= 0)
);

create index if not exists idx_exercise_weight_history_client_exercise
  on public.exercise_weight_history(client_id, exercise_id, session_date);

alter table public.exercise_weight_history enable row level security;

drop policy if exists "exercise_weight_history_select_scoped" on public.exercise_weight_history;
create policy "exercise_weight_history_select_scoped"
on public.exercise_weight_history
for select
to authenticated
using (
  public.is_current_trainer(trainer_id)
  or client_id = public.get_current_client_id()
);

drop policy if exists "exercise_weight_history_insert_scoped" on public.exercise_weight_history;
create policy "exercise_weight_history_insert_scoped"
on public.exercise_weight_history
for insert
to authenticated
with check (
  public.is_current_trainer(trainer_id)
  or client_id = public.get_current_client_id()
);
