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

                    SectionLabel(text: "Agenda di oggi")
                    todayAgenda

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

    private var todayAgenda: some View {
        FitCard {
            if viewModel.appointmentsForToday.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.txtSecondary.opacity(0.5))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nessun appuntamento oggi")
                            .font(.custom("Archivo-ExtraBold", size: 14))
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        Button { showingAddAppointment = true } label: {
                            Text("Aggiungi appuntamento →")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.indigo)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.appointmentsForToday.enumerated()), id: \.element.id) { index, appt in
                        DashboardAgendaRow(
                            appointment: appt,
                            clientName: viewModel.clientName(for: appt)
                        )
                        if index < viewModel.appointmentsForToday.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.bgLine)
                                .padding(.leading, 68)
                        }
                    }
                    NavigationLink {
                        AppointmentsCalendarView(trainer: trainer, services: services)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Vai all'agenda →")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.indigo)
                        }
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
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

private struct DashboardAgendaRow: View {
    let appointment: Appointment
    let clientName: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(startTimeString)
                    .font(.custom("Archivo-ExtraBold", size: 13))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text(durationString)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
            .frame(width: 52, alignment: .trailing)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusColor)
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                Text(clientName)
                    .font(.custom("Archivo-ExtraBold", size: 14))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                HStack(spacing: 6) {
                    Text(appointment.sessionType.rawValue)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(sessionTypeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(sessionTypeColor.opacity(0.1))
                        .clipShape(Capsule())
                    Text(appointment.status.rawValue)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var startTimeString: String {
        appointment.startTime.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }

    private var durationString: String {
        let minutes = Int(appointment.endTime.timeIntervalSince(appointment.startTime) / 60)
        return "\(minutes)min"
    }

    private var statusColor: Color {
        switch appointment.status {
        case .scheduled: return DesignSystem.Colors.indigo
        case .completed: return DesignSystem.Colors.teal
        case .cancelled: return DesignSystem.Colors.amber
        }
    }

    private var sessionTypeColor: Color {
        switch appointment.sessionType {
        case .workout: return DesignSystem.Colors.limeDark
        case .assessment: return DesignSystem.Colors.indigo
        case .nutrition: return DesignSystem.Colors.teal
        case .checkin: return DesignSystem.Colors.amber
        case .recovery: return DesignSystem.Colors.txtSecondary
        }
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
    @State private var exerciseHistory: [ExerciseWeightHistoryDTO] = []
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
            exerciseHistory = await services.workoutService.fetchExerciseWeightHistory(for: client.id)
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
            if let active = workoutPlans.first(where: { $0.status == .active }) ?? workoutPlans.first {
                NavigationLink {
                    TrainerClientWorkoutPlansView(client: client, workoutPlans: workoutPlans)
                } label: {
                    workoutPlanSummaryCard(active, isActive: active.status == .active)
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateView(title: "Nessuna scheda", message: "Crea una scheda per questo cliente.", icon: "dumbbell")
            }
        }
    }

    private var dietTab: some View {
        VStack(spacing: 12) {
            if let active = nutritionPlans.first {
                NavigationLink {
                    TrainerClientNutritionPlansView(client: client, nutritionPlans: nutritionPlans)
                } label: {
                    nutritionPlanSummaryCard(active)
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateView(title: "Nessun piano", message: "Crea un piano alimentare per questo cliente.", icon: "fork.knife")
            }
        }
    }

    private func workoutPlanSummaryCard(_ plan: WorkoutPlan, isActive: Bool) -> some View {
        FitCard(border: isActive ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: isActive ? 2 : 1) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.custom("Archivo-ExtraBold", size: 16))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(plan.goal.isEmpty ? "Nessun obiettivo" : plan.goal)
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    Text(plan.status.rawValue)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(isActive ? DesignSystem.Colors.limeDark : DesignSystem.Colors.txtSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isActive ? DesignSystem.Colors.limeBg : DesignSystem.Colors.bgLine)
                        .clipShape(Capsule())
                }
                HStack(spacing: 16) {
                    Label("\(plan.days.count) giorni", systemImage: "calendar")
                    Label("\(plan.days.flatMap(\.exercises).count) esercizi", systemImage: "dumbbell")
                }
                .font(DesignSystem.Typography.labelSM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                HStack {
                    Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
            }
        }
    }

    private func nutritionPlanSummaryCard(_ plan: NutritionPlan) -> some View {
        FitCard(border: DesignSystem.Colors.teal, lineWidth: 2) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(plan.dailyCalories) kcal")
                        .font(.custom("Archivo-Black", size: 22))
                        .foregroundStyle(DesignSystem.Colors.teal)
                    Spacer()
                    Text("Attivo")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.tealBg)
                        .clipShape(Capsule())
                }
                Text("P \(plan.proteinGrams)g · C \(plan.carbohydrateGrams)g · G \(plan.fatGrams)g")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                HStack {
                    Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.teal)
                }
            }
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
        NavigationLink {
            TrainerClientProgressView(
                client: client,
                progressEntries: progressEntries,
                exerciseHistory: exerciseHistory,
                workoutPlans: workoutPlans
            )
        } label: {
            progressSummaryCard
        }
        .buttonStyle(.plain)
    }

    private var progressSummaryCard: some View {
        let diff = client.currentWeightKg - client.initialWeightKg
        let exerciseCount = Set(exerciseHistory.map(\.exerciseId)).count
        return FitCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Progressi")
                        .font(.custom("Archivo-ExtraBold", size: 16))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "%.1f kg", client.currentWeightKg))
                            .font(.custom("Archivo-Black", size: 22))
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                        Text("peso attuale")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "%+.1f kg", diff))
                            .font(.custom("Archivo-Black", size: 22))
                            .foregroundStyle(diff <= 0 ? DesignSystem.Colors.teal : DesignSystem.Colors.amber)
                        Text("dall'inizio")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    if exerciseCount > 0 {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(exerciseCount)")
                                .font(.custom("Archivo-Black", size: 22))
                                .foregroundStyle(DesignSystem.Colors.indigo)
                            Text("esercizi")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    }
                }
            }
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

