import Foundation
import Combine

@MainActor
final class TrainerDashboardViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var appointments: [Appointment] = []
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var progressEntries: [ProgressEntry] = []
    @Published var insights: [TrainerClientInsight] = []
    @Published var isLoadingInsights = false

    private let trainer: Trainer
    private let services: AppServices

    init(trainer: Trainer, services: AppServices) {
        self.trainer = trainer
        self.services = services
    }

    func load() {
        Task<Void, Never>(priority: nil) {
            clients = await services.clientService.fetchClients(for: trainer.id)
            appointments = await services.appointmentService.fetchAppointments(forTrainer: trainer.id)
            workoutPlans = await services.workoutService.fetchWorkoutPlans(for: trainer.id)
            progressEntries = services.database.progressEntries
            isLoadingInsights = true
            insights = await services.trainerInsightsService.fetchClientsNeedingAttention(
                trainerID: trainer.id,
                clients: clients,
                progressEntries: progressEntries
            )
            isLoadingInsights = false
        }
    }

    var appointmentsToday: Int {
        appointments.filter { Calendar.current.isDateInToday($0.startTime) }.count
    }

    var newClientsThisMonth: Int {
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        return clients.filter {
            Calendar.current.component(.month, from: $0.joinedAt) == month &&
            Calendar.current.component(.year, from: $0.joinedAt) == year
        }.count
    }

    var activePlans: Int {
        workoutPlans.filter { $0.status == .active }.count
    }
}

@MainActor
final class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var searchText = ""

    private let trainer: Trainer
    private let clientService: ClientService

    init(trainer: Trainer, clientService: ClientService) {
        self.trainer = trainer
        self.clientService = clientService
    }

    var filteredClients: [Client] {
        guard !searchText.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.goal.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() {
        Task<Void, Never>(priority: nil) { clients = await clientService.fetchClients(for: trainer.id) }
    }

    func makeEmptyClient() -> Client {
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
            accessCode: clientService.generateUniqueAccessCode(),
            joinedAt: Date(),
            trainerNotes: ""
        )
    }

    func save(_ client: Client) {
        Task<Void, Never>(priority: nil) {
            if clients.contains(where: { $0.id == client.id }) {
                _ = try? await clientService.updateClient(client)
            } else {
                _ = await clientService.createClient(client)
            }
            load()
        }
    }

    func delete(_ client: Client) {
        Task<Void, Never>(priority: nil) {
            await clientService.deleteClient(client)
            load()
        }
    }
}

@MainActor
final class AppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var selectedDate = Date()

    private let trainer: Trainer
    private let service: AppointmentService

    init(trainer: Trainer, service: AppointmentService) {
        self.trainer = trainer
        self.service = service
    }

    var appointmentsForSelectedDate: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    var futureAppointments: [Appointment] {
        appointments.filter { $0.startTime >= Date() }
    }

    func weekDates() -> [Date] {
        (-3...10).map { .daysFromNow($0) }
    }

    func load() {
        Task<Void, Never>(priority: nil) { appointments = await service.fetchAppointments(forTrainer: trainer.id) }
    }

    func save(_ appointment: Appointment) {
        Task<Void, Never>(priority: nil) {
            if appointments.contains(where: { $0.id == appointment.id }) {
                _ = try? await service.updateAppointment(appointment)
            } else {
                _ = await service.createAppointment(appointment)
            }
            load()
        }
    }

    func delete(_ appointment: Appointment) {
        Task<Void, Never>(priority: nil) {
            await service.deleteAppointment(appointment)
            load()
        }
    }
}

@MainActor
final class MachinesViewModel: ObservableObject {
    @Published var machines: [Machine] = []
    @Published var selectedGroup: MuscleGroup?

    private let trainer: Trainer
    private let service: MachineService

    init(trainer: Trainer, service: MachineService) {
        self.trainer = trainer
        self.service = service
    }

    var filteredMachines: [Machine] {
        guard let selectedGroup else { return machines }
        return machines.filter { $0.muscleGroup == selectedGroup }
    }

    func makeEmptyMachine() -> Machine {
        Machine(id: UUID(), trainerID: trainer.id, name: "", muscleGroup: .fullBody, description: "", usageNotes: "", imageName: nil, isAvailable: true)
    }

    func load() {
        Task<Void, Never>(priority: nil) { machines = await service.fetchMachines(for: trainer.id) }
    }

    func save(_ machine: Machine) {
        Task<Void, Never>(priority: nil) {
            if machines.contains(where: { $0.id == machine.id }) {
                _ = try? await service.updateMachine(machine)
            } else {
                _ = await service.createMachine(machine)
            }
            load()
        }
    }

