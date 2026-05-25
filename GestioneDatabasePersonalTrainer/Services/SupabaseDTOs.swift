import Foundation

struct ProfileDTO: Codable {
    var id: UUID
    var role: String
    var email: String
    var firstName: String
    var lastName: String
    var avatarUrl: String?
    var phone: String?
}

struct TrainerDTO: Codable {
    var id: UUID
    var userId: UUID
    var businessName: String
    var vatNumber: String?
    var phone: String?
    var bio: String?
    var maxClients: Int?
    var status: String
}

struct ClientDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var userId: UUID?
    var status: String
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var birthDate: String?
    var heightCm: Double?
    var initialWeightKg: Double?
    var currentWeightKg: Double?
    var goal: String?
    var accessCode: String?
    var isRegistered: Bool?
    var notes: String?
    var joinedAt: String?
}

struct AppointmentDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var title: String
    var sessionType: String
    var startsAt: String
    var endsAt: String
    var status: String
    var notes: String?
}

struct MachineDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var name: String
    var muscleGroup: String
    var description: String?
    var usageNotes: String?
    var imageUrl: String?
    var isAvailable: Bool
}

struct WorkoutPlanDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var name: String
    var goal: String?
    var startsAt: String?
    var endsAt: String?
    var status: String
    var published: Bool? = nil
}

struct NutritionPlanDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var name: String
    var dailyCalories: Int
    var proteinsG: Int?
    var carbsG: Int?
    var fatsG: Int?
    var targetWeightKg: Double?
    var notes: String?
    var startsAt: String?
    var endsAt: String?
    var status: String
    var published: Bool? = nil
}

struct ExerciseWeightHistoryDTO: Codable, Identifiable, Hashable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var exerciseId: UUID
    var sessionDate: String?
    var weightKg: Double
    var effectiveFromSessionId: UUID?
    var createdByUserId: UUID?
}

struct ProgressEntryDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var entryDate: String
    var weightKg: Double?
    var waistCm: Double?
    var chestCm: Double?
    var armCm: Double?
    var legCm: Double?
    var notes: String?
    var createdByUserId: UUID
}

struct DailyCheckInDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var checkinDate: String
    var energyLevel: Int
    var sleepQuality: Int
    var hungerLevel: Int
    var stressLevel: Int
    var muscleSoreness: Bool
    var dietAdherence: String
    var workoutCompleted: Bool
    var notes: String?
    var createdAt: String?
    var updatedAt: String?
}

struct DailyGoalDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var goalDate: String
    var goalType: String
    var title: String
    var targetValue: Double?
    var currentValue: Double?
    var unit: String?
    var status: String
    var createdAt: String?
    var updatedAt: String?
}

struct ActivitySummaryDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var summaryDate: String
    var steps: Int?
    var stepsGoal: Int?
    var source: String
    var createdAt: String?
    var updatedAt: String?
}

struct StreakDTO: Codable {
    var id: UUID?
    var trainerId: UUID
    var clientId: UUID
    var streakType: String
    var currentCount: Int
    var bestCount: Int
    var lastCompletedAt: String?
    var createdAt: String?
    var updatedAt: String?
}

struct MuscleGroupDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var slug: String
    var description: String?
    var sortOrder: Int
}

struct MachineCatalogDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var muscleGroup: String
    var category: String?
    var description: String?
    var usageNotes: String?
    var difficulty: String?
    var isBodyweight: Bool
}

struct ExerciseCatalogDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var muscleGroup: String
    var secondaryMuscles: [String]?
    var equipment: String?
    var difficulty: String?
    var movementType: String?
    var description: String?
    var executionNotes: String?
    var commonMistakes: String?
    var defaultSets: Int?
    var defaultReps: String?
    var defaultRestSeconds: Int?
}

struct FoodCatalogDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var category: String
    var caloriesPer100g: Int?
    var proteinsPer100g: Double?
    var carbsPer100g: Double?
    var fatsPer100g: Double?
    var unit: String
    var notes: String?
}

