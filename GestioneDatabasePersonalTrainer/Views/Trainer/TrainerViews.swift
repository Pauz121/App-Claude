import SwiftUI
import Charts

struct TrainerMainTabView: View {
    @EnvironmentObject private var services: AppServices
    let trainer: Trainer

    var body: some View {
        TabView {
            TrainerDashboardView(trainer: trainer, services: services)
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            ClientsListView(trainer: trainer, services: services)
                .tabItem { Label("Clienti", systemImage: "person.2.fill") }

            AppointmentsCalendarView(trainer: trainer, services: services)
                .tabItem { Label("Agenda", systemImage: "calendar") }

            TrainerMessagesView(trainer: trainer, services: services)
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .badge("")

            TrainerMenuView(trainer: trainer, services: services)
                .tabItem { Label("", systemImage: "line.3.horizontal") }
        }
        .tint(DesignSystem.Colors.indigo)
    }
}

struct TrainerDashboardView: View {
    @StateObject private var viewModel: TrainerDashboardViewModel
    @State private var clients: [Client] = []
    @State private var showingAddClient = false
    @State private var showingAddAppointment = false
    @State private var showingCreateWorkout = false
    @State private var showingCreateNutrition = false
    @State private var showingAlerts = false
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
                VStack(alignment: .leading, spacing: 18) {
                    header
                    kpiGrid

                    SectionLabel(text: "Azioni rapide")
                    quickActions
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddClient) {
                AddClientView(client: makeEmptyClient()) { client in
                    Task {
                        _ = await services.clientService.createClient(client)
                        reload()
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView(trainer: trainer, clients: clients) { appointment in
                    Task {
                        _ = await services.appointmentService.createAppointment(appointment)
                        reload()
                    }
                }
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutPlanView(clients: clients, catalogService: services.catalogService, services: services) { plan in
                    Task { _ = await services.workoutService.createWorkoutPlan(plan); reload() }
                }
            }
            .sheet(isPresented: $showingCreateNutrition) {
                CreateNutritionPlanView(clients: clients, catalogService: services.catalogService, services: services) { plan in
                    Task { _ = await services.nutritionService.createNutritionPlan(plan); reload() }
                }
            }
            .sheet(isPresented: $showingAlerts) {
                TrainerNotificationsSheet(insights: viewModel.insights)
                    .presentationDetents([.large])
            }
            .appScreen()
            .task { reload() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(trainer.studioName.uppercased())
                    .font(DesignSystem.Typography.sectionLabel())
                    .tracking(1.8)
                    .foregroundStyle(DesignSystem.Colors.indigo)
                Text("Ciao, \(trainer.firstName)")
                    .font(.custom("Archivo-ExtraBold", size: 26))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
            }
            Spacer()
            HStack(spacing: 10) {
                Button { showingAlerts = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            .frame(width: 36, height: 36)
                            .background(DesignSystem.Colors.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(DesignSystem.Colors.bgLine, lineWidth: 1)
                            )
                        if !viewModel.insights.isEmpty {
                            Circle()
                                .fill(DesignSystem.Colors.amber)
                                .frame(width: 9, height: 9)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
                Text("PRO")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.txtPrimary)
                    .clipShape(Capsule())
            }
        }
    }

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            DashboardStatCard(
                icon: "person.2.fill",
                value: "\(viewModel.clients.count)",
                title: "Clienti attivi",
                delta: "+\(viewModel.newClientsThisMonth)",
                iconColor: DesignSystem.Colors.indigo,
                iconBackground: DesignSystem.Colors.indigoBg
            )
            DashboardStatCard(
                icon: "calendar.badge.clock",
                value: "\(viewModel.appointmentsToday)",
                title: "Sessioni oggi",
                delta: nil,
                iconColor: DesignSystem.Colors.amber,
                iconBackground: DesignSystem.Colors.amberBg
            )
            DashboardStatCard(
                icon: "list.clipboard.fill",
                value: "\(viewModel.activePlans)",
                title: "Schede attive",
                delta: nil,
                iconColor: DesignSystem.Colors.teal,
                iconBackground: DesignSystem.Colors.tealBg
            )
            DashboardStatCard(
                icon: "sparkles",
                value: "\(viewModel.newClientsThisMonth)",
                title: "Nuovi iscritti",
                delta: "+\(viewModel.newClientsThisMonth)",
                iconColor: DesignSystem.Colors.limeDark,
                iconBackground: DesignSystem.Colors.limeBg
            )
        }
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            QuickActionCard(icon: "person.badge.plus", title: "Nuovo cliente", subtitle: "Aggiungi e genera codice accesso", color: DesignSystem.Colors.indigo, colorBackground: DesignSystem.Colors.indigoBg, action: { showingAddClient = true })
            QuickActionCard(icon: "dumbbell.fill", title: "Nuova scheda", subtitle: "Crea piano allenamento", color: DesignSystem.Colors.teal, colorBackground: DesignSystem.Colors.tealBg, action: { showingCreateWorkout = true })
            QuickActionCard(icon: "fork.knife", title: "Nuovo piano", subtitle: "Crea piano alimentare", color: DesignSystem.Colors.amber, colorBackground: DesignSystem.Colors.amberBg, action: { showingCreateNutrition = true })
            QuickActionCard(icon: "calendar.badge.plus", title: "Appuntamento", subtitle: "Pianifica una sessione", color: DesignSystem.Colors.limeDark, colorBackground: DesignSystem.Colors.limeBg, action: { showingAddAppointment = true })
        }
    }

    private func reload() {
        viewModel.load()
        Task { clients = await services.clientService.fetchClients(for: trainer.id) }
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

struct TrainerAlertListView: View {
    let insights: [TrainerClientInsight]
    let clients: [Client]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Feedback & Alert")
                    .font(DesignSystem.Typography.titleLG())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                LazyVStack(spacing: 12) {
                    ForEach(insights) { insight in
                        FitCard {
                            HStack(spacing: 12) {
                                AvatarView(initials: initials(for: insight.clientName), gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.teal], size: 42)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(insight.clientName)
                                        .font(.custom("Archivo-ExtraBold", size: 15))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    Text(insight.message)
                                        .font(DesignSystem.Typography.labelMD())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                                Spacer()
                                Image(systemName: insight.iconName)
                                    .foregroundStyle(color(for: insight.severity))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: insight.severity))
                                .frame(width: 3)
                                .padding(.vertical, 14)
                        }
                    }
                    if insights.isEmpty {
                        EmptyStateView(title: "Nessun alert", message: "I feedback critici dei clienti appariranno qui.", icon: "bell")
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined()
    }

    private func color(for severity: InsightSeverity) -> Color {
        switch severity {
        case .info: return DesignSystem.Colors.indigo
        case .success: return DesignSystem.Colors.lime
        case .warning: return DesignSystem.Colors.amber
        case .alert: return Color(hex: "E57373")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SearchBarView(text: $viewModel.searchText, placeholder: "Cerca cliente, email o obiettivo")
                    SectionLabel(text: "\(viewModel.filteredClients.count) attivi")
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredClients) { client in
                            NavigationLink {
                                ClientDetailView(client: client, onSave: viewModel.save, onDelete: viewModel.delete)
                            } label: {
                                trainerClientRow(client)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Clienti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddClient = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(DesignSystem.Colors.txtPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(client: viewModel.makeEmptyClient(), onSave: viewModel.save)
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }

    private func trainerClientRow(_ client: Client) -> some View {
        FitCard {
            HStack(spacing: 12) {
                UserAvatarView(imageUrl: nil, firstName: client.firstName, lastName: client.lastName, size: 44, gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime])
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.custom("Archivo-ExtraBold", size: 16))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text("\(client.goal.isEmpty ? "Obiettivo" : client.goal) · \(weeksSinceJoin(client)) settimane")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
                StatusPill(status: .active)
            }
        }
    }
}

struct ClientDetailView: View {
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var selectedTab: DetailTab = .schedule
    @State private var workoutPlans: [WorkoutPlan] = []
    @State private var nutritionPlans: [NutritionPlan] = []
    @State private var progressEntries: [ProgressEntry] = []
    let client: Client
    let onSave: (Client) -> Void
    let onDelete: (Client) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                FitCard {
                    HStack(spacing: 14) {
                        UserAvatarView(imageUrl: nil, firstName: client.firstName, lastName: client.lastName, size: 52, gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime])
                        VStack(alignment: .leading, spacing: 4) {
                            Text(client.fullName)
                                .font(.custom("Archivo-ExtraBold", size: 18))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text(client.goal.isEmpty ? "Nessun obiettivo" : client.goal)
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            StatusPill(status: .active)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(String(format: "%.1f kg", client.currentWeightKg))
                                .font(.custom("Archivo-Black", size: 18))
                                .foregroundStyle(DesignSystem.Colors.limeDark)
                            Text("peso attuale")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    }
                }

                detailTabs

                Group {
                    switch selectedTab {
                    case .schedule: scheduleTab
                    case .diet: dietTab
                    case .feedback: feedbackTab
                    case .progress: progressTab
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddClientView(client: client, onSave: onSave)
        }
        .appScreen()
        .task {
            workoutPlans = await services.workoutService.fetchWorkoutPlans(forClient: client.id)
            nutritionPlans = await services.nutritionService.fetchNutritionPlans(forClient: client.id)
            progressEntries = await services.progressService.fetchProgressEntries(for: client.id)
        }
    }

    private var detailTabs: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(selectedTab == tab ? DesignSystem.Colors.indigo : DesignSystem.Colors.txtSecondary)
                        Rectangle()
                            .fill(selectedTab == tab ? DesignSystem.Colors.indigo : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var scheduleTab: some View {
        VStack(spacing: 12) {
            ForEach(workoutPlans.first?.days ?? []) { day in
                FitCard {
                    HStack {
                        FitIconChip(systemName: "dumbbell.fill", color: DesignSystem.Colors.indigo, background: DesignSystem.Colors.indigoBg, size: 34)
                        VStack(alignment: .leading) {
                            Text(day.title)
                                .font(.custom("Archivo-ExtraBold", size: 15))
                            Text("\(day.exercises.count) esercizi")
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        Spacer()
                    }
                }
            }
            AccentButton(title: "Modifica scheda", color: DesignSystem.Colors.indigo) {}
        }
    }

    private var dietTab: some View {
        VStack(spacing: 12) {
            if let plan = nutritionPlans.first {
                FitCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(plan.dailyCalories) kcal")
                            .font(.custom("Archivo-Black", size: 26))
                            .foregroundStyle(DesignSystem.Colors.teal)
                        Text("P \(plan.proteinGrams)g · C \(plan.carbohydrateGrams)g · G \(plan.fatGrams)g")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
            }
            AccentButton(title: "Modifica piano", color: DesignSystem.Colors.indigo) {}
        }
    }

    private var feedbackTab: some View {
        VStack(spacing: 12) {
            FitCard {
                Text("I check settimanali salvati verranno mostrati qui con le metriche energia, sonno, fame e stress.")
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var progressTab: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                compactProgress("Peso", String(format: "%.1fkg", client.currentWeightKg), DesignSystem.Colors.limeDark)
                compactProgress("Inizio", String(format: "%.1fkg", client.initialWeightKg), DesignSystem.Colors.indigo)
            }
            FitCard {
                Chart(progressEntries.sorted { $0.date < $1.date }) { entry in
                    BarMark(x: .value("Data", entry.date), y: .value("Peso", entry.weightKg))
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
                .frame(height: 170)
            }
        }
    }

    private func compactProgress(_ title: String, _ value: String, _ color: Color) -> some View {
        FitCard {
            Text(value)
                .font(.custom("Archivo-Black", size: 22))
                .foregroundStyle(color)
            Text(title)
                .font(DesignSystem.Typography.labelSM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
        }
    }

    private enum DetailTab: CaseIterable, Identifiable {
        case schedule, diet, feedback, progress
        var id: Self { self }
        var title: String {
            switch self {
            case .schedule: return "Scheda"
            case .diet: return "Dieta"
            case .feedback: return "Feedback"
            case .progress: return "Progressi"
            }
        }
    }
}

struct AppointmentsCalendarView: View {
    @StateObject private var viewModel: AppointmentsViewModel
    @State private var clients: [Client] = []
    @State private var showingAdd = false
    @State private var editingAppointment: Appointment?
    @State private var mode: CalendarMode = .week
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
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("Agenda")
                            .font(.custom("Archivo-ExtraBold", size: 26))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).year()))
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    SegmentedPicker(options: CalendarMode.allCases, selection: $mode, title: \.title, accent: DesignSystem.Colors.indigo)
                    mode == .week ? AnyView(weekView) : AnyView(monthView)

                    SectionLabel(text: viewModel.selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    LazyVStack(spacing: 12) {
                        if viewModel.appointmentsForSelectedDate.isEmpty {
                            EmptyStateView(title: "Nessun appuntamento", message: "Non ci sono appuntamenti per il giorno selezionato.", icon: "calendar", actionTitle: "Aggiungi appuntamento") {
                                showingAdd = true
                            }
                        } else {
                            ForEach(viewModel.appointmentsForSelectedDate) { appointment in
                                Button { editingAppointment = appointment } label: {
                                    appointmentCard(appointment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(DesignSystem.Colors.txtPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddAppointmentView(trainer: trainer, clients: clients, existingAppointments: viewModel.appointments) { appointment in
                    viewModel.save(appointment)
                }
            }
            .sheet(item: $editingAppointment) { appointment in
                AddAppointmentView(trainer: trainer, clients: clients, appointment: appointment, existingAppointments: viewModel.appointments) { appointment in
                    viewModel.save(appointment)
                }
            }
            .appScreen()
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
        }
    }

    private var weekView: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(viewModel.weekDates().prefix(7), id: \.self) { date in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { viewModel.selectedDate = date }
                } label: {
                    VStack(spacing: 8) {
                        Text(String(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1)))
                            .font(DesignSystem.Typography.labelSM())
                        Text(date.formatted(.dateTime.day()))
                            .font(.custom("Archivo-ExtraBold", size: 16))
                        ForEach(0..<min(appointmentCount(on: date), 3), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.indigo)
                                .frame(height: 8)
                        }
                    }
                    .foregroundStyle(Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) ? .white : DesignSystem.Colors.txtPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 102)
                    .background(Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var monthView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(monthDates, id: \.self) { date in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { viewModel.selectedDate = date }
                } label: {
                    Text(date.formatted(.dateTime.day()))
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(dayForeground(date))
                        .frame(width: 36, height: 36)
                        .background(dayBackground(date))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private func appointmentCard(_ appointment: Appointment) -> some View {
        let typeColor = appointment.sessionType == .checkin ? DesignSystem.Colors.amber : DesignSystem.Colors.indigo
        return FitCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(typeColor)
                    .frame(width: 3, height: 54)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(appointment.startTime.formattedTime()) – \(appointment.endTime.formattedTime())")
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(typeColor)
                    Text(clientName(for: appointment.clientID))
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(appointment.sessionType.displayName)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
            }
        }
    }

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.selectedDate)) ?? viewModel.selectedDate
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<31
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private func appointmentCount(on date: Date) -> Int {
        viewModel.appointments.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }.count
    }

    private func dayForeground(_ date: Date) -> Color {
        if Calendar.current.isDateInToday(date) { return .white }
        if appointmentCount(on: date) > 0 { return DesignSystem.Colors.indigo }
        return DesignSystem.Colors.txtPrimary
    }

    private func dayBackground(_ date: Date) -> Color {
        if Calendar.current.isDateInToday(date) { return DesignSystem.Colors.txtPrimary }
        if appointmentCount(on: date) > 0 { return DesignSystem.Colors.indigoBg }
        return .clear
    }

    private func clientName(for id: UUID) -> String {
        clients.first(where: { $0.id == id })?.fullName ?? "Cliente"
    }
}

private enum CalendarMode: CaseIterable, Hashable {
    case week, month
    var title: String {
        switch self {
        case .week: return "Settimana"
        case .month: return "Mese"
        }
    }
}

struct TrainerMessagesView: View {
    @StateObject private var viewModel: ClientsViewModel
    let trainer: Trainer

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        _viewModel = StateObject(wrappedValue: ClientsViewModel(trainer: trainer, clientService: services.clientService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Messaggi")
                            .font(.custom("Archivo-ExtraBold", size: 26))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Spacer()
                        Text("\(viewModel.clients.count) da leggere")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.amber)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.amberBg)
                            .clipShape(Capsule())
                    }
                    SearchBarView(text: $viewModel.searchText, placeholder: "Cerca cliente, email o telefono")
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredClients) { client in
                            NavigationLink {
                                TrainerConversationView(client: client)
                            } label: {
                                conversationRow(client)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .appScreen()
            .task { viewModel.load() }
        }
    }

    private func conversationRow(_ client: Client) -> some View {
        HStack(spacing: 12) {
            UserAvatarView(imageUrl: nil, firstName: client.firstName, lastName: client.lastName, size: 44, gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime])
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text("Tu: aggiorniamo la prossima sessione.")
                    .font(DesignSystem.Typography.bodySM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
                Text("09:42")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                Circle()
                    .fill(DesignSystem.Colors.indigo)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.indigoBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct TrainerConversationView: View {
    let client: Client
    @State private var text = ""
    @State private var messages: [LocalTrainerMessage] = [
        LocalTrainerMessage(text: "Come ti senti dopo l'ultima scheda?", isMine: true),
        LocalTrainerMessage(text: "Meglio, ma ho faticato sugli affondi.", isMine: false)
    ]
    @State private var showingFeedback = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                UserAvatarView(imageUrl: nil, firstName: client.firstName, lastName: client.lastName, size: 32, gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime])
                Text(client.fullName)
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                Button { showingFeedback = true } label: {
                    Image(systemName: "clipboard")
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
            }
            .padding(16)

            ScrollView {
                VStack(spacing: 12) {
                    Text("OGGI")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    ForEach(messages) { message in
                        HStack {
                            if message.isMine { Spacer(minLength: 40) }
                            Text(message.text)
                                .font(DesignSystem.Typography.bodyMD())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(message.isMine ? DesignSystem.Colors.indigoBg : DesignSystem.Colors.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(message.isMine ? DesignSystem.Colors.indigoBg : DesignSystem.Colors.bgLine, lineWidth: 1))
                            if !message.isMine { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(20)
            }

            HStack(spacing: 10) {
                TextField("Scrivi a \(client.firstName)…", text: $text)
                    .font(DesignSystem.Typography.bodyMD())
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(DesignSystem.Colors.bgCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DesignSystem.Colors.bgLine, lineWidth: 1))
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DesignSystem.Colors.indigo)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFeedback) {
            FeedbackOverlaySheet(client: client)
                .presentationDetents([.fraction(0.72)])
        }
        .appScreen()
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(LocalTrainerMessage(text: trimmed, isMine: true))
        text = ""
    }
}

private struct FeedbackOverlaySheet: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule().fill(DesignSystem.Colors.bgLine).frame(width: 46, height: 5).frame(maxWidth: .infinity)
            Text("Feedback di \(client.firstName)")
                .font(DesignSystem.Typography.titleLG())
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
            Text("Check settimanali")
                .font(DesignSystem.Typography.labelMD())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
            FitCard {
                Text("Energia stabile · Sonno medio · Stress da monitorare")
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
            Spacer()
        }
        .padding(24)
        .appScreen()
    }
}

