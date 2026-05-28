import Foundation
import Combine

enum AppError: LocalizedError {
    case invalidCredentials
    case accessCodeNotFound
    case missingClient
    case missingEntity
    case wrongRole

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Credenziali non valide."
        case .accessCodeNotFound:
            return "Codice cliente non trovato."
        case .missingClient:
            return "Cliente non trovato."
        case .missingEntity:
            return "Elemento non trovato."
        case .wrongRole:
            return "Il ruolo dell'utente non corrisponde all'area selezionata."
        }
    }
}

@MainActor
final class AppServices: ObservableObject {
    let database: MockDatabase
    let supabase: SupabaseManager
    let authService: AuthService
    let trainerService: TrainerService
    let clientService: ClientService
    let subscriptionService: SubscriptionService
    let inviteCodeService: InviteCodeService
    let workoutService: WorkoutService
    let nutritionService: NutritionService
    let appointmentService: AppointmentService
    let machineService: MachineService
    let progressService: ProgressService
    let storageService: StorageService
    let catalogService: CatalogService
    let healthKitService: HealthKitService
    let dailyCheckInService: DailyCheckInService
    let dailyGoalsService: DailyGoalsService
    let activitySummaryService: ActivitySummaryService
    let streakService: StreakService
    let trainerInsightsService: TrainerInsightsService
    let savedMealService: SavedMealService
    let trainerNotesService: TrainerNotesService
    let clientPaymentService: ClientPaymentService
    let trainerClientPaymentService: TrainerClientPaymentService

    convenience init() {
        self.init(database: MockDatabase.shared, supabase: SupabaseManager.shared)
    }

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
        trainerService = TrainerService(database: database, supabase: supabase)
        subscriptionService = SubscriptionService(supabase: supabase)
        inviteCodeService = InviteCodeService(database: database, supabase: supabase)
        authService = AuthService(database: database, supabase: supabase)
        clientService = ClientService(database: database, supabase: supabase, inviteCodeService: inviteCodeService)
        workoutService = WorkoutService(database: database, supabase: supabase)
        nutritionService = NutritionService(database: database, supabase: supabase)
        appointmentService = AppointmentService(database: database, supabase: supabase)
        machineService = MachineService(database: database, supabase: supabase)
        progressService = ProgressService(database: database, supabase: supabase)
        storageService = StorageService(supabase: supabase)
        catalogService = CatalogService(supabase: supabase)
        healthKitService = HealthKitService()
        dailyCheckInService = DailyCheckInService(database: database, supabase: supabase)
        dailyGoalsService = DailyGoalsService(supabase: supabase)
        activitySummaryService = ActivitySummaryService(supabase: supabase)
        streakService = StreakService(supabase: supabase)
        trainerInsightsService = TrainerInsightsService(
            dailyCheckInService: dailyCheckInService,
            activitySummaryService: activitySummaryService,
            streakService: streakService
        )
        savedMealService = SavedMealService(database: database, supabase: supabase)
        trainerNotesService = TrainerNotesService(supabase: supabase)
        clientPaymentService = ClientPaymentService(supabase: supabase)
        trainerClientPaymentService = TrainerClientPaymentService(supabase: supabase)
    }
}

