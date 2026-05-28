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

struct SavedMealFood: Identifiable, Codable, Hashable {
    var id: UUID
    var foodCatalogID: UUID?
    var name: String
    var quantityGrams: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbPer100g: Double
    var fatPer100g: Double

    var kcal: Double { caloriesPer100g * quantityGrams / 100 }
    var proteinGrams: Double { proteinPer100g * quantityGrams / 100 }
    var carbGrams: Double { carbPer100g * quantityGrams / 100 }
    var fatGrams: Double { fatPer100g * quantityGrams / 100 }
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
    var foods: [SavedMealFood] = []

    var displayProtein: Double { foods.isEmpty ? proteinGrams : foods.reduce(0) { $0 + $1.proteinGrams } }
    var displayCarb: Double { foods.isEmpty ? carbGrams : foods.reduce(0) { $0 + $1.carbGrams } }
    var displayFat: Double { foods.isEmpty ? fatGrams : foods.reduce(0) { $0 + $1.fatGrams } }
    var kcal: Double { foods.isEmpty ? proteinGrams * 4 + carbGrams * 4 + fatGrams * 9 : foods.reduce(0) { $0 + $1.kcal } }
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

// MARK: - Trainer Personal Notes

enum NotePriority: String, Codable, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Bassa"
        case .medium: return "Media"
        case .high: return "Alta"
        case .critical: return "Massima"
        }
    }
    var sortOrder: Int {
        switch self { case .low: return 0; case .medium: return 1; case .high: return 2; case .critical: return 3 }
    }
}

enum NoteStatus: String, Codable, CaseIterable, Identifiable {
    case open = "open"
    case completed = "completed"
    case archived = "archived"
    var id: String { rawValue }
    var label: String {
        switch self { case .open: return "Aperta"; case .completed: return "Completata"; case .archived: return "Archiviata" }
    }
}

enum NoteSource: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"
    case payment = "payment"
    case system = "system"
    var id: String { rawValue }
}

struct TrainerPersonalNote: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var title: String
    var body: String
    var noteDate: Date?
    var noteTime: String?
    var priority: NotePriority
    var status: NoteStatus
    var source: NoteSource
    var relatedClientID: UUID?
    var relatedPaymentID: UUID?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    var isCompleted: Bool { status == .completed }
    var isForToday: Bool {
        guard let d = noteDate else { return false }
        return Calendar.current.isDateInToday(d)
    }
    var isHighPriority: Bool { priority == .high || priority == .critical }
}

// MARK: - Client Payments

enum PaymentFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly = "monthly"
    case bimonthly = "bimonthly"
    case quarterly = "quarterly"
    case semiannual = "semiannual"
    case annual = "annual"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .monthly: return "Mensile"
        case .bimonthly: return "Bimestrale"
        case .quarterly: return "Trimestrale"
        case .semiannual: return "Semestrale"
        case .annual: return "Annuale"
        }
    }
    var months: Int {
        switch self { case .monthly: return 1; case .bimonthly: return 2; case .quarterly: return 3; case .semiannual: return 6; case .annual: return 12 }
    }
}

enum PaymentPlanStatus: String, Codable, CaseIterable, Identifiable {
    case active = "active"
    case paused = "paused"
    case cancelled = "cancelled"
    var id: String { rawValue }
}

struct ClientPaymentPlan: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var frequency: PaymentFrequency
    var amount: Double
    var currency: String
    var startDate: Date
    var dueDay: Int?
    var notes: String
    var status: PaymentPlanStatus
    var createdAt: Date
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case due = "due"
    case paidByClient = "paid_by_client"
    case confirmed = "confirmed"
    case overdue = "overdue"
    case cancelled = "cancelled"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .due: return "Da pagare"
        case .paidByClient: return "Segnato come pagato"
        case .confirmed: return "Confermato"
        case .overdue: return "Scaduto"
        case .cancelled: return "Annullato"
        }
    }
}

struct ClientPayment: Identifiable, Codable, Hashable {
    var id: UUID
    var trainerID: UUID
    var clientID: UUID
    var paymentPlanID: UUID
    var amount: Double
    var currency: String
    var periodStart: Date?
    var periodEnd: Date?
    var dueDate: Date
    var status: PaymentStatus
    var paidByClientAt: Date?
    var trainerConfirmedAt: Date?
    var invoiceNoteCreatedAt: Date?
    var createdAt: Date
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
