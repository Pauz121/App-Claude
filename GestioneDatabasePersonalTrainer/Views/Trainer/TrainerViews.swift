import SwiftUI

struct TrainerMainTabView: View {
    @EnvironmentObject private var services: AppServices
    let trainer: Trainer

    var body: some View {
        TabView {
            TrainerDashboardView(trainer: trainer, services: services)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }

            ClientsListView(trainer: trainer, services: services)
                .tabItem { Label("Clienti", systemImage: "person.2") }

            AppointmentsCalendarView(trainer: trainer, services: services)
                .tabItem { Label("Agenda", systemImage: "calendar") }

            MachinesListView(trainer: trainer, services: services)
                .tabItem { Label("Macchine", systemImage: "dumbbell") }

            WorkoutPlansListView(trainer: trainer, services: services)
                .tabItem { Label("Schede", systemImage: "list.clipboard") }

            NutritionPlansListView(trainer: trainer, services: services)
                .tabItem { Label("Diete", systemImage: "fork.knife") }

            SubscriptionView(trainer: trainer, services: services)
                .tabItem { Label("Piano", systemImage: "creditcard") }
        }
    }
}

struct TrainerDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: TrainerDashboardViewModel
    @State private var clients: [Client] = []
    @State private var showingAddClient = false
    @State private var showingAddAppointment = false
    @State private var showingCreateWorkout = false
    @State private var showingCreateNutrition = false
    let trainer: Trainer
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
        _viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(trainer: trainer, services: services))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    trainerHeader

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Azioni rapide")
                            .font(AppTypography.section)
                            .foregroundStyle(AppColors.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                            QuickActionButton(title: "Nuovo cliente", systemImage: "person.badge.plus", color: AppColors.primaryBlack) {
                                showingAddClient = true
                            }
                            QuickActionButton(title: "Nuovo appuntamento", systemImage: "calendar.badge.plus", color: AppColors.calendarBlue) {
                                showingAddAppointment = true
                            }
                            QuickActionButton(title: "Nuova scheda", systemImage: "figure.run", color: AppColors.workoutBlack) {
                                showingCreateWorkout = true
                            }
                            QuickActionButton(title: "Nuovo piano", systemImage: "fork.knife", color: AppColors.nutritionYellow) {
                                showingCreateNutrition = true
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                        StatCard(title: "Clienti attivi", value: "\(viewModel.clients.count)", icon: "person.2.fill", color: AppColors.primaryBlack)
                        StatCard(title: "Oggi", value: "\(viewModel.appointmentsToday)", icon: "calendar.badge.clock", color: AppColors.calendarBlue)
                        StatCard(title: "Schede attive", value: "\(viewModel.activePlans)", icon: "figure.run", color: AppColors.successGreen)
                        StatCard(title: "Nuovi iscritti", value: "\(viewModel.newClientsThisMonth)", icon: "sparkles", color: AppColors.energyOrange)
                    }

                    compactWeekSummary

                    SectionCard(title: "Agenda di oggi", icon: "calendar") {
                        if today.isEmpty {
                            EmptyStateView(
                                title: "Giornata libera",
                                message: "Non hai appuntamenti in agenda oggi.",
                                icon: "calendar.badge.plus",
                                actionTitle: "Aggiungi appuntamento"
                            ) {
                                showingAddAppointment = true
                            }
                        } else {
                            ForEach(today) { appointment in
                                AppointmentRowView(appointment: appointment, client: viewModel.clients.first(where: { $0.id == appointment.clientID }))
                            }
                        }
                    }

                    TrainerClientInsightsView(insights: viewModel.insights, isLoading: viewModel.isLoadingInsights)

                    SectionCard(title: "Alert operativi", icon: "bell.badge") {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            DashboardAlertRow(icon: "creditcard", title: "Piano \(trainer.subscriptionTier.rawValue)", subtitle: "Controlla trial, limiti clienti e upgrade.", color: AppColors.warningYellow)
                            DashboardAlertRow(icon: "chart.line.uptrend.xyaxis", title: "\(viewModel.progressEntries.count) progressi registrati", subtitle: "Monitora i clienti che non aggiornano da tempo.", color: AppColors.progressGreen)
                            DashboardAlertRow(icon: "clock", title: "\(viewModel.appointments.filter { $0.status == .scheduled }.count) sessioni programmate", subtitle: "Usa l'agenda per completare o annullare le sessioni.", color: AppColors.calendarBlue)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Console")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authViewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(client: makeEmptyClient()) { client in
                    Task<Void, Never>(priority: nil) {
                        _ = await services.clientService.createClient(client)
                        viewModel.load()
                        clients = await services.clientService.fetchClients(for: trainer.id)
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView(trainer: trainer, clients: clients) { appointment in
                    Task<Void, Never>(priority: nil) {
                        _ = await services.appointmentService.createAppointment(appointment)
                        viewModel.load()
                    }
                }
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutPlanView(clients: clients, catalogService: services.catalogService) { client, name, goal in
                    WorkoutPlansViewModel(trainer: trainer, service: services.workoutService).createTemplatePlan(client: client, name: name, goal: goal)
                    viewModel.load()
                }
            }
            .sheet(isPresented: $showingCreateNutrition) {
                CreateNutritionPlanView(clients: clients, catalogService: services.catalogService) { client, calories, targetWeight in
                    NutritionPlansViewModel(trainer: trainer, service: services.nutritionService).createTemplatePlan(client: client, calories: calories, targetWeight: targetWeight)
                    viewModel.load()
                }
            }
            .appScreen()
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
        }
    }

    private var trainerHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ciao, \(trainer.firstName)")
                        .font(AppTypography.hero)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(trainer.studioName)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                StatusBadge(text: trainer.subscriptionTier.rawValue, style: .trialing)
            }

            HStack(spacing: AppSpacing.sm) {
                Label("\(today.count) oggi", systemImage: "calendar")
                Label("\(viewModel.clients.count) clienti", systemImage: "person.2")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.sm)
    }

    private var compactWeekSummary: some View {
        SectionCard(title: "Settimana", icon: "calendar.day.timeline.left") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach((-3...3).map { Date.daysFromNow($0) }, id: \.self) { date in
                        let count = viewModel.appointments.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }.count
                        VStack(spacing: 7) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2.weight(.semibold))
                            Text(date.formatted(.dateTime.day()))
                                .font(.headline)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(AppColors.primaryBlack)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppColors.border)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundStyle(Calendar.current.isDateInToday(date) ? AppColors.primaryBlack : AppColors.textSecondary)
                        .frame(width: 58, height: 86)
                        .background(Calendar.current.isDateInToday(date) ? AppColors.surfaceSecondary : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(Calendar.current.isDateInToday(date) ? AppColors.primaryBlack : AppColors.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var today: [Appointment] {
        viewModel.appointments.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    private func makeEmptyClient() -> Client {
        Client(
            id: UUID(),
            trainerID: trainer.id,
            firstName: "",
            lastName: "",
            email: "",
            phone: "",
            birthDate: .daysFromNow(-10000),
            heightCm: 170,
            initialWeightKg: 70,
            currentWeightKg: 70,
            goal: "",
            accessCode: AccessCodeGenerator.make(existingCodes: Set(clients.map(\.accessCode))),
            joinedAt: Date(),
            trainerNotes: ""
        )
    }
}

private struct DashboardAlertRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
    }
}

