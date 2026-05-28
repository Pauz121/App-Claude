-- saved_meals: pasti ricorrenti del trainer, riutilizzabili nelle diete
create table if not exists public.saved_meals (
    id          uuid primary key default gen_random_uuid(),
    trainer_id  uuid not null references public.trainers(id) on delete cascade,
    name        text not null,
    description text,
    notes       text,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

-- saved_meal_foods: alimenti dal catalogo associati a un pasto salvato
create table if not exists public.saved_meal_foods (
    id               uuid primary key default gen_random_uuid(),
    saved_meal_id    uuid not null references public.saved_meals(id) on delete cascade,
    food_catalog_id  uuid references public.food_catalog(id) on delete set null,
    name             text not null,
    quantity_grams   numeric(8,2) not null default 100,
    calories_per_100g numeric(8,2),
    protein_per_100g  numeric(8,2),
    carb_per_100g     numeric(8,2),
    fat_per_100g      numeric(8,2),
    created_at       timestamptz not null default now()
);

-- updated_at trigger for saved_meals
create or replace function public.set_saved_meals_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger trg_saved_meals_updated_at
    before update on public.saved_meals
    for each row execute function public.set_saved_meals_updated_at();

-- RLS
alter table public.saved_meals      enable row level security;
alter table public.saved_meal_foods enable row level security;

-- saved_meals: trainer owns their own rows
create policy "trainer_select_saved_meals" on public.saved_meals
    for select using (
        trainer_id = (select id from public.trainers where user_id = auth.uid())
    );

create policy "trainer_insert_saved_meals" on public.saved_meals
    for insert with check (
        trainer_id = (select id from public.trainers where user_id = auth.uid())
    );

create policy "trainer_update_saved_meals" on public.saved_meals
    for update using (
        trainer_id = (select id from public.trainers where user_id = auth.uid())
    );

create policy "trainer_delete_saved_meals" on public.saved_meals
    for delete using (
        trainer_id = (select id from public.trainers where user_id = auth.uid())
    );

-- saved_meal_foods: access via parent saved_meal ownership
create policy "trainer_select_saved_meal_foods" on public.saved_meal_foods
    for select using (
        exists (
            select 1 from public.saved_meals sm
            where sm.id = saved_meal_id
              and sm.trainer_id = (select id from public.trainers where user_id = auth.uid())
        )
    );

create policy "trainer_insert_saved_meal_foods" on public.saved_meal_foods
    for insert with check (
        exists (
            select 1 from public.saved_meals sm
            where sm.id = saved_meal_id
              and sm.trainer_id = (select id from public.trainers where user_id = auth.uid())
        )
    );

create policy "trainer_update_saved_meal_foods" on public.saved_meal_foods
    for update using (
        exists (
            select 1 from public.saved_meals sm
            where sm.id = saved_meal_id
              and sm.trainer_id = (select id from public.trainers where user_id = auth.uid())
        )
    );

create policy "trainer_delete_saved_meal_foods" on public.saved_meal_foods
    for delete using (
        exists (
            select 1 from public.saved_meals sm
            where sm.id = saved_meal_id
              and sm.trainer_id = (select id from public.trainers where user_id = auth.uid())
        )
    );

-- indexes
create index if not exists idx_saved_meals_trainer_id     on public.saved_meals(trainer_id);
create index if not exists idx_saved_meal_foods_meal_id   on public.saved_meal_foods(saved_meal_id);
create index if not exists idx_saved_meal_foods_catalog_id on public.saved_meal_foods(food_catalog_id);

-- grants
grant select, insert, update, delete on public.saved_meals      to authenticated;
grant select, insert, update, delete on public.saved_meal_foods to authenticated;
