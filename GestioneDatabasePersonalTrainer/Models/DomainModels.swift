import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case trainer
    case client

    var id: String { rawValue }
}

struct User: Identifiable, Codable, Hashable {
    var id: UUID
    var email: String
    var role: UserRole
    var displayName: String
}

struct Trainer: Identifiable, Codable, Hashable {
    var id: UUID
    var userID: UUID
    var firstName: String
    var lastName: String
    var email: String
    var studioName: String
    var subscriptionTier: SubscriptionTier

    var fullName: String { "\(firstName) \(lastName)" }
}

enum SubscriptionTier: String, Codable, CaseIterable, Identifiable {
    case free = "Free"
    case pro = "Pro"
    case studio = "Studio"

    var id: String { rawValue }
}

struct Client: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var birthDate: Date
    var heightCm: Double
    var initialWeightKg: Double
    var currentWeightKg: Double
    var goal: String
    var accessCode: String
    var isRegistered: Bool = false
    var joinedAt: Date
    var trainerNotes: String

    var fullName: String { "\(firstName) \(lastName)" }
}

struct Appointment: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var sessionType: SessionType
    var notes: String
    var status: AppointmentStatus
}

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case assessment = "Valutazione"
    case workout = "Allenamento"
    case nutrition = "Nutrizione"
    case checkin = "Check-in"
    case recovery = "Recupero"

    var id: String { rawValue }
}

enum AppointmentStatus: String, Codable, CaseIterable, Identifiable {
    case scheduled = "Programmato"
    case completed = "Completato"
    case cancelled = "Annullato"

    var id: String { rawValue }
}

struct Machine: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var description: String
    var usageNotes: String
    var imageName: String?
    var isAvailable: Bool
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Petto"
    case back = "Dorso"
    case shoulders = "Spalle"
    case biceps = "Bicipiti"
    case triceps = "Tricipiti"
    case legs = "Gambe"
    case glutes = "Glutei"
    case abs = "Addome"
    case cardio = "Cardio"
    case fullBody = "Full body"

    var id: String { rawValue }
}

struct WorkoutPlan: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var name: String
    var goal: String
    var createdAt: Date
    var startDate: Date
    var endDate: Date
    var status: PlanStatus
    var days: [WorkoutDay]
    var withTrainer: Bool = false
}

enum PlanStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Attiva"
    case archived = "Archiviata"

    var id: String { rawValue }
}

struct WorkoutDay: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var dayIndex: Int
    var exercises: [Exercise]
}

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var machineID: UUID?
    var muscleGroup: MuscleGroup
    var sets: Int
    var reps: String
    var restSeconds: Int
    var recommendedLoad: String
    var technicalNotes: String
    var order: Int
}

struct NutritionPlan: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var dailyCalories: Int
    var proteinGrams: Int
    var carbohydrateGrams: Int
    var fatGrams: Int
    var targetWeightKg: Double
    var notes: String
    var startDate: Date
    var endDate: Date
    var meals: [Meal]
}

struct Meal: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var time: Date
    var foods: [MealFood]
    var notes: String
    var dayIndex: Int = 0
}

struct MealFood: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var quantity: String
    var notes: String
    var proteinGrams: Double = 0
    var carbGrams: Double = 0
    var fatGrams: Double = 0

    var kcal: Double { proteinGrams * 4 + carbGrams * 4 + fatGrams * 9 }
}

struct ProgressEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var clientID: UUID
    var date: Date
    var weightKg: Double
    var waistCm: Double
    var chestCm: Double
    var armCm: Double
    var legCm: Double
    var frontPhotoName: String?
    var sidePhotoName: String?
    var backPhotoName: String?
    var notes: String
}

struct SavedMeal: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var name: String
    var description: String
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var notes: String
    var createdAt: Date

    var kcal: Double { proteinGrams * 4 + carbGrams * 4 + fatGrams * 9 }
}

enum DailyGoalType: String, Codable, CaseIterable, Identifiable {
    case steps
    case workout
    case checkIn = "check_in"
    case weight
    case progressPhoto = "progress_photo"

    var id: String { rawValue }
}

struct DailyGoal: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var goalDate: Date
    var title: String
    var description: String
    var goalType: DailyGoalType
    var targetValue: Double?
    var currentValue: Double?
    var unit: String?
    var isCompleted: Bool
    var iconName: String
    var color: String
}

struct DailyStepSummary: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var summaryDate: Date
    var steps: Int
    var stepsGoal: Int
    var source: String
    var createdAt: Date?
    var updatedAt: Date?

    var progress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepsGoal), 1)
    }
}

enum DietAdherence: String, Codable, CaseIterable, Identifiable {
    case yes
    case partial
    case no

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yes: return "Si"
        case .partial: return "Parziale"
        case .no: return "No"
        }
    }
}

struct DailyCheckIn: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var checkinDate: Date
    var energyLevel: Int
    var sleepQuality: Int
    var hungerLevel: Int
    var stressLevel: Int
    var muscleSoreness: Bool
    var dietAdherence: DietAdherence
    var workoutCompleted: Bool
    var notes: String
    var createdAt: Date?
    var updatedAt: Date?
}

enum StreakType: String, Codable, CaseIterable, Identifiable {
    case checkIn = "check_in"
    case steps
    case workoutWeek = "workout_week"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkIn: return "Check"
        case .steps: return "Passi"
        case .workoutWeek: return "Allenamenti"
        }
    }
}

struct Streak: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var streakType: StreakType
    var currentCount: Int
    var bestCount: Int
    var lastCompletedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
}

enum TrainerInsightType: String, Codable, Hashable {
    case missingCheckIn = "missing_check_in"
    case checkInCompleted = "check_in_completed"
    case stepsReached = "steps_reached"
    case lowActivity = "low_activity"
    case staleProgress = "stale_progress"
    case streak = "streak"
}

struct TrainerClientInsight: Identifiable, Codable, Hashable {
    var id: UUID
    var clientID: UUID?
    var clientName: String
    var title: String
    var message: String
    var type: TrainerInsightType
    var severity: InsightSeverity
    var iconName: String
}

enum InsightSeverity: String, Codable, Hashable {
    case info
    case success
    case warning
    case alert
}

struct AccessCode: Identifiable, Codable, Hashable {
    var id: UUID
    var code: String
    var trainerID: UUID
    var clientID: UUID
    var createdAt: Date
    var isActive: Bool
}

extension SessionType {
    var displayName: String {
        switch self {
        case .checkin: return "Check Studio"
        default: return rawValue
        }
    }
}

extension Date {
    static func daysFromNow(_ days: Int, hour: Int = 9, minute: Int = 0) -> Date {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let shiftedDay = Calendar.current.date(byAdding: .day, value: days, to: startOfToday) ?? startOfToday
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: shiftedDay) ?? shiftedDay
    }

    func formattedDay() -> String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    func formattedTime() -> String {
        formatted(.dateTime.hour().minute())
    }
}