struct ClientsListView: View {
    @StateObject private var viewModel: ClientsViewModel
    @State private var showingAddClient = false
    let trainer: Trainer

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        _viewModel = StateObject(wrappedValue: ClientsViewModel(trainer: trainer, clientService: services.clientService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                SearchBarView(text: $viewModel.searchText, placeholder: "Cerca cliente, email o obiettivo")
                    .padding(.horizontal, AppSpacing.lg)

                List {
                    ForEach(viewModel.filteredClients) { client in
                        NavigationLink {
                            ClientDetailView(client: client, onSave: viewModel.save, onDelete: viewModel.delete)
                        } label: {
                            ClientRowView(client: client)
                        }
                        .listRowBackground(AppColors.surface)
                    }
                    .onDelete { offsets in
                        offsets.map { viewModel.filteredClients[$0] }.forEach(viewModel.delete)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Clienti")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(client: viewModel.makeEmptyClient(), onSave: viewModel.save)
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }
}

struct ClientDetailView: View {
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var inviteCode: String?
    @State private var inviteError: String?
    let client: Client
    let onSave: (Client) -> Void
    let onDelete: (Client) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SectionCard(title: client.fullName, icon: "person.crop.circle") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        InfoLine(label: "Email", value: client.email)
                        InfoLine(label: "Telefono", value: client.phone)
                        InfoLine(label: "Obiettivo", value: client.goal)
                        if let inviteError {
                            Text(inviteError)
                                .font(.caption)
                                .foregroundStyle(AppColors.warning)
                        }
                        SecondaryButton(title: "Genera codice monouso", systemImage: "key.horizontal") {
                            Task<Void, Never>(priority: nil) {
                                do {
                                    inviteCode = try await services.inviteCodeService.generateInviteCode(trainerID: client.trainerID, clientID: client.id)
                                    inviteError = nil
                                } catch {
                                    inviteError = error.localizedDescription
                                }
                            }
                        }
                    }
                }

                if let displayedInviteCode {
                    InviteCodeView(code: displayedInviteCode)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    StatCard(title: "Altezza", value: String(format: "%.0f cm", client.heightCm), icon: "ruler", color: AppColors.accent)
                    StatCard(title: "Peso attuale", value: String(format: "%.1f kg", client.currentWeightKg), icon: "scalemass", color: AppColors.success)
                }

                SectionCard(title: "Note trainer", icon: "note.text") {
                    Text(client.trainerNotes.isEmpty ? "Nessuna nota." : client.trainerNotes)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }

                DestructiveButton(title: "Elimina cliente", systemImage: "trash") {
                    onDelete(client)
                    dismiss()
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Dettaglio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Modifica") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddClientView(client: client, onSave: onSave)
        }
        .appScreen()
    }