// MARK: - Trainer: lista schede cliente

struct TrainerClientWorkoutPlansView: View {
    let client: Client
    let workoutPlans: [WorkoutPlan]

    private var activePlan: WorkoutPlan? {
        workoutPlans.first(where: { $0.status == .active }) ?? workoutPlans.first
    }
    private var historicalPlans: [WorkoutPlan] {
        workoutPlans.filter { $0.id != activePlan?.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan = activePlan {
                    SectionLabel(text: "Scheda attiva")
                    NavigationLink {
                        TrainerClientWorkoutPlanDetailView(plan: plan, client: client)
                    } label: {
                        workoutPlanCard(plan, highlighted: true)
                    }
                    .buttonStyle(.plain)
                }
                if !historicalPlans.isEmpty {
                    SectionLabel(text: "Storiche (\(historicalPlans.count))")
                    LazyVStack(spacing: 12) {
                        ForEach(historicalPlans) { plan in
                            NavigationLink {
                                TrainerClientWorkoutPlanDetailView(plan: plan, client: client)
                            } label: {
                                workoutPlanCard(plan, highlighted: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if workoutPlans.isEmpty {
                    EmptyStateView(title: "Nessuna scheda", message: "Nessuna scheda assegnata a questo cliente.", icon: "dumbbell")
                }
            }
            .padding(20)
        }
        .navigationTitle("\(client.firstName) · Schede")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func workoutPlanCard(_ plan: WorkoutPlan, highlighted: Bool) -> some View {
        FitCard(border: highlighted ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: highlighted ? 2 : 1) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.name)
                            .font(.custom("Archivo-ExtraBold", size: 16))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(plan.goal.isEmpty ? "Nessun obiettivo" : plan.goal)
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    Text(plan.status.rawValue)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(highlighted ? DesignSystem.Colors.limeDark : DesignSystem.Colors.txtSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(highlighted ? DesignSystem.Colors.limeBg : DesignSystem.Colors.bgLine)
                        .clipShape(Capsule())
                }
                HStack(spacing: 16) {
                    Label("\(plan.days.count) giorni", systemImage: "calendar")
                    Label("\(plan.days.flatMap(\.exercises).count) esercizi", systemImage: "dumbbell")
                }
                .font(DesignSystem.Typography.labelSM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                HStack {
                    Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.indigo)
                }
            }
        }
    }
}

// MARK: - Trainer: dettaglio scheda cliente

struct TrainerClientWorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    let client: Client
    @State private var expandedDay: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FitCard(border: plan.status == .active ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: plan.status == .active ? 2 : 1) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name)
                                    .font(.custom("Archivo-ExtraBold", size: 18))
                                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                if !plan.goal.isEmpty {
                                    Text(plan.goal)
                                        .font(DesignSystem.Typography.bodyMD())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                            }
                            Spacer()
                            Text(plan.status.rawValue)
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(plan.status == .active ? DesignSystem.Colors.limeDark : DesignSystem.Colors.txtSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(plan.status == .active ? DesignSystem.Colors.limeBg : DesignSystem.Colors.bgLine)
                                .clipShape(Capsule())
                        }
                        Divider()
                        HStack(spacing: 16) {
                            Label("\(plan.days.count) giorni", systemImage: "calendar")
                            Label("\(plan.days.flatMap(\.exercises).count) esercizi", systemImage: "dumbbell")
                        }
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }

                SectionLabel(text: "Giorni di allenamento")

                if plan.days.isEmpty {
                    EmptyStateView(title: "Nessun giorno", message: "Questa scheda non ha giorni configurati.", icon: "calendar")
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(plan.days.sorted { $0.dayIndex < $1.dayIndex }) { day in
                            trainerDayCard(day)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func trainerDayCard(_ day: WorkoutDay) -> some View {
        let isExpanded = expandedDay == day.id
        return FitCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedDay = isExpanded ? nil : day.id
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("\(day.dayIndex)")
                            .font(.custom("Archivo-Black", size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(day.exercises.isEmpty ? DesignSystem.Colors.bgLine : DesignSystem.Colors.indigo)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.title)
                                .font(.custom("Archivo-ExtraBold", size: 15))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text(day.exercises.isEmpty ? "Riposo" : "\(day.exercises.count) esercizi · ~\(max(day.exercises.count * 8, 25)) min")
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded && !day.exercises.isEmpty {
                    Divider().padding(.top, 12)
                    LazyVStack(spacing: 8) {
                        ForEach(day.exercises.sorted { $0.order < $1.order }) { exercise in
                            TrainerExerciseRow(exercise: exercise)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

private struct TrainerExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(exercise.order)")
                .font(.custom("Archivo-Black", size: 13))
                .foregroundStyle(DesignSystem.Colors.indigo)
                .frame(width: 28, height: 28)
                .background(DesignSystem.Colors.indigoBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.custom("Archivo-ExtraBold", size: 14))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                HStack(spacing: 4) {
                    Text("\(exercise.sets)×\(exercise.reps)")
                    Text("·")
                    Text("rec \(exercise.restSeconds)s")
                    if !exercise.recommendedLoad.isEmpty {
                        Text("·")
                        Text(exercise.recommendedLoad)
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                    }
                }
                .font(DesignSystem.Typography.bodySM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                if !exercise.technicalNotes.isEmpty {
                    Text(exercise.technicalNotes)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Trainer: lista diete cliente

struct TrainerClientNutritionPlansView: View {
    let client: Client
    let nutritionPlans: [NutritionPlan]

    private var activePlan: NutritionPlan? { nutritionPlans.first }
    private var historicalPlans: [NutritionPlan] { Array(nutritionPlans.dropFirst()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan = activePlan {
                    SectionLabel(text: "Piano attivo")
                    NavigationLink {
                        TrainerClientNutritionPlanDetailView(plan: plan, client: client)
                    } label: {
                        nutritionPlanCard(plan, highlighted: true)
                    }
                    .buttonStyle(.plain)
                }
                if !historicalPlans.isEmpty {
                    SectionLabel(text: "Storici (\(historicalPlans.count))")
                    LazyVStack(spacing: 12) {
                        ForEach(historicalPlans) { plan in
                            NavigationLink {
                                TrainerClientNutritionPlanDetailView(plan: plan, client: client)
                            } label: {
                                nutritionPlanCard(plan, highlighted: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if nutritionPlans.isEmpty {
                    EmptyStateView(title: "Nessun piano", message: "Nessun piano alimentare assegnato a questo cliente.", icon: "fork.knife")
                }
            }
            .padding(20)
        }
        .navigationTitle("\(client.firstName) · Diete")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func nutritionPlanCard(_ plan: NutritionPlan, highlighted: Bool) -> some View {
        FitCard(border: highlighted ? DesignSystem.Colors.teal : DesignSystem.Colors.bgLine, lineWidth: highlighted ? 2 : 1) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(plan.dailyCalories) kcal")
                        .font(.custom("Archivo-Black", size: 20))
                        .foregroundStyle(DesignSystem.Colors.teal)
                    Spacer()
                    Text(highlighted ? "Attivo" : "Archiviato")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(highlighted ? DesignSystem.Colors.teal : DesignSystem.Colors.txtSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(highlighted ? DesignSystem.Colors.tealBg : DesignSystem.Colors.bgLine)
                        .clipShape(Capsule())
                }
                Text("P \(plan.proteinGrams)g · C \(plan.carbohydrateGrams)g · G \(plan.fatGrams)g")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                HStack {
                    Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(highlighted ? DesignSystem.Colors.teal : DesignSystem.Colors.txtSecondary)
                }
            }
        }
    }
}

// MARK: - Trainer: dettaglio dieta cliente

struct TrainerClientNutritionPlanDetailView: View {
    let plan: NutritionPlan
    let client: Client
    @State private var expandedDay: Int? = nil

    private let weekdayLabels = ["", "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]

    private var hasWeeklyGrouping: Bool {
        plan.meals.contains { $0.dayIndex > 0 }
    }

    private var groupedByDay: [(dayIndex: Int, meals: [Meal])] {
        let days = Array(Set(plan.meals.map(\.dayIndex))).sorted()
        return days.map { d in
            (dayIndex: d, meals: plan.meals.filter { $0.dayIndex == d }.sorted { $0.time < $1.time })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FitCard(border: DesignSystem.Colors.teal, lineWidth: 2) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Piano alimentare")
                                    .font(.custom("Archivo-ExtraBold", size: 18))
                                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                if plan.targetWeightKg > 0 {
                                    Text(String(format: "Obiettivo: %.1f kg", plan.targetWeightKg))
                                        .font(DesignSystem.Typography.bodySM())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                            }
                            Spacer()
                            Text("\(plan.dailyCalories) kcal")
                                .font(.custom("Archivo-Black", size: 22))
                                .foregroundStyle(DesignSystem.Colors.teal)
                        }
                        HStack(spacing: 16) {
                            macroChip("P", "\(plan.proteinGrams)g", DesignSystem.Colors.teal)
                            macroChip("C", "\(plan.carbohydrateGrams)g", DesignSystem.Colors.amber)
                            macroChip("G", "\(plan.fatGrams)g", DesignSystem.Colors.limeDark)
                        }
                        Divider()
                        Text("\(plan.startDate.formattedDay()) – \(plan.endDate.formattedDay())")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }

                if plan.meals.isEmpty {
                    FitCard {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 28))
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Text("Pasti non ancora caricati")
                                .font(DesignSystem.Typography.bodyMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Text("I dati arriveranno quando il piano viene salvato con il nuovo flusso.")
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else if hasWeeklyGrouping {
                    SectionLabel(text: "Piano settimanale")
                    LazyVStack(spacing: 10) {
                        ForEach(groupedByDay, id: \.dayIndex) { group in
                            trainerDayMealCard(group)
                        }
                    }
                } else {
                    SectionLabel(text: "Pasti")
                    LazyVStack(spacing: 10) {
                        ForEach(plan.meals) { meal in
                            TrainerMealRow(meal: meal, estimatedDayKcal: plan.dailyCalories, totalMealsInDay: plan.meals.count)
                        }
                    }
                }

                if !plan.notes.isEmpty {
                    SectionLabel(text: "Note")
                    FitCard {
                        Text(plan.notes)
                            .font(DesignSystem.Typography.bodyMD())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Piano alimentare")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func macroChip(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.labelSM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
            Text(value)
                .font(.custom("Archivo-ExtraBold", size: 14))
                .foregroundStyle(color)
        }
    }

    private func mealKcal(_ meal: Meal) -> Int {
        let fromFoods = meal.foods.reduce(0.0) { $0 + $1.kcal }
        if fromFoods > 0 { return Int(fromFoods) }
        return plan.dailyCalories / max(plan.meals.count, 1)
    }

    private func trainerDayMealCard(_ group: (dayIndex: Int, meals: [Meal])) -> some View {
        let isExpanded = expandedDay == group.dayIndex
        let label = group.dayIndex > 0 && group.dayIndex < weekdayLabels.count
            ? weekdayLabels[group.dayIndex] : "Giorno \(group.dayIndex)"
        let totalKcal = group.meals.reduce(0) { $0 + mealKcal($1) }
        return FitCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedDay = isExpanded ? nil : group.dayIndex
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("\(group.dayIndex)")
                            .font(.custom("Archivo-Black", size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(DesignSystem.Colors.teal)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(label)
                                .font(.custom("Archivo-ExtraBold", size: 15))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text("\(group.meals.count) pasti · \(totalKcal) kcal")
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().padding(.top, 12)
                    LazyVStack(spacing: 8) {
                        ForEach(group.meals) { meal in
                            TrainerMealRow(meal: meal, estimatedDayKcal: plan.dailyCalories, totalMealsInDay: max(group.meals.count, 1))
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

private struct TrainerMealRow: View {
    let meal: Meal
    let estimatedDayKcal: Int
    let totalMealsInDay: Int
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    FitIconChip(systemName: "fork.knife", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(meal.name)
                            .font(.custom("Archivo-ExtraBold", size: 14))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(meal.foods.isEmpty ? "Nessun alimento" : meal.foods.map(\.name).joined(separator: ", "))
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(estimatedKcal) kcal")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.teal)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            .buttonStyle(.plain)

            if expanded && !meal.foods.isEmpty {
                Divider().padding(.top, 10)
                VStack(spacing: 6) {
                    ForEach(meal.foods) { food in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.custom("Archivo-ExtraBold", size: 13))
                                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                Text("P\(Int(food.proteinGrams))g · C\(Int(food.carbGrams))g · G\(Int(food.fatGrams))g")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(food.quantity)
                                    .font(DesignSystem.Typography.labelSM())
                                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                Text("\(Int(food.kcal)) kcal")
                                    .font(DesignSystem.Typography.labelSM())
                                    .foregroundStyle(DesignSystem.Colors.teal)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var estimatedKcal: Int {
        let fromFoods = meal.foods.reduce(0.0) { $0 + $1.kcal }
        if fromFoods > 0 { return Int(fromFoods) }
        return estimatedDayKcal / totalMealsInDay
    }
}

// MARK: - Trainer: progressi cliente

private struct ExerciseProgressGroup: Identifiable {
    var id: UUID { exerciseId }
    let exerciseId: UUID
    let name: String
    let entries: [ExerciseWeightHistoryDTO]

    var firstWeight: Double? { entries.first?.weightKg }
    var lastWeight: Double? { entries.last?.weightKg }
    var gain: Double? {
        guard let f = firstWeight, let l = lastWeight else { return nil }
        return l - f
    }
}

struct TrainerClientProgressView: View {
    let client: Client
    let progressEntries: [ProgressEntry]
    let exerciseHistory: [ExerciseWeightHistoryDTO]
    let workoutPlans: [WorkoutPlan]

    @State private var segment = 0
    private let segments = ["Peso", "Esercizi"]

    private var sortedEntries: [ProgressEntry] {
        progressEntries.sorted { $0.date < $1.date }
    }
    private var weightDiff: Double { client.currentWeightKg - client.initialWeightKg }
    private var hasMeasurements: Bool {
        progressEntries.contains { $0.waistCm > 0 || $0.chestCm > 0 || $0.armCm > 0 || $0.legCm > 0 }
    }
    private var latestEntry: ProgressEntry? { sortedEntries.last }

    private var exerciseNameMap: [UUID: String] {
        workoutPlans
            .flatMap(\.days)
            .flatMap(\.exercises)
            .reduce(into: [:]) { $0[$1.id] = $1.name }
    }
    private var exerciseGroups: [ExerciseProgressGroup] {
        let grouped = Dictionary(grouping: exerciseHistory, by: \.exerciseId)
        return grouped.map { exerciseId, entries in
            let sorted = entries.sorted { ($0.sessionDate ?? "") < ($1.sessionDate ?? "") }
            let name = exerciseNameMap[exerciseId] ?? "Esercizio (\(exerciseId.uuidString.prefix(6)))"
            return ExerciseProgressGroup(exerciseId: exerciseId, name: name, entries: sorted)
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("", selection: $segment) {
                    ForEach(segments.indices, id: \.self) { i in
                        Text(segments[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                if segment == 0 {
                    weightSection
                } else {
                    exerciseSection
                }
            }
            .padding(20)
        }
        .navigationTitle("\(client.firstName) · Progressi")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    // ── Peso ────────────────────────────────────────────────

    private var weightSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                weightStatCard("Inizio", String(format: "%.1f kg", client.initialWeightKg), DesignSystem.Colors.indigo)
                weightStatCard("Attuale", String(format: "%.1f kg", client.currentWeightKg), DesignSystem.Colors.limeDark)
                weightStatCard("Diff.", String(format: "%+.1f kg", weightDiff), weightDiff <= 0 ? DesignSystem.Colors.teal : DesignSystem.Colors.amber)
            }

            FitCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Andamento peso")
                        .font(.custom("Archivo-ExtraBold", size: 14))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    if sortedEntries.count > 1 {
                        Chart {
                            ForEach(sortedEntries) { entry in
                                LineMark(x: .value("Data", entry.date), y: .value("kg", entry.weightKg))
                                    .foregroundStyle(DesignSystem.Colors.indigo)
                                    .interpolationMethod(.catmullRom)
                                AreaMark(x: .value("Data", entry.date), y: .value("kg", entry.weightKg))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [DesignSystem.Colors.indigo.opacity(0.13), .clear],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                            }
                        }
                        .frame(height: 170)
                    } else if sortedEntries.count == 1 {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(DesignSystem.Colors.indigo)
                            Text("Una misurazione. Aggiungi altre per vedere il grafico.")
                                .font(DesignSystem.Typography.bodySM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        .padding(.vertical, 16)
                    } else {
                        EmptyStateView(title: "Nessuna misurazione", message: "Aggiungi misure per vedere l'andamento del peso.", icon: "chart.line.uptrend.xyaxis")
                            .frame(height: 120)
                    }
                }
            }

            if hasMeasurements, let entry = latestEntry {
                SectionLabel(text: "Ultima misurazione")
                HStack(spacing: 10) {
                    measureStatCard("Vita", entry.waistCm, "cm")
                    measureStatCard("Petto", entry.chestCm, "cm")
                }
                HStack(spacing: 10) {
                    measureStatCard("Braccio", entry.armCm, "cm")
                    measureStatCard("Coscia", entry.legCm, "cm")
                }
            }
        }
    }

    // ── Esercizi ─────────────────────────────────────────────

    private var exerciseSection: some View {
        VStack(spacing: 12) {
            if exerciseGroups.isEmpty {
                EmptyStateView(
                    title: "Nessun dato esercizi",
                    message: "I carichi vengono registrati durante gli allenamenti del cliente.",
                    icon: "dumbbell"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(exerciseGroups) { group in
                        NavigationLink {
                            TrainerClientExerciseProgressDetailView(group: group)
                        } label: {
                            ExerciseSparklineCard(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func weightStatCard(_ title: String, _ value: String, _ color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.custom("Archivo-Black", size: 17))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private func measureStatCard(_ title: String, _ value: Double, _ unit: String) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(value > 0 ? String(format: "%.1f \(unit)", value) : "--")
                    .font(.custom("Archivo-Black", size: 18))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }
}

private struct ExerciseSparklineCard: View {
    let group: ExerciseProgressGroup

    private struct SparkPoint: Identifiable {
        let id: Int
        let weight: Double
    }
    private var sparkPoints: [SparkPoint] {
        group.entries.enumerated().map { SparkPoint(id: $0.offset, weight: $0.element.weightKg) }
    }

    var body: some View {
        FitCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(group.name)
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    if let first = group.firstWeight, let last = group.lastWeight {
                        Text(String(format: "%.1f kg → %.1f kg", first, last))
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    if let gain = group.gain {
                        Text(String(format: "%+.1f kg", gain))
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(gain >= 0 ? DesignSystem.Colors.limeDark : DesignSystem.Colors.amber)
                    }
                }
                Spacer()
                if sparkPoints.count > 1 {
                    Chart(sparkPoints) { p in
                        LineMark(x: .value("i", p.id), y: .value("kg", p.weight))
                            .foregroundStyle(DesignSystem.Colors.indigo)
                            .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(width: 68, height: 38)
                } else {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.bgLine)
                        .frame(width: 68, height: 38)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }
}

struct TrainerClientExerciseProgressDetailView: View {
    let group: ExerciseProgressGroup

    private struct ChartPoint: Identifiable {
        let id: Int
        let weight: Double
        let label: String
    }
    private var chartPoints: [ChartPoint] {
        group.entries.enumerated().map { i, e in
            let label: String
            if let dateStr = e.sessionDate {
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
                if let d = fmt.date(from: dateStr) {
                    let out = DateFormatter(); out.dateFormat = "dd/MM"
                    label = out.string(from: d)
                } else { label = "S\(i + 1)" }
            } else { label = "S\(i + 1)" }
            return ChartPoint(id: i, weight: e.weightKg, label: label)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    exStatCard("Primo", group.firstWeight.map { String(format: "%.1f kg", $0) } ?? "--", DesignSystem.Colors.indigo)
                    exStatCard("Ultimo", group.lastWeight.map { String(format: "%.1f kg", $0) } ?? "--", DesignSystem.Colors.limeDark)
                    exStatCard("Guadagno", group.gain.map { String(format: "%+.1f kg", $0) } ?? "--", (group.gain ?? 0) >= 0 ? DesignSystem.Colors.teal : DesignSystem.Colors.amber)
                }

                SectionLabel(text: "Carico nel tempo")
                FitCard {
                    VStack(alignment: .leading, spacing: 8) {
                        if chartPoints.count > 1 {
                            Chart(chartPoints) { p in
                                LineMark(x: .value("Sessione", p.id), y: .value("Carico (kg)", p.weight))
                                    .foregroundStyle(DesignSystem.Colors.indigo)
                                    .interpolationMethod(.catmullRom)
                                AreaMark(x: .value("Sessione", p.id), y: .value("Carico (kg)", p.weight))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [DesignSystem.Colors.indigo.opacity(0.13), .clear],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                PointMark(x: .value("Sessione", p.id), y: .value("Carico (kg)", p.weight))
                                    .foregroundStyle(DesignSystem.Colors.indigo)
                                    .symbolSize(36)
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .chartXAxis {
                                AxisMarks(values: .automatic) { v in
                                    AxisValueLabel {
                                        if let i = v.as(Int.self), i < chartPoints.count {
                                            Text(chartPoints[i].label)
                                                .font(DesignSystem.Typography.labelSM())
                                        }
                                    }
                                }
                            }
                            .chartYAxisLabel("kg")
                            .frame(height: 200)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(DesignSystem.Colors.indigo)
                                Text("Solo una sessione. Continua ad allenarti per vedere il progresso.")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }

                SectionLabel(text: "Storico sessioni (\(group.entries.count))")
                LazyVStack(spacing: 8) {
                    ForEach(Array(group.entries.reversed().enumerated()), id: \.offset) { i, entry in
                        sessionRow(entry, sessionIndex: group.entries.count - i)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func sessionRow(_ entry: ExerciseWeightHistoryDTO, sessionIndex: Int) -> some View {
        FitCard {
            HStack(spacing: 12) {
                Text("S\(sessionIndex)")
                    .font(.custom("Archivo-Black", size: 13))
                    .foregroundStyle(DesignSystem.Colors.indigo)
                    .frame(width: 34, height: 34)
                    .background(DesignSystem.Colors.indigoBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: "%.1f kg", entry.weightKg))
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    if let dateStr = entry.sessionDate {
                        Text(formattedDate(dateStr))
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private func formattedDate(_ iso: String) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        if let d = fmt.date(from: iso) {
            let out = DateFormatter(); out.dateFormat = "d MMM yyyy"; out.locale = Locale(identifier: "it_IT")
            return out.string(from: d)
        }
        return iso
    }

    private func exStatCard(_ title: String, _ value: String, _ color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.custom("Archivo-Black", size: 17))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
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
        HStack(alignment: .top, spacing: 6) {
            ForEach(viewModel.weekDates(), id: \.self) { date in
                weekDayCell(date: date)
            }
        }
    }

    private func weekDayCell(date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday    = Calendar.current.isDateInToday(date)
        let hasAppts   = appointmentCount(on: date) > 0
        return Button {
            withAnimation(.easeOut(duration: 0.18)) { viewModel.selectedDate = date }
        } label: {
            VStack(spacing: 6) {
                Text(String(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1)))
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(isSelected ? Color.white.opacity(0.72) : DesignSystem.Colors.txtSecondary)
                Text(date.formatted(.dateTime.day()))
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(isSelected ? .white : DesignSystem.Colors.txtPrimary)
                if hasAppts {
                    Capsule()
                        .frame(width: 20, height: 2.5)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.78) : DesignSystem.Colors.txtPrimary.opacity(0.68))
                } else {
                    Color.clear.frame(height: 2.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background(isSelected ? DesignSystem.Colors.txtPrimary : DesignSystem.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear
                            : (isToday ? DesignSystem.Colors.txtPrimary.opacity(0.4) : DesignSystem.Colors.bgLine),
                        lineWidth: (isToday && !isSelected) ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
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
        .navigationTitle("Pasti salvati")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            EditSavedMealSheet(
                meal: SavedMeal(id: UUID(), trainerID: trainer.id, name: "", description: "", proteinGrams: 0, carbGrams: 0, fatGrams: 0, notes: "", createdAt: Date()),
                catalogService: services.catalogService
            ) { saved in
                Task { _ = await services.savedMealService.createSavedMeal(saved); reload() }
            }
        }
        .sheet(item: $editingMeal) { meal in
            EditSavedMealSheet(meal: meal, catalogService: services.catalogService) { updated in
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
                        macroTag("P \(Int(meal.displayProtein))g", DesignSystem.Colors.teal)
                        macroTag("C \(Int(meal.displayCarb))g", DesignSystem.Colors.amber)
                        macroTag("G \(Int(meal.displayFat))g", DesignSystem.Colors.limeDark)
                        macroTag("\(Int(meal.kcal)) kcal", DesignSystem.Colors.indigo)
                        if !meal.foods.isEmpty {
                            macroTag("\(meal.foods.count) alimenti", DesignSystem.Colors.indigo.opacity(0.7))
                        }
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
    @State private var catalog: [FoodCatalogDTO] = []
    @State private var showingFoodSearch = false
    let catalogService: CatalogService
    let onSave: (SavedMeal) -> Void

    init(meal: SavedMeal, catalogService: CatalogService, onSave: @escaping (SavedMeal) -> Void) {
        _meal = State(initialValue: meal)
        self.catalogService = catalogService
        self.onSave = onSave
    }

    var totalKcal: Double { meal.foods.reduce(0) { $0 + $1.kcal } }
    var totalProtein: Double { meal.foods.reduce(0) { $0 + $1.proteinGrams } }
    var totalCarb: Double { meal.foods.reduce(0) { $0 + $1.carbGrams } }
    var totalFat: Double { meal.foods.reduce(0) { $0 + $1.fatGrams } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FitInputField(label: "Nome pasto", text: $meal.name)
                    FitInputField(label: "Note (opzionale)", text: $meal.notes)

                    HStack {
                        SectionLabel(text: "Alimenti (\(meal.foods.count))")
                        Spacer()
                        Button { showingFoodSearch = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Aggiungi")
                            }
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.teal)
                        }
                        .buttonStyle(.plain)
                    }

                    if meal.foods.isEmpty {
                        FitCard {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                Text("Cerca alimenti dal catalogo con il tasto +")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(meal.foods) { food in
                                foodRow(food)
                            }
                        }
                        FitCard {
                            VStack(spacing: 10) {
                                HStack {
                                    FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 30)
                                    Text("Totale")
                                        .font(DesignSystem.Typography.labelMD())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    Spacer()
                                    Text("\(Int(totalKcal)) kcal")
                                        .font(.custom("Archivo-ExtraBold", size: 18))
                                        .foregroundStyle(DesignSystem.Colors.teal)
                                }
                                HStack(spacing: 8) {
                                    macroTag("P \(String(format: "%.1f", totalProtein))g", DesignSystem.Colors.teal)
                                    macroTag("C \(String(format: "%.1f", totalCarb))g", DesignSystem.Colors.amber)
                                    macroTag("G \(String(format: "%.1f", totalFat))g", DesignSystem.Colors.limeDark)
                                    Spacer()
                                }
                            }
                        }
                    }

                    AccentButton(title: "Salva pasto", color: DesignSystem.Colors.teal) {
                        meal.proteinGrams = totalProtein
                        meal.carbGrams = totalCarb
                        meal.fatGrams = totalFat
                        onSave(meal)
                        dismiss()
                    }
                    .disabled(meal.name.isEmpty || meal.foods.isEmpty)
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
        .sheet(isPresented: $showingFoodSearch) {
            SavedMealFoodSearchSheet(catalog: catalog) { food in
                meal.foods.append(food)
            }
        }
        .task {
            if catalog.isEmpty {
                catalog = await catalogService.fetchFoodCatalog()
            }
        }
    }

    private func foodRow(_ food: SavedMealFood) -> some View {
        FitCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.custom("Archivo-SemiBold", size: 14))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    HStack(spacing: 6) {
                        Text("\(Int(food.quantityGrams))g")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        macroTag("P \(String(format: "%.1f", food.proteinGrams))g", DesignSystem.Colors.teal)
                        macroTag("C \(String(format: "%.1f", food.carbGrams))g", DesignSystem.Colors.amber)
                        macroTag("\(Int(food.kcal)) kcal", DesignSystem.Colors.indigo)
                    }
                }
                Spacer()
                Button {
                    meal.foods.removeAll { $0.id == food.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
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
}

private struct SavedMealFoodSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFood: FoodCatalogDTO?
    @State private var quantityGrams: Double = 100
    let catalog: [FoodCatalogDTO]
    let onAdd: (SavedMealFood) -> Void

    var filtered: [FoodCatalogDTO] {
        searchText.isEmpty ? catalog :
            catalog.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
    }

    var computedKcal: Double {
        guard let f = selectedFood, let kcal = f.caloriesPer100g else { return 0 }
        return Double(kcal) * quantityGrams / 100
    }

    var body: some View {
        NavigationStack {
            Group {
                if let food = selectedFood {
                    ScrollView {
                        VStack(spacing: 16) {
                            FitCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(food.name)
                                        .font(.custom("Archivo-ExtraBold", size: 18))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    Text(food.category)
                                        .font(DesignSystem.Typography.bodySM())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    if let kcal = food.caloriesPer100g {
                                        Text("\(kcal) kcal / 100g")
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(DesignSystem.Colors.teal)
                                    }
                                }
                            }
                            FitCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Quantità")
                                            .font(DesignSystem.Typography.labelMD())
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                        Spacer()
                                        Stepper(value: $quantityGrams, in: 5...2000, step: 5) {
                                            Text("\(Int(quantityGrams)) g")
                                                .font(.custom("Archivo-ExtraBold", size: 16))
                                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                        }
                                    }
                                    Divider()
                                    HStack {
                                        FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 28)
                                        Text("Calorie")
                                            .font(DesignSystem.Typography.labelMD())
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                        Spacer()
                                        Text("\(Int(computedKcal)) kcal")
                                            .font(.custom("Archivo-ExtraBold", size: 17))
                                            .foregroundStyle(DesignSystem.Colors.teal)
                                    }
                                }
                            }
                            AccentButton(title: "Aggiungi alimento", color: DesignSystem.Colors.teal) {
                                let smf = SavedMealFood(
                                    id: UUID(),
                                    foodCatalogID: food.id,
                                    name: food.name,
                                    quantityGrams: quantityGrams,
                                    caloriesPer100g: Double(food.caloriesPer100g ?? 0),
                                    proteinPer100g: food.proteinsPer100g ?? 0,
                                    carbPer100g: food.carbsPer100g ?? 0,
                                    fatPer100g: food.fatsPer100g ?? 0
                                )
                                onAdd(smf)
                                dismiss()
                            }
                            Button("Scegli altro alimento") { selectedFood = nil; quantityGrams = 100 }
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 0) {
                        SearchBarView(text: $searchText, placeholder: "Cerca alimento...")
                            .padding([.horizontal, .top], 16)
                        if catalog.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Caricamento catalogo...")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if filtered.isEmpty {
                            EmptyStateView(title: "Nessun risultato", message: "Prova con un termine diverso.", icon: "magnifyingglass")
                                .padding(20)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(filtered) { item in
                                        Button { selectedFood = item; quantityGrams = 100 } label: {
                                            FitCard {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(item.name)
                                                            .font(.custom("Archivo-SemiBold", size: 14))
                                                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                                        Text(item.category)
                                                            .font(DesignSystem.Typography.labelSM())
                                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                                    }
                                                    Spacer()
                                                    if let kcal = item.caloriesPer100g {
                                                        Text("\(kcal) kcal/100g")
                                                            .font(DesignSystem.Typography.labelSM())
                                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                                    }
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(selectedFood != nil ? "Quantità" : "Cerca alimento")
                        .font(.custom("Archivo-Bold", size: 16))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                }
            }
            .appScreen()
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