private struct LocalTrainerMessage: Identifiable {
    let id = UUID()
    let text: String
    let isMine: Bool
}

struct TrainerMenuView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let trainer: Trainer
    let services: AppServices

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Menu")
                        .font(.custom("Archivo-ExtraBold", size: 26))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    SectionLabel(text: "Contenuti")
                    NavigationLink { WorkoutPlansListView(trainer: trainer, services: services) } label: { menuRow("Schede", "list.clipboard.fill") }
                    NavigationLink { NutritionPlansListView(trainer: trainer, services: services) } label: { menuRow("Diete", "fork.knife") }
                    NavigationLink { SavedMealsListView(trainer: trainer, services: services) } label: { menuRow("Pasti salvati", "bookmark.fill") }
                    NavigationLink { MachinesListView(trainer: trainer, services: services) } label: { menuRow("Catalogo macchinari", "dumbbell.fill") }

                    SectionLabel(text: "Studio")
                    NavigationLink { SubscriptionView(trainer: trainer, services: services) } label: { menuRow("Abbonamenti", "creditcard.fill") }
                    NavigationLink { TrainerSettingsView(trainer: trainer) } label: { menuRow("Impostazioni", "gearshape.fill") }
                    Button {
                        authViewModel.logout()
                    } label: {
                        menuRow("Esci", "rectangle.portrait.and.arrow.right", muted: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .appScreen()
        }
    }

    private func menuRow(_ title: String, _ icon: String, muted: Bool = false) -> some View {
        FitCard {
            HStack(spacing: 12) {
                FitIconChip(systemName: icon, color: muted ? DesignSystem.Colors.txtSecondary : DesignSystem.Colors.indigo, background: muted ? DesignSystem.Colors.bgLine.opacity(0.7) : DesignSystem.Colors.indigoBg, size: 36)
                Text(title)
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }
}

struct MachinesListView: View {
    @StateObject private var viewModel: MachinesViewModel
    @State private var showingAdd = false
    let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.services = services
        _viewModel = StateObject(wrappedValue: MachinesViewModel(trainer: trainer, service: services.machineService))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Catalogo macchinari")
                        .font(DesignSystem.Typography.titleLG())
                    Spacer()
                    Button("+") { showingAdd = true }
                        .font(.custom("Archivo-Black", size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DesignSystem.Colors.txtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        PillFilterButton(title: "Tutti", isSelected: viewModel.selectedGroup == nil, color: DesignSystem.Colors.indigo) { viewModel.selectedGroup = nil }
                        ForEach(MuscleGroup.allCases) { group in
                            PillFilterButton(title: group.rawValue, isSelected: viewModel.selectedGroup == group, color: DesignSystem.Colors.indigo) { viewModel.selectedGroup = group }
                        }
                    }
                }
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredMachines) { machine in
                        MachineCard(machine: machine)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAdd) {
            AddMachineView(machine: viewModel.makeEmptyMachine(), catalogService: services.catalogService, onSave: viewModel.save)
        }
        .appScreen()
        .task { viewModel.load() }
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
        plansList(title: "Schede", icon: "dumbbell.fill", plans: viewModel.plans.map { plan in
            (plan.id, plan.name, clients.first(where: { $0.id == plan.clientID })?.fullName ?? "Cliente", plan.status.rawValue)
        })
            .sheet(isPresented: $showingCreate) {
                CreateWorkoutPlanView(clients: clients, catalogService: services.catalogService, services: services) { plan in
                    viewModel.createPlan(plan)
                }
            }
            .task {
                viewModel.load()
                clients = await services.clientService.fetchClients(for: trainer.id)
            }
    }

    private func plansList(title: String, icon: String, plans: [(UUID, String, String, String)]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text(title).font(DesignSystem.Typography.titleLG())
                    Spacer()
                    Button("+") { showingCreate = true }
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DesignSystem.Colors.txtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                ForEach(plans, id: \.0) { plan in
                    FitCard {
                        HStack {
                            FitIconChip(systemName: icon, color: DesignSystem.Colors.indigo, background: DesignSystem.Colors.indigoBg, size: 36)
                            VStack(alignment: .leading) {
                                Text(plan.1).font(.custom("Archivo-ExtraBold", size: 15))
                                Text(plan.2).font(DesignSystem.Typography.labelMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            Spacer()
                            StatusBadge(text: plan.3, style: .active)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
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
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("Diete").font(DesignSystem.Typography.titleLG())
                    Spacer()
                    Button("+") { showingCreate = true }
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DesignSystem.Colors.txtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                ForEach(viewModel.plans) { plan in
                    FitCard {
                        HStack {
                            FitIconChip(systemName: "fork.knife", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 36)
                            VStack(alignment: .leading) {
                                Text("\(plan.dailyCalories) kcal").font(.custom("Archivo-ExtraBold", size: 15))
                                Text(clients.first(where: { $0.id == plan.clientID })?.fullName ?? "Cliente").font(DesignSystem.Typography.labelMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            Spacer()
                            StatusBadge(text: "attiva", style: .active)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreate) {
            CreateNutritionPlanView(clients: clients, catalogService: services.catalogService, services: services) { plan in
                viewModel.createPlan(plan)
            }
        }
        .appScreen()
        .task {
            viewModel.load()
            clients = await services.clientService.fetchClients(for: trainer.id)
        }
    }
}

struct SubscriptionView: View {
    @State private var plans: [SubscriptionPlanDTO] = []
    @State private var errorMessage: String?
    let trainer: Trainer
    let services: AppServices

    private var mockExpiryDate: Date { .daysFromNow(28) }

    private var currentPlanFeatures: [String] {
        switch trainer.subscriptionTier {
        case .free: return ["Fino a 3 clienti", "Schede base", "Agenda settimanale"]
        case .pro: return ["Clienti illimitati", "Schede avanzate", "Piani alimentari", "Agenda completa", "Progressi e foto", "Check-in clienti", "Analytics"]
        case .studio: return ["Tutto di Pro", "Multi-trainer", "Branding studio", "Supporto prioritario", "Reportistica avanzata", "API access"]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Abbonamento")
                    .font(.custom("Archivo-ExtraBold", size: 26))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)

                currentPlanCard
                featuresCard
                SectionLabel(text: "Altri piani")
                otherPlansSection
                if let errorMessage {
                    Text(errorMessage).font(DesignSystem.Typography.bodySM()).foregroundStyle(AppColors.dangerRed)
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

    private var currentPlanCard: some View {
        FitCard(border: DesignSystem.Colors.indigo, lineWidth: 2) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("PIANO ATTUALE")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.indigo)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.indigoBg)
                        .clipShape(Capsule())
                    Spacer()
                    Text("ATTIVO")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.limeDark)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.limeBg)
                        .clipShape(Capsule())
                }
                Text(trainer.subscriptionTier.rawValue.uppercased())
                    .font(.custom("Archivo-Black", size: 32))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("Scade il \(mockExpiryDate.formatted(.dateTime.day().month(.wide).year()))")
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
    }

    private var featuresCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Incluso nel piano")
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                ForEach(currentPlanFeatures, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                            .font(.system(size: 16))
                        Text(feature)
                            .font(DesignSystem.Typography.bodyMD())
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Spacer()
                    }
                }
            }
        }
    }

    private var otherPlansSection: some View {
        VStack(spacing: 12) {
            if plans.isEmpty {
                staticPlanCards
            } else {
                ForEach(plans) { plan in
                    planCard(name: plan.name, price: plan.monthlyPrice, description: plan.description, maxClients: plan.maxClients)
                }
            }
            FitCard {
                HStack(spacing: 10) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("Il pagamento avverrà tramite il sistema di fatturazione. Placeholder per Stripe / RevenueCat / StoreKit.")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        .italic()
                }
            }
        }
    }

    private var staticPlanCards: some View {
        Group {
            if trainer.subscriptionTier != .free {
                planCard(name: "Free", price: 0, description: "Per iniziare. Fino a 3 clienti, funzionalità base.", maxClients: 3)
            }
            if trainer.subscriptionTier != .pro {
                planCard(name: "Pro", price: 29, description: "Clienti illimitati, piani alimentari, analytics.", maxClients: nil)
            }
            if trainer.subscriptionTier != .studio {
                planCard(name: "Studio", price: 79, description: "Multi-trainer, branding, reportistica avanzata.", maxClients: nil)
            }
        }
    }

    private func planCard(name: String, price: Double, description: String, maxClients: Int?) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(name.uppercased())
                        .font(.custom("Archivo-Black", size: 18))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Spacer()
                    if let maxClients {
                        Text("Max \(maxClients) clienti")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.bgLine)
                            .clipShape(Capsule())
                    }
                }
                Text(price == 0 ? "Gratuito" : String(format: "%.0f EUR / mese", price))
                    .font(.custom("Archivo-ExtraBold", size: 22))
                    .foregroundStyle(DesignSystem.Colors.indigo)
                Text(description)
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                AccentButton(title: "Passa a \(name)", color: DesignSystem.Colors.indigo) {
                    // Placeholder — collegare Stripe / RevenueCat / StoreKit
                }
            }
        }
    }
}

