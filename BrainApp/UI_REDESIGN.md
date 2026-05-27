# UI Redesign

Data aggiornamento: 2026-05-17

## Stato UI attuale

L'app e stata spostata da una UI dark fredda a una direzione light moderna. Il lavoro ha riguardato design system, componenti condivisi, dashboard trainer, dashboard cliente e calendario trainer.

La logica Supabase, Auth, database, servizi e ViewModel non e stata rifatta. Le modifiche sono concentrate sul frontend SwiftUI e usano i dati gia esposti dai ViewModel esistenti.

## Problemi dello stile precedente

- Dark mode forzata.
- Sfondo nero/blu notte troppo tecnico.
- Card blu-grigie con ombre marcate.
- Accento blu dominante.
- Area trainer e area cliente molto simili.
- Dashboard trainer troppo statica.
- Dashboard cliente poco personale.
- Calendario appuntamenti poco centrale per l'area admin.
- Foto progresso trattate come placeholder semplici.

## Nuova direzione visiva

- UI light con sfondo quasi bianco.
- Superfici bianche con bordo sottile.
- Bottoni primari neri.
- Ombre quasi nulle.
- Colori di stato usati solo per semantica.
- Sezioni piu ariose e meno dense.
- Componenti piu cliccabili.
- Area trainer piu operativa.
- Area cliente piu personale e motivazionale.

## Palette

- `appBackground`: `#FAFAF8`
- `surface`: `#FFFFFF`
- `surfaceSecondary`: `#F1F1EE`
- `border`: `#E5E5E0`
- `textPrimary`: `#111111`
- `textSecondary`: `#666666`
- `textMuted`: `#9A9A9A`
- `primaryBlack`: `#111111`
- `successGreen`: `#21A67A`
- `dangerRed`: `#E5484D`
- `warningYellow`: `#F5B942`
- `infoBlue`: `#3B82F6`
- `energyOrange`: `#FF7A1A`

## Componenti modificati

- `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`
- `PrimaryButtonStyle`
- `SecondaryButtonStyle`
- `DestructiveButtonStyle`
- `PrimaryButton`
- `SecondaryButton`
- `DestructiveButton`
- `StatusBadge`
- `StatCard`
- `SectionCard`
- `ClientRowView`
- `AppointmentRowView`
- `ProgressPhotoCard`
- `EmptyStateView`
- `SearchBarView`
- `MachineCard`

## Componenti aggiunti

- `QuickActionButton`
- `PillFilterButton`
- `MiniProgressBar`
- `DashboardAlertRow`
- `ClientDashboardMetric`
- `CalendarDayButton`
- `CalendarMonthDayButton`

## Calendario admin dinamico

`AppointmentsCalendarView` e stato trasformato in una vista agenda piu centrale per il trainer:

- vista settimanale
- vista mensile
- selezione giorno
- evidenza giorno corrente
- badge conteggio appuntamenti
- filtro stato appuntamento
- timeline giornaliera
- tap su appuntamento per modifica
- menu contestuale per completare, annullare o eliminare
- CTA per creare appuntamento quando non ci sono sessioni

Il calendario continua a usare `AppointmentsViewModel` e `AppointmentService`.

## Differenza area trainer e cliente

Area trainer:

- tono operativo
- dashboard console
- azioni rapide
- statistiche business
- agenda del giorno
- settimana compatta
- alert operativi

Area cliente:

- tono personale
- focus su allenamento di oggi
- obiettivo peso
- piano alimentare attivo
- progressi e foto
- azioni rapide semplici

## File modificati

- `GestioneDatabasePersonalTrainer/DesignSystem/DesignSystem.swift`
- `GestioneDatabasePersonalTrainer/App/GestioneDatabasePersonalTrainerApp.swift`
- `GestioneDatabasePersonalTrainer/Views/Components/Components.swift`
- `GestioneDatabasePersonalTrainer/Views/Trainer/TrainerViews.swift`
- `GestioneDatabasePersonalTrainer/Views/Client/ClientViews.swift`
- `BrainApp/UI_REDESIGN.md`
- `BrainApp/DECISIONI_TECNICHE.md`
- `BrainApp/SWIFTUI.md`
- `BrainApp/TODO.md`

## Decisioni prese

- Rimuovere dark mode forzata.
- Tenere supporto futuro alla dark mode, ma priorizzare light mode.
- Usare nero come azione primaria.
- Usare verde, rosso, giallo, blu e arancio solo come stati o accenti funzionali.
- Rendere il calendario trainer una schermata centrale del prodotto.
- Non modificare backend, Auth, Supabase, RPC o RLS in questa fase.

## Limiti rimasti

- Build non verificata su Xcode.
- UI non verificata su simulatore/device reale.
- Foto progresso ancora senza upload reale collegato allo Storage.
- Alcune schermate secondarie restano solo parzialmente ridisegnate.
- Le quick action per schede/diete si appoggiano ancora ai flussi template esistenti.

## Restyling Dashboard Stat Cards

Data: 2026-05-27

### Cosa e stato cambiato

Le KPI card della TrainerDashboardView erano inline (funzione `kpi()` privata). Sono state sostituite con il componente riutilizzabile `DashboardStatCard`.

### Nuovo stile delle card

- Sfondo bianco puro (`bgCard` = `#FFFFFF`)
- Corner radius 18, continuo
- Bordo `Color.black.opacity(0.06)` — quasi invisibile
- Ombra `Color.black.opacity(0.04)`, radius 8, y 4 — delicatissima
- Altezza minima 110pt, padding interno 16pt
- Numero: `Archivo-Black` 26pt, colore `txtPrimary`
- Titolo: `Sora-SemiBold` 11pt, colore `txtSecondary`
- Icona: `FitIconChip` size 30, in alto a sinistra
- Delta: `TrendBadge` (testo verde + capsule background verde 12% opacity), in alto a destra
- Press feedback: `scaleEffect 0.97` via `KPICardButtonStyle`
- Accessibility: `accessibilityLabel` con valore + titolo + delta

### Componente creato

`DashboardStatCard` — in `Views/Components/Components.swift`

Firma:
```swift
struct DashboardStatCard: View {
    let icon: String
    let value: String
    let title: String
    let delta: String?
    let iconColor: Color
    let iconBackground: Color
    var onTap: (() -> Void)? = nil
}
```

### File modificati

- `GestioneDatabasePersonalTrainer/Views/Components/Components.swift` — aggiunto `DashboardStatCard`, `KPICardButtonStyle`, aggiornato `TrendBadge` (capsule background), aggiunta `#Preview`
- `GestioneDatabasePersonalTrainer/Views/Trainer/TrainerViews.swift` — `kpiGrid` aggiornato a `DashboardStatCard`, rimossa funzione `kpi()` inline

### Riferimento visivo

Card bianche con angoli arrotondati, icona colorata in alto sinistra, delta verde in capsule in alto destra, numero grande Archivo-Black in basso, titolo grigio sotto. Griglia 2 colonne. Stile iOS light premium.

---

## Prossimi miglioramenti UI

- Rifinire form di creazione cliente, appuntamento, scheda e dieta.
- Aggiungere stati loading/error coerenti in tutte le schermate.
- Collegare `PhotosPicker` e preview foto reale quando Storage sara operativo.
- Migliorare tab bar e toolbar con micro-interazioni coerenti.
- Fare QA visuale su iPhone piccolo e grande.
