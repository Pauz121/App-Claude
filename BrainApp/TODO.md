# TODO operativo

Data aggiornamento: 2026-05-29

## Agenda trainer — fix settimana + linea appuntamenti (2026-05-28)

- [x] `weekDates()`: calcolo lunedì con formula `(weekday - 2 + 7) % 7` — robusto, no edge case
- [x] `weekView`: 7 giorni Lun–Dom, rimuovi `.prefix(7)` (già esatto)
- [x] `weekDayCell(date:)`: Capsule 20×2.5pt al posto dei dots multipli
- [x] Indicatore oggi: bordo 1.5pt sottile invece di sfondo pieno
- [x] Selected state: sfondo `txtPrimary` (nero), testo bianco
- [ ] Testare lunedì–domenica su iPhone reale con locale diversa

## Dashboard Trainer + Note + Pagamenti (2026-05-29)

- [x] Dashboard trainer: note personali spostate come primo blocco dopo header
- [x] `todayAgendaWithBanner`: banner appuntamenti integrato in cima alla FitCard agenda (non più standalone)
- [x] `DashboardNoteRow`: riga nota con barra priorità, preview, pill, checkmark button
- [x] `AddTrainerNoteSheet`: form nuova/modifica nota con priority picker e data opzionale
- [x] `TrainerPersonalNotesListView`: lista completa note con filter pills e toggle completate
- [x] `ClientDetailView`: tab "Pagamenti" aggiunto (5° tab)
- [x] `TrainerClientPaymentsView`: vista gestione pagamenti cliente lato trainer
- [x] `CreatePaymentPlanSheet`: form creazione/modifica piano pagamenti
- [x] `TrainerClientPaymentService.confirmPayment`: metodo confirm pagamento
- [x] `ClientDashboardView.paymentsCard`: card pagamenti in dashboard cliente
- [x] `ClientPaymentsView`: vista pagamenti lato cliente con "Segna come pagato"
- [x] `AddClientView`: pagamento opzionale con Toggle (solo nuovo cliente)
- [x] `AddClientView`: copia codice inline (bottone affiancato al codice, non sotto)
- [ ] Testare su Xcode: build con nuovi struct e EnvironmentObject
- [ ] Testare dashboard trainer: ordine sezioni (note → agenda)
- [ ] Testare banner agenda: tap → naviga al tab Agenda
- [ ] Testare AddClientView: sezione pagamento visibile solo per nuovo cliente
- [ ] Testare su Supabase: client_payment_plans + client_payments generati dopo creazione cliente
- [ ] Testare trigger fattura: si attiva su paid_by_client
- [ ] Testare confirmPayment: aggiorna status + trainer_confirmed_at

## Dashboard Trainer — card statistiche e agenda giornaliera (2026-05-28)

- [x] `DashboardStatCard`: icona 44pt (era 30pt), minHeight 126
- [x] `TrainerDashboardViewModel`: aggiunto `appointmentsForToday` e `clientName(for:)`
- [x] `TrainerDashboardView`: sezione "Agenda di oggi" con empty state e lista reale
- [x] `DashboardAgendaRow`: orario, durata, barra colorata, nome cliente, tipo, stato, nota
- [ ] Testare su Xcode con appuntamenti reali da Supabase
- [ ] Verificare che `NavigationLink → AppointmentsCalendarView` dentro `NavigationStack` non crei doppie navigation bar

## Da fare subito

- [ ] Build Xcode dopo aggiunta HealthKit.
- [ ] Applicare migration `20260517123000_daily_engagement_healthkit.sql` su Supabase.
- [ ] Testare consenso Apple Salute su iPhone reale.
- [ ] Testare RLS nuove tabelle con trainer A/B e cliente A/B.
- [ ] Aprire progetto su Mac e verificare build Xcode.
- [ ] Correggere eventuali errori Swift.
- [ ] Eseguire seed demo Supabase senza salvare credenziali.
- [ ] Verificare login trainer demo.
- [ ] Verificare login cliente demo.
- [ ] Implementare persistenza sessione in Keychain.
- [ ] Correggere mapping status appuntamenti.
- [ ] Correggere mapping status schede e nutrizione.
- [ ] Completare visualizzazione/generazione codice invito.
- [ ] Rimuovere `try?` critici dai flussi clienti/appuntamenti.