@MainActor
final class AuthService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func restoreSession() async throws -> AuthSession? {
        guard AppConfiguration.isSupabaseConfigured, let user = supabase.session?.user else { return nil }
        let profiles: [ProfileDTO] = try await supabase.select("profiles", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(user.id.uuidString)")
        ])
        guard let profile = profiles.first else { return nil }

        if profile.role == "trainer" {
            return .trainer(try await fetchTrainer(for: user.id, profile: profile))
        }

        if profile.role == "client" {
            return .client(try await fetchClient(for: user.id))
        }

        return nil
    }

    func registerTrainer(email: String, password: String, firstName: String, lastName: String, businessName: String, selectedPlanSlug: String) async throws -> Trainer {
        guard AppConfiguration.isSupabaseConfigured else { throw SupabaseError.notConfigured }
        let session = try await supabase.signUp(email: email, password: password)
        let trainer: TrainerDTO = try await supabase.rpc("create_trainer_account", params: RPCCreateTrainerParams(
            pPlanSlug: selectedPlanSlug,
            pFirstName: firstName,
            pLastName: lastName,
            pBusinessName: businessName,
            pPhone: nil
        ))
        let profile = ProfileDTO(id: session.user.id, role: "trainer", email: email, firstName: firstName, lastName: lastName, avatarUrl: nil, phone: nil)
        return SupabaseMapper.trainer(from: trainer, profile: profile)
    }

    func registerClientWithInviteCode(code: String, email: String, password: String) async throws -> Client {
        guard AppConfiguration.isSupabaseConfigured else { throw SupabaseError.notConfigured }
        _ = try await supabase.signUp(email: email, password: password)
        let dto: ClientDTO = try await supabase.rpc("redeem_client_invite_code", params: RPCRedeemInviteParams(pCode: code, pEmail: email))
        return SupabaseMapper.client(from: dto)
    }

    func loginTrainer(email: String, password: String) async throws -> Trainer {
        if AppConfiguration.isSupabaseConfigured {
            let session = try await supabase.signIn(email: email, password: password)
            let profiles: [ProfileDTO] = try await supabase.select("profiles", queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "id", value: "eq.\(session.user.id.uuidString)")
            ])
            guard let profile = profiles.first, profile.role == "trainer" else { throw AppError.wrongRole }
            return try await fetchTrainer(for: session.user.id, profile: profile)
        }

        guard email.lowercased() == database.trainer.email.lowercased(), !password.isEmpty else {
            throw AppError.invalidCredentials
        }
        return database.trainer
    }

    func loginClient(email: String, password: String) async throws -> Client {
        guard AppConfiguration.isSupabaseConfigured else { throw SupabaseError.notConfigured }
        let session = try await supabase.signIn(email: email, password: password)
        return try await fetchClient(for: session.user.id)
    }

    func loginClient(accessCode: String) async throws -> Client {
        let normalized = accessCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let accessCode = database.accessCodes.first(where: { $0.code == normalized && $0.isActive }),
              let client = database.clients.first(where: { $0.id == accessCode.clientID }) else {
            throw AppError.accessCodeNotFound
        }
        return client
    }

    func demoTrainer() -> Trainer {
        database.trainer
    }

    func demoClient() throws -> Client {
        guard let client = database.clients.first else { throw AppError.missingClient }
        return client
    }

    func logout() async {
        if AppConfiguration.isSupabaseConfigured {
            await supabase.signOut()
        }
    }

    private func fetchTrainer(for userID: UUID, profile: ProfileDTO) async throws -> Trainer {
        let trainers: [TrainerDTO] = try await supabase.select("trainers", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)")
        ])
        guard let trainer = trainers.first else { throw AppError.wrongRole }
        return SupabaseMapper.trainer(from: trainer, profile: profile)
    }

    private func fetchClient(for userID: UUID) async throws -> Client {
        let clients: [ClientDTO] = try await supabase.select("clients", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)")
        ])
        guard let client = clients.first else { throw AppError.wrongRole }
        return SupabaseMapper.client(from: client)
    }
}

@MainActor
final class TrainerService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchCurrentTrainer() async throws -> Trainer {
        guard AppConfiguration.isSupabaseConfigured, let user = supabase.session?.user else { return database.trainer }
        let profiles: [ProfileDTO] = try await supabase.select("profiles", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(user.id.uuidString)")
        ])
        let trainers: [TrainerDTO] = try await supabase.select("trainers", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString)")
        ])
        guard let trainer = trainers.first else { return database.trainer }
        return SupabaseMapper.trainer(from: trainer, profile: profiles.first)
    }
}

@MainActor
final class SubscriptionService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) {
        self.supabase = supabase
    }

    func fetchPlans() async throws -> [SubscriptionPlanDTO] {
        try await supabase.select("subscription_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "monthly_price.asc")
        ])
    }

    func trainerCanAddClient(trainerID: UUID) async -> Bool {
        guard AppConfiguration.isSupabaseConfigured else { return true }
        let result: Bool? = try? await supabase.rpc("trainer_can_add_client", params: ["p_trainer_id": trainerID.uuidString])
        return result ?? false
    }
}

struct SubscriptionPlanDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var slug: String
    var description: String
    var monthlyPrice: Double
    var yearlyPrice: Double?
    var maxClients: Int?
    var trialDays: Int
    var isActive: Bool
}

@MainActor
final class InviteCodeService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func generateInviteCode(trainerID: UUID, clientID: UUID) async throws -> String {
        if AppConfiguration.isSupabaseConfigured {
            let code: String = try await supabase.rpc("generate_client_invite_code", params: RPCTrainerInviteParams(pTrainerId: trainerID, pClientId: clientID))
            return code
        }
        return AccessCodeGenerator.make(existingCodes: Set(database.accessCodes.map(\.code)))
    }
}

@MainActor
final class ClientService {
    private let database: MockDatabase
    private let supabase: SupabaseManager
    private let inviteCodeService: InviteCodeService

    init(database: MockDatabase, supabase: SupabaseManager, inviteCodeService: InviteCodeService) {
        self.database = database
        self.supabase = supabase
        self.inviteCodeService = inviteCodeService
    }

