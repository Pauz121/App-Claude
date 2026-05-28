import SwiftUI
import Charts
import PhotosUI

struct ClientMainTabView: View {
    @EnvironmentObject private var services: AppServices
    let client: Client

    var body: some View {
        TabView {
            ClientDashboardView(client: client, services: services)
                .tabItem { Label("Oggi", systemImage: "house.fill") }

            ClientWorkoutView(client: client, services: services)
                .tabItem { Label("Scheda", systemImage: "dumbbell.fill") }

            ClientNutritionView(client: client, services: services)
                .tabItem { Label("Dieta", systemImage: "fork.knife") }

            ClientProgressView(client: client, services: services)
                .tabItem { Label("Progressi", systemImage: "chart.xyaxis.line") }

            ClientChatView(client: client)
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }
        }
        .tint(DesignSystem.Colors.limeDark)
    }
}

struct ClientDashboardView: View {
    @StateObject private var viewModel: ClientDashboardViewModel
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
                VStack(alignment: .leading, spacing: 18) {
                    header
                    weeklyProgressCard

                    SectionLabel(text: "Oggi")
                    todayWorkoutCard

                    HStack(spacing: 12) {
                        miniMetric(icon: "flame.fill", color: DesignSystem.Colors.teal, value: viewModel.activeNutritionPlan.map { "\($0.dailyCalories)" } ?? "--", subtitle: "kcal di oggi")
                        stepsMiniCard
                    }

                    SectionLabel(text: "Dal tuo coach")
                    checkInCard
                    paymentsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingCheckIn) {
                DailyCheckInSheet(client: client, existing: viewModel.todayCheckIn, services: services) { saved in
                    viewModel.didSaveCheckIn(saved)
                }
            }
            .appScreen()
            .task { viewModel.load() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(weekday.uppercased()) · SETTIMANA \(weekNumber)")
                    .font(DesignSystem.Typography.sectionLabel())
                    .tracking(1.8)
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                Text("Ciao, \(client.firstName)")
                    .font(DesignSystem.Typography.titleXL())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
            }
            Spacer()
            NavigationLink {
                ClientProfileView(client: client, services: services)
            } label: {
                AvatarView(initials: initials, gradient: [DesignSystem.Colors.lime, DesignSystem.Colors.teal], size: 42)
            }
            .buttonStyle(.plain)
        }
    }

    private var weeklyProgressCard: some View {
        let total = max(viewModel.activeWorkoutPlan?.days.count ?? 3, 1)
        let completed = min(total, viewModel.todayGoals.filter(\.isCompleted).count)
        let progress = Double(completed) / Double(total)

        return FitCard {
            HStack(spacing: 18) {
                FitProgressRing(
                    progress: progress,
                    color: DesignSystem.Colors.lime,
                    lineWidth: 12,
                    content: AnyView(
                        VStack(spacing: 1) {
                            Text("\(completed)/\(total)")
                                .font(.custom("Archivo-Black", size: 20))
                                .foregroundStyle(DesignSystem.Colors.limeDark)
                            Text("sessioni")
                                .font(.custom("Sora-Regular", size: 10))
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    )
                )
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Obiettivo settimanale")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("\(completed) di \(total) sessioni")
                        .font(.custom("Archivo-ExtraBold", size: 18))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    streakPill
                }
                Spacer()
            }
        }
    }

    private var todayWorkoutCard: some View {
        let day = viewModel.activeWorkoutPlan?.days.sorted { $0.dayIndex < $1.dayIndex }.first
        let exerciseCount = day?.exercises.count ?? 0

        return FitCard(background: DesignSystem.Colors.limeBg, border: Color(hex: "DDE7C2")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(day?.title.uppercased() ?? "ALLENAMENTO")
                    .font(DesignSystem.Typography.labelSM())
                    .tracking(1.1)
                    .foregroundStyle(DesignSystem.Colors.limeDark)
                Text(day?.title ?? "Allenamento di oggi")
                    .font(.custom("Archivo-Black", size: 24))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text("\(exerciseCount) esercizi · ~\(max(exerciseCount * 8, 25)) min")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                NavigationLink {
                    ClientWorkoutView(client: client, services: services)
                } label: {
                    Text("Inizia allenamento ->")
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DesignSystem.Colors.limeDark)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func miniMetric(icon: String, color: Color, value: String, subtitle: String) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 9) {
                FitIconChip(systemName: icon, color: color, background: color.opacity(0.12), size: 32)
                Text(value)
                    .font(.custom("Archivo-ExtraBold", size: 22))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var stepsMiniCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: 9) {
                FitIconChip(systemName: "shoeprints.fill", color: DesignSystem.Colors.limeDark, background: DesignSystem.Colors.limeBg, size: 32)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(viewModel.todaySteps?.steps ?? 0)")
                        .font(.custom("Archivo-ExtraBold", size: 22))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    TrendBadge(value: "+10%")
                }
                Text("passi vs ieri")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var checkInCard: some View {
        Button { showingCheckIn = true } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(DesignSystem.Colors.limeDark)
                    .frame(width: 9, height: 9)
                    .shadow(color: DesignSystem.Colors.limeDark.opacity(0.45), radius: 7)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check settimanale")
                        .font(.custom("Archivo-ExtraBold", size: 14))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text("5 domande · scade domenica")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.limeDark)
            }
            .padding(16)
            .background(DesignSystem.Colors.limeBg)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DesignSystem.Colors.lime, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            )
        }
        .buttonStyle(.plain)
    }

    private var streakPill: some View {
        Text("🔥 \(viewModel.checkInStreak?.currentCount ?? 0) giorni di fila")
            .font(DesignSystem.Typography.labelSM())
            .foregroundStyle(DesignSystem.Colors.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DesignSystem.Colors.amberBg)
            .clipShape(Capsule())
    }

    private var paymentsCard: some View {
        NavigationLink {
            ClientPaymentsView(client: client, services: services)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(DesignSystem.Colors.indigo)
                    .frame(width: 9, height: 9)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Piano pagamenti")
                        .font(.custom("Archivo-ExtraBold", size: 14))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text("Visualizza e gestisci i tuoi pagamenti")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.indigo)
            }
            .padding(16)
            .background(DesignSystem.Colors.indigoBg)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DesignSystem.Colors.indigo.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        "\(client.firstName.first.map(String.init) ?? "")\(client.lastName.first.map(String.init) ?? "")"
    }

    private var weekday: String {
        Date().formatted(.dateTime.weekday(.wide))
    }

    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }
}

