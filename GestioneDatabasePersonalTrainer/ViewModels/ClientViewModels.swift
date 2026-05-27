import Foundation
import Combine

@MainActor
final class ClientDashboardViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var nutritionPlans: [NutritionPlan] = []
    @Published var progressEntries: [ProgressEntry] = []
    @Published var todaySteps: DailyStepSummary?
    @Published var weeklyStepSummaries: [DailyStepSummary] = []
    @Published var weeklyAverageSteps: Double = 0
    @Published var todayGoals: [DailyGoal] = []
    @Published var todayCheckIn: DailyCheckIn?
    @Published var streaks: [Streak] = []
    @Published var healthKitState: HealthKitAuthorizationState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client: Client
    private let services: AppServices
    private let stepsGoal = 10_000
    private var persistedGoals: [DailyGoal] = []

    init(client: Client, services: AppServices) {
        self.client = client
        self.services = services
    }

    func load() {
        isLoading = true
        errorMessage = nil
        Task<Void, Never>(priority: nil) {
            appointments = await services.appointmentService.fetchAppointments(forClient: client.id)
            workoutPlans = await services.workoutService.fetchWorkoutPlans(forClient: client.id)
            nutritionPlans = await services.nutritionService.fetchNutritionPlans(forClient: client.id)
            progressEntries = await services.progressService.fetchProgressEntries(for: client.id)
            todayCheckIn = await services.dailyCheckInService.fetchTodayCheckIn(clientId: client.id)
            persistedGoals = await services.dailyGoalsService.fetchTodayGoals(clientId: client.id)
            streaks = await services.streakService.fetchClientStreaks(clientId: client.id)
            weeklyStepSummaries = await services.activitySummaryService.fetchLast7DaysActivity(clientId: client.id)
            todaySteps = weeklyStepSummaries.first(where: { Calendar.current.isDateInToday($0.summaryDate) })
            weeklyAverageSteps = weeklyStepSummaries.isEmpty ? 0 : Double(weeklyStepSummaries.reduce(0) { $0 + $1.steps }) / Double(weeklyStepSummaries.count)
            healthKitState = services.healthKitService.authorizationState
            rebuildGoals()
            isLoading = false
        }
    }

    func requestHealthKitAccessAndRefresh() {
        Task<Void, Never>(priority: nil) {
            do {
                try await services.healthKitService.requestAuthorization()
                await refreshStepsFromHealthKit()
            } catch {
                healthKitState = services.healthKitService.authorizationState
                errorMessage = error.localizedDescription
            }
        }
    }

    func refreshStepsFromHealthKit() async {
        do {
            let steps = try await services.healthKitService.fetchTodaySteps()
            let summary = DailyStepSummary(
                id: todaySteps?.id ?? UUID(),
                trainerID: client.trainerID,
                clientID: client.id,
                summaryDate: Date(),
                steps: steps,
                stepsGoal: stepsGoal,
                source: "healthkit",
                createdAt: nil,
                updatedAt: nil
            )
            todaySteps = await services.activitySummaryService.upsertTodayStepSummary(summary)
            weeklyStepSummaries = await services.activitySummaryService.fetchLast7DaysActivity(clientId: client.id)
            weeklyAverageSteps = try await services.healthKitService.fetchWeeklyAverageSteps()
            if steps >= stepsGoal {
                _ = await services.streakService.updateStepsStreak(trainerID: client.trainerID, clientID: client.id)
            }
            streaks = await services.streakService.fetchClientStreaks(clientId: client.id)
            healthKitState = services.healthKitService.authorizationState
            rebuildGoals()
        } catch {
            healthKitState = services.healthKitService.authorizationState
            errorMessage = error.localizedDescription
            rebuildGoals()
        }
    }

    func markGoalCompleted(_ goal: DailyGoal) {
        Task<Void, Never>(priority: nil) {
            _ = await services.dailyGoalsService.markGoalCompleted(goal)
            if goal.goalType == .checkIn {
                todayCheckIn = await services.dailyCheckInService.fetchTodayCheckIn(clientId: client.id)
            }
            rebuildGoals()
        }
    }

    func didSaveCheckIn(_ checkIn: DailyCheckIn) {
        todayCheckIn = checkIn
        Task<Void, Never>(priority: nil) {
            streaks = await services.streakService.fetchClientStreaks(clientId: client.id)
            rebuildGoals()
        }
    }

    var activeWorkoutPlan: WorkoutPlan? {
        workoutPlans.first(where: { $0.status == .active })
    }

    var activeNutritionPlan: NutritionPlan? {
        nutritionPlans.first
    }

    var nextAppointment: Appointment? {
        appointments.first(where: { $0.startTime >= Date() })
    }

    var checkInStreak: Streak? {
        streaks.first(where: { $0.streakType == .checkIn })
    }

    var stepsStreak: Streak? {
        streaks.first(where: { $0.streakType == .steps })
    }

    var stepMotivationText: String {
        guard let todaySteps else { return "Collega Apple Salute per vedere i passi di oggi." }
        if todaySteps.steps >= todaySteps.stepsGoal { return "Obiettivo raggiunto." }
        let missing = max(todaySteps.stepsGoal - todaySteps.steps, 0)
        if todaySteps.steps > todaySteps.stepsGoal / 2 { return "Ottimo ritmo oggi. Mancano \(missing) passi." }
        return "Ti mancano \(missing) passi. Inizia con una camminata leggera."
    }

    private func rebuildGoals() {
        var goals: [DailyGoal] = []
        let steps = todaySteps?.steps ?? 0
        goals.append(DailyGoal(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            goalDate: Date(),
            title: "Passi giornalieri",
            description: "Raggiungi il tuo obiettivo di movimento.",
            goalType: .steps,
            targetValue: Double(stepsGoal),
            currentValue: Double(steps),
            unit: "passi",
            isCompleted: steps >= stepsGoal,
            iconName: "figure.walk",
            color: "success"
        ))

        goals.append(DailyGoal(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            goalDate: Date(),
            title: activeWorkoutPlan?.days.first?.title ?? "Allenamento del giorno",
            description: activeWorkoutPlan == nil ? "Nessuna scheda attiva pubblicata." : "Completa la scheda assegnata dal trainer.",
            goalType: .workout,
            targetValue: 1,
            currentValue: 0,
            unit: nil,
            isCompleted: false,
            iconName: "figure.run",
            color: "primary"
        ))

        goals.append(DailyGoal(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            goalDate: Date(),
            title: "Check-in giornaliero",
            description: todayCheckIn == nil ? "Non ancora compilato." : "Compilato oggi.",
            goalType: .checkIn,
            targetValue: 1,
            currentValue: todayCheckIn == nil ? 0 : 1,
            unit: nil,
            isCompleted: todayCheckIn != nil,
            iconName: "checklist",
            color: "success"
        ))

        if shouldUpdateWeight {
            goals.append(DailyGoal(
                id: UUID(),
                trainerID: client.trainerID,
                clientID: client.id,
                goalDate: Date(),
                title: "Aggiorna peso",
                description: "Registra il peso settimanale quando previsto.",
                goalType: .weight,
                targetValue: 1,
                currentValue: 0,
                unit: nil,
                isCompleted: false,
                iconName: "scalemass",
                color: "info"
            ))
        }

        if shouldUpdateProgressPhoto {
            goals.append(DailyGoal(
                id: UUID(),
                trainerID: client.trainerID,
                clientID: client.id,
                goalDate: Date(),
                title: "Foto progresso",
                description: "Carica una foto progresso quando prevista.",
                goalType: .progressPhoto,
                targetValue: 1,
                currentValue: 0,
                unit: nil,
                isCompleted: false,
                iconName: "camera",
                color: "warning"
            ))
        }

        let generatedTypes = Set(goals.map(\.goalType))
        todayGoals = goals + persistedGoals.filter { !generatedTypes.contains($0.goalType) }
    }

    private var shouldUpdateWeight: Bool {
        guard let latest = progressEntries.first else { return true }
        let days = Calendar.current.dateComponents([.day], from: latest.date, to: Date()).day ?? 0
        return days >= 7
    }

    private var shouldUpdateProgressPhoto: Bool {
        guard let latest = progressEntries.first else { return true }
        return latest.frontPhotoName == nil && latest.sidePhotoName == nil && latest.backPhotoName == nil
    }
}

