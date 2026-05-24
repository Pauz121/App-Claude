import SwiftUI
import UIKit

struct AddClientView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var client: Client
    @State private var selectedObjective: String
    let onSave: (Client) -> Void
    private let objectives = ["Dimagrimento", "Massa", "Ricomposizione", "Tonificazione", "Forza", "Altro"]

    init(client: Client, onSave: @escaping (Client) -> Void) {
        _client = State(initialValue: client)
        _selectedObjective = State(initialValue: client.goal.isEmpty ? "Dimagrimento" : client.goal)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(client.firstName.isEmpty ? "Nuovo cliente" : "Modifica cliente")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    SectionLabel(text: "Anagrafica")
                    field("Nome", text: $client.firstName)
                    field("Cognome", text: $client.lastName)
                    field("Numero di telefono", text: $client.phone, keyboard: .phonePad)
                    FitCard {
                        DatePicker("Data nascita", selection: $client.birthDate, displayedComponents: .date)
                            .font(DesignSystem.Typography.labelMD())
                            .tint(DesignSystem.Colors.indigo)
                    }

                    SectionLabel(text: "Dati fisici")
                    HStack(spacing: 10) {
                        numberField("Altezza", value: $client.heightCm, suffix: "cm")
                        numberField("Peso iniziale", value: $client.initialWeightKg, suffix: "kg")
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                        ForEach(objectives, id: \.self) { objective in
                            Button {
                                selectedObjective = objective
                                client.goal = objective
                            } label: {
                                Text(objective)
                                    .font(DesignSystem.Typography.labelMD())
                                    .foregroundStyle(selectedObjective == objective ? .white : DesignSystem.Colors.txtPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(selectedObjective == objective ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selectedObjective == objective ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SectionLabel(text: "Accesso cliente")
                    if client.isRegistered {
                        Text("✓ Cliente registrato")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.limeDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DesignSystem.Colors.limeBg)
                            .clipShape(Capsule())
                    } else {
                        FitCard {
                            HStack {
                                Text("Codice")
                                    .font(DesignSystem.Typography.bodyMD())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                Spacer()
                                Text(client.accessCode)
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(DesignSystem.Colors.limeDark)
                            }
                        }
                        Text("Il cliente usera questo codice per accedere alla sua app")
                            .font(DesignSystem.Typography.bodySM())
                            .italic()
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        Button {
                            UIPasteboard.general.string = client.accessCode
                        } label: {
                            Label("Copia codice", systemImage: "doc.on.doc")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.indigo)
                        }
                    }

                    SectionLabel(text: "Note trainer")
                    TextEditor(text: $client.trainerNotes)
                        .frame(minHeight: 110)
                        .padding(10)
                        .background(DesignSystem.Colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))

                    PrimaryButton(title: client.firstName.isEmpty ? "Crea cliente & invia codice" : "Salva modifiche") {
                        if client.goal.isEmpty {
                            client.goal = selectedObjective
                        }
                        onSave(client)
                        dismiss()
                    }
                    .disabled(client.firstName.isEmpty || client.lastName.isEmpty)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        if client.goal.isEmpty {
                            client.goal = selectedObjective
                        }
                        onSave(client)
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.indigo)
                    .disabled(client.firstName.isEmpty || client.lastName.isEmpty)
                }
            }
            .appScreen()
        }
    }

    private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        FitCard {
            TextField(title, text: text)
                .keyboardType(keyboard)
                .font(DesignSystem.Typography.bodyMD())
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
        }
    }

    private func numberField(_ title: String, value: Binding<Double>, suffix: String) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                HStack {
                    TextField(title, value: value, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.custom("Archivo-ExtraBold", size: 18))
                    Text(suffix)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
    }
}

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appointment: Appointment
    let clients: [Client]
    let onSave: (Appointment) -> Void

    init(trainer: Trainer, clients: [Client], appointment: Appointment? = nil, onSave: @escaping (Appointment) -> Void) {
        self.clients = clients
        let firstClientID = clients.first?.id ?? UUID()
        _appointment = State(initialValue: appointment ?? Appointment(
            id: UUID(),
            trainerID: trainer.id,
            clientID: firstClientID,
            date: Date(),
            startTime: .daysFromNow(0, hour: 10),
            endTime: .daysFromNow(0, hour: 11),
            sessionType: .workout,
            notes: "",
            status: .scheduled
        ))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    Picker("Cliente", selection: $appointment.clientID) {
                        ForEach(clients) { client in
                            Text(client.fullName).tag(client.id)
                        }
                    }
                }

                Section("Sessione") {
                    DatePicker("Inizio", selection: $appointment.startTime)
                    DatePicker("Fine", selection: $appointment.endTime)
                    Picker("Tipologia", selection: $appointment.sessionType) {
                        ForEach(SessionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Picker("Stato", selection: $appointment.status) {
                        ForEach(AppointmentStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Note") {
                    TextEditor(text: $appointment.notes)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle("Appuntamento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        appointment.date = appointment.startTime
                        onSave(appointment)
                        dismiss()
                    }
                    .disabled(clients.isEmpty)
                }
            }
        }
    }
}

