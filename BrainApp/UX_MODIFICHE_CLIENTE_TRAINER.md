# UX Modifiche Cliente e Trainer

Data creazione: 2026-05-28

Documento delle modifiche UX/UI applicate alle aree trainer e cliente.

---

## Dashboard Trainer — card statistiche e agenda giornaliera

Data: 2026-05-28

### Modifica 1 — Card statistiche

File: `Views/Components/Components.swift` — `struct DashboardStatCard`

Cambiamenti:
- `FitIconChip` size: `30` → `44` (icona più grande e visibile nel box arrotondato)
- Spacing VStack: `10` → `12`
- Spacer minLength: `4` → `6`
- minHeight card: `110` → `126` (compensa l'icona più grande)

Layout risultante: icona 44pt in box con cornerRadius automatico (`size * 0.3`), numero grande sotto, label secondaria, delta badge in alto a destra. Stile invariato (bgCard, shadow 0.04, border 0.06).

### Modifica 2 — Sezione "Agenda di oggi"

File: `Views/Trainer/TrainerViews.swift` — `TrainerDashboardView`
File: `ViewModels/TrainerViewModels.swift` — `TrainerDashboardViewModel`

**ViewModel** — aggiunte due computed property:
- `appointmentsForToday: [Appointment]` — filtra `appointments` per `isDateInToday($0.startTime)`, ordinati per `startTime`
- `clientName(for:) -> String` — risolve `clientID → fullName` dalla lista `clients` già caricata

**View** — aggiunta tra `kpiGrid` e `quickActions`:
- `SectionLabel("Agenda di oggi")`
- `todayAgenda` computed var: `FitCard` con branch vuoto/pieno
  - **Empty state**: icona calendar, testo "Nessun appuntamento oggi", CTA "Aggiungi appuntamento →" che apre `showingAddAppointment`
  - **Lista**: `DashboardAgendaRow` per ogni appuntamento + divider tra righe + link "Vai all'agenda →" che naviga a `AppointmentsCalendarView`

**Componente** — nuovo `private struct DashboardAgendaRow`:
- Colonna orario a sinistra (52pt): `HH:mm` + durata in minuti
- Barra colorata verticale (3pt): colore per status (indigo=programmato, teal=completato, amber=annullato)
- Colonna contenuto: nome cliente (bold), badge tipo sessione + badge stato, nota (1 riga troncata se presente)

**Colori status:**
- `.scheduled` → `indigo`
- `.completed` → `teal`
- `.cancelled` → `amber`

**Colori tipo sessione:**
- `.workout` → `limeDark`
- `.assessment` → `indigo`
- `.nutrition` → `teal`
- `.checkin` → `amber`
- `.recovery` → `txtSecondary`

**Dati:** reali da Supabase via `appointmentService.fetchAppointments(forTrainer:)` già chiamato in `load()`. Nessuna modifica a DB/Auth/Supabase.

---

## UX Modifiche Area Cliente e Trainer — Sessione precedente

Data: 2026-05-27

### Trainer

- `TrainerConversationView` header: `AvatarView` → `UserAvatarView`
- `TrainerMessagesView.conversationRow`: `AvatarView` → `UserAvatarView`
- `TrainerDashboardView.quickActions`: sostituito con `QuickActionCard` grid 2 colonne
- `ClientDetailView` header: layout compatto HStack con `UserAvatarView(size: 52)`
- `AppointmentsCalendarView` header: centrato
- Aggiunto bell icon con badge amber in dashboard header
- Rimosso blocco Feedback & Alert dalla dashboard → sheet separato `TrainerNotificationsSheet`
- `AppointmentsViewModel.weekDates()`: settimana parte da lunedì (Calendar firstWeekday=2)

### Cliente

- Dashboard: calorie card collegata a `viewModel.activeNutritionPlan?.dailyCalories` (era hardcoded "2.350")
- `ClientProgressView`: init aggiornato con `workoutService` per `exerciseWeightHistory`
- `exerciseChart()`: usa `viewModel.exerciseWeightHistory.filter { $0.exerciseId == exercise.id }` invece di bodyweight entries
- `ClientNutritionView`: `NavigationStack(path:)` + auto-naviga al giorno odierno (offset 0) al caricamento del piano
- `ClientWorkoutView`: settimane collassabili via `weekGroups(for:)` + `@State expandedWeek: Int? = 1`
- `ClientProfileView`: `PhotosPicker` con badge camera, preview immagine locale selezionata
- `ClientChatView.chatHeader`: `AvatarView` → `UserAvatarView`

### Nuovi componenti in Components.swift

- `UserAvatarView`: `AsyncImage` + fallback initials, parametri `imageUrl`, `firstName`, `lastName`, `size`, `gradient`
- `TrainerNotificationsSheet`: lista insights del trainer in sheet
- `QuickActionCard`: card con icona + titolo + subtitle, `KPICardButtonStyle`
- `DashboardStatCard`: card KPI con icon box, numero, label, delta badge
- `KPICardButtonStyle`: scala 0.97 on press

---

## Agenda trainer — vista settimana corretta + linea appuntamenti

Data: 2026-05-28

### File modificati

- `ViewModels/TrainerViewModels.swift` — `weekDates()`
- `Views/Trainer/TrainerViews.swift` — `AppointmentsCalendarView.weekView` + nuovo `weekDayCell(date:)`

### Fix `weekDates()` — lunedì garantito

Vecchio approccio (`yearForWeekOfYear/weekOfYear`) aveva edge case su alcune locale/timezone.

Nuovo calcolo diretto:
```swift
let weekday = cal.component(.weekday, from: selectedDate)  // Sun=1, Mon=2..Sat=7
let daysFromMonday = (weekday - 2 + 7) % 7                 // Mon=0, Tue=1..Sun=6
let monday = selectedDate - daysFromMonday days
// week = monday + [0,1,2,3,4,5,6]
```

Risultato garantito: **7 date sempre da Lunedì a Domenica**.

### Nuovo `weekDayCell(date:)` — sostituzione dots con linea

Sostituisce il vecchio `ForEach(0..<min(appointmentCount,3)) { RoundedRectangle(height: 8) }`.

**Nuovo indicatore appuntamenti:**
```
Capsule().frame(width: 20, height: 2.5)
```
- Singola linea sottile 20×2.5pt
- Capsula arrotondata = elegante, non spessa
- Colore: `Color.white.opacity(0.78)` su selezione, `txtPrimary.opacity(0.68)` su default
- `Color.clear.frame(height: 2.5)` se nessun appuntamento (mantiene altezza costante)

**Indicatore oggi (non selezionato):**
- Bordo 1.5pt, `txtPrimary.opacity(0.4)` — distinguibile senza aggressività

**Stato selezionato:**
- Background `txtPrimary` (nero), testo bianco, no bordo

**Dimensioni cella:** 84pt altezza (era 102pt) — più compatta

### Struttura visiva risultante

```
Lun   Mar   Mer   Gio   Ven   Sab   Dom
  L     M     M     G     V     S     D   ← prima lettera
  12    13   [14]   15    16    17    18  ← giorno ([] = oggi con bordo)
        ━          ━                      ← linea se ha appuntamenti
```
`[...]` = selected (sfondo nero)

---

## Dettaglio cliente trainer — sezione Progressi ridisegnata

Data: 2026-05-28

### Obiettivo

Sostituire il tab Progressi (grafico barre semplice peso) con una vista completa separata in due sezioni: peso+misure e progressi esercizi con sparkline.

### File modificato

`Views/Trainer/TrainerViews.swift`

### Migration creata

`supabase/migrations/20260528140000_exercise_progress_entries.sql`

### Modifiche a `ClientDetailView`

**Stato aggiunto:** `@State private var exerciseHistory: [ExerciseWeightHistoryDTO] = []`

**`.task` aggiornato:** carica anche `services.workoutService.fetchExerciseWeightHistory(for: client.id)`

**`progressTab`** — sostituito con card tappabile `progressSummaryCard` → `NavigationLink → TrainerClientProgressView`

**`progressSummaryCard`** mostra:
- Peso attuale (verde lime)
- Differenza dall'inizio (teal se calo, amber se aumento)
- N. esercizi tracciati (se > 0)
- Chevron →

### Nuovi struct

**`ExerciseProgressGroup`** (private struct):
- `exerciseId: UUID`, `name: String`, `entries: [ExerciseWeightHistoryDTO]` sorted asc
- Computed: `firstWeight`, `lastWeight`, `gain`

**`TrainerClientProgressView`** (struct pubblico):
- `Picker` segmented "Peso" | "Esercizi"
- **Sezione Peso** (`segment == 0`):
  - 3 stat card: Inizio, Attuale, Diff.
  - Grafico linea + area fill (`LineMark + AreaMark`, `interpolationMethod: .catmullRom`) su `progress_entries.weightKg` nel tempo
  - X-axis: mesi (`AxisMarks stride by .month`)
  - `chartYScale(domain: .automatic(includesZero: false))` — peso non parte da 0
  - Empty state se < 2 misurazioni
  - Se `hasMeasurements`: griglia 2×2 misure corporee (vita, petto, braccio, coscia)
- **Sezione Esercizi** (`segment == 1`):
  - Lista `ExerciseSparklineCard` per ogni esercizio
  - Empty state se nessun dato
  - `exerciseNameMap` risolve UUID → nome da `workoutPlans.flatMap(\.days).flatMap(\.exercises)`
  - Fallback nome: `"Esercizio (\(id.prefix(6)))"`

**`ExerciseSparklineCard`** (private struct):
- Nome esercizio, `X.X kg → Y.Y kg`, badge guadagno ±
- Mini sparkline 68×38pt: `LineMark` solo, assi nascosti, `chartYScale(includesZero: false)`
- NavigationLink → `TrainerClientExerciseProgressDetailView`

**`TrainerClientExerciseProgressDetailView`** (struct pubblico):
- 3 stat card: Primo, Ultimo, Guadagno
- Grafico full `LineMark + AreaMark + PointMark` con x-axis label date (dd/MM)
- Lista storico sessioni (più recente in cima) con chip S1…SN, peso, data formattata italiano

### Separazione dato dati

| Sezione | Fonte | Tabella |
|---------|-------|---------|
| Peso | `progressEntries: [ProgressEntry]` | `progress_entries` |
| Esercizi | `exerciseHistory: [ExerciseWeightHistoryDTO]` | `exercise_weight_history` |

Zero crossover — nessun dato incrociato tra le due sezioni.

### Migration `exercise_progress_entries`

Tabella futura più ricca per sostituire `exercise_weight_history`:
- `exercise_name text not null` — nome sempre disponibile senza join
- `exercise_id`, `machine_id`, `workout_plan_id` — riferimenti opzionali
- `weight_used`, `reps`, `sets` — metriche sessione
- RLS completa: trainer CRUD propri clienti, cliente read+insert propri dati
- Trigger `updated_at`

Oggi la UI usa ancora `exercise_weight_history` (già popolata da `WeightEditSheet`). La nuova tabella è pronta per migrazione futura.

---

## Dettaglio cliente trainer — schede e diete cliccabili

Data: 2026-05-28

### Obiettivo

Rendere la scheda e la dieta nel dettaglio cliente cliccabili, aprendo pagine di navigazione con lista completa (attuale + storiche) e dettaglio completo per ogni piano.

### File modificato

`Views/Trainer/TrainerViews.swift`

### Modifiche a `ClientDetailView`

**`scheduleTab`** — rimosso flat list giorni + bottone non funzionale. Sostituito con:
- Card tappabile `workoutPlanSummaryCard` che mostra: nome, obiettivo, stato badge, N giorni, N esercizi, date inizio/fine
- `NavigationLink → TrainerClientWorkoutPlansView(client:workoutPlans:)`
- Empty state se nessuna scheda caricata

**`dietTab`** — rimosso display statico + bottone non funzionale. Sostituito con:
- Card tappabile `nutritionPlanSummaryCard` che mostra: kcal, macros (P/C/G), badge "Attivo", date inizio/fine
- `NavigationLink → TrainerClientNutritionPlansView(client:nutritionPlans:)`
- Empty state se nessun piano caricato

Dati: già caricati nel `.task` esistente via `workoutService.fetchWorkoutPlans(forClient:)` e `nutritionService.fetchNutritionPlans(forClient:)`. Nessuna nuova chiamata Supabase.

### Nuovi struct

**`TrainerClientWorkoutPlansView`** (struct pubblico):
- Sezione "Scheda attiva" con piano `status == .active` in evidenza (bordo indigo 2pt)
- Sezione "Storiche (N)" per piani restanti
- Ogni card → `NavigationLink → TrainerClientWorkoutPlanDetailView`
- Empty state se `workoutPlans.isEmpty`

**`TrainerClientWorkoutPlanDetailView`** (struct pubblico):
- Header card: nome, obiettivo, stato badge, N giorni, N esercizi, date
- Lista giorni collassabile (`expandedDay: UUID?`)
- Ogni giorno espandibile mostra lista `TrainerExerciseRow`

**`TrainerExerciseRow`** (struct privato):
- Chip indice (indigo), nome esercizio, `sets×reps`, recupero, carico, note tecniche (max 2 righe)

**`TrainerClientNutritionPlansView`** (struct pubblico):
- Sezione "Piano attivo" con primo piano in evidenza (bordo teal 2pt)
- Sezione "Storici (N)" per piani restanti
- Ogni card → `NavigationLink → TrainerClientNutritionPlanDetailView`
- Empty state se `nutritionPlans.isEmpty`

**`TrainerClientNutritionPlanDetailView`** (struct pubblico):
- Header card: "Piano alimentare", obiettivo kg, kcal giornaliere, macro P/C/G, date
- Se `plan.meals.isEmpty`: card info "Pasti non ancora caricati"
- Se pasti con `dayIndex > 0`: sezione "Piano settimanale" con giorni Lunedì–Domenica collassabili
- Ogni giorno espandibile mostra `TrainerMealRow`
- Se pasti senza raggruppamento: lista flat `TrainerMealRow`
- Sezione "Note" se presente

**`TrainerMealRow`** (struct privato):
- Header: icona fork.knife, nome pasto, kcal stimati, chevron
- Espandibile: lista alimenti con nome, quantità, macros, kcal per alimento
- kcal: usa `meal.foods.reduce(kcal)` se disponibile, altrimenti `dailyKcal / totalMeals`

### Navigazione

Flusso: `ClientsListView (NavigationStack)` → `ClientDetailView` → tab Scheda/Dieta → `TrainerClientWorkout/NutritionPlansView` → `TrainerClientWorkout/NutritionPlanDetailView`

Navigation stack unico, back button automatico iOS.

---

## Wizard "Crea nuova dieta" — ridisegno completo

Data: 2026-05-28

### Obiettivo

Sostituire il wizard generico con un flusso strutturato a 3 livelli:
1. Selezione giorni (Lunedì–Domenica)
2. Pagina giorno con 6 slot pasto fissi
3. Editor alimenti per ogni pasto, con ricerca catalogo Supabase

### File modificati

- `Views/Trainer/TrainerForms.swift`
- `Services/SupabaseDTOs.swift`
- `Services/AppServices.swift`
- `supabase/migrations/20260528120000_meals_day_of_week.sql` (NEW)

### Struttura dati locale wizard

```
NutritionDay (7 giorni, dayIndex 1–7)
  └── [Meal] (6 pasti fissi)
        └── [MealFood] (alimenti aggiunti dall'utente)
```

`NutritionDay`: `id, dayIndex, label ("Lunedì"…), meals: [Meal]`
`Meal`: `id, name, targetCalories, time, notes, foods: [MealFood], dayIndex`
`MealFood`: `id, name, quantity, notes, proteinGrams, carbGrams, fatGrams`

### Slot pasto fissi (6 per giorno)

| Slot | Nome | Ora default |
|------|------|-------------|
| 0 | Colazione | 07:00 |
| 1 | Spuntino mattina | 10:00 |
| 2 | Pranzo | 13:00 |
| 3 | Spuntino pomeridiano | 16:00 |
| 4 | Cena | 20:00 |
| 5 | Pre-nanna | 22:00 |

### Nuovi componenti in TrainerForms.swift

**`IdentifiableInt`**: wrapper `struct IdentifiableInt: Identifiable { var id: Int }` per usare `.sheet(item:)` con indice `Int`.

**`NutritionWeekDayRow`**: riga giorno nella lista Step 2.
- Chip giorno (1–7), teal se giorno ha kcal
- Label giorno (Lunedì–Domenica)
- Sommario: `N pasti · XXX kcal`
- Checkmark se tutti i pasti hanno almeno 1 alimento
- Chevron → apre `NutritionDayDetailSheet`

**`NutritionDayDetailSheet`**: sheet fullscreen per un giorno.
- Header card: totali giorno (kcal, P/C/G)
- Lista 6 pasti con bottone → apre `MealFoodEditorSheet`
- Menu "Aggiungi pasto" per slot extra

**`MealFoodEditorSheet`**: editor alimenti per un pasto.
- `SearchBar` filtra `[FoodCatalogDTO]` in memoria (caricati da `CatalogService`)
- Panel aggiunta: stepper quantità (grammi), preview live kcal/P/C/G animata
- Lista alimenti aggiunti con swipe-delete
- Card totali pasto
- `commitFood()`: calcola macros proporzionali, costruisce `MealFood`, append a `meal.foods`

### Formula kcal/macros

```
kcal = caloriesPer100g * quantityGrams / 100
      oppure (protein*4 + carbs*4 + fats*9) se caloriesPer100g è nil
protein = proteinsPer100g * quantityGrams / 100
carbs   = carbsPer100g   * quantityGrams / 100
fats    = fatsPer100g    * quantityGrams / 100
```

### Persistenza su Supabase

`NutritionService.createNutritionPlan` ora salva in sequenza:
1. INSERT `nutrition_plans` → ottieni `plan.id`
2. Per ogni giorno → per ogni pasto: INSERT `meals` con `day_of_week = meal.dayIndex`
3. Per ogni `MealFood`: INSERT `meal_foods` con kcal/macros calcolati

**DTOs aggiunti in `SupabaseDTOs.swift`:**
- `MealDTO`: `id, nutritionPlanId, name, mealTime, mealOrder, dayOfWeek, notes`
- `MealFoodDTO`: `id, mealId, foodName, quantity, calories, proteinsG, carbsG, fatsG, notes`

### Migration DB

File: `supabase/migrations/20260528120000_meals_day_of_week.sql`

```sql
alter table public.meals
  add column if not exists day_of_week integer check (day_of_week between 1 and 7);
create index if not exists idx_meals_plan_day
  on public.meals(nutrition_plan_id, day_of_week, meal_order);
```

Semantica: `1=Lunedì, 7=Domenica`. `NULL` = piano senza raggruppamento settimanale.

### Cosa testare su Xcode

- Step 2 mostra 7 righe (Lunedì–Domenica)
- Tap riga apre sheet giorno con 6 slot
- Ricerca catalogo filtra correttamente (case-insensitive, nome+categoria)
- Stepper quantità aggiorna preview live
- `commitFood` aggiunge alimento alla lista
- Totali giorno si aggiornano dopo ogni `commitFood`
- Salvataggio crea piano + 42 pasti (7gg × 6) + alimenti su Supabase
- `day_of_week` salvato correttamente (1–7)

### Limitazioni note

- `fetchNutritionPlans` non carica ancora meals/foods da Supabase (solo header piano)
- Sheet doppio (`showingSavedMealPicker` + `selectedDayForEdit`) richiede iOS 16.4+