    func fetchClients(for trainerID: UUID) async -> [Client] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.clients.filter { $0.trainerID == trainerID }.sorted { $0.joinedAt > $1.joinedAt }
        }

        do {
            let rows: [ClientDTO] = try await supabase.select("clients", queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ])
            return rows.map(SupabaseMapper.client)
        } catch {
            return []
        }
    }

    func createClient(_ client: Client) async -> Client {
        guard AppConfiguration.isSupabaseConfigured else {
            database.clients.append(client)
            database.accessCodes.append(AccessCode(id: UUID(), code: client.accessCode, trainerID: client.trainerID, clientID: client.id, createdAt: Date(), isActive: true))
            return client
        }

        do {
            let createdRows: [ClientDTO] = try await supabase.insert("clients", value: SupabaseMapper.clientDTO(from: client))
            guard var created = createdRows.first.map(SupabaseMapper.client) else { return client }
            created.accessCode = try await inviteCodeService.generateInviteCode(trainerID: created.trainerID, clientID: created.id)
            return created
        } catch {
            return client
        }
    }

    func updateClient(_ client: Client) async throws -> Client {
        guard AppConfiguration.isSupabaseConfigured else {
            guard let index = database.clients.firstIndex(where: { $0.id == client.id }) else { throw AppError.missingClient }
            database.clients[index] = client
            return client
        }

        let rows: [ClientDTO] = try await supabase.update("clients", filters: [
            URLQueryItem(name: "id", value: "eq.\(client.id.uuidString)")
        ], value: SupabaseMapper.clientDTO(from: client))
        return rows.first.map(SupabaseMapper.client) ?? client
    }

    func deleteClient(_ client: Client) async {
        guard AppConfiguration.isSupabaseConfigured else {
            database.clients.removeAll { $0.id == client.id }
            database.accessCodes.removeAll { $0.clientID == client.id }
            database.appointments.removeAll { $0.clientID == client.id }
            database.workoutPlans.removeAll { $0.clientID == client.id }
            database.nutritionPlans.removeAll { $0.clientID == client.id }
            database.progressEntries.removeAll { $0.clientID == client.id }
            return
        }
        try? await supabase.delete("clients", filters: [URLQueryItem(name: "id", value: "eq.\(client.id.uuidString)")])
    }

    func generateUniqueAccessCode() -> String {
        AccessCodeGenerator.make(existingCodes: Set(database.accessCodes.map(\.code)))
    }
}

@MainActor
final class AppointmentService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchAppointments(forTrainer trainerID: UUID) async -> [Appointment] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.appointments.filter { $0.trainerID == trainerID }.sorted { $0.startTime < $1.startTime }
        }
        let rows: [AppointmentDTO] = (try? await supabase.select("appointments", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "order", value: "starts_at.asc")
        ])) ?? []
        return rows.map(SupabaseMapper.appointment)
    }

    func fetchAppointments(forClient clientID: UUID) async -> [Appointment] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.appointments.filter { $0.clientID == clientID }.sorted { $0.startTime < $1.startTime }
        }
        let rows: [AppointmentDTO] = (try? await supabase.select("appointments", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "starts_at.asc")
        ])) ?? []
        return rows.map(SupabaseMapper.appointment)
    }

    func createAppointment(_ appointment: Appointment) async -> Appointment {
        guard AppConfiguration.isSupabaseConfigured else {
            database.appointments.append(appointment)
            return appointment
        }
        let rows: [AppointmentDTO] = (try? await supabase.insert("appointments", value: SupabaseMapper.appointmentDTO(from: appointment))) ?? []
        return rows.first.map(SupabaseMapper.appointment) ?? appointment
    }

    func updateAppointment(_ appointment: Appointment) async throws -> Appointment {
        guard AppConfiguration.isSupabaseConfigured else {
            guard let index = database.appointments.firstIndex(where: { $0.id == appointment.id }) else { throw AppError.missingEntity }
            database.appointments[index] = appointment
            return appointment
        }
        let rows: [AppointmentDTO] = try await supabase.update("appointments", filters: [
            URLQueryItem(name: "id", value: "eq.\(appointment.id.uuidString)")
        ], value: SupabaseMapper.appointmentDTO(from: appointment))
        return rows.first.map(SupabaseMapper.appointment) ?? appointment
    }

    func deleteAppointment(_ appointment: Appointment) async {
        guard AppConfiguration.isSupabaseConfigured else {
            database.appointments.removeAll { $0.id == appointment.id }
            return
        }
        try? await supabase.delete("appointments", filters: [URLQueryItem(name: "id", value: "eq.\(appointment.id.uuidString)")])
    }
}

