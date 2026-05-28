# Decisioni tecniche

Data aggiornamento: 2026-05-17

## Decisioni prese

### BrainApp come vault tecnico

Decisione: usare `BrainApp/` come memoria tecnica centrale del progetto.

Motivazione: mantenere stato, roadmap, decisioni e note tecniche sincronizzate con lo sviluppo.

Regola: BrainApp contiene documentazione, non codice sorgente dell'app e non credenziali.

### Supabase come backend principale

Decisione: completare l'app usando Supabase Auth, Postgres, RLS, RPC e Storage.

Motivazione: schema e migration sono gia presenti; cataloghi e policy esistono.

Alternative scartate per ora: Firebase o API custom, perche richiederebbero riscrittura del backend.

### REST manuale da stabilizzare prima di valutare SDK

Decisione: non cambiare subito architettura Supabase client. Prima rendere stabili mapping, errori e CRUD.

Motivazione: sostituire il client adesso aggiungerebbe rischio mentre il prodotto non e ancora completo.

Nota futura: valutare Supabase Swift SDK se REST manuale diventa troppo fragile con query annidate e Storage signed URL.

### Keychain per sessione

Decisione: spostare sessione Auth da `UserDefaults` a Keychain.

Motivazione: access token e refresh token non devono stare in storage non sicuro.

Alternative scartate: lasciare `UserDefaults` per MVP. Non consigliato per dati Auth.

### Label UI italiane separate dai valori DB

Decisione: gli enum Swift devono avere valore DB inglese e label italiana separata.

Motivazione: Postgres usa check constraint inglesi; la UI deve restare italiana.

### Template copiati nelle tabelle operative

Decisione: quando un trainer usa un template, i dati devono essere copiati in `workout_*` o `nutrition_*`, non referenziati direttamente come template attivo.

Motivazione: il piano assegnato al cliente deve restare stabile anche se il catalogo/template globale cambia.

### Storage foto privato

Decisione: usare bucket privato `progress-photos`.

Motivazione: foto progresso sono dati personali sensibili.

Nota futura: usare signed URL temporanee o download autenticato.

### Pagamenti da decidere dopo MVP operativo

Decisione: completare prima trial e limite clienti; integrare pagamenti dopo aver chiarito modello commerciale e regole App Store.

Motivazione: Stripe o Apple IAP dipendono da cosa si vende e da come viene consumato il servizio.

### Restyling UI Light Fitness SaaS

Decisione: passare da dark mode forzata a una UI light moderna, premium e piu vicina al mondo fitness/personal trainer.

Motivazione: lo stile precedente era corretto ma troppo freddo, tecnico e simile a una dashboard aziendale. Il prodotto deve sembrare una SaaS iOS commerciale, piu umana e piu immediata per trainer e clienti.

Decisioni operative:

- rimuovere `.preferredColorScheme(.dark)`;
- usare `#FAFAF8` come background principale e superfici bianche con bordo sottile;
- usare bottoni primari neri;
- usare colori di stato controllati: verde per completato/progresso, rosso per azioni critiche, giallo per warning, blu per informazione/calendario, arancio per energia;
- differenziare area trainer e area cliente;
- rendere il calendario trainer un elemento centrale dell'area admin;
- mantenere invariati Supabase, Auth, database, servizi e ViewModel salvo necessita di collegamento UI.

Alternative scartate: mantenere dark mode come direzione principale; continuare con accento blu dominante; introdurre una nuova architettura UI separata.

### Integrazione HealthKit e funzionalita quotidiane

Decisione: integrare HealthKit solo per `stepCount` e usare l'app come dashboard giornaliera con passi, obiettivi, check-in e streak.

Motivazione: i passi sono un segnale quotidiano semplice e motivante. Consentono al cliente di aprire l'app ogni giorno e al trainer di vedere insight operativi senza introdurre notifiche, missioni settimanali o funzioni mediche.

Decisioni operative:

- leggere solo passi da Apple Salute dopo consenso esplicito;
- salvare su Supabase solo riepiloghi giornalieri in `client_activity_summaries`;
- non salvare dati HealthKit grezzi;
- tenere check-in e streak in tabelle dedicate con RLS;
- mantenere MVVM e Supabase REST manuale esistente;
- aggiungere capability HealthKit tramite entitlements e usage description;
- mostrare una card privacy prima della richiesta permesso;
- non introdurre notifiche push, missioni settimanali, chat, pagamenti o consigli sanitari automatici.

Alternative scartate: leggere calorie/distanza/battito/sonno; generare consigli sanitari automatici; salvare stream HealthKit dettagliati; introdurre un backend separato per gli insight.

### Pagamento opzionale in AddClientView — firma onSave invariata

Decisione: aggiungere piano pagamenti opzionale alla creazione cliente senza cambiare la firma `onSave: (Client) -> Void`.

Motivazione: cambiare la firma richiederebbe aggiornare `ClientsViewModel`, `ClientDetailView` e tutti i caller. Il rischio di regressione è alto per un beneficio marginale (il piano è opzionale).

Soluzione adottata:
- `@EnvironmentObject private var services: AppServices` in `AddClientView`
- `isNewClient: Bool` calcolato in `init()` da `client.firstName.isEmpty` — deve essere `let`, non computed, perché al salvataggio `firstName` è già valorizzato
- `saveAndDismiss()` chiama `onSave(client)` poi, se `paymentEnabled`, avvia un `Task` con 800ms sleep prima di creare il piano
- 800ms sleep mitiga la race condition FK: il client deve esistere in DB prima che il piano possa referenziarlo
- `AppServices` è reference type (class), sicuro da usare in Task dopo `dismiss()`

Alternative scartate: cambiare firma `onSave` (invasivo); usare callback onAppear (inaffidabile); zero delay (race condition FK).

### Dashboard trainer — banner appuntamenti integrato

Decisione: unire il banner "appuntamenti di oggi" con il blocco "Agenda di oggi" in una sola `FitCard`, invece di tenerli come due elementi separati.

Motivazione: riduce il rumore visivo. Il banner diventa la riga header tappabile della card agenda, navigando al tab Agenda (`selectedTab = 2`).

Alternative scartate: mantenere `todayBanner` standalone (troppo spazio); rimuovere il banner (perde l'accesso rapido al tab).

## Decisioni da prendere

- Usare REST manuale o Supabase Swift SDK per query annidate e Storage avanzato.
- Implementare completamento allenamenti con stato locale, tabella dedicata o log progressi.
- Stripe vs Apple In-App Purchase.
- Strategia immagini: compressione, risoluzione massima, retention e cancellazione.
- Quanto dettaglio nutrizionale calcolare automaticamente.

## Regole future BrainApp

- Se si completa una fase: aggiornare `TODO.md`.
- Se cambia una decisione: aggiornare questo file.
- Se cambia schema/RLS/Storage: aggiornare `SUPABASE.md`.
- Se cambia struttura app/UI/ViewModel: aggiornare `SWIFTUI.md`.
- Se cambia stato generale: aggiornare `STATO_PROGETTO.md`.
- Se cambia roadmap: aggiornare `ROADMAP.md` e `PIANO_COMPLETAMENTO_APP.md`.