struct ClientWorkoutView: View {
    @StateObject private var viewModel: ClientWorkoutViewModel
    @State private var expandedWeek: Int? = 1
    let client: Client
    let services: AppServices

    init(client: Client, services: AppServices) {
        self.client = client
        self.services = services
        _viewModel = StateObject(wrappedValue: ClientWorkoutViewModel(client: client, service: services.workoutService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("LE TUE SCHEDE")
                        .font(DesignSystem.Typography.sectionLabel())
                        .tracking(1.8)
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("I tuoi allenamenti")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    if let plan = viewModel.activePlan {
                        LazyVStack(spacing: 16) {
                            ForEach(weekGroups(for: plan), id: \.week) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            expandedWeek = expandedWeek == group.week ? nil : group.week
                                        }
                                    } label: {
                                        HStack {
                                            Text("SETTIMANA \(group.week)")
                                                .font(DesignSystem.Typography.sectionLabel())
                                                .tracking(1.8)
                                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .rotationEffect(.degrees(expandedWeek == group.week ? 90 : 0))
                                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                                .font(.caption.weight(.bold))
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    if expandedWeek == group.week {
                                        VStack(spacing: 10) {
                                            ForEach(group.days) { day in
                                                ClientWorkoutDayCard(
                                                    client: client,
                                                    services: services,
                                                    day: day,
                                                    isCompleted: viewModel.completedWorkoutDayIDs.contains(day.id)
                                                ) {
                                                    viewModel.toggleCompletion(for: day)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        EmptyStateView(title: "Nessuna scheda attiva", message: "Il trainer non ha ancora pubblicato una scheda.", icon: "dumbbell")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .appScreen()
            .task { viewModel.load() }
        }
    }

    private func weekGroups(for plan: WorkoutPlan) -> [(week: Int, days: [WorkoutDay])] {
        let sorted = plan.days.sorted { $0.dayIndex < $1.dayIndex }
        guard !sorted.isEmpty else { return [] }
        let daysBetween = Calendar.current.dateComponents([.day], from: plan.startDate, to: plan.endDate).day ?? 28
        let totalWeeks = max(1, Int(ceil(Double(daysBetween) / 7.0)))
        let daysPerWeek = max(1, Int(ceil(Double(sorted.count) / Double(totalWeeks))))
        var groups: [Int: [WorkoutDay]] = [:]
        for day in sorted {
            let week = (day.dayIndex - 1) / daysPerWeek + 1
            groups[week, default: []].append(day)
        }
        return groups.sorted { $0.key < $1.key }.map { (week: $0.key, days: $0.value) }
    }
}

private struct ClientWorkoutDayCard: View {
    let client: Client
    let services: AppServices
    let day: WorkoutDay
    let isCompleted: Bool
    let onToggleCompleted: () -> Void

    var body: some View {
        if isRestDay {
            content
                .opacity(0.6)
        } else if isCompleted {
            FitCard(background: DesignSystem.Colors.limeBg, border: Color(hex: "DDE7C2")) {
                content
            }
        } else {
            NavigationLink {
                ClientWorkoutDetailView(client: client, services: services, day: day, isCompleted: isCompleted, onToggleCompleted: onToggleCompleted)
            } label: {
                FitCard { content }
            }
            .buttonStyle(.plain)
        }
    }

    private var content: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(chipColor)
                Text(chipText)
                    .font(.custom("Archivo-Black", size: 15))
                    .foregroundStyle(chipForeground)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(isRestDay ? "Riposo" : day.title)
                    .font(.custom("Archivo-ExtraBold", size: 15))
                    .foregroundStyle(isCompleted || isRestDay ? DesignSystem.Colors.txtSecondary : DesignSystem.Colors.txtPrimary)
                Text("\(day.exercises.count) esercizi · ~\(max(day.exercises.count * 8, 25)) min")
                    .font(DesignSystem.Typography.bodySM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
            Spacer()
            if isCompleted {
                Text("Completato")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.limeDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.lime.opacity(0.18))
                    .clipShape(Capsule())
            } else if !isRestDay {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var isRestDay: Bool {
        day.exercises.isEmpty
    }

    private var chipText: String {
        if isCompleted { return "✓" }
        if isRestDay { return "." }
        return "\(day.dayIndex)"
    }

    private var chipColor: Color {
        if isCompleted { return DesignSystem.Colors.lime }
        if isRestDay { return DesignSystem.Colors.bgLine }
        return DesignSystem.Colors.lime
    }

    private var chipForeground: Color {
        isRestDay ? DesignSystem.Colors.txtSecondary : .white
    }
}

struct ClientWorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client
    let services: AppServices
    let day: WorkoutDay
    let isCompleted: Bool
    let onToggleCompleted: () -> Void

    @State private var completedExerciseIDs: Set<UUID> = []
    @State private var editingWeight: Exercise?
    @State private var showingNotes: Exercise?
    @State private var showCompletionOverlay = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("SETTIMANA 1 DI 1")
                            .font(DesignSystem.Typography.sectionLabel())
                            .tracking(1.8)
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        Spacer()
                        Text("\(completedCount)/\(totalCount)")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                    }

                    Text(day.title)
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    HStack(spacing: 10) {
                        stat("Esercizi", "\(totalCount)", DesignSystem.Colors.indigo)
                        stat("Minuti", "\(max(totalCount * 8, 25))", DesignSystem.Colors.amber)
                        stat("Fatti", "\(completedCount)/\(totalCount)", DesignSystem.Colors.limeDark)
                    }

                    SectionLabel(text: "Esercizi")

                    LazyVStack(spacing: 12) {
                        ForEach(day.exercises.sorted { $0.order < $1.order }) { exercise in
                            ClientExerciseCard(
                                exercise: exercise,
                                index: exercise.order,
                                state: state(for: exercise),
                                onComplete: { complete(exercise) },
                                onWeight: { editingWeight = exercise },
                                onNotes: { showingNotes = exercise }
                            )
                        }
                    }
                }
                .padding(20)
            }

            if showCompletionOverlay {
                WorkoutCompletionOverlay(exerciseCount: totalCount, minutes: max(totalCount * 8, 25)) {
                    onToggleCompleted()
                    dismiss()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingWeight) { exercise in
            WeightEditSheet(exercise: exercise) { newWeight in
                Task {
                    await services.workoutService.addExerciseWeightHistory(
                        trainerID: client.trainerID,
                        clientID: client.id,
                        exerciseID: exercise.id,
                        weightKg: newWeight,
                        effectiveFromSessionID: nil
                    )
                }
            }
                .presentationDetents([.medium])
        }
        .sheet(item: $showingNotes) { exercise in
            ExerciseNotesSheet(exercise: exercise)
                .presentationDetents([.medium])
        }
        .appScreen()
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.custom("Archivo-Black", size: 21))
                    .foregroundStyle(color)
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var totalCount: Int { day.exercises.count }
    private var completedCount: Int { completedExerciseIDs.count }

    private func state(for exercise: Exercise) -> ClientExerciseCard.State {
        if completedExerciseIDs.contains(exercise.id) { return .completed }
        let sorted = day.exercises.sorted { $0.order < $1.order }
        let firstOpen = sorted.first { !completedExerciseIDs.contains($0.id) }
        return firstOpen?.id == exercise.id ? .current : .future
    }

    private func complete(_ exercise: Exercise) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            completedExerciseIDs.insert(exercise.id)
            showCompletionOverlay = completedExerciseIDs.count == totalCount && totalCount > 0
        }
    }
}

private struct ClientExerciseCard: View {
    enum State {
        case completed
        case current
        case future
    }

    let exercise: Exercise
    let index: Int
    let state: State
    let onComplete: () -> Void
    let onWeight: () -> Void
    let onNotes: () -> Void

    var body: some View {
        FitCard(border: border, lineWidth: state == .current ? 2 : 1) {
            HStack(alignment: .center, spacing: 12) {
                Text(state == .completed ? "✓" : "\(index)")
                    .font(.custom("Archivo-Black", size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(state == .completed ? DesignSystem.Colors.lime.opacity(0.55) : DesignSystem.Colors.limeDark)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Button(action: onNotes) {
                        Text(exercise.name)
                            .font(.custom("Archivo-ExtraBold", size: 15))
                            .foregroundStyle(state == .completed ? DesignSystem.Colors.txtSecondary : DesignSystem.Colors.txtPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        Text("\(exercise.sets) x \(exercise.reps) ·")
                        Button(action: onWeight) {
                            HStack(spacing: 3) {
                                Text(exercise.recommendedLoad)
                                Image(systemName: "pencil")
                            }
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                        }
                        .buttonStyle(.plain)
                        Text("· rec \(exercise.restSeconds)s")
                    }
                    .font(DesignSystem.Typography.bodySM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }

                if state == .current {
                    Button(action: onComplete) {
                        Image(systemName: "play.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            .frame(width: 42, height: 34)
                            .background(Color(hex: "EEF1F4"))
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .opacity(state == .completed ? 0.55 : 1)
        .shadow(color: state == .current ? DesignSystem.Colors.lime.opacity(0.16) : .clear, radius: 12, x: 0, y: 6)
    }

    private var border: Color {
        state == .current ? DesignSystem.Colors.lime : DesignSystem.Colors.bgLine
    }
}

private struct WeightEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let onSave: (Double) -> Void
    @State private var weight: Double = 30

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(DesignSystem.Colors.bgLine)
                .frame(width: 46, height: 5)
            Text(exercise.name)
                .font(DesignSystem.Typography.titleMD())
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
            HStack(spacing: 22) {
                stepButton("-") { weight = max(0, weight - 1.25) }
                Text(String(format: "%.2f kg", weight))
                    .font(.custom("Archivo-Black", size: 36))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton("+") { weight += 1.25 }
            }
            Text("La modifica si applica da questo allenamento in poi. Le sessioni precedenti non vengono modificate.")
                .font(DesignSystem.Typography.bodySM())
                .italic()
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                .multilineTextAlignment(.center)
            AccentButton(title: "Salva", color: DesignSystem.Colors.limeDark) {
                onSave(weight)
                dismiss()
            }
            Button("Annulla") { dismiss() }
                .font(DesignSystem.Typography.labelMD())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
        }
        .padding(24)
        .appScreen()
        .onAppear {
            weight = Double(exercise.recommendedLoad.filter { "0123456789.,".contains($0) }.replacingOccurrences(of: ",", with: ".")) ?? 30
        }
    }

    private func stepButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Archivo-Black", size: 26))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(DesignSystem.Colors.limeDark)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(DesignSystem.Colors.bgLine)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
            Text(exercise.name)
                .font(DesignSystem.Typography.titleMD())
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
            Text("\(exercise.sets) x \(exercise.reps) · \(exercise.recommendedLoad) · rec \(exercise.restSeconds)s")
                .font(DesignSystem.Typography.labelMD())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
            if !exercise.technicalNotes.isEmpty {
                SectionLabel(text: "Note del coach")
                HStack(alignment: .top, spacing: 10) {
                    AvatarView(initials: "MC", gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.teal], size: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marco")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(exercise.technicalNotes)
                            .font(DesignSystem.Typography.bodyMD())
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .appScreen()
    }
}

private struct WorkoutCompletionOverlay: View {
    let exerciseCount: Int
    let minutes: Int
    let onHome: () -> Void
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 18) {
                Circle()
                    .fill(DesignSystem.Colors.limeBg)
                    .frame(width: 110, height: 110)
                    .scaleEffect(animate ? 1.08 : 0.76)
                    .opacity(animate ? 1 : 0.6)
                    .overlay(Text("🎉").font(.system(size: 52)))
                Text("Allenamento completato! 💪")
                    .font(.custom("Archivo-Black", size: 30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("\(exerciseCount) esercizi · \(minutes) min")
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DesignSystem.Colors.bgCard)
                    .clipShape(Capsule())
                Text("3 giorni di fila!")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.amber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.amberBg)
                    .clipShape(Capsule())
                PrimaryButton(title: "Torna alla home", action: onHome)
                Button("Vedi riepilogo") {}
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62).repeatCount(2, autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct ClientNutritionView: View {
    @StateObject private var viewModel: ClientNutritionViewModel
    @State private var path: [Int] = []
    let client: Client

    init(client: Client, services: AppServices) {
        self.client = client
        _viewModel = StateObject(wrappedValue: ClientNutritionViewModel(client: client, service: services.nutritionService))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("OBIETTIVO · \(client.goal.isEmpty ? "Percorso" : client.goal)")
                        .font(DesignSystem.Typography.sectionLabel())
                        .tracking(1.8)
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("La tua dieta")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    if let plan = viewModel.activePlan {
                        nutritionSummary(plan)
                        LazyVStack(spacing: 12) {
                            ForEach(days, id: \.offset) { item in
                                NavigationLink(value: item.offset) {
                                    dietDayCard(title: item.title, offset: item.offset, plan: plan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        EmptyStateView(title: "Nessun piano attivo", message: "Il trainer non ha ancora pubblicato un piano alimentare.", icon: "fork.knife")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Dieta")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Int.self) { offset in
                if let plan = viewModel.activePlan {
                    DietDayDetailView(plan: plan, dayOffset: offset)
                }
            }
            .appScreen()
            .task { viewModel.load() }
            .onChange(of: viewModel.activePlan) { _, plan in
                if plan != nil && path.isEmpty { path = [0] }
            }
        }
    }

    private func nutritionSummary(_ plan: NutritionPlan) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Piano settimanale")
                    .font(.custom("Archivo-ExtraBold", size: 16))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text("\(plan.dailyCalories) kcal")
                    .font(.custom("Archivo-ExtraBold", size: 24))
                    .foregroundStyle(DesignSystem.Colors.teal)
                HStack {
                    macro("P", "\(plan.proteinGrams)g", DesignSystem.Colors.teal)
                    macro("C", "\(plan.carbohydrateGrams)g", DesignSystem.Colors.amber)
                    macro("G", "\(plan.fatGrams)g", DesignSystem.Colors.limeDark)
                }
            }
        }
    }

    private func macro(_ label: String, _ value: String, _ color: Color) -> some View {
        Text("\(label): \(value)")
            .font(DesignSystem.Typography.labelSM())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dietDayCard(title: String, offset: Int, plan: NutritionPlan) -> some View {
        let isToday = offset == 0
        let isPast = offset < 0
        return FitCard(background: isPast ? DesignSystem.Colors.limeBg : DesignSystem.Colors.bgCard, border: isToday ? DesignSystem.Colors.teal : (isPast ? DesignSystem.Colors.lime : DesignSystem.Colors.bgLine), lineWidth: isToday ? 2 : 1) {
            HStack(spacing: 12) {
                Text(isPast ? "✓" : "\(offset + 4)")
                    .font(.custom("Archivo-Black", size: 14))
                    .foregroundStyle(isToday || isPast ? .white : DesignSystem.Colors.txtSecondary)
                    .frame(width: 36, height: 36)
                    .background(isToday ? DesignSystem.Colors.teal : (isPast ? DesignSystem.Colors.lime : DesignSystem.Colors.bgLine))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.custom("Archivo-ExtraBold", size: 15))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        if isToday {
                            Text("OGGI")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.tealBg)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(plan.meals.count) pasti")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
                Text(isToday ? "\(plan.dailyCalories) kcal" : "\(plan.dailyCalories) kcal")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(isToday ? DesignSystem.Colors.teal : DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var days: [(offset: Int, title: String)] {
        (-3...3).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            return (offset, date.formatted(.dateTime.weekday(.wide)))
        }
    }
}

private struct DietDayDetailView: View {
    let plan: NutritionPlan
    let dayOffset: Int
    @State private var checkedMealIDs: Set<UUID> = []
    @State private var selectedMeal: Meal?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(format: "OBIETTIVO · %.1f KG", plan.targetWeightKg))
                    .font(DesignSystem.Typography.sectionLabel())
                    .tracking(1.8)
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                Text("La tua dieta")
                    .font(DesignSystem.Typography.titleLG())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)

                calorieRing
                HStack(spacing: 10) {
                    macroCard("Proteine", consumedMacro(plan.proteinGrams), DesignSystem.Colors.teal)
                    macroCard("Carbo", consumedMacro(plan.carbohydrateGrams), DesignSystem.Colors.amber)
                    macroCard("Grassi", consumedMacro(plan.fatGrams), DesignSystem.Colors.limeDark)
                }

                SectionLabel(text: "Pasti di oggi")
                LazyVStack(spacing: 12) {
                    ForEach(plan.meals) { meal in
                        mealCard(meal)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal, kcal: mealKcal)
                .presentationDetents([.fraction(0.72)])
        }
        .appScreen()
    }

    private var calorieRing: some View {
        FitCard {
            HStack(spacing: 18) {
                FitProgressRing(
                    progress: Double(consumedKcal) / Double(max(plan.dailyCalories, 1)),
                    color: DesignSystem.Colors.teal,
                    lineWidth: 12,
                    content: AnyView(
                        VStack(spacing: 1) {
                            Text("\(consumedKcal)")
                                .font(.custom("Archivo-Black", size: 24))
                                .foregroundStyle(DesignSystem.Colors.teal)
                            Text("/\(plan.dailyCalories) kcal")
                                .font(.custom("Sora-Regular", size: 10))
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    )
                )
                .frame(width: 106, height: 106)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Oggi hai assunto")
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("\(remainingKcal) kcal rimaste")
                        .font(.custom("Archivo-ExtraBold", size: 20))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(remainingKcal >= 0 ? "in linea" : "attenzione")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(remainingKcal >= 0 ? DesignSystem.Colors.teal : DesignSystem.Colors.amber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(remainingKcal >= 0 ? DesignSystem.Colors.tealBg : DesignSystem.Colors.amberBg)
                        .clipShape(Capsule())
                }
                Spacer()
            }
        }
    }

    private func macroCard(_ title: String, _ value: Int, _ color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(value)g")
                    .font(.custom("Archivo-Black", size: 19))
                    .foregroundStyle(color)
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private func mealCard(_ meal: Meal) -> some View {
        let checked = checkedMealIDs.contains(meal.id)
        let disabled = dayOffset != 0
        return Button { selectedMeal = meal } label: {
            FitCard {
                HStack(alignment: .top, spacing: 12) {
                    Text("🍽")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(meal.name)
                                .font(.custom("Archivo-ExtraBold", size: 15))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Spacer()
                            Text("\(mealKcal) kcal")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.teal)
                        }
                        Text(meal.foods.map(\.name).joined(separator: ", "))
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            .lineLimit(1)
                    }
                    Button {
                        guard !disabled else { return }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if checked {
                                checkedMealIDs.remove(meal.id)
                            } else {
                                checkedMealIDs.insert(meal.id)
                            }
                        }
                    } label: {
                        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(checked ? DesignSystem.Colors.teal : DesignSystem.Colors.bgLine)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.55 : 1)
    }

    private var mealKcal: Int {
        max(plan.dailyCalories / max(plan.meals.count, 1), 1)
    }

    private var consumedKcal: Int {
        checkedMealIDs.count * mealKcal
    }

    private var remainingKcal: Int {
        plan.dailyCalories - consumedKcal
    }

    private func consumedMacro(_ total: Int) -> Int {
        Int(Double(total) * Double(checkedMealIDs.count) / Double(max(plan.meals.count, 1)))
    }
}

private struct MealDetailSheet: View {
    let meal: Meal
    let kcal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(DesignSystem.Colors.bgLine)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
            HStack {
                Text("🍽")
                    .font(.title)
                Text(meal.name)
                    .font(DesignSystem.Typography.titleLG())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                Text("\(kcal) kcal")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.teal)
            }
            SectionLabel(text: "Alimenti")
            ForEach(meal.foods) { food in
                HStack(alignment: .top) {
                    Text(food.name)
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Spacer()
                    Text(food.quantity)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Divider().background(DesignSystem.Colors.bgLine)
            }
            if !meal.notes.isEmpty {
                SectionLabel(text: "Note del coach")
                Text(meal.notes)
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
            }
            Spacer()
        }
        .padding(24)
        .appScreen()
    }
}

struct ClientProgressView: View {
    enum Mode: String, CaseIterable, Hashable {
        case measures = "Peso & Misure"
        case exercises = "Esercizi"
    }

    @StateObject private var viewModel: ClientProgressViewModel
    @StateObject private var workoutViewModel: ClientWorkoutViewModel
    @State private var showingAdd = false
    @State private var mode: Mode = .measures
    @State private var expandedExerciseID: UUID?
    let client: Client

    init(client: Client, services: AppServices) {
        self.client = client
        _viewModel = StateObject(wrappedValue: ClientProgressViewModel(client: client, service: services.progressService, workoutService: services.workoutService))
        _workoutViewModel = StateObject(wrappedValue: ClientWorkoutViewModel(client: client, service: services.workoutService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SegmentedPicker(options: Mode.allCases, selection: $mode, title: \.rawValue, accent: DesignSystem.Colors.limeDark)

                    if mode == .measures {
                        measuresView
                    } else {
                        exercisesView
                    }
                }
                .padding(20)
            }
            .navigationTitle("Progressi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+ Nuovo") { showingAdd = true }
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.limeDark)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddProgressEntryView(client: client, onSave: viewModel.addEntry)
            }
            .appScreen()
            .task {
                viewModel.load()
                workoutViewModel.load()
            }
        }
    }

    private var measuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                miniStat(icon: "scalemass.fill", color: DesignSystem.Colors.limeDark, value: String(format: "%.1fkg", client.currentWeightKg), subtitle: "peso attuale")
                miniStat(icon: "chart.bar.fill", color: DesignSystem.Colors.amber, value: deltaText, subtitle: "dall'inizio · giorni")
            }

            FitCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(minWeightText)
                        Spacer()
                        Text(maxWeightText)
                    }
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)

                    Chart(weightChartPoints) { entry in
                        BarMark(
                            x: .value("Settimana", entry.label),
                            y: .value("Peso", entry.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [DesignSystem.Colors.lime, DesignSystem.Colors.limeDark], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(6)
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 170)
                }
            }

            SectionLabel(text: "Foto")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(hex: "EEF1F4"))
                        .aspectRatio(0.8, contentMode: .fit)
                        .overlay(Image(systemName: "camera.fill").foregroundStyle(DesignSystem.Colors.txtSecondary))
                }
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(DesignSystem.Colors.bgCard)
                    .aspectRatio(0.8, contentMode: .fit)
                    .overlay(Text("+").font(.system(size: 28, weight: .semibold)).foregroundStyle(DesignSystem.Colors.txtSecondary))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(DesignSystem.Colors.bgLine, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
            }
        }
    }

    private var exercisesView: some View {
        LazyVStack(spacing: 12) {
            ForEach(uniqueExercises) { exercise in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        expandedExerciseID = expandedExerciseID == exercise.id ? nil : exercise.id
                    }
                } label: {
                    FitCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.custom("Archivo-ExtraBold", size: 15))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    Text("Ultimo: \(exercise.recommendedLoad) · S1")
                                        .font(DesignSystem.Typography.bodySM())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(expandedExerciseID == exercise.id ? 90 : 0))
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                            if expandedExerciseID == exercise.id {
                                exerciseChart(exercise)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exerciseChart(_ exercise: Exercise) -> some View {
        let history = viewModel.exerciseWeightHistory.filter { $0.exerciseId == exercise.id }
        let data = history.enumerated().map { (index, entry) in
            ExerciseProgressPoint(label: "S\(index + 1)", weight: entry.weightKg)
        }
        return VStack(alignment: .leading, spacing: 10) {
            if data.count > 1 {
                Chart(data) { point in
                    LineMark(x: .value("Sessione", point.label), y: .value("Kg", point.weight))
                        .foregroundStyle(DesignSystem.Colors.lime)
                    PointMark(x: .value("Sessione", point.label), y: .value("Kg", point.weight))
                        .foregroundStyle(DesignSystem.Colors.lime)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 170)
            } else {
                Text("Solo una sessione registrata — continua ad allenarti per vedere il progresso")
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
            }
            HStack {
                Text(String(format: "Inizio: %.1fkg", data.first?.weight ?? 0))
                Spacer()
                Text(String(format: "Attuale: %.1fkg", data.last?.weight ?? 0))
                    .foregroundStyle(DesignSystem.Colors.limeDark)
                Spacer()
                TrendBadge(value: String(format: "+%.1fkg", max((data.last?.weight ?? 0) - (data.first?.weight ?? 0), 0)))
            }
            .font(DesignSystem.Typography.labelSM())
            .foregroundStyle(DesignSystem.Colors.txtSecondary)
        }
    }

    private func miniStat(icon: String, color: Color, value: String, subtitle: String) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 8) {
                FitIconChip(systemName: icon, color: color, background: color.opacity(0.12), size: 32)
                Text(value)
                    .font(.custom("Archivo-Black", size: 26))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(subtitle)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var weightEntries: [ProgressEntry] {
        let entries = viewModel.entries.sorted { $0.date < $1.date }
        return entries.isEmpty ? [ProgressEntry(id: UUID(), clientID: client.id, date: Date(), weightKg: client.currentWeightKg, waistCm: 0, chestCm: 0, armCm: 0, legCm: 0, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "")] : entries
    }

    private var weightChartPoints: [ExerciseProgressPoint] {
        Array(weightEntries.enumerated()).map { index, entry in
            ExerciseProgressPoint(label: "S\(index + 1)", weight: entry.weightKg)
        }
    }

    private var uniqueExercises: [Exercise] {
        var seen = Set<String>()
        return workoutViewModel.activePlan?.days.flatMap(\.exercises).filter { seen.insert($0.name).inserted } ?? []
    }

    private var minWeightText: String {
        String(format: "%.1f kg", weightEntries.map(\.weightKg).min() ?? client.currentWeightKg)
    }

    private var maxWeightText: String {
        String(format: "%.1f kg", weightEntries.map(\.weightKg).max() ?? client.currentWeightKg)
    }

    private var deltaText: String {
        let delta = client.currentWeightKg - client.initialWeightKg
        return String(format: "%+.1fkg", delta)
    }
}