@MainActor
final class MachineService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchMachines(for trainerID: UUID) async -> [Machine] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.machines.filter { $0.trainerID == trainerID }.sorted { $0.name < $1.name }
        }
        let rows: [MachineDTO] = (try? await supabase.select("machines", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "order", value: "name.asc")
        ])) ?? []
        return rows.map(SupabaseMapper.machine)
    }

    func createMachine(_ machine: Machine) async -> Machine {
        guard AppConfiguration.isSupabaseConfigured else {
            database.machines.append(machine)
            return machine
        }
        let rows: [MachineDTO] = (try? await supabase.insert("machines", value: SupabaseMapper.machineDTO(from: machine))) ?? []
        return rows.first.map(SupabaseMapper.machine) ?? machine
    }

    func updateMachine(_ machine: Machine) async throws -> Machine {
        guard AppConfiguration.isSupabaseConfigured else {
            guard let index = database.machines.firstIndex(where: { $0.id == machine.id }) else { throw AppError.missingEntity }
            database.machines[index] = machine
            return machine
        }
        let rows: [MachineDTO] = try await supabase.update("machines", filters: [
            URLQueryItem(name: "id", value: "eq.\(machine.id.uuidString)")
        ], value: SupabaseMapper.machineDTO(from: machine))
        return rows.first.map(SupabaseMapper.machine) ?? machine
    }

    func deleteMachine(_ machine: Machine) async {
        guard AppConfiguration.isSupabaseConfigured else {
            database.machines.removeAll { $0.id == machine.id }
            return
        }
        try? await supabase.delete("machines", filters: [URLQueryItem(name: "id", value: "eq.\(machine.id.uuidString)")])
    }
}

@MainActor
final class WorkoutService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchWorkoutPlans(for trainerID: UUID) async -> [WorkoutPlan] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.workoutPlans.filter { $0.trainerID == trainerID }.sorted { $0.createdAt > $1.createdAt }
        }
        let rows: [WorkoutPlanDTO] = (try? await supabase.select("workout_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])) ?? []
        return rows.map { dto in
            WorkoutPlan(id: dto.id ?? UUID(), trainerID: dto.trainerId, clientID: dto.clientId, name: dto.name, goal: dto.goal ?? "", createdAt: Date(), startDate: Date(), endDate: .daysFromNow(28), status: dto.status == "archived" ? .archived : .active, days: [])
        }
    }

    func fetchWorkoutPlans(forClient clientID: UUID) async -> [WorkoutPlan] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.workoutPlans.filter { $0.clientID == clientID }.sorted { $0.createdAt > $1.createdAt }
        }
        let rows: [WorkoutPlanDTO] = (try? await supabase.select("workout_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])) ?? []
        return rows.map { dto in
            WorkoutPlan(id: dto.id ?? UUID(), trainerID: dto.trainerId, clientID: dto.clientId, name: dto.name, goal: dto.goal ?? "", createdAt: Date(), startDate: Date(), endDate: .daysFromNow(28), status: dto.status == "archived" ? .archived : .active, days: [])
        }
    }

    func createWorkoutPlan(_ plan: WorkoutPlan) async -> WorkoutPlan {
        guard AppConfiguration.isSupabaseConfigured else {
            database.workoutPlans.append(plan)
            return plan
        }
        let dto = WorkoutPlanDTO(id: plan.id, trainerId: plan.trainerID, clientId: plan.clientID, name: plan.name, goal: plan.goal, startsAt: SupabaseMapper.formatDate(plan.startDate), endsAt: SupabaseMapper.formatDate(plan.endDate), status: plan.status.rawValue.lowercased())
        let _: [WorkoutPlanDTO]? = try? await supabase.insert("workout_plans", value: dto)
        return plan
    }

    func updateWorkoutPlan(_ plan: WorkoutPlan) async throws -> WorkoutPlan {
        guard AppConfiguration.isSupabaseConfigured else {
            guard let index = database.workoutPlans.firstIndex(where: { $0.id == plan.id }) else { throw AppError.missingEntity }
            database.workoutPlans[index] = plan
            return plan
        }
        return plan
    }

    func addExerciseWeightHistory(trainerID: UUID, clientID: UUID, exerciseID: UUID, weightKg: Double, effectiveFromSessionID: UUID?) async {
        guard AppConfiguration.isSupabaseConfigured else { return }
        let dto = ExerciseWeightHistoryDTO(
            id: UUID(),
            trainerId: trainerID,
            clientId: clientID,
            exerciseId: exerciseID,
            sessionDate: SupabaseMapper.formatDate(Date()),
            weightKg: weightKg,
            effectiveFromSessionId: effectiveFromSessionID,
            createdByUserId: supabase.session?.user.id
        )
        let _: [ExerciseWeightHistoryDTO]? = try? await supabase.insert("exercise_weight_history", value: dto)
    }

    func fetchExerciseWeightHistory(for clientID: UUID) async -> [ExerciseWeightHistoryDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("exercise_weight_history", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "session_date.asc")
        ])) ?? []
    }
}