@MainActor
final class ClientWorkoutViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var completedWorkoutDayIDs: Set<UUID> = []

    private let client: Client
    private let service: WorkoutService

    init(client: Client, service: WorkoutService) {
        self.client = client
        self.service = service
    }

    func load() {
        Task<Void, Never>(priority: nil) { plans = await service.fetchWorkoutPlans(forClient: client.id) }
    }

    var activePlan: WorkoutPlan? {
        plans.first(where: { $0.status == .active })
    }

    func toggleCompletion(for day: WorkoutDay) {
        if completedWorkoutDayIDs.contains(day.id) {
            completedWorkoutDayIDs.remove(day.id)
        } else {
            completedWorkoutDayIDs.insert(day.id)
        }
    }
}

@MainActor
final class ClientNutritionViewModel: ObservableObject {
    @Published var plans: [NutritionPlan] = []

    private let client: Client
    private let service: NutritionService

    init(client: Client, service: NutritionService) {
        self.client = client
        self.service = service
    }

    func load() {
        Task<Void, Never>(priority: nil) { plans = await service.fetchNutritionPlans(forClient: client.id) }
    }

    var activePlan: NutritionPlan? {
        plans.first
    }
}

@MainActor
final class ClientProgressViewModel: ObservableObject {
    @Published var entries: [ProgressEntry] = []
    @Published var exerciseWeightHistory: [ExerciseWeightHistoryDTO] = []

    private let client: Client
    private let service: ProgressService
    private let workoutService: WorkoutService

    init(client: Client, service: ProgressService, workoutService: WorkoutService) {
        self.client = client
        self.service = service
        self.workoutService = workoutService
    }

    func load() {
        Task<Void, Never>(priority: nil) {
            entries = await service.fetchProgressEntries(for: client.id)
            exerciseWeightHistory = await workoutService.fetchExerciseWeightHistory(for: client.id)
        }
    }

    func addEntry(weight: Double, waist: Double, chest: Double, arm: Double, leg: Double, notes: String) {
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
            _ = await service.addProgressEntry(entry)
            load()
        }
    }
}
