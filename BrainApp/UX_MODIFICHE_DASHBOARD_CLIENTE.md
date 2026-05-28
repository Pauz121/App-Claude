# UX Modifiche Dashboard Trainer e Cliente — Sessione 2026-05-29

Data creazione: 2026-05-29

Documento delle modifiche UX/UI dalla sessione del 29 maggio 2026.  
Copre: note personali trainer, banner agenda integrato, pagamento opzionale in AddClientView, copia codice inline, area pagamenti trainer e cliente.

---

## 1. Dashboard Trainer — Note personali in primo piano

### Obiettivo

Spostare la sezione "Note personali" come primo blocco di contenuto dopo l'header della dashboard trainer, prima dell'agenda di oggi.

### Ordine precedente

```
header
todayBanner (standalone)
notesPreview
SectionLabel("Agenda di oggi")
todayAgenda
SectionLabel("Azioni rapide")
quickActions
```

### Ordine nuovo

```
header
notesPreview            ← primo blocco (spostato su)
SectionLabel("Agenda di oggi")
todayAgendaWithBanner   ← banner integrato (vedi §2)
SectionLabel("Azioni rapide")
quickActions
```

### File modificato

`Views/Trainer/TrainerViews.swift` — `TrainerDashboardView.body`

---

## 2. Dashboard Trainer — Banner appuntamenti integrato nell'agenda

### Obiettivo

Eliminare il blocco `todayBanner` standalone. Inserire un banner tappabile come riga header all'interno del blocco "Agenda di oggi" (unica `FitCard`).

### Componente nuovo: `todayAgendaWithBanner`

`private var todayAgendaWithBanner: some View` in `TrainerDashboardView`.

**Struttura visiva:**

```
┌─────────────────────────────────────────────────────┐
│  [●] Hai N appuntamenti oggi      Agenda  [›]       │  ← tappabile, tab 2
│      Prossimo alle HH:mm                            │
├─────────────────────────────────────────────────────┤
│  [DashboardAgendaRow]  (se appointments > 0)        │
│  [DashboardAgendaRow]                               │
│  ─────────────────────────────────────────────────  │
│  [Vai all'agenda →]  (NavigationLink)               │
├─────────────────────────────────────────────────────┤
│  (empty state se 0 appuntamenti)                    │
└─────────────────────────────────────────────────────┘
```

**Banner row (tappabile):**
- `Button { selectedTab = 2 }` — naviga al tab Agenda
- Cerchio con icona calendar: amber se ci sono appuntamenti, `bgLine` se vuoto
- Testo: "Hai N appuntamenti oggi" oppure "Nessun appuntamento oggi"
- Subtitle: "Prossimo alle HH:mm" se esiste `appointmentsForToday.first`
- Label "Agenda" + `chevron.right` in indigo a destra

**Vecchi var rimasti ma non più usati:**
- `todayBanner` (era standalone) — presente nel file, non referenziato nel body
- `todayAgenda` (era sezione separata) — presente nel file, non referenziato nel body

### File modificato

`Views/Trainer/TrainerViews.swift` — `TrainerDashboardView`

---

## 3. Note personali trainer — Vista completa e form

### Strutture aggiunte in `TrainerViews.swift`

**`DashboardNoteRow`** (private struct):
- `FitCard` con barra colorata sinistra (colore per priorità)
- Titolo nota + preview corpo (2 righe)
- Pill priorità: Bassa/Media/Alta/Massima
- Nome cliente se associata a un cliente
- Data formattata `dd/MM/yyyy`
- Checkmark button a destra: chiama `onComplete`
- Tap intera riga: chiama `onTap` (apre edit sheet)

**Colori priorità:**
- `.low` → `txtSecondary`
- `.medium` → `indigo`
- `.high` → `amber`
- `.critical` → `Color(hex:"E57373")` (rosso)

**`AddTrainerNoteSheet`** (struct pubblico):
- Init doppio: `init(trainer:clients:onSave:)` per nuova nota, `init(note:trainer:clients:onSave:)` per modifica
- `@State`: title, noteBody, priority, hasDate, noteDate
- Priority picker a pill (4 opzioni)
- `DatePicker` opzionale (mostrato se `hasDate == true`)
- `saveNote()` preserva `id/source/status` dalla nota originale se modifica

