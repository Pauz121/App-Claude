import SwiftUI
import UIKit

// MARK: - T3 New/Edit Client View

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
                VStack(alignment: .leading, spacing: 20) {
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
                        Text("Il cliente userà questo codice per accedere alla sua app")
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
                        if client.goal.isEmpty { client.goal = selectedObjective }
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
                        if client.goal.isEmpty { client.goal = selectedObjective }
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

// MARK: - T4A New/Edit Appointment View

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appointment: Appointment
    @State private var showClientPicker = false
    @State private var showStartPicker = false
    @State private var showEndPicker = false
    @State private var repeatEnabled = false
    @State private var selectedWeekdays: Set<Int> = []
    @State private var repeatEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showRepeatEndPicker = false
    let clients: [Client]
    let onSave: (Appointment) -> Void

    private let weekdayLabels = ["L", "M", "M", "G", "V", "S", "D"]

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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appuntamento")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    // Client picker
                    Button { showClientPicker = true } label: {
                        FitCard {
                            HStack {
                                if let client = clients.first(where: { $0.id == appointment.clientID }) {
                                    AvatarView(
                                        initials: "\(client.firstName.first.map(String.init) ?? "")\(client.lastName.first.map(String.init) ?? "")",
                                        gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime],
                                        size: 34
                                    )
                                    Text(client.fullName)
                                        .font(.custom("Archivo-ExtraBold", size: 15))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                } else {
                                    Image(systemName: "person.circle")
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    Text("Seleziona cliente")
                                        .font(DesignSystem.Typography.bodyMD())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Type chips
                    HStack(spacing: 10) {
                        typeChip(
                            label: "🏋️ Allenamento",
                            active: appointment.sessionType == .workout,
                            activeColor: DesignSystem.Colors.indigo
                        ) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                appointment.sessionType = .workout
                            }
                        }
                        typeChip(
                            label: "📍 Check-in Studio",
                            active: appointment.sessionType == .checkin,
                            activeColor: DesignSystem.Colors.amber
                        ) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                appointment.sessionType = .checkin
                            }
                        }
                    }

                    // Date/time fields
                    SectionLabel(text: "Orario")
                    dateRow(label: "Inizio", date: $appointment.startTime, showPicker: $showStartPicker)
                    dateRow(label: "Fine", date: $appointment.endTime, showPicker: $showEndPicker)

                    if showStartPicker {
                        DatePicker("", selection: $appointment.startTime)
                            .datePickerStyle(.graphical)
                            .tint(DesignSystem.Colors.indigo)
                            .padding(.horizontal, 4)
                    }

                    if showEndPicker {
                        DatePicker("", selection: $appointment.endTime)
                            .datePickerStyle(.graphical)
                            .tint(DesignSystem.Colors.indigo)
                            .padding(.horizontal, 4)
                    }

                    // Repeat (only for workout type)
                    if appointment.sessionType == .workout {
                        FitCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $repeatEnabled.animation(.easeInOut(duration: 0.2))) {
                                    HStack(spacing: 10) {
                                        FitIconChip(systemName: "repeat", color: DesignSystem.Colors.indigo, background: DesignSystem.Colors.indigoBg, size: 30)
                                        Text("Ripeti")
                                            .font(.custom("Archivo-ExtraBold", size: 15))
                                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    }
                                }
                                .tint(DesignSystem.Colors.indigo)

                                if repeatEnabled {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Giorni della settimana")
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                        HStack(spacing: 6) {
                                            ForEach(0..<7, id: \.self) { index in
                                                let selected = selectedWeekdays.contains(index)
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.14)) {
                                                        if selected {
                                                            selectedWeekdays.remove(index)
                                                        } else {
                                                            selectedWeekdays.insert(index)
                                                        }
                                                    }
                                                } label: {
                                                    Text(weekdayLabels[index])
                                                        .font(DesignSystem.Typography.labelSM())
                                                        .foregroundStyle(selected ? .white : DesignSystem.Colors.txtPrimary)
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 34)
                                                        .background(selected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                                .stroke(selected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        Divider().background(DesignSystem.Colors.bgLine)
                                        HStack {
                                            Text("Fino al")
                                                .font(DesignSystem.Typography.labelMD())
                                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                            Spacer()
                                            Button {
                                                withAnimation { showRepeatEndPicker.toggle() }
                                            } label: {
                                                Text(repeatEndDate.formatted(.dateTime.day().month(.wide).year()))
                                                    .font(.custom("Archivo-ExtraBold", size: 14))
                                                    .foregroundStyle(DesignSystem.Colors.indigo)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        if showRepeatEndPicker {
                                            DatePicker("", selection: $repeatEndDate, in: Date()..., displayedComponents: .date)
                                                .datePickerStyle(.graphical)
                                                .tint(DesignSystem.Colors.indigo)
                                        }
                                        Text("L'allenamento verrà aggiunto per ogni giorno selezionato fino alla data indicata")
                                            .font(DesignSystem.Typography.bodySM())
                                            .italic()
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    }
                                }
                            }
                        }
                    }

                    // Status picker
                    SectionLabel(text: "Stato")
                    FitCard {
                        HStack {
                            Text("Stato")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Spacer()
                            Picker("", selection: $appointment.status) {
                                ForEach(AppointmentStatus.allCases) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .tint(DesignSystem.Colors.indigo)
                        }
                    }

                    // Notes
                    SectionLabel(text: "Note")
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $appointment.notes)
                            .font(DesignSystem.Typography.bodyMD())
                            .frame(minHeight: 80)
                            .padding(10)
                            .background(DesignSystem.Colors.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))
                        if appointment.notes.isEmpty {
                            Text("Aggiungi una nota…")
                                .font(DesignSystem.Typography.bodyMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                    PrimaryButton(title: "Salva appuntamento") {
                        appointment.date = appointment.startTime
                        onSave(appointment)
                        dismiss()
                    }
                    .disabled(clients.isEmpty)
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
                        appointment.date = appointment.startTime
                        onSave(appointment)
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.indigo)
                    .disabled(clients.isEmpty)
                }
            }
            .sheet(isPresented: $showClientPicker) {
                ClientPickerSheet(clients: clients, selectedID: $appointment.clientID)
            }
            .appScreen()
        }
    }

    private func typeChip(label: String, active: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Archivo-ExtraBold", size: 14))
                .foregroundStyle(active ? .white : DesignSystem.Colors.txtPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(active ? activeColor : DesignSystem.Colors.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(active ? activeColor : DesignSystem.Colors.bgLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func dateRow(label: String, date: Binding<Date>, showPicker: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPicker.wrappedValue.toggle()
            }
        } label: {
            FitCard {
                HStack {
                    Text(label)
                        .font(DesignSystem.Typography.bodyMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Text(date.wrappedValue.formatted(.dateTime.day().month().hour().minute()))
                        .font(.custom("Archivo-ExtraBold", size: 16))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Client Picker Sheet

private struct ClientPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let clients: [Client]
    @Binding var selectedID: UUID

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(clients) { client in
                        Button {
                            selectedID = client.id
                            dismiss()
                        } label: {
                            FitCard {
                                HStack(spacing: 12) {
                                    AvatarView(
                                        initials: "\(client.firstName.first.map(String.init) ?? "")\(client.lastName.first.map(String.init) ?? "")",
                                        gradient: [DesignSystem.Colors.indigo, DesignSystem.Colors.lime],
                                        size: 40
                                    )
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(client.fullName)
                                            .font(.custom("Archivo-ExtraBold", size: 15))
                                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                        Text(client.goal.isEmpty ? "Obiettivo non impostato" : client.goal)
                                            .font(DesignSystem.Typography.bodySM())
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    }
                                    Spacer()
                                    if selectedID == client.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(DesignSystem.Colors.indigo)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Seleziona cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            .appScreen()
        }
    }
}

// MARK: - T6C Add Machine Sheet

struct AddMachineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var machine: Machine
    @State private var catalog: [MachineCatalogDTO] = []
    @State private var selectedCatalogID = ""
    let catalogService: CatalogService?
    let onSave: (Machine) -> Void

    init(machine: Machine, catalogService: CatalogService? = nil, onSave: @escaping (Machine) -> Void) {
        _machine = State(initialValue: machine)
        self.catalogService = catalogService
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(DesignSystem.Colors.bgLine)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(machine.name.isEmpty ? "Nuovo macchinario" : "Modifica macchinario")
                        .font(.custom("Archivo-ExtraBold", size: 20))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        .padding(.horizontal, 24)

                    // Catalog picker (if available)
                    if !catalog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "Catalogo globale")
                                .padding(.horizontal, 24)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(catalog.prefix(8)) { item in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.16)) {
                                                selectedCatalogID = item.id.uuidString
                                                machine.name = item.name
                                                machine.muscleGroup = MuscleGroup.allCases.first(where: { $0.rawValue == item.muscleGroup }) ?? .fullBody
                                                machine.description = item.description ?? ""
                                                machine.usageNotes = item.usageNotes ?? ""
                                            }
                                        } label: {
                                            Text(item.name)
                                                .font(DesignSystem.Typography.labelSM())
                                                .foregroundStyle(selectedCatalogID == item.id.uuidString ? .white : DesignSystem.Colors.txtPrimary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 9)
                                                .background(selectedCatalogID == item.id.uuidString ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(selectedCatalogID == item.id.uuidString ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Macchinario")
                            .padding(.horizontal, 24)

                        FitCard {
                            TextField("Nome macchinario", text: $machine.name)
                                .font(DesignSystem.Typography.bodyMD())
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        }
                        .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Gruppo muscolare")
                            .padding(.horizontal, 24)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                            ForEach(MuscleGroup.allCases) { group in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.14)) {
                                        machine.muscleGroup = group
                                    }
                                } label: {
                                    Text(group.rawValue)
                                        .font(DesignSystem.Typography.labelSM())
                                        .foregroundStyle(machine.muscleGroup == group ? .white : DesignSystem.Colors.txtPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(machine.muscleGroup == group ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(machine.muscleGroup == group ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Note (opzionale)")
                            .padding(.horizontal, 24)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $machine.usageNotes)
                                .font(DesignSystem.Typography.bodyMD())
                                .frame(minHeight: 80)
                                .padding(10)
                                .background(DesignSystem.Colors.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))
                            if machine.usageNotes.isEmpty {
                                Text("Note di utilizzo…")
                                    .font(DesignSystem.Typography.bodyMD())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    AccentButton(title: "Aggiungi", color: DesignSystem.Colors.indigo) {
                        onSave(machine)
                        dismiss()
                    }
                    .padding(.horizontal, 24)
                    .disabled(machine.name.isEmpty)

                    Spacer(minLength: 24)
                }
            }
        }
        .background(DesignSystem.Colors.bgMain.ignoresSafeArea())
        .task {
            catalog = await catalogService?.fetchMachineCatalog() ?? []
        }
    }
}

// MARK: - T6A Create Workout Plan View

struct CreateWorkoutPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClientID: UUID
    @State private var selectedTemplateID = ""
    @State private var templates: [WorkoutTemplateDTO] = []
    @State private var exercises: [ExerciseCatalogDTO] = []
    @State private var name = "Ipertrofia 4 settimane"
    @State private var goal = "Aumento massa magra"
    @State private var durationWeeks = 4
    let clients: [Client]
    let catalogService: CatalogService?
    let onCreate: (Client, String, String) -> Void
    private let goals = ["Dimagrimento", "Massa", "Ricomposizione", "Tonificazione", "Forza", "Altro"]

    init(clients: [Client], catalogService: CatalogService? = nil, onCreate: @escaping (Client, String, String) -> Void) {
        self.clients = clients
        self.catalogService = catalogService
        _selectedClientID = State(initialValue: clients.first?.id ?? UUID())
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nuova scheda")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    SectionLabel(text: "Cliente")
                    FitCard {
                        Picker("Cliente", selection: $selectedClientID) {
                            ForEach(clients) { client in
                                Text(client.fullName).tag(client.id)
                            }
                        }
                        .tint(DesignSystem.Colors.indigo)
                        .font(DesignSystem.Typography.bodyMD())
                    }

                    SectionLabel(text: "Dettagli scheda")
                    FitCard {
                        TextField("Nome scheda", text: $name)
                            .font(DesignSystem.Typography.bodyMD())
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    }

                    FitCard {
                        HStack {
                            Text("Durata")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Spacer()
                            Stepper("\(durationWeeks) settimane", value: $durationWeeks, in: 1...52)
                                .font(.custom("Archivo-ExtraBold", size: 15))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                .tint(DesignSystem.Colors.indigo)
                        }
                    }

                    SectionLabel(text: "Obiettivo")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                        ForEach(goals, id: \.self) { g in
                            Button {
                                withAnimation(.easeInOut(duration: 0.14)) { goal = g }
                            } label: {
                                Text(g)
                                    .font(DesignSystem.Typography.labelMD())
                                    .foregroundStyle(goal == g ? .white : DesignSystem.Colors.txtPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(goal == g ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(goal == g ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !templates.isEmpty {
                        SectionLabel(text: "Template")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(templates) { template in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.14)) {
                                            selectedTemplateID = template.id.uuidString
                                            name = template.name
                                            goal = template.goal ?? goal
                                        }
                                    } label: {
                                        Text(template.name)
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(selectedTemplateID == template.id.uuidString ? .white : DesignSystem.Colors.txtPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(selectedTemplateID == template.id.uuidString ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(selectedTemplateID == template.id.uuidString ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !exercises.isEmpty {
                        FitCard {
                            HStack {
                                FitIconChip(systemName: "dumbbell.fill", color: DesignSystem.Colors.indigo, background: DesignSystem.Colors.indigoBg, size: 30)
                                Text("\(exercises.count) esercizi disponibili nel catalogo")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                    }

                    AccentButton(title: "Pubblica al cliente", color: DesignSystem.Colors.indigo) {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, name, goal)
                        }
                        dismiss()
                    }
                    .disabled(clients.isEmpty || name.isEmpty)
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
                    Button("Crea") {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, name, goal)
                        }
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.indigo)
                    .disabled(clients.isEmpty || name.isEmpty)
                }
            }
            .appScreen()
            .task {
                templates = await catalogService?.fetchWorkoutTemplates() ?? []
                exercises = await catalogService?.fetchExerciseCatalog() ?? []
            }
        }
    }
}

// MARK: - T6B Create Nutrition Plan View

struct CreateNutritionPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClientID: UUID
    @State private var selectedMealTemplateID = ""
    @State private var mealTemplates: [MealTemplateDTO] = []
    @State private var foods: [FoodCatalogDTO] = []
    @State private var calories = 2100
    @State private var proteins = 160
    @State private var carbs = 220
    @State private var fats = 65
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nuovo piano alimentare")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

                    SectionLabel(text: "Cliente")
                    FitCard {
                        Picker("Cliente", selection: $selectedClientID) {
                            ForEach(clients) { client in
                                Text(client.fullName).tag(client.id)
                            }
                        }
                        .tint(DesignSystem.Colors.indigo)
                        .font(DesignSystem.Typography.bodyMD())
                    }

                    SectionLabel(text: "Calorie target")
                    FitCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Calorie giornaliere")
                                    .font(DesignSystem.Typography.labelMD())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                Spacer()
                                Text("\(calories) kcal")
                                    .font(.custom("Archivo-ExtraBold", size: 18))
                                    .foregroundStyle(DesignSystem.Colors.teal)
                            }
                            Stepper("", value: $calories, in: 1200...5000, step: 50)
                                .labelsHidden()
                                .tint(DesignSystem.Colors.teal)
                        }
                    }

                    SectionLabel(text: "Macro")
                    HStack(spacing: 10) {
                        macroField("Proteine", value: $proteins, suffix: "g", color: DesignSystem.Colors.teal)
                        macroField("Carbo", value: $carbs, suffix: "g", color: DesignSystem.Colors.amber)
                        macroField("Grassi", value: $fats, suffix: "g", color: DesignSystem.Colors.limeDark)
                    }

                    SectionLabel(text: "Peso obiettivo")
                    FitCard {
                        HStack {
                            Text("Peso obiettivo")
                                .font(DesignSystem.Typography.labelMD())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            Spacer()
                            TextField("", value: $targetWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.custom("Archivo-ExtraBold", size: 18))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("kg")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    }

                    if !mealTemplates.isEmpty {
                        SectionLabel(text: "Template pasti")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(mealTemplates) { template in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.14)) {
                                            selectedMealTemplateID = template.id.uuidString
                                        }
                                    } label: {
                                        Text(template.name)
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(selectedMealTemplateID == template.id.uuidString ? .white : DesignSystem.Colors.txtPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(selectedMealTemplateID == template.id.uuidString ? DesignSystem.Colors.teal : DesignSystem.Colors.bgCard)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(selectedMealTemplateID == template.id.uuidString ? DesignSystem.Colors.teal : DesignSystem.Colors.bgLine, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !foods.isEmpty {
                        FitCard {
                            HStack {
                                FitIconChip(systemName: "fork.knife", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 30)
                                Text("\(foods.count) alimenti nel food catalog")
                                    .font(DesignSystem.Typography.bodySM())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                    }

                    AccentButton(title: "Pubblica al cliente", color: DesignSystem.Colors.teal) {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, calories, targetWeight)
                        }
                        dismiss()
                    }
                    .disabled(clients.isEmpty)
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
                    Button("Crea") {
                        if let client = clients.first(where: { $0.id == selectedClientID }) {
                            onCreate(client, calories, targetWeight)
                        }
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.indigo)
                    .disabled(clients.isEmpty)
                }
            }
            .appScreen()
            .task {
                mealTemplates = await catalogService?.fetchMealTemplates() ?? []
                foods = await catalogService?.fetchFoodCatalog() ?? []
            }
        }
    }

    private func macroField(_ title: String, value: Binding<Int>, suffix: String, color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(color)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    TextField("", value: value, format: .number)
                        .keyboardType(.numberPad)
                        .font(.custom("Archivo-Black", size: 20))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(suffix)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
    }
}
