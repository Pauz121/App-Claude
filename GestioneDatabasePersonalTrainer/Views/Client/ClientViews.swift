import SwiftUI

struct ClientMainTabView: View {
    @EnvironmentObject private var services: AppServices
    let client: Client

    var body: some View {
        TabView {
            ClientDashboardView(client: client, services: services)
                .tabItem { Label("Home", systemImage: "house") }

            ClientProfileView(client: client, services: services)
                .tabItem { Label("Profilo", systemImage: "person.crop.circle") }

            ClientWorkoutView(client: client, services: services)
                .tabItem { Label("Scheda", systemImage: "figure.run") }

            ClientNutritionView(client: client, services: services)
                .tabItem { Label("Dieta", systemImage: "fork.knife") }

            ClientProgressView(client: client, services: services)
                .tabItem { Label("Progressi", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}

struct ClientDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ClientDashboardViewModel
    @State private var showingAddProgress = false
    @State private var showingCheckIn = false
    let client: Client
    let services: AppServices

    init(client: Client, services: AppServices) {
        self.client = client
        self.services = services
        _viewModel = StateObject(wrappedValue: ClientDashboardViewModel(client: client, services: services))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    todayHeader

                    if viewModel.healthKitState != .authorized || viewModel.todaySteps == nil {
                        HealthPermissionView(state: viewModel.healthKitState) {
                            viewModel.requestHealthKitAccessAndRefresh()
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.dangerRed)
                    }

                    StepsSummaryCard(
                        summary: viewModel.todaySteps,
                        motivation: viewModel.stepMotivationText,
                        isLoading: viewModel.isLoading
                    ) {
                        if viewModel.healthKitState == .authorized {
                            Task<Void, Never>(priority: nil) { await viewModel.refreshStepsFromHealthKit() }
                        } else {
                            viewModel.requestHealthKitAccessAndRefresh()
                        }
                    }

                    DailyGoalsView(goals: viewModel.todayGoals, onTapGoal: handleGoalTap)

                    checkInSection

                    StreakCard(streak: viewModel.checkInStreak ?? viewModel.stepsStreak, fallbackTitle: "Costanza")

                    todayPlanSection

                    progressSection
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Oggi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authViewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showingAddProgress) {
                AddProgressEntryView(client: client) { weight, waist, chest, arm, leg, notes in
                    let entry = ProgressEntry(
                        id: UUID(),
                        clientID: client.id,
                        date: Date(),
                        weightKg: weight,
                        waistCm: waist,
                        chestCm: chest,
                        armCm: arm,
                        legCm: leg,
                        frontPhotoName: nil,
                        sidePhotoName: nil,
                        backPhotoName: nil,
                        notes: notes
                    )
                    Task<Void, Never>(priority: nil) {
                        _ = await services.progressService.addProgressEntry(entry)
                        viewModel.load()
                    }
                }
            }
            .sheet(isPresented: $showingCheckIn) {
                DailyCheckInSheet(client: client, existing: viewModel.todayCheckIn, services: services) { saved in
                    viewModel.didSaveCheckIn(saved)
                }
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }

    private var todayHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Ciao \(client.firstName)")
                .font(AppTypography.hero)
                .foregroundStyle(AppColors.textPrimary)
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
            Text("Oggi concentriamoci su movimento e costanza.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
        .padding(.top, AppSpacing.sm)
    }

    private var checkInSection: some View {
        SectionCard(title: "Check-in", icon: "checklist") {
            if let checkIn = viewModel.todayCheckIn {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                    MetricMiniCard(title: "Energia", value: "\(checkIn.energyLevel)/5", icon: "bolt.fill", color: AppColors.energyOrange)
                    MetricMiniCard(title: "Sonno", value: "\(checkIn.sleepQuality)/5", icon: "moon.fill", color: AppColors.infoBlue)
                    MetricMiniCard(title: "Dieta", value: checkIn.dietAdherence.label, icon: "leaf", color: AppColors.successGreen)
                    MetricMiniCard(title: "Allenamento", value: checkIn.workoutCompleted ? "Fatto" : "No", icon: "figure.run", color: checkIn.workoutCompleted ? AppColors.successGreen : AppColors.warningYellow)
                }
                SecondaryButton(title: "Modifica check-in", systemImage: "pencil") {
                    showingCheckIn = true
                }
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Completa il check-in di oggi")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Servono meno di due minuti per aggiornare trainer e percorso.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    PrimaryButton(title: "Compila ora", systemImage: "checkmark.circle") {
                        showingCheckIn = true
                    }
                }
            }
        }
    }