struct AddMachineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var machine: Machine
    @State private var catalog: [MachineCatalogDTO] = []
    @State private var selectedCatalogID: UUID?
    let catalogService: CatalogService?
    let onSave: (Machine) -> Void

    init(machine: Machine, catalogService: CatalogService? = nil, onSave: @escaping (Machine) -> Void) {
        _machine = State(initialValue: machine)
        self.catalogService = catalogService
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                if !catalog.isEmpty {
                    Section("Catalogo globale") {
                        Picker("Scegli dal catalogo", selection: $selectedCatalogID) {
                            Text("Personalizzato").tag(Optional<UUID>.none)
                            ForEach(catalog) { item in
                                Text("\(item.name) - \(item.muscleGroup)").tag(Optional(item.id))
                            }
                        }
                        .onChange(of: selectedCatalogID) { _, newValue in
                            guard let newValue, let item = catalog.first(where: { $0.id == newValue }) else { return }
                            machine.name = item.name
                            machine.muscleGroup = MuscleGroup.allCases.first(where: { $0.rawValue == item.muscleGroup }) ?? .fullBody
                            machine.description = item.description ?? ""
                            machine.usageNotes = item.usageNotes ?? ""
                        }
                    }
                }

                Section("Macchinario") {
                    TextField("Nome", text: $machine.name)
                    Picker("Gruppo muscolare", selection: $machine.muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    Toggle("Disponibile", isOn: $machine.isAvailable)
                }

                Section("Descrizione") {
                    TextField("Descrizione", text: $machine.description, axis: .vertical)
                    TextField("Note utilizzo", text: $machine.usageNotes, axis: .vertical)
                }
            }
            .navigationTitle(machine.name.isEmpty ? "Nuovo macchinario" : "Modifica")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        onSave(machine)
                        dismiss()
                    }
                    .disabled(machine.name.isEmpty)
                }
            }
            .task {
                catalog = await catalogService?.fetchMachineCatalog() ?? []
            }
        }
    }
}

struct CreateWorkoutPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClientID: UUID
    @State private var selectedTemplateID: UUID?
    @State private var templates: [WorkoutTemplateDTO] = []
    @State private var exercises: [ExerciseCatalogDTO] = []
    @State private var name = "Ipertrofia 4 settimane"
    @State private var goal = "Aumento massa magra"
    let clients: [Client]
    let catalogService: CatalogService?
    let onCreate: (Client, String, String) -> Void

    init(clients: [Client], catalogService: CatalogService? = nil, onCreate: @escaping (Client, String, String) -> Void) {
        self.clients = clients
        self.catalogService = catalogService
        _selectedClientID = State(initialValue: clients.first?.id ?? UUID())
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    Picker("Cliente", selection: $selectedClientID) {
                        ForEach(clients) { client in
                            Text(client.fullName).tag(client.id)
                        }
                    }
                }

                Section("Scheda") {
                    if !templates.isEmpty {
                        Picker("Template", selection: $selectedTemplateID) {
                            Text("Nessun template").tag(Optional<UUID>.none)
                            ForEach(templates) { template in
                                Text(template.name).tag(Optional(template.id))
                            }
                        }
                        .onChange(of: selectedTemplateID) { _, newValue in
                            guard let newValue, let template = templates.first(where: { $0.id == newValue }) else { return }
                            name = template.name
                            goal = template.goal ?? goal
                        }
                    }
                    TextField("Nome scheda", text: $name)
                    TextField("Obiettivo", text: $goal, axis: .vertical)
                }

                Section("Catalogo esercizi") {
                    Text(exercises.isEmpty ? "Configura Supabase o accedi per leggere gli esercizi globali." : "\(exercises.count) esercizi disponibili nel catalogo globale. Quando assegni una scheda, gli esercizi vengono copiati nelle tabelle operative del cliente.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Crea scheda")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, name, goal)
                        }
                        dismiss()
                    }
                    .disabled(clients.isEmpty || name.isEmpty)
                }
            }
            .task {
                templates = await catalogService?.fetchWorkoutTemplates() ?? []
                exercises = await catalogService?.fetchExerciseCatalog() ?? []
            }
        }
    }
}

struct CreateNutritionPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClientID: UUID
    @State private var selectedMealTemplateID: UUID?
    @State private var mealTemplates: [MealTemplateDTO] = []
    @State private var foods: [FoodCatalogDTO] = []
    @State private var calories = 2100
    @State private var targetWeight = 70.0
    let clients: [Client]
    let catalogService: CatalogService?
    let onCreate: (Client, Int, Double) -> Void

    init(clients: [Client], catalogService: CatalogService? = nil, onCreate: @escaping (Client, Int, Double) -> Void) {
        self.clients = clients
        self.catalogService = catalogService
        _selectedClientID = State(initialValue: clients.first?.id ?? UUID())
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    Picker("Cliente", selection: $selectedClientID) {
                        ForEach(clients) { client in
                            Text(client.fullName).tag(client.id)
                        }
                    }
                }

                Section("Target") {
                    Stepper("Calorie: \(calories) kcal", value: $calories, in: 1200...4500, step: 50)
                    TextField("Peso obiettivo", value: $targetWeight, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Template pasti") {
                    if mealTemplates.isEmpty {
                        Text("Configura Supabase o accedi per leggere i template pasto.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Pasto base", selection: $selectedMealTemplateID) {
                            Text("Nessuno").tag(Optional<UUID>.none)
                            ForEach(mealTemplates) { template in
                                Text(template.name).tag(Optional(template.id))
                            }
                        }
                    }
                    Text("\(foods.count) alimenti disponibili nel food catalog.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Crea piano")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, calories, targetWeight)
                        }
                        dismiss()
                    }
                    .disabled(clients.isEmpty)
                }
            }
            .task {
                mealTemplates = await catalogService?.fetchMealTemplates() ?? []
                foods = await catalogService?.fetchFoodCatalog() ?? []
            }
        }
    }
}