## Attivita per fase

### FASE 1 - Build e pulizia

- [ ] Build Debug su simulatore. Bloccata: serve Mac con Xcode.
- [ ] Avvio app. Bloccata: serve Mac con Xcode.
- [x] Navigazione auth verificata staticamente.
- [x] Verifica file nel target: tutti i 17 file Swift sono inclusi.
- [x] Decisione su view inutilizzate: `InviteCodeView` collegata al dettaglio cliente; `ClientAccessCodeRegistrationView` lasciata come wrapper non bloccante.

### FASE 2 - Auth e demo

- [ ] Seed demo Auth.
- [ ] Collegamento demo a `profiles`.
- [ ] Collegamento trainer a `trainers`.
- [ ] Collegamento cliente a `clients`.
- [ ] Restore session.
- [ ] Logout.
- [ ] Keychain.

### FASE 3 - Mapping status

- [ ] `AppointmentStatus` con valore DB inglese e label italiana.
- [ ] Status workout coerente con DB.
- [ ] Status nutrition coerente con DB.
- [ ] Rimozione `rawValue.lowercased()` rischiosi.

### FASE 4 - Clienti/inviti

- [ ] CRUD cliente reale.
- [ ] Generazione codice.
- [ ] Stato codice.
- [ ] Registrazione cliente.
- [ ] Revoca/scadenza.
- [ ] Limite piano.

### FASE 5 - Appuntamenti

- [ ] Create.
- [ ] Read trainer.
- [ ] Read cliente.
- [ ] Update.
- [ ] Delete.
- [ ] Dashboard aggiornate.

### FASE 6 - Schede

- [ ] DTO `workout_days`.
- [ ] DTO `exercises`.
- [ ] Lettura piano completo.
- [ ] Creazione da template.
- [ ] Creazione esercizi da catalogo.
- [ ] Area cliente con scheda completa.
- [x] `TrainerClientWorkoutPlansView`: lista schede attiva+storiche nel dettaglio cliente.
- [x] `TrainerClientWorkoutPlanDetailView`: giorni collassabili + esercizi completi (sets, reps, recupero, carico, note).
- [x] `TrainerClientNutritionPlansView`: lista diete attiva+storiche nel dettaglio cliente.
- [x] `TrainerClientNutritionPlanDetailView`: giorni (Lunedì–Domenica) collassabili + pasti + alimenti con macros/kcal.
- [x] `ClientDetailView.scheduleTab`: card tappabile → naviga a lista schede.
- [x] `ClientDetailView.dietTab`: card tappabile → naviga a lista diete.

### FASE 7 - Nutrizione

- [x] DTO `MealDTO` con `day_of_week`.
- [x] DTO `MealFoodDTO` con macros.
- [x] Migration `meals.day_of_week` (1=Lun, 7=Dom).
- [x] Wizard "Crea nuova dieta": flusso 3 livelli settimana→giorno→editor.
- [x] 7 giorni Lunedì–Domenica, 6 slot pasto fissi per giorno.
- [x] `MealFoodEditorSheet`: ricerca `food_catalog`, stepper grammi, preview kcal live.
- [x] `createNutritionPlan`: salva meals + meal_foods su Supabase.
- [ ] `fetchNutritionPlans`: caricare meals + meal_foods da Supabase (solo header ora).
- [ ] Lettura piano completo con giorni/pasti/alimenti nel client area.
- [ ] Creazione da template.
- [ ] Area cliente con dieta completa (giorno per giorno).

### FASE 8B - Progressi trainer (esercizi)

- [x] `TrainerClientProgressView`: segmented "Peso" | "Esercizi".
- [x] Sezione Peso: `LineMark + AreaMark` su `progress_entries.weightKg`, stat card Inizio/Attuale/Diff., misure corporee.
- [x] Sezione Esercizi: lista `ExerciseSparklineCard` (nome, prima→ultima, guadagno, sparkline 68×38pt).
- [x] `TrainerClientExerciseProgressDetailView`: full chart + storico sessioni.
- [x] Risoluzione nome esercizio da `workoutPlans` caricati.
- [x] `ClientDetailView.progressTab`: card tappabile con peso+diff+N esercizi.
- [x] Migration `exercise_progress_entries` con `exercise_name text` e RLS completa.
- [ ] Popolare `exercise_progress_entries` dal client workout (attualmente usa `exercise_weight_history`).