private struct ExerciseProgressPoint: Identifiable {
    var id: String { label }
    let label: String
    let weight: Double
}

struct ClientProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil
    let client: Client

    init(client: Client, services: AppServices) {
        self.client = client
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
                                } else {
                                    AvatarView(initials: initials, gradient: [DesignSystem.Colors.lime, DesignSystem.Colors.teal], size: 70)
                                }
                            }
                            Circle()
                                .fill(DesignSystem.Colors.limeDark)
                                .frame(width: 22, height: 22)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 10)).foregroundStyle(.white))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                avatarImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                    Text(client.fullName)
                        .font(DesignSystem.Typography.titleMD())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(client.email.isEmpty ? client.phone : client.email)
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                .frame(maxWidth: .infinity)

                FitCard {
                    VStack(spacing: 0) {
                        profileRow("Altezza", String(format: "%.0f cm", client.heightCm))
                        Divider().background(DesignSystem.Colors.bgLine)
                        profileRow("Peso iniziale", String(format: "%.1f kg", client.initialWeightKg))
                        Divider().background(DesignSystem.Colors.bgLine)
                        profileRow("Peso attuale", String(format: "%.1f kg", client.currentWeightKg), valueColor: DesignSystem.Colors.limeDark)
                        Divider().background(DesignSystem.Colors.bgLine)
                        profileRow("Obiettivo", client.goal)
                        Divider().background(DesignSystem.Colors.bgLine)
                        profileRow("Coach", "Marco")
                    }
                }

                SectionLabel(text: "Account")
                    .frame(maxWidth: .infinity, alignment: .leading)

                menuRow(icon: "bell.fill", title: "Notifiche")
                menuRow(icon: "heart.fill", title: "App Salute")
                Button {
                    authViewModel.logout()
                } label: {
                    FitCard {
                        HStack {
                            FitIconChip(systemName: "rectangle.portrait.and.arrow.right", color: DesignSystem.Colors.txtSecondary, background: DesignSystem.Colors.bgLine.opacity(0.6), size: 34)
                            Text("Esci")
                                .font(.custom("Archivo-ExtraBold", size: 15))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private func profileRow(_ label: String, _ value: String, valueColor: Color = DesignSystem.Colors.txtPrimary) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodyMD())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.labelMD())
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }

    private func menuRow(icon: String, title: String) -> some View {
        FitCard {
            HStack {
                FitIconChip(systemName: icon, color: DesignSystem.Colors.limeDark, background: DesignSystem.Colors.limeBg, size: 34)
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

    private var initials: String {
        "\(client.firstName.first.map(String.init) ?? "")\(client.lastName.first.map(String.init) ?? "")"
    }
}

struct ClientChatView: View {
    let client: Client
    @State private var text = ""
    @State private var messages: [LocalChatMessage] = [
        LocalChatMessage(text: "Come sta andando questa settimana?", isMine: false, date: Date().addingTimeInterval(-3600)),
        LocalChatMessage(text: "Bene, ho completato gli allenamenti.", isMine: true, date: Date().addingTimeInterval(-1800))
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatHeader
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("OGGI")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                .padding(.vertical, 8)
                            ForEach(messages) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding(20)
                    }
                    .onAppear { scrollBottom(proxy) }
                    .onChange(of: messages.count) { _, _ in scrollBottom(proxy) }
                }
                inputBar
            }
            .toolbar(.hidden, for: .navigationBar)
            .appScreen()
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 10) {
            UserAvatarView(imageUrl: nil, firstName: "Marco", lastName: "C", size: 38, gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.teal])
            Text("Marco · coach")
                .font(.custom("Archivo-ExtraBold", size: 16))
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(DesignSystem.Colors.bgMain)
    }

    private func chatBubble(_ message: LocalChatMessage) -> some View {
        HStack {
            if message.isMine { Spacer(minLength: 40) }
            Text(message.text)
                .font(DesignSystem.Typography.bodyMD())
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(message.isMine ? DesignSystem.Colors.limeBg : DesignSystem.Colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(message.isMine ? Color(hex: "DDE7C2") : DesignSystem.Colors.bgLine, lineWidth: 1)
                )
            if !message.isMine { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Scrivi a Marco…", text: $text)
                .font(DesignSystem.Typography.bodyMD())
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(DesignSystem.Colors.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(DesignSystem.Colors.bgLine, lineWidth: 1))
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(DesignSystem.Colors.limeDark)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(DesignSystem.Colors.bgMain)
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(LocalChatMessage(text: trimmed, isMine: true, date: Date()))
        text = ""
    }

    private func scrollBottom(_ proxy: ScrollViewProxy) {
        guard let id = messages.last?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

private struct LocalChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isMine: Bool
    let date: Date
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionLabel(text: "Misure")
                    progressField("Peso", value: $weight, suffix: "kg")
                    HStack(spacing: 10) {
                        progressField("Vita", value: $waist, suffix: "cm")
                        progressField("Fianchi", value: $chest, suffix: "cm")
                    }

                    SectionLabel(text: "Foto")
                    HStack(spacing: 10) {
                        photoSlot
                        photoSlot
                        photoSlot
                    }

                    SectionLabel(text: "Note")
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(DesignSystem.Colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))

                    AccentButton(title: "Salva progresso", color: DesignSystem.Colors.limeDark) {
                        onSave(weight, waist, chest, arm, leg, notes)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Nuovo progresso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .appScreen()
        }
    }

    private func progressField(_ label: String, value: Binding<Double>, suffix: String) -> some View {
        FitCard {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                Spacer()
                TextField(label, value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.custom("Archivo-ExtraBold", size: 18))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    .multilineTextAlignment(.trailing)
                Text(suffix)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    private var photoSlot: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(DesignSystem.Colors.bgCard)
            .aspectRatio(1, contentMode: .fit)
            .overlay(Image(systemName: "plus").foregroundStyle(DesignSystem.Colors.txtSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.Colors.bgLine, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
    }
}