**`TrainerPersonalNotesListView`** (struct pubblico):
- `@StateObject private var viewModel: TrainerNotesViewModel`
- Filter pills: Tutte / Massima / Alta / Media / Bassa
- Toggle "Mostra completate"
- `LazyVStack` con `DashboardNoteRow` per ogni nota
- Sheet add/edit via `AddTrainerNoteSheet`
- Toolbar button "+" per nuova nota

**ViewModel usato:** `TrainerNotesViewModel` (già definito in `TrainerViewModels.swift`)
- `filteredNotes`, `load()`, `save()`, `complete()`, `delete()`

---

## 4. Pagamenti — Area trainer

### `TrainerClientPaymentsView` (struct pubblico in `TrainerViews.swift`)

Aggiunto come tab "Pagamenti" in `ClientDetailView`.

**Struttura:**
- Card piano attivo: frequenza, importo, data inizio, note
- Se nessun piano: card "Nessun piano" + bottone "Crea piano"
- Lista pagamenti: stato con colore/icona, importo, scadenza
- Bottone "Conferma" per pagamenti in stato `.paidByClient`
- `reload()` async fetches piano + pagamenti

**`CreatePaymentPlanSheet`** (struct pubblico in `TrainerViews.swift`):
- `@State`: amount, frequency, startDate, notes
- `existing: ClientPaymentPlan?` — se presente, pre-popola campi
- Campo importo + selezione frequenza in griglia + DatePicker + TextEditor note
- `savePlan()` chiama `services.trainerClientPaymentService.createOrUpdatePaymentPlan`

**`ClientDetailView` aggiornato:**
- Aggiunto case `.payments` all'enum `DetailTab`
- `paymentsTab`: NavigationLink → `TrainerClientPaymentsView`
- Tab title: "Pagamenti", tab icon: "creditcard"

### `TrainerClientPaymentService.confirmPayment` (aggiunto in `AppServices.swift`)

```swift
func confirmPayment(_ payment: ClientPayment) async
```
- Aggiorna `status = .confirmed` e `trainerConfirmedAt = Date()` su Supabase
- UPDATE su `client_payments` filtrato per `id`

---

## 5. Pagamenti — Area cliente

### `ClientPaymentsView` (struct aggiunto in `ClientViews.swift`)

**Struttura:**
- Header card: frequenza piano, importo, data inizio
- Sezione "Pagamenti in sospeso": lista con "Segna come pagato" button
- Sezione "Storico pagamenti": lista pagamenti confermati/pagati

**ViewModel:** `ClientPaymentsViewModel` (già in `ClientViewModels.swift`)
- `markAsPaid(_:)` — chiama `service.markPaymentAsPaidByClient`
- `load()` — fetches payments + paymentPlan

### Card pagamenti in `ClientDashboardView`

`paymentsCard` aggiunto dopo `checkInCard`:
- Background `indigoBg`, bordo indigo 0.2 opacity
- NavigationLink → `ClientPaymentsView`

---

## 6. Creazione cliente — Pagamento opzionale

### Obiettivo

Permettere al trainer di impostare subito un piano pagamenti durante la creazione di un nuovo cliente, senza cambiare la firma di `onSave`.

### File modificato

`Views/Trainer/TrainerForms.swift` — `AddClientView`

### Modifiche a `AddClientView`

**Nuove proprietà:**
```swift
@EnvironmentObject private var services: AppServices
@State private var codeCopied = false
@State private var paymentEnabled = false
@State private var paymentAmount: Double = 100
@State private var paymentFrequency: PaymentFrequency = .monthly
@State private var paymentStartDate: Date = Date()
@State private var paymentNotes: String = ""
private let isNewClient: Bool   // let, calcolato nell'init
```

**`isNewClient`** calcolato in `init()` prima che i campi form vengano popolati:
```swift
self.isNewClient = client.firstName.isEmpty
```
Critico: non può essere una computed var perché al momento del salvataggio `client.firstName` è già compilato.

**`paymentSection`** (shown only when `isNewClient == true`):
- `SectionLabel("Pagamento")`
- `FitCard` con `Toggle("Imposta piano pagamenti", isOn: $paymentEnabled)`
- Se `paymentEnabled`:
  - Campo importo con `TextField` + label "EUR"
  - Griglia 3 colonne `PaymentFrequency.allCases` (pill selezionabile)
  - `DatePicker` data inizio in `FitCard`
  - `TextEditor` note opzionali in `FitCard`