### FASE 8 - Progressi/foto

- [ ] Photos picker.
- [ ] Upload Storage.
- [ ] Insert `progress_photos`.
- [ ] Lettura foto.
- [ ] Visualizzazione foto reale.
- [ ] Test privacy storage.

### FASE 8B - HealthKit e uso quotidiano

- [x] Modelli `DailyGoal`, `DailyStepSummary`, `DailyCheckIn`, `Streak`.
- [x] `HealthKitService` per disponibilita, autorizzazione, passi oggi, ultimi 7 giorni e media.
- [x] Servizi Supabase per check-in, obiettivi, riepiloghi attivita, streak e insight.
- [x] Dashboard cliente trasformata in "Oggi".
- [x] Sheet check-in giornaliero.
- [x] Card privacy/consenso Apple Salute.
- [x] Streak card.
- [x] Trainer insight "Clienti da seguire".
- [x] Migration nuove tabelle con RLS e grant.
- [ ] Build Xcode.
- [ ] Test iPhone reale HealthKit.
- [ ] Verifica RLS su Supabase remoto.

### FASE 9 - Cataloghi/template

- [x] Pasti salvati: `SavedMealFood` model, `foods: [SavedMealFood]` in `SavedMeal`.
- [x] Pasti salvati: `SavedMealDTO` + `SavedMealFoodDTO` in `SupabaseDTOs.swift`.
- [x] Pasti salvati: `SavedMealService` usa Supabase (`saved_meals` + `saved_meal_foods`).
- [x] Pasti salvati: `EditSavedMealSheet` con ricerca catalogo, stepper grammi, preview kcal/macro live.
- [x] Pasti salvati: `SavedMealFoodSearchSheet` — lista `food_catalog`, selezione, quantità, aggiungi.
- [x] Migration `20260528150000_saved_meals_foods.sql` — RLS trainer-owned.
- [x] Pasti salvati: rimosso `ToolbarItem(.topBarLeading)` con testo troncato; sostituito con `.navigationTitle("Pasti salvati")` standard.
- [ ] Picker catalogo macchine.
- [ ] Picker esercizi.
- [ ] Picker workout template.
- [ ] Picker meal template.

### FASE 10 - Sicurezza/RLS

- [ ] Test trainer A/B.
- [ ] Test cliente A/B.
- [ ] Test inviti.
- [ ] Test Storage privato.
- [ ] Revisione RPC `SECURITY DEFINER`.
- [ ] Advisor Supabase.

### FASE 11 - Errori/UX

- [ ] Loading state.
- [ ] Error state.
- [ ] Empty state.
- [ ] Retry.
- [ ] Validazione form.
- [ ] Feedback salvataggio.

### FASE 12 - SaaS

- [ ] Piano reale trainer.
- [ ] Trial residuo.
- [ ] Limite clienti UI.
- [ ] Upgrade plan.
- [ ] Scelta Stripe/IAP.
- [ ] Webhook/checkout sicuri.

### FASE 13 - Rilascio

- [ ] Test end-to-end.
- [ ] Device reale.
- [ ] TestFlight.
- [ ] Privacy policy.
- [ ] Termini servizio.
- [ ] App Store checklist.

## In corso

- [ ] FASE 1 in corso parziale: manca verifica reale su Xcode.
- [ ] Restyling UI in corso: manca verifica reale su Xcode/simulatore.

## Bloccate

- [ ] Verifica build bloccata finche non si usa un Mac con Xcode.
- [ ] Verifica avvio su simulatore bloccata finche non si usa un Mac con Xcode.

## Completate

- [x] Analisi tecnica iniziale.
- [x] Piano operativo documentato in BrainApp.
- [x] Audit statico target Xcode e sorgenti Swift.
- [x] Collegata `InviteCodeView` alla navigazione reale del dettaglio cliente.
- [x] Design system convertito a UI light moderna.
- [x] Componenti principali ridisegnati.
- [x] Dashboard trainer ridisegnata.
- [x] Calendario admin dinamico introdotto.
- [x] Dashboard cliente ridisegnata.
- [x] HealthKit, check-in giornaliero, obiettivi, streak e insight trainer implementati localmente.