@MainActor
final class NutritionService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchNutritionPlans(for trainerID: UUID) async -> [NutritionPlan] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.nutritionPlans.filter { $0.trainerID == trainerID }.sorted { $0.startDate > $1.startDate }
        }
        let rows: [NutritionPlanDTO] = (try? await supabase.select("nutrition_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])) ?? []
        return rows.map { dto in
            NutritionPlan(id: dto.id ?? UUID(), trainerID: dto.trainerId, clientID: dto.clientId, dailyCalories: dto.dailyCalories, proteinGrams: dto.proteinsG ?? 0, carbohydrateGrams: dto.carbsG ?? 0, fatGrams: dto.fatsG ?? 0, targetWeightKg: dto.targetWeightKg ?? 0, notes: dto.notes ?? "", startDate: Date(), endDate: .daysFromNow(30), meals: [])
        }
    }

    func fetchNutritionPlans(forClient clientID: UUID) async -> [NutritionPlan] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.nutritionPlans.filter { $0.clientID == clientID }.sorted { $0.startDate > $1.startDate }
        }
        let rows: [NutritionPlanDTO] = (try? await supabase.select("nutrition_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])) ?? []
        return rows.map { dto in
            NutritionPlan(id: dto.id ?? UUID(), trainerID: dto.trainerId, clientID: dto.clientId, dailyCalories: dto.dailyCalories, proteinGrams: dto.proteinsG ?? 0, carbohydrateGrams: dto.carbsG ?? 0, fatGrams: dto.fatsG ?? 0, targetWeightKg: dto.targetWeightKg ?? 0, notes: dto.notes ?? "", startDate: Date(), endDate: .daysFromNow(30), meals: [])
        }
    }

    func createNutritionPlan(_ plan: NutritionPlan) async -> NutritionPlan {
        guard AppConfiguration.isSupabaseConfigured else {
            database.nutritionPlans.append(plan)
            return plan
        }
        let planDTO = NutritionPlanDTO(id: plan.id, trainerId: plan.trainerID, clientId: plan.clientID, name: "Piano alimentare", dailyCalories: plan.dailyCalories, proteinsG: plan.proteinGrams, carbsG: plan.carbohydrateGrams, fatsG: plan.fatGrams, targetWeightKg: plan.targetWeightKg, notes: plan.notes, startsAt: SupabaseMapper.formatDate(plan.startDate), endsAt: SupabaseMapper.formatDate(plan.endDate), status: "active")
        let createdPlans: [NutritionPlanDTO]? = try? await supabase.insert("nutrition_plans", value: planDTO)
        let planID = createdPlans?.first?.id ?? plan.id

        for (order, meal) in plan.meals.enumerated() {
            let mealDTO = MealDTO(
                id: meal.id,
                nutritionPlanId: planID,
                name: meal.name,
                mealTime: Self.formatTimeOnly(meal.time),
                mealOrder: order + 1,
                dayOfWeek: meal.dayIndex > 0 ? meal.dayIndex : nil,
                notes: meal.notes.isEmpty ? nil : meal.notes
            )
            let savedMeals: [MealDTO]? = try? await supabase.insert("meals", value: mealDTO)
            let mealID = savedMeals?.first?.id ?? meal.id

            for food in meal.foods {
                let kcalInt = food.kcal > 0 ? Int(food.kcal.rounded()) : nil
                let foodDTO = MealFoodDTO(
                    id: food.id,
                    mealId: mealID,
                    foodName: food.name,
                    quantity: food.quantity,
                    calories: kcalInt,
                    proteinsG: food.proteinGrams > 0 ? food.proteinGrams : nil,
                    carbsG: food.carbGrams > 0 ? food.carbGrams : nil,
                    fatsG: food.fatGrams > 0 ? food.fatGrams : nil,
                    notes: food.notes.isEmpty ? nil : food.notes
                )
                let _: [MealFoodDTO]? = try? await supabase.insert("meal_foods", value: foodDTO)
            }
        }
        return plan
    }

    private static func formatTimeOnly(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}

@MainActor
final class ProgressService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchProgressEntries(for clientID: UUID) async -> [ProgressEntry] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.progressEntries.filter { $0.clientID == clientID }.sorted { $0.date > $1.date }
        }
        let rows: [ProgressEntryDTO] = (try? await supabase.select("progress_entries", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "entry_date.desc")
        ])) ?? []
        return rows.map(SupabaseMapper.progress)
    }

    func addProgressEntry(_ entry: ProgressEntry) async -> ProgressEntry {
        guard AppConfiguration.isSupabaseConfigured, let userID = supabase.session?.user.id else {
            database.progressEntries.append(entry)
            if let index = database.clients.firstIndex(where: { $0.id == entry.clientID }) {
                database.clients[index].currentWeightKg = entry.weightKg
            }
            return entry
        }
        guard let client = try? await currentClient(clientID: entry.clientID) else { return entry }
        let dto = ProgressEntryDTO(id: entry.id, trainerId: client.trainerID, clientId: entry.clientID, entryDate: SupabaseMapper.formatDate(entry.date), weightKg: entry.weightKg, waistCm: entry.waistCm, chestCm: entry.chestCm, armCm: entry.armCm, legCm: entry.legCm, notes: entry.notes, createdByUserId: userID)
        let _: [ProgressEntryDTO]? = try? await supabase.insert("progress_entries", value: dto)
        return entry
    }

    private func currentClient(clientID: UUID) async throws -> Client {
        let rows: [ClientDTO] = try await supabase.select("clients", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(clientID.uuidString)")
        ])
        guard let row = rows.first else { throw AppError.missingClient }
        return SupabaseMapper.client(from: row)
    }
}

