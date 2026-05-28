-- client_payment_plans: piano pagamenti per ogni cliente
create table if not exists public.client_payment_plans (
    id          uuid        primary key default gen_random_uuid(),
    trainer_id  uuid        not null references public.trainers(id) on delete cascade,
    client_id   uuid        not null references public.clients(id)  on delete cascade,
    frequency   text        not null default 'monthly',
    amount      numeric(10,2) not null,
    currency    text        not null default 'EUR',
    start_date  date        not null,
    due_day     integer,
    notes       text,
    status      text        not null default 'active',
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

alter table public.client_payment_plans
    add constraint cpp_frequency_check check (frequency in ('monthly','bimonthly','quarterly','semiannual','annual')),
    add constraint cpp_status_check    check (status    in ('active','paused','cancelled')),
    add constraint cpp_due_day_check   check (due_day is null or (due_day >= 1 and due_day <= 31));

-- client_payments: singole scadenze generate dal piano
create table if not exists public.client_payments (
    id                     uuid        primary key default gen_random_uuid(),
    trainer_id             uuid        not null references public.trainers(id)              on delete cascade,
    client_id              uuid        not null references public.clients(id)               on delete cascade,
    payment_plan_id        uuid        not null references public.client_payment_plans(id)  on delete cascade,
    amount                 numeric(10,2) not null,
    currency               text        not null default 'EUR',
    period_start           date,
    period_end             date,
    due_date               date        not null,
    status                 text        not null default 'due',
    paid_by_client_at      timestamptz,
    trainer_confirmed_at   timestamptz,
    invoice_note_created_at timestamptz,
    created_at             timestamptz not null default now(),
    updated_at             timestamptz not null default now()
);

alter table public.client_payments
    add constraint cp_status_check check (status in ('due','paid_by_client','confirmed','overdue','cancelled'));

-- updated_at triggers
create or replace function public.set_cpp_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger trg_cpp_updated_at
    before update on public.client_payment_plans
    for each row execute function public.set_cpp_updated_at();

create or replace function public.set_cp_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger trg_cp_updated_at
    before update on public.client_payments
    for each row execute function public.set_cp_updated_at();

-- RLS client_payment_plans
alter table public.client_payment_plans enable row level security;

-- trainer: accesso completo ai piani dei propri clienti
create policy "cpp_trainer_select" on public.client_payment_plans
    for select using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cpp_trainer_insert" on public.client_payment_plans
    for insert with check (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cpp_trainer_update" on public.client_payment_plans
    for update using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cpp_trainer_delete" on public.client_payment_plans
    for delete using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

-- cliente: solo lettura del proprio piano
create policy "cpp_client_select" on public.client_payment_plans
    for select using (client_id = (select id from public.clients where user_id = auth.uid()));

-- RLS client_payments
alter table public.client_payments enable row level security;

-- trainer: accesso completo ai pagamenti dei propri clienti
create policy "cp_trainer_select" on public.client_payments
    for select using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cp_trainer_insert" on public.client_payments
    for insert with check (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cp_trainer_update" on public.client_payments
    for update using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

create policy "cp_trainer_delete" on public.client_payments
    for delete using (trainer_id = (select id from public.trainers where user_id = auth.uid()));

-- cliente: lettura propri pagamenti
create policy "cp_client_select" on public.client_payments
    for select using (client_id = (select id from public.clients where user_id = auth.uid()));

-- cliente: può aggiornare solo status da 'due' a 'paid_by_client'
create policy "cp_client_mark_paid" on public.client_payments
    for update
    using (
        client_id = (select id from public.clients where user_id = auth.uid())
        and status = 'due'
    )
    with check (
        client_id = (select id from public.clients where user_id = auth.uid())
        and status = 'paid_by_client'
    );

-- TRIGGER: quando cliente segna pagamento come fatto → crea nota trainer "Fare fattura"
create or replace function public.on_client_payment_marked_paid()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_client_name text;
    v_amount_str  text;
    v_due_str     text;
begin
    if new.status = 'paid_by_client'
       and (old.status is distinct from 'paid_by_client')
       and new.invoice_note_created_at is null
    then
        select first_name || ' ' || last_name
          into v_client_name
          from public.clients
         where id = new.client_id;

        v_amount_str := to_char(new.amount, 'FM999990.00');
        v_due_str    := to_char(new.due_date, 'DD/MM/YYYY');

        insert into public.trainer_personal_notes (
            trainer_id,
            title,
            body,
            priority,
            status,
            source,
            related_client_id,
            related_payment_id
        ) values (
            new.trainer_id,
            'Fare fattura a ' || coalesce(v_client_name, 'cliente'),
            'Il cliente ' || coalesce(v_client_name, '') || ' ha segnato come pagato il pagamento di '
                || v_amount_str || ' € con scadenza ' || v_due_str
                || '. Verificare e procedere con fattura.',
            'critical',
            'open',
            'payment',
            new.client_id,
            new.id
        );

        new.invoice_note_created_at := now();
    end if;
    return new;
end;
$$;

create trigger trg_client_payment_marked_paid
    before update on public.client_payments
    for each row execute function public.on_client_payment_marked_paid();

-- indexes
create index if not exists idx_cpp_trainer_id  on public.client_payment_plans(trainer_id);
create index if not exists idx_cpp_client_id   on public.client_payment_plans(client_id);
create index if not exists idx_cp_trainer_id   on public.client_payments(trainer_id);
create index if not exists idx_cp_client_id    on public.client_payments(client_id);
create index if not exists idx_cp_due_date     on public.client_payments(due_date);
create index if not exists idx_cp_status       on public.client_payments(status);
create index if not exists idx_cp_plan_id      on public.client_payments(payment_plan_id);

grant select, insert, update, delete on public.client_payment_plans to authenticated;
grant select, insert, update, delete on public.client_payments        to authenticated;