struct MealTemplateDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var mealType: String
    var goal: String?
    var description: String?
}

struct WorkoutTemplateDTO: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var goal: String?
    var level: String?
    var daysPerWeek: Int?
    var description: String?
}

struct RPCTrainerInviteParams: Codable {
    let pTrainerId: UUID
    let pClientId: UUID
}

struct RPCRedeemInviteParams: Codable {
    let pCode: String
    let pEmail: String
}

struct RPCCreateTrainerParams: Codable {
    let pPlanSlug: String
    let pFirstName: String
    let pLastName: String
    let pBusinessName: String
    let pPhone: String?
}

enum SupabaseMapper {
    static let iso = ISO8601DateFormatter()

    static func trainer(from dto: TrainerDTO, profile: ProfileDTO? = nil) -> Trainer {
        Trainer(
            id: dto.id,
            userID: dto.userId,
            firstName: profile?.firstName ?? "",
            lastName: profile?.lastName ?? "",
            email: profile?.email ?? "",
            studioName: dto.businessName,
            subscriptionTier: .pro
        )
    }

    static func client(from dto: ClientDTO) -> Client {
        let id = dto.id ?? UUID()
        let email = dto.email ?? ""
        let phone = dto.phone ?? ""
        let birthDate = parseDate(dto.birthDate) ?? Date()
        let heightCm = dto.heightCm ?? 0
        let initialWeightKg = dto.initialWeightKg ?? 0
        let currentWeightKg = dto.currentWeightKg ?? initialWeightKg
        let goal = dto.goal ?? ""
        let accessCode = dto.accessCode ?? ""
        let isRegistered = dto.isRegistered ?? (dto.userId != nil)
        let joinedAt = parseDateTime(dto.joinedAt) ?? Date()
        let trainerNotes = dto.notes ?? ""

        Client(
            id: id,
            trainerID: dto.trainerId,
            firstName: dto.firstName,
            lastName: dto.lastName,
            email: email,
            phone: phone,
            birthDate: birthDate,
            heightCm: heightCm,
            initialWeightKg: initialWeightKg,
            currentWeightKg: currentWeightKg,
            goal: goal,
            accessCode: accessCode,
            isRegistered: isRegistered,
            joinedAt: joinedAt,
            trainerNotes: trainerNotes
        )
    }

    static func clientDTO(from client: Client) -> ClientDTO {
        ClientDTO(
            id: client.id,
            trainerId: client.trainerID,
            userId: nil,
            status: "pending_registration",
            firstName: client.firstName,
            lastName: client.lastName,
            email: client.email.isEmpty ? nil : client.email,
            phone: client.phone.isEmpty ? nil : client.phone,
            birthDate: formatDate(client.birthDate),
            heightCm: client.heightCm,
            initialWeightKg: client.initialWeightKg,
            currentWeightKg: client.currentWeightKg,
            goal: client.goal,
            accessCode: client.accessCode.isEmpty ? nil : client.accessCode,
            isRegistered: client.isRegistered,
            notes: client.trainerNotes,
            joinedAt: nil
        )
    }

    static func appointment(from dto: AppointmentDTO) -> Appointment {
        let start = parseDateTime(dto.startsAt) ?? Date()
        let end = parseDateTime(dto.endsAt) ?? start.addingTimeInterval(3600)
        return Appointment(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            clientID: dto.clientId,
            date: start,
            startTime: start,
            endTime: end,
            sessionType: SessionType.allCases.first { $0.rawValue == dto.sessionType } ?? .workout,
            notes: dto.notes ?? "",
            status: appointmentStatus(from: dto.status)
        )
    }

