-- Migration: add day_of_week to meals table
-- 1 = Lunedì, 2 = Martedì, 3 = Mercoledì, 4 = Giovedì,
-- 5 = Venerdì, 6 = Sabato, 7 = Domenica

alter table public.meals
  add column if not exists day_of_week integer
    check (day_of_week between 1 and 7);

comment on column public.meals.day_of_week is
  'Day of week for this meal slot. 1=Monday … 7=Sunday. NULL means a single daily plan without weekly grouping.';

create index if not exists idx_meals_plan_day
  on public.meals(nutrition_plan_id, day_of_week, meal_order);