    func delete(_ machine: Machine) {
        Task<Void, Never>(priority: nil) {
            await service.deleteMachine(machine)
            load()
        }
    }
}

@MainActor
final class WorkoutPlansViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []

    private let trainer: Trainer
    private let service: WorkoutService

    init(trainer: Trainer, service: WorkoutService) {
        self.trainer = trainer
        self.service = service
    }

    func load() {
        Task<Void, Never>(priority: nil) { plans = await service.fetchWorkoutPlans(for: trainer.id) }
    }

    func createTemplatePlan(client: Client, name: String, goal: String) {
        let plan = WorkoutPlan(
            id: UUID(),
            trainerID: trainer.id,
            clientID: client.id,
            name: name,
            goal: goal,
            createdAt: Date(),
            startDate: Date(),
            endDate: .daysFromNow(28),
            status: .active,
            days: [
                WorkoutDay(id: UUID(), title: "Lower body", dayIndex: 1, exercises: [
                    Exercise(id: UUID(), name: "Leg press", machineID: nil, muscleGroup: .legs, sets: 4, reps: "10", restSeconds: 90, recommendedLoad: "RPE 8", technicalNotes: "Controllo del range completo.", order: 1),
                    Exercise(id: UUID(), name: "Affondi camminati", machineID: nil, muscleGroup: .glutes, sets: 3, reps: "12 per lato", restSeconds: 75, recommendedLoad: "Manubri leggeri", technicalNotes: "Busto stabile.", order: 2)
                ]),
                WorkoutDay(id: UUID(), title: "Upper body", dayIndex: 2, exercises: [
                    Exercise(id: UUID(), name: "Lat machine", machineID: nil, muscleGroup: .back, sets: 4, reps: "10", restSeconds: 75, recommendedLoad: "Progressivo", technicalNotes: "Gomiti bassi.", order: 1),
                    Exercise(id: UUID(), name: "Chest press", machineID: nil, muscleGroup: .chest, sets: 3, reps: "10", restSeconds: 75, recommendedLoad: "Moderato", technicalNotes: "Scapole ferme.", order: 2)
                ])
            ]
        )

        Task<Void, Never>(priority: nil) {
            _ = await service.createWorkoutPlan(plan)
            load()
        }
    }

    func createPlan(_ plan: WorkoutPlan) {
        Task<Void, Never>(priority: nil) {
            _ = await service.createWorkoutPlan(plan)
            load()
        }
    }
}

@MainActor
final class NutritionPlansViewModel: ObservableObject {
    @Published var plans: [NutritionPlan] = []

    private let trainer: Trainer
    private let service: NutritionService

    init(trainer: Trainer, service: NutritionService) {
        self.trainer = trainer
        self.service = service
    }

    func load() {
        Task<Void, Never>(priority: nil) { plans = await service.fetchNutritionPlans(for: trainer.id) }
    }

    func createTemplatePlan(client: Client, calories: Int, targetWeight: Double) {
        let plan = NutritionPlan(
            id: UUID(),
            trainerID: trainer.id,
            clientID: client.id,
            dailyCalories: calories,
            proteinGrams: 140,
            carbohydrateGrams: 210,
            fatGrams: 60,
            targetWeightKg: targetWeight,
            notes: "Piano generato come base. Personalizzare alimenti e note in base ad anamnesi e preferenze.",
            startDate: Date(),
            endDate: .daysFromNow(30),
            meals: [
                Meal(id: UUID(), name: "Colazione", time: .daysFromNow(0, hour: 7, minute: 30), foods: [MealFood(id: UUID(), name: "Yogurt greco", quantity: "170 g", notes: "")], notes: ""),
                Meal(id: UUID(), name: "Pranzo", time: .daysFromNow(0, hour: 13), foods: [MealFood(id: UUID(), name: "Riso e pollo", quantity: "90 g + 160 g", notes: "Peso riso a crudo")], notes: ""),
                Meal(id: UUID(), name: "Cena", time: .daysFromNow(0, hour: 20), foods: [MealFood(id: UUID(), name: "Pesce e patate", quantity: "150 g + 250 g", notes: "")], notes: "")
            ]
        )

        Task<Void, Never>(priority: nil) {
            _ = await service.createNutritionPlan(plan)
            load()
        }
    }

    func createPlan(_ plan: NutritionPlan) {
        Task<Void, Never>(priority: nil) {
            _ = await service.createNutritionPlan(plan)
            load()
        }
    }
}
