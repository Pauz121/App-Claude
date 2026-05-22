import Foundation
import Combine

@MainActor
final class DailyCheckInViewModel: ObservableObject {
    @Published var energyLevel = 3
    @Published var sleepQuality = 3
    @Published var hungerLevel = 3
    @Published var stressLevel = 3
    @Published var muscleSoreness = false
    @Published var dietAdherence: DietAdherence = .partial
    @Published var workoutCompleted = false
    @Published var notes = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let client: Client
    private let checkInService: DailyCheckInService
    private let streakService: StreakService
    private let onSaved: (DailyCheckIn) -> Void

    init(client: Client, existing: DailyCheckIn?, checkInService: DailyCheckInService, streakService: StreakService, onSaved: @escaping (DailyCheckIn) -> Void) {
        self.client = client
        self.checkInService = checkInService
        self.streakService = streakService
        self.onSaved = onSaved

        if let existing {
            energyLevel = existing.energyLevel
            sleepQuality = existing.sleepQuality
            hungerLevel = existing.hungerLevel
            stressLevel = existing.stressLevel
            muscleSoreness = existing.muscleSoreness
            dietAdherence = existing.dietAdherence
            workoutCompleted = existing.workoutCompleted
            notes = existing.notes
        }
    }

    func save() {
        isSaving = true
        errorMessage = nil

        let checkIn = DailyCheckIn(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            checkinDate: Date(),
            energyLevel: energyLevel,
            sleepQuality: sleepQuality,
            hungerLevel: hungerLevel,
            stressLevel: stressLevel,
            muscleSoreness: muscleSoreness,
            dietAdherence: dietAdherence,
            workoutCompleted: workoutCompleted,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: nil,
            updatedAt: nil
        )

        Task<Void, Never>(priority: nil) {
            do {
                let saved = try await checkInService.createOrUpdateTodayCheckIn(checkIn)
                _ = await streakService.updateCheckInStreak(trainerID: client.trainerID, clientID: client.id)
                isSaving = false
                onSaved(saved)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
final class TrainerInsightsViewModel: ObservableObject {
    @Published var insights: [TrainerClientInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let trainer: Trainer
    private let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
    }

    func load(clients: [Client], progressEntries: [ProgressEntry]) {
        isLoading = true
        errorMessage = nil
        Task<Void, Never>(priority: nil) {
            insights = await services.trainerInsightsService.fetchClientsNeedingAttention(
                trainerID: trainer.id,
                clients: clients,
                progressEntries: progressEntries
            )
            isLoading = false
        }
    }
}