struct TrainerSettingsView: View {
    let trainer: Trainer
    @State private var notifications = true
    @State private var theme = "Sistema"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Impostazioni")
                    .font(DesignSystem.Typography.titleLG())
                SectionLabel(text: "Profilo trainer")
                VStack(spacing: 8) {
                    AvatarView(initials: initials(trainer), gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.teal], size: 70)
                    Button("Modifica foto") {}
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
                .frame(maxWidth: .infinity)
                settingsRow("Nome", trainer.firstName)
                settingsRow("Cognome", trainer.lastName)
                settingsRow("Studio/Palestra", trainer.studioName)
                settingsRow("Specializzazione", "Personal trainer")
                SectionLabel(text: "Preferenze")
                FitCard {
                    Toggle("Notifiche", isOn: $notifications)
                        .tint(DesignSystem.Colors.indigo)
                        .font(DesignSystem.Typography.labelMD())
                }
                settingsRow("Lingua", "Italiano")
                settingsRow("Tema", theme)
                SectionLabel(text: "Account")
                settingsRow("Cambia password", "")
                settingsRow("Privacy e dati", "")
                settingsRow("Termini di servizio", "")
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func settingsRow(_ title: String, _ value: String) -> some View {
        FitCard {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }
}

struct SavedMealsListView: View {
    @State private var meals: [SavedMeal] = []
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingMeal: SavedMeal?
    let trainer: Trainer
    let services: AppServices