    private var todayPlanSection: some View {
        SectionCard(title: "Allenamento e piano", icon: "calendar.badge.clock") {
            VStack(spacing: AppSpacing.md) {
                if let appointment = viewModel.nextAppointment {
                    AppointmentRowView(appointment: appointment, client: client)
                } else {
                    Text("Nessun appuntamento programmato.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                    MetricMiniCard(title: "Scheda attiva", value: viewModel.activeWorkoutPlan?.name ?? "Non assegnata", icon: "figure.run", color: AppColors.primaryBlack)
                    MetricMiniCard(title: "Dieta", value: viewModel.activeNutritionPlan.map { "\($0.dailyCalories) kcal" } ?? "Non assegnata", icon: "fork.knife", color: AppColors.nutritionYellow)
                }

                HStack(spacing: AppSpacing.sm) {
                    NavigationLink {
                        ClientWorkoutView(client: client, services: services)
                    } label: {
                        Label("Scheda", systemImage: "figure.run")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    NavigationLink {
                        ClientNutritionView(client: client, services: services)
                    } label: {
                        Label("Dieta", systemImage: "fork.knife")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private var progressSection: some View {
        SectionCard(title: "Progressi", icon: "chart.line.uptrend.xyaxis") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                MetricMiniCard(title: "Peso attuale", value: String(format: "%.1f kg", client.currentWeightKg), icon: "scalemass", color: AppColors.successGreen)
                MetricMiniCard(title: "Media passi", value: "\(Int(viewModel.weeklyAverageSteps))", icon: "chart.bar", color: AppColors.infoBlue)
            }
            SecondaryButton(title: "Aggiungi peso o foto", systemImage: "plus.circle") {
                showingAddProgress = true
            }
        }
    }

    private func handleGoalTap(_ goal: DailyGoal) {
        switch goal.goalType {
        case .checkIn:
            showingCheckIn = true
        case .weight, .progressPhoto:
            showingAddProgress = true
        case .steps:
            if viewModel.healthKitState == .authorized {
                Task<Void, Never>(priority: nil) { await viewModel.refreshStepsFromHealthKit() }
            } else {
                viewModel.requestHealthKitAccessAndRefresh()
            }
        case .workout:
            break
        }
    }
}

struct ClientProfileView: View {
    @StateObject private var progressViewModel: ClientProgressViewModel
    let client: Client

    init(client: Client, services: AppServices) {
        self.client = client
        _progressViewModel = StateObject(wrappedValue: ClientProgressViewModel(client: client, service: services.progressService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionCard(title: client.fullName, icon: "person.crop.circle") {
                        ClientInfoLine(label: "Email", value: client.email)
                        ClientInfoLine(label: "Altezza", value: String(format: "%.0f cm", client.heightCm))
                        ClientInfoLine(label: "Peso iniziale", value: String(format: "%.1f kg", client.initialWeightKg))
                        ClientInfoLine(label: "Peso attuale", value: String(format: "%.1f kg", client.currentWeightKg))
                        ClientInfoLine(label: "Obiettivo", value: client.goal)
                    }

                    SectionCard(title: "Storico progressi", icon: "chart.xyaxis.line") {
                        if progressViewModel.entries.isEmpty {
                            Text("Nessun progresso registrato.")
                                .foregroundStyle(AppColors.textSecondary)
                        } else {
                            ForEach(progressViewModel.entries) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(entry.date.formattedDay())
                                            .font(.headline)
                                        Text(entry.notes)
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Text("\(entry.weightKg, specifier: "%.1f") kg")
                                        .font(.subheadline.weight(.semibold))
                                }
                                Divider().background(AppColors.divider)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Profilo")
            .appScreen()
            .task { progressViewModel.load() }
        }
    }
}

private struct ClientInfoLine: View {
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

struct ClientWorkoutView: View {
    @StateObject private var viewModel: ClientWorkoutViewModel

    init(client: Client, services: AppServices) {
        _viewModel = StateObject(wrappedValue: ClientWorkoutViewModel(client: client, service: services.workoutService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if let plan = viewModel.activePlan {
                        SectionCard(title: plan.name, icon: "list.clipboard") {
                            Text(plan.goal)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                            Text("\(plan.startDate.formattedDay()) - \(plan.endDate.formattedDay())")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        ForEach(plan.days) { day in
                            NavigationLink {
                                ClientWorkoutDetailView(day: day, isCompleted: viewModel.completedWorkoutDayIDs.contains(day.id)) {
                                    viewModel.toggleCompletion(for: day)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Giorno \(day.dayIndex)")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.accent)
                                        Text(day.title)
                                            .font(.headline)
                                            .foregroundStyle(AppColors.textPrimary)
                                        Text("\(day.exercises.count) esercizi")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: viewModel.completedWorkoutDayIDs.contains(day.id) ? "checkmark.circle.fill" : "chevron.right")
                                        .foregroundStyle(viewModel.completedWorkoutDayIDs.contains(day.id) ? AppColors.success : AppColors.textSecondary)
                                }
                                .appCard()
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        EmptyStateView(title: "Nessuna scheda attiva", message: "Il trainer non ha ancora pubblicato una scheda.", icon: "figure.run")
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Scheda")
            .appScreen()
            .task { viewModel.load() }
        }
    }
}

struct ClientWorkoutDetailView: View {
    let day: WorkoutDay
    let isCompleted: Bool
    let onToggleCompleted: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SectionCard(title: day.title, icon: "figure.run") {
                    Text("Giorno \(day.dayIndex)")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    PrimaryButton(title: isCompleted ? "Segna come da completare" : "Segna completato", systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark.circle") {
                        onToggleCompleted()
                    }
                }

                SectionCard(title: "Esercizi", icon: "dumbbell") {
                    ForEach(day.exercises.sorted { $0.order < $1.order }) { exercise in
                        WorkoutExerciseRow(exercise: exercise)
                        Divider().background(AppColors.divider)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Allenamento")
        .appScreen()
    }
}

struct ClientNutritionView: View {
    @StateObject private var viewModel: ClientNutritionViewModel

    init(client: Client, services: AppServices) {
        _viewModel = StateObject(wrappedValue: ClientNutritionViewModel(client: client, service: services.nutritionService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if let plan = viewModel.activePlan {
                        SectionCard(title: "Piano attivo", icon: "fork.knife") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                                MacroNutrientCard(title: "Calorie", value: "\(plan.dailyCalories)", color: AppColors.accent)
                                MacroNutrientCard(title: "Proteine", value: "\(plan.proteinGrams) g", color: AppColors.success)
                                MacroNutrientCard(title: "Carboidrati", value: "\(plan.carbohydrateGrams) g", color: AppColors.violet)
                                MacroNutrientCard(title: "Grassi", value: "\(plan.fatGrams) g", color: AppColors.warning)
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
                    } else {
                        EmptyStateView(title: "Nessun piano attivo", message: "Il trainer non ha ancora pubblicato un piano alimentare.", icon: "fork.knife")
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Nutrizione")
            .appScreen()
            .task { viewModel.load() }
        }
    }
}

struct ClientProgressView: View {
    @StateObject private var viewModel: ClientProgressViewModel
    @State private var showingAdd = false
    let client: Client

    init(client: Client, services: AppServices) {
        self.client = client
        _viewModel = StateObject(wrappedValue: ClientProgressViewModel(client: client, service: services.progressService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if viewModel.entries.isEmpty {
                        EmptyStateView(title: "Nessun progresso", message: "Registra peso, misure e foto per monitorare il percorso.", icon: "camera.metering.matrix")
                    } else {
                        ForEach(viewModel.entries) { entry in
                            SectionCard(title: entry.date.formattedDay(), icon: "chart.line.uptrend.xyaxis") {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                                    MacroNutrientCard(title: "Peso", value: String(format: "%.1f kg", entry.weightKg), color: AppColors.success)
                                    MacroNutrientCard(title: "Vita", value: String(format: "%.0f cm", entry.waistCm), color: AppColors.accent)
                                    MacroNutrientCard(title: "Petto", value: String(format: "%.0f cm", entry.chestCm), color: AppColors.violet)
                                    MacroNutrientCard(title: "Gamba", value: String(format: "%.0f cm", entry.legCm), color: AppColors.warning)
                                }
                                HStack(spacing: AppSpacing.md) {
                                    ProgressPhotoCard(title: "Fronte", photoName: entry.frontPhotoName)
                                    ProgressPhotoCard(title: "Lato", photoName: entry.sidePhotoName)
                                    ProgressPhotoCard(title: "Retro", photoName: entry.backPhotoName)
                                }
                                Text(entry.notes)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Progressi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddProgressEntryView(client: client, onSave: viewModel.addEntry)
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }
}

struct AddProgressEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double
    @State private var waist = 72.0
    @State private var chest = 90.0
    @State private var arm = 30.0
    @State private var leg = 53.0
    @State private var notes = ""
    let onSave: (Double, Double, Double, Double, Double, String) -> Void

    init(client: Client, onSave: @escaping (Double, Double, Double, Double, Double, String) -> Void) {
        _weight = State(initialValue: client.currentWeightKg)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Misure") {
                    TextField("Peso", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Vita", value: $waist, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Petto", value: $chest, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Braccio", value: $arm, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Gamba", value: $leg, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Foto") {
                    Label("Upload foto predisposto per cloud storage futuro", systemImage: "photo.badge.plus")
                }

                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nuovo progresso")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        onSave(weight, waist, chest, arm, leg, notes)
                        dismiss()
                    }
                }
            }
        }
    }
}