    static func appointmentDTO(from appointment: Appointment) -> AppointmentDTO {
        AppointmentDTO(
            id: appointment.id,
            trainerId: appointment.trainerID,
            clientId: appointment.clientID,
            title: appointment.sessionType.rawValue,
            sessionType: appointment.sessionType.rawValue,
            startsAt: iso.string(from: appointment.startTime),
            endsAt: iso.string(from: appointment.endTime),
            status: appointment.status.rawValue.lowercased(),
            notes: appointment.notes
        )
    }

    static func machine(from dto: MachineDTO) -> Machine {
        Machine(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            name: dto.name,
            muscleGroup: MuscleGroup.allCases.first { $0.rawValue == dto.muscleGroup } ?? .fullBody,
            description: dto.description ?? "",
            usageNotes: dto.usageNotes ?? "",
            imageName: dto.imageUrl,
            isAvailable: dto.isAvailable
        )
    }

    static func machineDTO(from machine: Machine) -> MachineDTO {
        MachineDTO(id: machine.id, trainerId: machine.trainerID, name: machine.name, muscleGroup: machine.muscleGroup.rawValue, description: machine.description, usageNotes: machine.usageNotes, imageUrl: machine.imageName, isAvailable: machine.isAvailable)
    }

    static func progress(from dto: ProgressEntryDTO) -> ProgressEntry {
        ProgressEntry(
            id: dto.id ?? UUID(),
            clientID: dto.clientId,
            date: parseDate(dto.entryDate) ?? Date(),
            weightKg: dto.weightKg ?? 0,
            waistCm: dto.waistCm ?? 0,
            chestCm: dto.chestCm ?? 0,
            armCm: dto.armCm ?? 0,
            legCm: dto.legCm ?? 0,
            frontPhotoName: nil,
            sidePhotoName: nil,
            backPhotoName: nil,
            notes: dto.notes ?? ""
        )
    }

    static func dailyCheckIn(from dto: DailyCheckInDTO) -> DailyCheckIn {
        DailyCheckIn(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            clientID: dto.clientId,
            checkinDate: parseDate(dto.checkinDate) ?? Date(),
            energyLevel: dto.energyLevel,
            sleepQuality: dto.sleepQuality,
            hungerLevel: dto.hungerLevel,
            stressLevel: dto.stressLevel,
            muscleSoreness: dto.muscleSoreness,
            dietAdherence: DietAdherence(rawValue: dto.dietAdherence) ?? .partial,
            workoutCompleted: dto.workoutCompleted,
            notes: dto.notes ?? "",
            createdAt: parseDateTime(dto.createdAt),
            updatedAt: parseDateTime(dto.updatedAt)
        )
    }

    static func dailyCheckInDTO(from checkIn: DailyCheckIn) -> DailyCheckInDTO {
        DailyCheckInDTO(
            id: checkIn.id,
            trainerId: checkIn.trainerID,
            clientId: checkIn.clientID,
            checkinDate: formatDate(checkIn.checkinDate),
            energyLevel: checkIn.energyLevel,
            sleepQuality: checkIn.sleepQuality,
            hungerLevel: checkIn.hungerLevel,
            stressLevel: checkIn.stressLevel,
            muscleSoreness: checkIn.muscleSoreness,
            dietAdherence: checkIn.dietAdherence.rawValue,
            workoutCompleted: checkIn.workoutCompleted,
            notes: checkIn.notes.isEmpty ? nil : checkIn.notes,
            createdAt: nil,
            updatedAt: nil
        )
    }

    static func dailyGoal(from dto: DailyGoalDTO) -> DailyGoal {
        let goalType = DailyGoalType(rawValue: dto.goalType) ?? .checkIn
        return DailyGoal(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            clientID: dto.clientId,
            goalDate: parseDate(dto.goalDate) ?? Date(),
            title: dto.title,
            description: dailyGoalDescription(for: goalType),
            goalType: goalType,
            targetValue: dto.targetValue,
            currentValue: dto.currentValue,
            unit: dto.unit,
            isCompleted: dto.status == "completed",
            iconName: dailyGoalIcon(for: goalType),
            color: dailyGoalColor(for: goalType)
        )
    }