@MainActor
final class StorageService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) {
        self.supabase = supabase
    }

    func uploadProgressPhoto(data: Data, trainerID: UUID, clientID: UUID, progressEntryID: UUID, photoType: String) async throws -> String {
        let path = "\(trainerID.uuidString)/\(clientID.uuidString)/\(progressEntryID.uuidString)/\(photoType)_\(UUID().uuidString).jpg"
        try await supabase.uploadProgressPhoto(data: data, storagePath: path)
        return path
    }
}

@MainActor
final class CatalogService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) {
        self.supabase = supabase
    }

    func fetchMuscleGroups() async -> [MuscleGroupDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("muscle_groups", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "sort_order.asc")
        ])) ?? []
    }

    func fetchMachineCatalog() async -> [MachineCatalogDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("machine_catalog", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "muscle_group.asc,name.asc")
        ])) ?? []
    }

    func fetchExerciseCatalog() async -> [ExerciseCatalogDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("exercise_catalog", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "muscle_group.asc,name.asc")
        ])) ?? []
    }

    func fetchFoodCatalog() async -> [FoodCatalogDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("food_catalog", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "category.asc,name.asc")
        ])) ?? []
    }

    func fetchMealTemplates() async -> [MealTemplateDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("meal_templates", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "meal_type.asc,name.asc")
        ])) ?? []
    }

    func fetchWorkoutTemplates() async -> [WorkoutTemplateDTO] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        return (try? await supabase.select("workout_templates", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "level.asc,name.asc")
        ])) ?? []
    }
}

@MainActor
final class SavedMealService {
    private let database: MockDatabase
    private let supabase: SupabaseManager

    init(database: MockDatabase, supabase: SupabaseManager) {
        self.database = database
        self.supabase = supabase
    }

    func fetchSavedMeals(for trainerID: UUID) async -> [SavedMeal] {
        guard AppConfiguration.isSupabaseConfigured else {
            return database.savedMeals.filter { $0.trainerID == trainerID }.sorted { $0.name < $1.name }
        }
        let rows: [SavedMealDTO] = (try? await supabase.select("saved_meals", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "order", value: "name.asc")
        ])) ?? []
        var meals: [SavedMeal] = []
        for dto in rows {
            let mealID = dto.id ?? UUID()
            let foods: [SavedMealFoodDTO] = (try? await supabase.select("saved_meal_foods", queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "saved_meal_id", value: "eq.\(mealID.uuidString)")
            ])) ?? []
            meals.append(SupabaseMapper.savedMeal(from: dto, foods: foods))
        }
        return meals
    }

    func createSavedMeal(_ meal: SavedMeal) async -> SavedMeal {
        guard AppConfiguration.isSupabaseConfigured else {
            database.savedMeals.append(meal)
            return meal
        }
        let created: [SavedMealDTO] = (try? await supabase.insert("saved_meals", value: SupabaseMapper.savedMealDTO(from: meal))) ?? []
        let mealID = created.first?.id ?? meal.id
        for food in meal.foods {
            let _: [SavedMealFoodDTO]? = try? await supabase.insert("saved_meal_foods", value: SupabaseMapper.savedMealFoodDTO(from: food, savedMealId: mealID))
        }
        return meal
    }

    func updateSavedMeal(_ meal: SavedMeal) async {
        guard AppConfiguration.isSupabaseConfigured else {
            if let index = database.savedMeals.firstIndex(where: { $0.id == meal.id }) {
                database.savedMeals[index] = meal
            }
            return
        }
        let _: [SavedMealDTO]? = try? await supabase.update("saved_meals", filters: [
            URLQueryItem(name: "id", value: "eq.\(meal.id.uuidString)")
        ], value: SupabaseMapper.savedMealDTO(from: meal))
        try? await supabase.delete("saved_meal_foods", filters: [URLQueryItem(name: "saved_meal_id", value: "eq.\(meal.id.uuidString)")])
        for food in meal.foods {
            let _: [SavedMealFoodDTO]? = try? await supabase.insert("saved_meal_foods", value: SupabaseMapper.savedMealFoodDTO(from: food, savedMealId: meal.id))
        }
    }

    func deleteSavedMeal(_ meal: SavedMeal) async {
        guard AppConfiguration.isSupabaseConfigured else {
            database.savedMeals.removeAll { $0.id == meal.id }
            return
        }
        try? await supabase.delete("saved_meals", filters: [URLQueryItem(name: "id", value: "eq.\(meal.id.uuidString)")])
    }
}