    var filtered: [SavedMeal] {
        searchText.isEmpty ? meals : meals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SearchBarView(text: $searchText, placeholder: "Cerca pasto salvato")
                SectionLabel(text: "\(filtered.count) pasti")
                LazyVStack(spacing: 12) {
                    ForEach(filtered) { meal in
                        savedMealRow(meal)
                    }
                    if filtered.isEmpty {
                        EmptyStateView(title: "Nessun pasto salvato", message: "Aggiungi pasti ricorrenti per riutilizzarli nelle diete.", icon: "bookmark")
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Pasti salvati")
                    .font(.custom("Archivo-ExtraBold", size: 20))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DesignSystem.Colors.txtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAdd) {
            EditSavedMealSheet(meal: SavedMeal(id: UUID(), trainerID: trainer.id, name: "", description: "", proteinGrams: 0, carbGrams: 0, fatGrams: 0, notes: "", createdAt: Date())) { saved in
                Task { _ = await services.savedMealService.createSavedMeal(saved); reload() }
            }
        }
        .sheet(item: $editingMeal) { meal in
            EditSavedMealSheet(meal: meal) { updated in
                Task { await services.savedMealService.updateSavedMeal(updated); reload() }
            }
        }
        .appScreen()
        .task { reload() }
    }

    private func savedMealRow(_ meal: SavedMeal) -> some View {
        FitCard {
            HStack(spacing: 12) {
                FitIconChip(systemName: "bookmark.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(meal.description.isEmpty ? "Nessuna descrizione" : meal.description)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        macroTag("P \(Int(meal.proteinGrams))g", DesignSystem.Colors.teal)
                        macroTag("C \(Int(meal.carbGrams))g", DesignSystem.Colors.amber)
                        macroTag("G \(Int(meal.fatGrams))g", DesignSystem.Colors.limeDark)
                        macroTag("\(Int(meal.kcal)) kcal", DesignSystem.Colors.indigo)
                    }
                }
                Spacer()
                Menu {
                    Button("Modifica") { editingMeal = meal }
                    Button("Elimina", role: .destructive) {
                        Task { await services.savedMealService.deleteSavedMeal(meal); reload() }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
    }

    private func macroTag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(DesignSystem.Typography.labelSM())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func reload() {
        Task { meals = await services.savedMealService.fetchSavedMeals(for: trainer.id) }
    }
}

struct EditSavedMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var meal: SavedMeal
    let onSave: (SavedMeal) -> Void

    init(meal: SavedMeal, onSave: @escaping (SavedMeal) -> Void) {
        _meal = State(initialValue: meal)
        self.onSave = onSave
    }

    var computedKcal: Int { Int(meal.proteinGrams * 4 + meal.carbGrams * 4 + meal.fatGrams * 9) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FitInputField(label: "Nome pasto", text: $meal.name)
                    FitInputField(label: "Descrizione / alimenti", text: $meal.description)
                    SectionLabel(text: "Macro")
                    HStack(spacing: 10) {
                        macroInput("Proteine", value: $meal.proteinGrams, color: DesignSystem.Colors.teal)
                        macroInput("Carbo", value: $meal.carbGrams, color: DesignSystem.Colors.amber)
                        macroInput("Grassi", value: $meal.fatGrams, color: DesignSystem.Colors.limeDark)
                    }
                    FitCard {
                        HStack {
                            FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 30)
                            Text("Calorie calcolate")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Spacer()
                            Text("\(computedKcal) kcal")
                                .font(.custom("Archivo-ExtraBold", size: 18))
                                .foregroundStyle(DesignSystem.Colors.teal)
                        }
                    }
                    FitInputField(label: "Note (opzionale)", text: $meal.notes)
                    AccentButton(title: "Salva pasto", color: DesignSystem.Colors.teal) {
                        onSave(meal)
                        dismiss()
                    }
                    .disabled(meal.name.isEmpty)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            .appScreen()
        }
    }

    private func macroInput(_ label: String, value: Binding<Double>, color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(DesignSystem.Typography.labelSM()).foregroundStyle(color)
                TextField("0", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.custom("Archivo-Black", size: 18))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text("g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }
}

private func initials(_ client: Client) -> String {
    "\(client.firstName.first.map(String.init) ?? "")\(client.lastName.first.map(String.init) ?? "")"
}

private func initials(_ trainer: Trainer) -> String {
    "\(trainer.firstName.first.map(String.init) ?? "")\(trainer.lastName.first.map(String.init) ?? "")"
}

private func weeksSinceJoin(_ client: Client) -> Int {
    max(Calendar.current.dateComponents([.weekOfYear], from: client.joinedAt, to: Date()).weekOfYear ?? 0, 1)
}