    private var displayedInviteCode: String? {
        inviteCode ?? (client.accessCode.isEmpty ? nil : client.accessCode)
    }
}

struct InviteCodeView: View {
    let code: String

    var body: some View {
        SectionCard(title: "Codice invito", icon: "key.horizontal") {
            Text(code)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColors.successGreen)
            Text("Comunica questo codice al cliente. In produzione e monouso, con scadenza e audit.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

private struct InfoLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct AppointmentsCalendarView: View {
    @StateObject private var viewModel: AppointmentsViewModel
    @State private var clients: [Client] = []
    @State private var showingAdd = false
    @State private var editingAppointment: Appointment?
    @State private var calendarMode: CalendarDisplayMode = .week
    @State private var statusFilter: AppointmentStatusFilter = .all
    let trainer: Trainer
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
        _viewModel = StateObject(wrappedValue: AppointmentsViewModel(trainer: trainer, service: services.appointmentService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    calendarHeader

                    Picker("Vista calendario", selection: $calendarMode) {
                        ForEach(CalendarDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if calendarMode == .month {
                        monthCalendar
                    } else {
                        weekCalendar
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(AppointmentStatusFilter.allCases) { filter in
                                PillFilterButton(title: filter.title, isSelected: statusFilter == filter, color: filter.color) {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        statusFilter = filter
                                    }
                                }
                            }
                        }
                    }

                    dayTimeline
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddAppointmentView(trainer: trainer, clients: clients, onSave: viewModel.save)
            }
            .sheet(item: $editingAppointment) { appointment in
                AddAppointmentView(trainer: trainer, clients: clients, appointment: appointment, onSave: viewModel.save)
            }
            .appScreen()
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
        }
    }

    private var calendarHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Calendario")
                    .font(AppTypography.hero)
                    .foregroundStyle(AppColors.textPrimary)
                Text(monthTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            HStack(spacing: AppSpacing.sm) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 38, height: 38)
                }
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 38, height: 38)
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppColors.textPrimary)
            .background(AppColors.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
        }
    }

    private var weekCalendar: some View {
        SectionCard(title: "Settimana", icon: "calendar.day.timeline.left") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(weekDates, id: \.self) { date in
                        CalendarDayButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            isInDisplayedMonth: true,
                            appointmentCount: appointmentCount(on: date)
                        ) {
                            select(date)
                        }
                    }
                }
            }
        }
    }

    private var monthCalendar: some View {
        SectionCard(title: "Mese", icon: "calendar") {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

            VStack(spacing: AppSpacing.sm) {
                HStack {
                    ForEach(shortWeekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppColors.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(monthGridDates, id: \.self) { date in
                        CalendarMonthDayButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            isInDisplayedMonth: Calendar.current.isDate(date, equalTo: viewModel.selectedDate, toGranularity: .month),
                            appointmentCount: appointmentCount(on: date)
                        ) {
                            select(date)
                        }
                    }
                }
            }
        }
    }

    private var dayTimeline: some View {
        SectionCard(title: viewModel.selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)), icon: "clock") {
            if filteredAppointmentsForSelectedDate.isEmpty {
                EmptyStateView(
                    title: "Nessuna sessione",
                    message: "Non ci sono appuntamenti per questo giorno con il filtro attuale.",
                    icon: "calendar.badge.plus",
                    actionTitle: "Crea appuntamento"
                ) {
                    showingAdd = true
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(filteredAppointmentsForSelectedDate) { appointment in
                        Button {
                            editingAppointment = appointment
                        } label: {
                            AppointmentRowView(appointment: appointment, client: clients.first(where: { $0.id == appointment.clientID }))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Segna completato") {
                                var updated = appointment
                                updated.status = .completed
                                viewModel.save(updated)
                            }
                            Button("Annulla sessione") {
                                var updated = appointment
                                updated.status = .cancelled
                                viewModel.save(updated)
                            }
                            Button("Elimina", role: .destructive) {
                                viewModel.delete(appointment)
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredAppointmentsForSelectedDate: [Appointment] {
        viewModel.appointments
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: viewModel.selectedDate) }
            .filter(statusFilter.matches)
            .sorted { $0.startTime < $1.startTime }
    }

    private var weekDates: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: viewModel.selectedDate) else {
            return viewModel.weekDates()
        }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var monthGridDates: [Date] {
        let calendar = Calendar.current
        let selected = viewModel.selectedDate
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: selected),
            let daysRange = calendar.range(of: .day, in: .month, for: selected)
        else { return [] }

        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        var dates: [Date] = []

        if leadingDays > 0 {
            for offset in stride(from: leadingDays, through: 1, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth) {
                    dates.append(date)
                }
            }
        }

        for day in daysRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }

        while dates.count % 7 != 0 {
            if let last = dates.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                dates.append(next)
            }
        }

        return dates
    }

    private var shortWeekdays: [String] {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        let first = Calendar.current.firstWeekday - 1
        let ordered = Array(symbols[first...]) + Array(symbols[..<first])
        return ordered.map { String($0.prefix(2)).uppercased() }
    }

    private var monthTitle: String {
        viewModel.selectedDate.formatted(.dateTime.month(.wide).year())
    }

    private func appointmentCount(on date: Date) -> Int {
        viewModel.appointments.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }.count
    }

    private func select(_ date: Date) {
        withAnimation(.easeOut(duration: 0.18)) {
            viewModel.selectedDate = date
        }
    }

    private func changeMonth(by value: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            viewModel.selectedDate = Calendar.current.date(byAdding: .month, value: value, to: viewModel.selectedDate) ?? viewModel.selectedDate
        }
    }
}

private enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Settimana"
        case .month: return "Mese"
        }
    }
}

private enum AppointmentStatusFilter: String, CaseIterable, Identifiable {
    case all
    case scheduled
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Tutti"
        case .scheduled: return "Programm."
        case .completed: return "Completati"
        case .cancelled: return "Annullati"
        }
    }

    var color: Color {
        switch self {
        case .all: return AppColors.primaryBlack
        case .scheduled: return AppColors.calendarBlue
        case .completed: return AppColors.successGreen
        case .cancelled: return AppColors.dangerRed
        }
    }

    func matches(_ appointment: Appointment) -> Bool {
        switch self {
        case .all: return true
        case .scheduled: return appointment.status == .scheduled
        case .completed: return appointment.status == .completed
        case .cancelled: return appointment.status == .cancelled
        }
    }
}

private struct CalendarDayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isInDisplayedMonth: Bool
    let appointmentCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                if appointmentCount > 0 {
                    Text("\(appointmentCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? AppColors.primaryBlack : .white)
                        .frame(width: 22, height: 22)
                        .background(isSelected ? .white : AppColors.primaryBlack)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(isSelected ? .white.opacity(0.55) : AppColors.border)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isSelected ? .white : (isInDisplayedMonth ? AppColors.textPrimary : AppColors.textMuted))
            .frame(width: 64, height: 92)
            .background(isSelected ? AppColors.primaryBlack : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(isToday && !isSelected ? AppColors.primaryBlack : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarMonthDayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isInDisplayedMonth: Bool
    let appointmentCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 3) {
                    ForEach(0..<min(appointmentCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? .white : AppColors.calendarBlue)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .foregroundStyle(isSelected ? .white : (isInDisplayedMonth ? AppColors.textPrimary : AppColors.textMuted))
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppColors.primaryBlack : (isToday ? AppColors.surfaceSecondary : AppColors.surface))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .stroke(isToday && !isSelected ? AppColors.primaryBlack : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isInDisplayedMonth ? 1 : 0.45)
    }
}

struct MachinesListView: View {
    @StateObject private var viewModel: MachinesViewModel
    @State private var showingAdd = false
    @State private var editingMachine: Machine?
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.services = services
        _viewModel = StateObject(wrappedValue: MachinesViewModel(trainer: trainer, service: services.machineService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Menu {
                        Button("Tutti") { viewModel.selectedGroup = nil }
                        ForEach(MuscleGroup.allCases) { group in
                            Button(group.rawValue) { viewModel.selectedGroup = group }
                        }
                    } label: {
                        Label(viewModel.selectedGroup?.rawValue ?? "Filtra gruppo", systemImage: "line.3.horizontal.decrease.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    ForEach(viewModel.filteredMachines) { machine in
                        Button {
                            editingMachine = machine
                        } label: {
                            MachineCard(machine: machine)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Elimina", role: .destructive) { viewModel.delete(machine) }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Macchinari")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddMachineView(machine: viewModel.makeEmptyMachine(), catalogService: services.catalogService, onSave: viewModel.save)
            }
            .sheet(item: $editingMachine) { machine in
                AddMachineView(machine: machine, catalogService: services.catalogService, onSave: viewModel.save)
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }
}

struct WorkoutPlansListView: View {
    @StateObject private var viewModel: WorkoutPlansViewModel
    @State private var clients: [Client] = []
    @State private var showingCreate = false
    let trainer: Trainer
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
        _viewModel = StateObject(wrappedValue: WorkoutPlansViewModel(trainer: trainer, service: services.workoutService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.plans.isEmpty {
                        EmptyStateView(title: "Nessuna scheda", message: "Crea una scheda personalizzata per un cliente.", icon: "list.clipboard")
                    } else {
                        ForEach(viewModel.plans) { plan in
                            NavigationLink {
                                WorkoutPlanDetailView(plan: plan, client: clients.first(where: { $0.id == plan.clientID }))
                            } label: {
                                PlanCard(title: plan.name, subtitle: clients.first(where: { $0.id == plan.clientID })?.fullName ?? "Cliente", status: plan.status.rawValue, icon: "figure.run")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Schede")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateWorkoutPlanView(clients: clients, catalogService: services.catalogService, onCreate: viewModel.createTemplatePlan)
            }
            .appScreen()
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
        }
    }
}

struct NutritionPlansListView: View {
    @StateObject private var viewModel: NutritionPlansViewModel
    @State private var clients: [Client] = []
    @State private var showingCreate = false
    let trainer: Trainer
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
        _viewModel = StateObject(wrappedValue: NutritionPlansViewModel(trainer: trainer, service: services.nutritionService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if viewModel.plans.isEmpty {
                        EmptyStateView(title: "Nessun piano", message: "Crea un piano alimentare per un cliente.", icon: "fork.knife")
                    } else {
                        ForEach(viewModel.plans) { plan in
                            NavigationLink {
                                NutritionPlanDetailView(plan: plan)
                            } label: {
                                PlanCard(title: "\(plan.dailyCalories) kcal", subtitle: clients.first(where: { $0.id == plan.clientID })?.fullName ?? "Cliente", status: String(format: "Target %.1f kg", plan.targetWeightKg), icon: "leaf")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Nutrizione")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateNutritionPlanView(clients: clients, catalogService: services.catalogService, onCreate: viewModel.createTemplatePlan)
            }
            .appScreen()
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
        }
    }
}

private struct PlanCard: View {
    let title: String
    let subtitle: String
    let status: String
    let icon: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primaryBlack)
                .frame(width: 44, height: 44)
                .background(AppColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.successGreen)
        }
        .appCard()
    }
}

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    let client: Client?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SectionCard(title: plan.name, icon: "list.clipboard") {
                    InfoLine(label: "Cliente", value: client?.fullName ?? "Cliente")
                    InfoLine(label: "Obiettivo", value: plan.goal)
                    InfoLine(label: "Stato", value: plan.status.rawValue)
                }

                ForEach(plan.days) { day in
                    SectionCard(title: "Giorno \(day.dayIndex): \(day.title)", icon: "figure.run") {
                        ForEach(day.exercises.sorted { $0.order < $1.order }) { exercise in
                            WorkoutExerciseRow(exercise: exercise)
                            Divider().background(AppColors.divider)
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Scheda")
        .appScreen()
    }
}

struct NutritionPlanDetailView: View {
    let plan: NutritionPlan

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SectionCard(title: "Piano alimentare", icon: "fork.knife") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                        MacroNutrientCard(title: "Calorie", value: "\(plan.dailyCalories)", color: AppColors.nutritionYellow)
                        MacroNutrientCard(title: "Proteine", value: "\(plan.proteinGrams) g", color: AppColors.successGreen)
                        MacroNutrientCard(title: "Carboidrati", value: "\(plan.carbohydrateGrams) g", color: AppColors.infoBlue)
                        MacroNutrientCard(title: "Grassi", value: "\(plan.fatGrams) g", color: AppColors.energyOrange)
                    }
                    Text(plan.notes)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                ForEach(plan.meals) { meal in
                    SectionCard(title: meal.name, icon: "clock") {
                        Text(meal.time.formattedTime())
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        ForEach(meal.foods) { food in
                            HStack {
                                Text(food.name)
                                Spacer()
                                Text(food.quantity)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .font(.subheadline)
                        }
                        if !meal.notes.isEmpty {
                            Text(meal.notes)
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Nutrizione")
        .appScreen()
    }
}

struct SubscriptionView: View {
    @State private var plans: [SubscriptionPlanDTO] = []
    @State private var errorMessage: String?
    let trainer: Trainer
    let services: AppServices

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionCard(title: "Piano attuale", icon: "creditcard") {
                        InfoLine(label: "Trainer", value: trainer.fullName)
                        InfoLine(label: "Studio", value: trainer.studioName)
                        InfoLine(label: "Piano locale", value: trainer.subscriptionTier.rawValue)
                    }

                    SectionCard(title: "Pacchetti SaaS", icon: "square.stack.3d.up") {
                        if plans.isEmpty {
                            Text(errorMessage ?? "Configura Supabase per leggere i piani reali.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                        } else {
                            ForEach(plans) { plan in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.name)
                                            .font(.headline)
                                        Text(plan.description)
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(String(format: "%.2f EUR", plan.monthlyPrice))
                                            .font(.subheadline.weight(.semibold))
                                        Text(plan.maxClients.map { "\($0) clienti" } ?? "Illimitato")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }
                                Divider().background(AppColors.divider)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Abbonamento")
            .appScreen()
            .task {
                do {
                    plans = try await services.subscriptionService.fetchPlans()
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