// MARK: - TrainerNotesService

@MainActor
final class TrainerNotesService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) { self.supabase = supabase }

    func fetchNotes(for trainerID: UUID) async -> [TrainerPersonalNote] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        let rows: [TrainerPersonalNoteDTO] = (try? await supabase.select("trainer_personal_notes", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "trainer_id", value: "eq.\(trainerID.uuidString)"),
            URLQueryItem(name: "status", value: "neq.archived"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])) ?? []
        return rows.map(SupabaseMapper.trainerPersonalNote)
    }

    func fetchDashboardNotes(for trainerID: UUID) async -> [TrainerPersonalNote] {
        let all = await fetchNotes(for: trainerID)
        let filtered = all.filter { note in
            guard !note.isCompleted else { return false }
            if note.isHighPriority { return true }
            if note.isForToday { return true }
            if note.noteDate == nil && note.source == .payment { return true }
            return false
        }
        let sorted = filtered.sorted { a, b in
            if a.priority.sortOrder != b.priority.sortOrder { return a.priority.sortOrder > b.priority.sortOrder }
            return a.createdAt > b.createdAt
        }
        return Array(sorted.prefix(5))
    }

    func createNote(_ note: TrainerPersonalNote) async -> TrainerPersonalNote {
        guard AppConfiguration.isSupabaseConfigured else { return note }
        let rows: [TrainerPersonalNoteDTO] = (try? await supabase.insert("trainer_personal_notes", value: SupabaseMapper.trainerPersonalNoteDTO(from: note))) ?? []
        return rows.first.map(SupabaseMapper.trainerPersonalNote) ?? note
    }

    func updateNote(_ note: TrainerPersonalNote) async {
        guard AppConfiguration.isSupabaseConfigured else { return }
        let _: [TrainerPersonalNoteDTO]? = try? await supabase.update("trainer_personal_notes", filters: [
            URLQueryItem(name: "id", value: "eq.\(note.id.uuidString)")
        ], value: SupabaseMapper.trainerPersonalNoteDTO(from: note))
    }

    func completeNote(_ note: TrainerPersonalNote) async {
        var n = note
        n.status = .completed
        n.completedAt = Date()
        await updateNote(n)
    }

    func deleteNote(_ note: TrainerPersonalNote) async {
        guard AppConfiguration.isSupabaseConfigured else { return }
        try? await supabase.delete("trainer_personal_notes", filters: [URLQueryItem(name: "id", value: "eq.\(note.id.uuidString)")])
    }
}

// MARK: - ClientPaymentService (client-side)

@MainActor
final class ClientPaymentService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) { self.supabase = supabase }

    func fetchPayments(forClient clientID: UUID) async -> [ClientPayment] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        let rows: [ClientPaymentDTO] = (try? await supabase.select("client_payments", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "due_date.asc")
        ])) ?? []
        return rows.map(SupabaseMapper.clientPayment)
    }

    func fetchPaymentPlan(forClient clientID: UUID) async -> ClientPaymentPlan? {
        guard AppConfiguration.isSupabaseConfigured else { return nil }
        let rows: [ClientPaymentPlanDTO] = (try? await supabase.select("client_payment_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "limit", value: "1")
        ])) ?? []
        return rows.first.map(SupabaseMapper.clientPaymentPlan)
    }

    func markPaymentAsPaidByClient(_ payment: ClientPayment) async -> ClientPayment {
        guard AppConfiguration.isSupabaseConfigured else { return payment }
        var updated = payment
        updated.status = .paidByClient
        updated.paidByClientAt = Date()
        let rows: [ClientPaymentDTO] = (try? await supabase.update("client_payments", filters: [
            URLQueryItem(name: "id", value: "eq.\(payment.id.uuidString)")
        ], value: SupabaseMapper.clientPaymentDTO(from: updated))) ?? []
        return rows.first.map(SupabaseMapper.clientPayment) ?? updated
    }
}