    static func dailyGoalDTO(from goal: DailyGoal) -> DailyGoalDTO {
        DailyGoalDTO(
            id: goal.id,
            trainerId: goal.trainerID,
            clientId: goal.clientID,
            goalDate: formatDate(goal.goalDate),
            goalType: goal.goalType.rawValue,
            title: goal.title,
            targetValue: goal.targetValue,
            currentValue: goal.currentValue,
            unit: goal.unit,
            status: goal.isCompleted ? "completed" : "pending",
            createdAt: nil,
            updatedAt: nil
        )
    }

    static func activitySummary(from dto: ActivitySummaryDTO) -> DailyStepSummary {
        DailyStepSummary(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            clientID: dto.clientId,
            summaryDate: parseDate(dto.summaryDate) ?? Date(),
            steps: dto.steps ?? 0,
            stepsGoal: dto.stepsGoal ?? 10_000,
            source: dto.source,
            createdAt: parseDateTime(dto.createdAt),
            updatedAt: parseDateTime(dto.updatedAt)
        )
    }

    static func activitySummaryDTO(from summary: DailyStepSummary) -> ActivitySummaryDTO {
        ActivitySummaryDTO(
            id: summary.id,
            trainerId: summary.trainerID,
            clientId: summary.clientID,
            summaryDate: formatDate(summary.summaryDate),
            steps: summary.steps,
            stepsGoal: summary.stepsGoal,
            source: summary.source,
            createdAt: nil,
            updatedAt: nil
        )
    }

    static func streak(from dto: StreakDTO) -> Streak {
        Streak(
            id: dto.id ?? UUID(),
            trainerID: dto.trainerId,
            clientID: dto.clientId,
            streakType: StreakType(rawValue: dto.streakType) ?? .checkIn,
            currentCount: dto.currentCount,
            bestCount: dto.bestCount,
            lastCompletedAt: parseDate(dto.lastCompletedAt),
            createdAt: parseDateTime(dto.createdAt),
            updatedAt: parseDateTime(dto.updatedAt)
        )
    }

    static func streakDTO(from streak: Streak) -> StreakDTO {
        StreakDTO(
            id: streak.id,
            trainerId: streak.trainerID,
            clientId: streak.clientID,
            streakType: streak.streakType.rawValue,
            currentCount: streak.currentCount,
            bestCount: streak.bestCount,
            lastCompletedAt: streak.lastCompletedAt.map(formatDate),
            createdAt: nil,
            updatedAt: nil
        )
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private static func parseDateTime(_ value: String?) -> Date? {
        guard let value else { return nil }
        return iso.date(from: value)
    }

    private static func appointmentStatus(from value: String) -> AppointmentStatus {
        switch value {
        case "completed": return .completed
        case "cancelled": return .cancelled
        default: return .scheduled
        }
    }

    private static func dailyGoalDescription(for type: DailyGoalType) -> String {
        switch type {
        case .steps: return "Raggiungi il movimento previsto per oggi."
        case .workout: return "Completa la scheda assegnata dal trainer."
        case .checkIn: return "Aggiorna energia, sonno e andamento della giornata."
        case .weight: return "Aggiorna il peso quando previsto."
        case .progressPhoto: return "Carica una foto progresso quando prevista."
        }
    }

    private static func dailyGoalIcon(for type: DailyGoalType) -> String {
        switch type {
        case .steps: return "figure.walk"
        case .workout: return "figure.run"
        case .checkIn: return "checklist"
        case .weight: return "scalemass"
        case .progressPhoto: return "camera"
        }
    }

    private static func dailyGoalColor(for type: DailyGoalType) -> String {
        switch type {
        case .steps, .checkIn: return "success"
        case .workout: return "primary"
        case .weight: return "info"
        case .progressPhoto: return "warning"
        }
    }
}