**`saveAndDismiss()`**:
- Chiama `onSave(client)` (firma invariata)
- Se `isNewClient && paymentEnabled && paymentAmount > 0`:
  - Costruisce `ClientPaymentPlan` e lo salva async
  - **800ms sleep** prima dell'insert per attendere che il client sia in DB (FK)
  - Chiama `services.trainerClientPaymentService.createOrUpdatePaymentPlan(plan)`
  - `createOrUpdatePaymentPlan` chiama internamente `generateUpcomingPayments` per nuovi piani

**Note tecniche:**
- `@EnvironmentObject services` è safe anche dopo `dismiss()` perché `AppServices` è una classe reference type tenuta viva dall'injection root
- La firma `onSave: (Client) -> Void` resta invariata — nessun impatto su `ClientsViewModel`, `ClientDetailView` o altri caller

---

## 7. Creazione cliente — Copia codice inline

### Obiettivo

Spostare il bottone "Copia codice" da riga standalone a bottone affiancato al codice di accesso, nella stessa `FitCard`.

### Modifica

**Prima:**
```
FitCard { Text(codice) }
Text("Il cliente userà questo codice...")
Button("Copia codice") { ... }
```

**Dopo:**
```
FitCard {
    HStack {
        VStack { Label "Codice accesso"; Text(codice) }
        Spacer()
        Button { copia + feedback } label: {
            Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                .background(codeCopied ? limeBg : indigoBg)
                .clipShape(RoundedRectangle)
        }
        .animation(.easeInOut(0.2), value: codeCopied)
    }
}
Text("Il cliente userà questo codice...")
// Rimosso: Button standalone
```

**Feedback visivo:**
- `codeCopied = true` al tap
- Icona cambia `doc.on.doc` → `checkmark`
- Background cambia `indigoBg` → `limeBg`
- Auto-reset a `false` dopo 2s via `Task { try? await Task.sleep(2s) }`

---

## Riepilogo file modificati

| File | Sezione / struct |
|------|-----------------|
| `Views/Trainer/TrainerViews.swift` | `TrainerDashboardView` body (ordine, `todayAgendaWithBanner`) |
| `Views/Trainer/TrainerViews.swift` | `DashboardNoteRow`, `AddTrainerNoteSheet`, `TrainerPersonalNotesListView` (nuovi) |
| `Views/Trainer/TrainerViews.swift` | `ClientDetailView.DetailTab` + `paymentsTab` |
| `Views/Trainer/TrainerViews.swift` | `TrainerClientPaymentsView`, `CreatePaymentPlanSheet` (nuovi) |
| `Views/Trainer/TrainerForms.swift` | `AddClientView` (rewrite completo: `isNewClient`, `paymentSection`, `codeCopied`, `saveAndDismiss`) |
| `Views/Client/ClientViews.swift` | `ClientDashboardView.paymentsCard` (nuovo) |
| `Views/Client/ClientViews.swift` | `ClientPaymentsView` (nuovo) |
| `Services/AppServices.swift` | `TrainerClientPaymentService.confirmPayment` (nuovo) |

## Cosa testare su Xcode

- Dashboard trainer: note personali appaiono PRIMA dell'agenda
- Banner appuntamenti è dentro la FitCard agenda, toccandolo si va al tab Agenda (tab 2)
- Tab "Pagamenti" visibile in `ClientDetailView`
- `TrainerClientPaymentsView`: lista pagamenti + bottone Conferma funzionante
- `CreatePaymentPlanSheet`: salva piano e genera pagamenti futuri
- `AddClientView` (nuovo cliente): sezione Pagamento visibile con Toggle
- `AddClientView` (cliente esistente): sezione Pagamento NON visibile
- Toggle attivo mostra campi frequenza/importo/data/note
- Salvataggio nuovo cliente + piano: dopo ~1s il piano compare in Supabase `client_payment_plans`
- Copia codice: tap bottone → icona checkmark verde per 2s → torna a doc.on.doc
- `ClientDashboardView`: card pagamenti visibile dopo checkin card
- `ClientPaymentsView`: pagamenti in sospeso, "Segna come pagato" aggiorna status

## Cosa testare su Supabase

- `client_payment_plans`: record inserito con `frequency`, `amount`, `start_date` corretti
- `client_payments`: pagamenti futuri generati automaticamente dopo creazione piano
- Trigger `auto_create_fattura_note`: si attiva quando cliente segna pagamento come `paid_by_client`
- `confirmPayment`: aggiorna `status = 'confirmed'` e `trainer_confirmed_at` su `client_payments`
- RLS: trainer vede solo pagamenti propri clienti, cliente vede solo i propri