// MARK: - TrainerClientPaymentService (trainer-side)

@MainActor
final class TrainerClientPaymentService {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) { self.supabase = supabase }

    func fetchPaymentPlan(forClient clientID: UUID) async -> ClientPaymentPlan? {
        guard AppConfiguration.isSupabaseConfigured else { return nil }
        let rows: [ClientPaymentPlanDTO] = (try? await supabase.select("client_payment_plans", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "limit", value: "1")
        ])) ?? []
        return rows.first.map(SupabaseMapper.clientPaymentPlan)
    }

    func fetchPayments(forClient clientID: UUID) async -> [ClientPayment] {
        guard AppConfiguration.isSupabaseConfigured else { return [] }
        let rows: [ClientPaymentDTO] = (try? await supabase.select("client_payments", queryItems: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientID.uuidString)"),
            URLQueryItem(name: "order", value: "due_date.desc")
        ])) ?? []
        return rows.map(SupabaseMapper.clientPayment)
    }

    func createOrUpdatePaymentPlan(_ plan: ClientPaymentPlan) async -> ClientPaymentPlan {
        guard AppConfiguration.isSupabaseConfigured else { return plan }
        let existing = await fetchPaymentPlan(forClient: plan.clientID)
        if let ex = existing {
            var updated = plan
            updated.id = ex.id
            let rows: [ClientPaymentPlanDTO] = (try? await supabase.update("client_payment_plans", filters: [
                URLQueryItem(name: "id", value: "eq.\(ex.id.uuidString)")
            ], value: SupabaseMapper.clientPaymentPlanDTO(from: updated))) ?? []
            return rows.first.map(SupabaseMapper.clientPaymentPlan) ?? updated
        } else {
            let rows: [ClientPaymentPlanDTO] = (try? await supabase.insert("client_payment_plans", value: SupabaseMapper.clientPaymentPlanDTO(from: plan))) ?? []
            let saved = rows.first.map(SupabaseMapper.clientPaymentPlan) ?? plan
            await generateUpcomingPayments(for: saved)
            return saved
        }
    }

    func generateUpcomingPayments(for plan: ClientPaymentPlan) async {
        guard AppConfiguration.isSupabaseConfigured else { return }
        let existing = await fetchPayments(forClient: plan.clientID)
        let future = existing.filter { $0.dueDate >= Calendar.current.startOfDay(for: Date()) && $0.status != .cancelled }
        guard future.isEmpty else { return }

        var base = plan.startDate
        let today = Calendar.current.startOfDay(for: Date())
        while base < today {
            base = Calendar.current.date(byAdding: .month, value: plan.frequency.months, to: base) ?? base
        }

        for i in 0..<3 {
            guard let dueDate = Calendar.current.date(byAdding: .month, value: plan.frequency.months * i, to: base) else { continue }
            let periodEnd = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
            let periodStart = Calendar.current.date(byAdding: .month, value: -plan.frequency.months, to: dueDate) ?? dueDate
            let dto = ClientPaymentDTO(
                id: nil, trainerId: plan.trainerID, clientId: plan.clientID,
                paymentPlanId: plan.id, amount: plan.amount, currency: plan.currency,
                periodStart: SupabaseMapper.formatDate(periodStart),
                periodEnd: SupabaseMapper.formatDate(periodEnd),
                dueDate: SupabaseMapper.formatDate(dueDate),
                status: "due", paidByClientAt: nil,
                trainerConfirmedAt: nil, invoiceNoteCreatedAt: nil,
                createdAt: nil, updatedAt: nil
            )
            let _: [ClientPaymentDTO]? = try? await supabase.insert("client_payments", value: dto)
        }
    }

    func confirmPayment(_ payment: ClientPayment) async {
        guard AppConfiguration.isSupabaseConfigured else { return }
        var updated = payment
        updated.status = .confirmed
        updated.trainerConfirmedAt = Date()
        let _: [ClientPaymentDTO]? = try? await supabase.update("client_payments", filters: [
            URLQueryItem(name: "id", value: "eq.\(payment.id.uuidString)")
        ], value: SupabaseMapper.clientPaymentDTO(from: updated))
    }
}
