import SwiftUI
import UIKit
import EventKit
import UserNotifications
import Charts

// MARK: - T3 New/Edit Client View

struct AddClientView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: AppServices
    @State private var client: Client
    @State private var selectedObjective: String
    @State private var codeCopied = false
    @State private var paymentEnabled = false
    @State private var paymentAmount: Double = 100
    @State private var paymentFrequency: PaymentFrequency = .monthly
    @State private var paymentStartDate: Date = Date()
    @State private var paymentNotes: String = ""
    let onSave: (Client) -> Void
    private let isNewClient: Bool
    private let objectives = ["Dimagrimento", "Massa", "Ricomposizione", "Tonificazione", "Forza", "Altro"]

    init(client: Client, onSave: @escaping (Client) -> Void) {
        _client = State(initialValue: client)
        _selectedObjective = State(initialValue: client.goal.isEmpty ? "Dimagrimento" : client.goal)
        self.onSave = onSave
        self.isNewClient = client.firstName.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(isNewClient ? "Nuovo cliente" : "Modifica cliente")
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
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Codice accesso")
                                        .font(DesignSystem.Typography.labelSM())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    Text(client.accessCode)
                                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(DesignSystem.Colors.limeDark)
                                }
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = client.accessCode
                                    codeCopied = true
                                    Task {
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        codeCopied = false
                                    }
                                } label: {
                                    Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(codeCopied ? DesignSystem.Colors.limeDark : DesignSystem.Colors.indigo)
                                        .frame(width: 36, height: 36)
                                        .background(codeCopied ? DesignSystem.Colors.limeBg : DesignSystem.Colors.indigoBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.2), value: codeCopied)
                            }
                        }
                        Text("Il cliente userà questo codice per accedere alla sua app")
                            .font(DesignSystem.Typography.bodySM())
                            .italic()
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }

                    if isNewClient {
                        paymentSection
                    }

                    SectionLabel(text: "Note trainer")
                    TextEditor(text: $client.trainerNotes)
                        .frame(minHeight: 110)
                        .padding(10)
                        .background(DesignSystem.Colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignSystem.Colors.bgLine, lineWidth: 1))

                    PrimaryButton(title: isNewClient ? "Crea cliente & invia codice" : "Salva modifiche") {
                        saveAndDismiss()
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
                    Button("Salva") { saveAndDismiss() }
                        .foregroundStyle(DesignSystem.Colors.indigo)
                        .disabled(client.firstName.isEmpty || client.lastName.isEmpty)
                }
            }
            .appScreen()
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Pagamento")
            FitCard {
                Toggle("Imposta piano pagamenti", isOn: $paymentEnabled)
                    .tint(DesignSystem.Colors.indigo)
                    .font(DesignSystem.Typography.labelMD())
            }
            if paymentEnabled {
                FitCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Importo (€)")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        HStack {
                            TextField("0", value: $paymentAmount, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.custom("Archivo-ExtraBold", size: 20))
                                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text("EUR")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(PaymentFrequency.allCases) { freq in
                        Button { paymentFrequency = freq } label: {
                            Text(freq.label)
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(paymentFrequency == freq ? .white : DesignSystem.Colors.txtPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(paymentFrequency == freq ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(paymentFrequency == freq ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                FitCard {
                    DatePicker("Data inizio", selection: $paymentStartDate, displayedComponents: .date)
                        .tint(DesignSystem.Colors.indigo)
                        .font(DesignSystem.Typography.labelMD())
                }

                FitCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note pagamento (opzionale)")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                        TextEditor(text: $paymentNotes)
                            .frame(minHeight: 60)
                            .font(DesignSystem.Typography.bodyMD())
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    }
                }
            }
        }
    }

    private func saveAndDismiss() {
        if client.goal.isEmpty { client.goal = selectedObjective }
        onSave(client)
        if isNewClient && paymentEnabled && paymentAmount > 0 {
            let svc = services.trainerClientPaymentService
            let plan = ClientPaymentPlan(
                id: UUID(),
                trainerID: client.trainerID,
                clientID: client.id,
                frequency: paymentFrequency,
                amount: paymentAmount,
                currency: "EUR",
                startDate: paymentStartDate,
                dueDay: nil,
                notes: paymentNotes,
                status: .active,
                createdAt: Date()
            )
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                _ = await svc.createOrUpdatePaymentPlan(plan)
            }
        }
        dismiss()
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
    @State private var appointmentDate: Date
    @State private var showDatePicker = false
    @State private var selectedStartSlot: Date?
    @State private var repeatEnabled = false
    @State private var selectedWeekdays: Set<Int> = []
    @State private var repeatEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showRepeatEndPicker = false
    @State private var addToCalendar = false
    @State private var calendarAccessDenied = false
    let clients: [Client]
    let existingAppointments: [Appointment]
    let onSave: (Appointment) -> Void

    private let weekdayLabels = ["L", "M", "M", "G", "V", "S", "D"]

    init(trainer: Trainer, clients: [Client], appointment: Appointment? = nil, existingAppointments: [Appointment] = [], onSave: @escaping (Appointment) -> Void) {
        self.clients = clients
        self.existingAppointments = existingAppointments
        self.onSave = onSave
        if let existing = appointment {
            _appointment = State(initialValue: existing)
            _appointmentDate = State(initialValue: Calendar.current.startOfDay(for: existing.startTime))
            _selectedStartSlot = State(initialValue: existing.startTime)
        } else {
            let firstClientID = clients.first?.id ?? UUID()
            let defaultAppt = Appointment(
                id: UUID(),
                trainerID: trainer.id,
                clientID: firstClientID,
                date: Date(),
                startTime: .daysFromNow(0, hour: 10),
                endTime: .daysFromNow(0, hour: 11),
                sessionType: .workout,
                notes: "",
                status: .scheduled
            )
            _appointment = State(initialValue: defaultAppt)
            _appointmentDate = State(initialValue: Calendar.current.startOfDay(for: Date()))
            _selectedStartSlot = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appuntamento")
                        .font(DesignSystem.Typography.titleLG())
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)

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

                    HStack(spacing: 10) {
                        typeChip(label: "🏋️ Allenamento", active: appointment.sessionType == .workout, activeColor: DesignSystem.Colors.indigo) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                appointment.sessionType = .workout
                                selectedStartSlot = nil
                            }
                        }
                        typeChip(label: "📍 Check Studio", active: appointment.sessionType == .checkin, activeColor: DesignSystem.Colors.amber) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                appointment.sessionType = .checkin
                                selectedStartSlot = nil
                            }
                        }
                    }

                    SectionLabel(text: "Giorno")
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showDatePicker.toggle() }
                    } label: {
                        FitCard {
                            HStack {
                                Text("Data")
                                    .font(DesignSystem.Typography.bodyMD())
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                Spacer()
                                Text(appointmentDate.formatted(.dateTime.day().month(.wide).year()))
                                    .font(.custom("Archivo-ExtraBold", size: 15))
                                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if showDatePicker {
                        DatePicker("", selection: $appointmentDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(DesignSystem.Colors.indigo)
                            .onChange(of: appointmentDate) { _, _ in selectedStartSlot = nil }
                    }

                    timeSlotsSection

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
                                                        if selected { selectedWeekdays.remove(index) } else { selectedWeekdays.insert(index) }
                                                    }
                                                } label: {
                                                    Text(weekdayLabels[index])
                                                        .font(DesignSystem.Typography.labelSM())
                                                        .foregroundStyle(selected ? .white : DesignSystem.Colors.txtPrimary)
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 34)
                                                        .background(selected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(selected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
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

                    FitCard {
                        VStack(spacing: 8) {
                            Toggle(isOn: $addToCalendar.animation(.easeInOut(duration: 0.2))) {
                                HStack(spacing: 10) {
                                    FitIconChip(systemName: "calendar.badge.plus", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 30)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Aggiungi al Calendario iPhone")
                                            .font(.custom("Archivo-ExtraBold", size: 14))
                                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                        Text("Sincronizza con l'app Calendario")
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                    }
                                }
                            }
                            .tint(DesignSystem.Colors.teal)

                            if calendarAccessDenied {
                                Button("Abilita accesso al Calendario nelle Impostazioni") {
                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                }
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(AppColors.dangerRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

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
                        if addToCalendar, let client = clients.first(where: { $0.id == appointment.clientID }) {
                            Task {
                                let success = await TrainerCalendarService.shared.addAppointment(appointment, clientName: client.fullName)
                                if !success { calendarAccessDenied = true; addToCalendar = false }
                            }
                        }
                        dismiss()
                    }
                    .disabled(clients.isEmpty || selectedStartSlot == nil)
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
                    .disabled(clients.isEmpty || selectedStartSlot == nil)
                }
            }
            .sheet(isPresented: $showClientPicker) {
                ClientPickerSheet(clients: clients, selectedID: $appointment.clientID)
            }
            .appScreen()
        }
    }

    @ViewBuilder
    private var timeSlotsSection: some View {
        let slots = availableSlots()
        let durationLabel = appointment.sessionType == .checkin ? "30 min" : "60 min"
        SectionLabel(text: "Orario disponibile · \(durationLabel)")

        if slots.isEmpty {
            FitCard {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Text("Nessun orario disponibile per questa data")
                        .font(DesignSystem.Typography.bodyMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(slots, id: \.self) { slot in
                    let isSelected = selectedStartSlot.map {
                        Calendar.current.isDate($0, equalTo: slot, toGranularity: .minute)
                    } ?? false
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedStartSlot = slot
                            appointment.startTime = slot
                            let dur = appointment.sessionType == .checkin ? 30 : 60
                            appointment.endTime = Calendar.current.date(byAdding: .minute, value: dur, to: slot) ?? slot
                            appointment.date = slot
                        }
                    } label: {
                        Text(slot.formattedTime())
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.txtPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(isSelected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func availableSlots() -> [Date] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: appointmentDate)
        let duration = appointment.sessionType == .checkin ? 30 : 60
        return stride(from: 7 * 60, to: 21 * 60, by: 30).compactMap { minuteOffset -> Date? in
            guard let slotStart = cal.date(byAdding: .minute, value: minuteOffset, to: dayStart),
                  let slotEnd = cal.date(byAdding: .minute, value: duration, to: slotStart) else { return nil }
            let dayApps = existingAppointments.filter {
                cal.isDate($0.startTime, inSameDayAs: dayStart) && $0.id != appointment.id
            }
            let hasConflict = dayApps.contains { slotStart < $0.endTime && slotEnd > $0.startTime }
            return hasConflict ? nil : slotStart
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

// MARK: - T6A Create Workout Plan View (Wizard)

struct CreateWorkoutPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    // Step 0 — client + basics
    @State private var selectedClientID: UUID
    @State private var planName = ""
    @State private var durationWeeks = 4
    // Step 1 — type
    @State private var withTrainer = false
    // Step 2A — con trainer: days + times
    @State private var selectedWeekdays: Set<Int> = []
    @State private var dayTimeSlots: [Int: Date] = [:]
    @State private var existingAppointments: [Appointment] = []
    // Step 2B — senza trainer: day count
    @State private var trainingDaysCount = 3
    // Step 3 — goal
    @State private var goal = "Ipertrofia"
    // Step 4 — exercise builder
    @State private var workoutDays: [WorkoutDay] = []
    // Step 5 — notification
    @State private var enableNotification = false
    @State private var notifyDaysBefore = 3
    @State private var notificationDenied = false

    let clients: [Client]
    let catalogService: CatalogService?
    let services: AppServices?
    let onCreate: (WorkoutPlan) -> Void

    private let goals = ["Dimagrimento", "Ipertrofia", "Ricomposizione corporea", "Forza", "Tonificazione", "Mantenimento", "Preparazione atletica", "Altro"]
    private let weekdayNames = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
    private let totalSteps = 5

    init(clients: [Client], catalogService: CatalogService? = nil, services: AppServices? = nil, onCreate: @escaping (WorkoutPlan) -> Void) {
        self.clients = clients
        self.catalogService = catalogService
        self.services = services
        _selectedClientID = State(initialValue: clients.first?.id ?? UUID())
        self.onCreate = onCreate
    }

    var selectedClient: Client? { clients.first(where: { $0.id == selectedClientID }) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            switch step {
                            case 0: stepZero
                            case 1: stepOne
                            case 2:
                                if withTrainer {
                                    stepTwoA
                                } else {
                                    stepTwoB
                                }
                            case 3: stepThree
                            case 4: stepFour
                            default: EmptyView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.22), value: step)
                    }
                    .padding(20)
                }
                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            .appScreen()
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(DesignSystem.Colors.bgLine)
                Capsule()
                    .fill(DesignSystem.Colors.indigo)
                    .frame(width: proxy.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: 5)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                SecondaryButton(title: "Indietro") {
                    withAnimation { step -= 1 }
                }
            }
            AccentButton(title: step == totalSteps - 1 ? "Crea scheda" : "Continua", color: DesignSystem.Colors.indigo) {
                if step == totalSteps - 1 {
                    createPlan()
                } else {
                    if step == 1 {
                        prepareDays()
                    }
                    withAnimation { step += 1 }
                }
            }
            .disabled(stepIsInvalid)
        }
        .padding(20)
    }

    private var stepIsInvalid: Bool {
        switch step {
        case 0: return planName.isEmpty || clients.isEmpty
        case 2: return withTrainer ? selectedWeekdays.isEmpty : false
        default: return false
        }
    }

    // MARK: Step 0 — Basics
    private var stepZero: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 1 · Cliente e nome")
            Text("Nuova scheda").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            FitCard {
                Picker("Cliente", selection: $selectedClientID) {
                    ForEach(clients) { client in Text(client.fullName).tag(client.id) }
                }
                .tint(DesignSystem.Colors.indigo)
            }
            FitCard {
                TextField("Nome scheda", text: $planName)
                    .font(DesignSystem.Typography.bodyMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
            }
            FitCard {
                HStack {
                    Text("Durata").font(DesignSystem.Typography.labelMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    Stepper("\(durationWeeks) settimane", value: $durationWeeks, in: 1...52)
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .tint(DesignSystem.Colors.indigo)
                }
            }
        }
    }

    // MARK: Step 1 — Tipo
    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 2 · Tipo di allenamento")
            Text("Come si allenerà?").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            Button { withAnimation { withTrainer = true } } label: {
                FitCard(border: withTrainer ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: withTrainer ? 2 : 1) {
                    HStack(spacing: 14) {
                        FitIconChip(systemName: "person.2.fill", color: DesignSystem.Colors.indigo, background: DesignSystem.Colors.indigoBg, size: 38)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Con trainer").font(.custom("Archivo-ExtraBold", size: 16)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text("Sessioni in studio con appuntamenti in agenda").font(DesignSystem.Typography.bodySM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        Spacer()
                        if withTrainer { Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.indigo) }
                    }
                }
            }.buttonStyle(.plain)
            Button { withAnimation { withTrainer = false } } label: {
                FitCard(border: !withTrainer ? DesignSystem.Colors.lime : DesignSystem.Colors.bgLine, lineWidth: !withTrainer ? 2 : 1) {
                    HStack(spacing: 14) {
                        FitIconChip(systemName: "figure.run", color: DesignSystem.Colors.limeDark, background: DesignSystem.Colors.limeBg, size: 38)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Senza trainer").font(.custom("Archivo-ExtraBold", size: 16)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                            Text("Il cliente si allena in autonomia, senza appuntamenti").font(DesignSystem.Typography.bodySM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                        Spacer()
                        if !withTrainer { Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.limeDark) }
                    }
                }
            }.buttonStyle(.plain)
        }
    }

    // MARK: Step 2A — Con trainer: giorni e orari
    private var stepTwoA: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 3 · Giorni e orari")
            Text("Scegli i giorni").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            Text("Seleziona i giorni e l'orario per ogni sessione. Verranno creati automaticamente gli appuntamenti per le \(durationWeeks) settimane.")
                .font(DesignSystem.Typography.bodyMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            ForEach(Array(weekdayNames.enumerated()), id: \.offset) { index, name in
                let isSelected = selectedWeekdays.contains(index)
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            if isSelected { selectedWeekdays.remove(index); dayTimeSlots.removeValue(forKey: index) }
                            else { selectedWeekdays.insert(index) }
                        }
                    } label: {
                        FitCard(border: isSelected ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: isSelected ? 2 : 1) {
                            HStack {
                                Text(name).font(.custom("Archivo-ExtraBold", size: 15)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.indigo)
                                }
                            }
                        }
                    }.buttonStyle(.plain)
                    if isSelected {
                        FitCard {
                            DatePicker("Orario", selection: Binding(
                                get: { dayTimeSlots[index] ?? Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date() },
                                set: { dayTimeSlots[index] = $0 }
                            ), displayedComponents: .hourAndMinute)
                            .tint(DesignSystem.Colors.indigo)
                            .font(DesignSystem.Typography.labelMD())
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: Step 2B — Senza trainer: numero giorni
    private var stepTwoB: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 3 · Frequenza")
            Text("Giorni a settimana").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            Text("Quanti giorni a settimana si allenerà il cliente?").font(DesignSystem.Typography.bodyMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach([2, 3, 4, 5, 6], id: \.self) { count in
                    Button { trainingDaysCount = count } label: {
                        VStack(spacing: 6) {
                            Text("\(count)").font(.custom("Archivo-Black", size: 28))
                                .foregroundStyle(trainingDaysCount == count ? .white : DesignSystem.Colors.txtPrimary)
                            Text("giorni").font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(trainingDaysCount == count ? .white.opacity(0.8) : DesignSystem.Colors.txtSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(trainingDaysCount == count ? DesignSystem.Colors.limeDark : DesignSystem.Colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(trainingDaysCount == count ? DesignSystem.Colors.lime : DesignSystem.Colors.bgLine, lineWidth: trainingDaysCount == count ? 2 : 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Step 3 — Obiettivo
    private var stepThree: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 4 · Obiettivo")
            Text("Qual è l'obiettivo?").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(goals, id: \.self) { g in
                    Button { goal = g } label: {
                        Text(g).font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(goal == g ? .white : DesignSystem.Colors.txtPrimary)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(goal == g ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgCard)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(goal == g ? DesignSystem.Colors.indigo : DesignSystem.Colors.bgLine, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Step 4 — Builder esercizi
    private var stepFour: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 5 · Esercizi")
            Text("Costruisci la scheda").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            ForEach($workoutDays) { $day in
                WorkoutDayBuilderCard(day: $day, onDelete: {
                    workoutDays.removeAll { $0.id == day.id }
                })
            }
            SecondaryButton(title: "+ Aggiungi giorno") {
                let nextIndex = (workoutDays.map(\.dayIndex).max() ?? 0) + 1
                workoutDays.append(WorkoutDay(id: UUID(), title: "Giorno \(nextIndex)", dayIndex: nextIndex, exercises: []))
            }
            if enableNotification || true {
                SectionLabel(text: "Notifica scadenza")
                FitCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $enableNotification.animation()) {
                            HStack(spacing: 10) {
                                FitIconChip(systemName: "bell.badge.fill", color: DesignSystem.Colors.amber, background: DesignSystem.Colors.amberBg, size: 30)
                                Text("Avviso scadenza scheda").font(.custom("Archivo-ExtraBold", size: 14)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                            }
                        }
                        .tint(DesignSystem.Colors.amber)
                        .onChange(of: enableNotification) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationService.shared.requestPermission()
                                    if !granted { enableNotification = false; notificationDenied = true }
                                }
                            }
                        }
                        if enableNotification {
                            HStack(spacing: 8) {
                                ForEach([1, 3, 5, 7], id: \.self) { days in
                                    Button { notifyDaysBefore = days } label: {
                                        Text(days == 1 ? "1g" : days == 7 ? "1 sett." : "\(days)g")
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(notifyDaysBefore == days ? .white : DesignSystem.Colors.txtPrimary)
                                            .frame(maxWidth: .infinity).frame(height: 36)
                                            .background(notifyDaysBefore == days ? DesignSystem.Colors.amber : DesignSystem.Colors.bgCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(notifyDaysBefore == days ? DesignSystem.Colors.amber : DesignSystem.Colors.bgLine, lineWidth: 1))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert("Notifiche disabilitate", isPresented: $notificationDenied) {
            Button("OK", role: .cancel) {}
            Button("Impostazioni") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
        } message: { Text("Abilita le notifiche nelle Impostazioni.") }
    }

    private func prepareDays() {
        if workoutDays.isEmpty {
            let count = withTrainer ? selectedWeekdays.count : trainingDaysCount
            workoutDays = (1...max(count, 1)).map { i in
                WorkoutDay(id: UUID(), title: "Giorno \(i)", dayIndex: i, exercises: [])
            }
        }
    }

    private func createPlan() {
        guard let client = selectedClient else { return }
        let start = Date()
        let end = Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: start) ?? start
        let plan = WorkoutPlan(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            name: planName,
            goal: goal,
            createdAt: start,
            startDate: start,
            endDate: end,
            status: .active,
            days: workoutDays.isEmpty ? defaultDays() : workoutDays,
            withTrainer: withTrainer
        )
        if enableNotification {
            NotificationService.shared.scheduleWorkoutPlanExpiry(clientName: client.fullName, endDate: end, daysBefore: notifyDaysBefore)
        }
        if withTrainer, let svc = services {
            Task {
                await createRecurringAppointments(for: client, plan: plan, appointmentService: svc.appointmentService)
            }
        }
        onCreate(plan)
        dismiss()
    }

    private func defaultDays() -> [WorkoutDay] {
        let count = withTrainer ? max(selectedWeekdays.count, 1) : trainingDaysCount
        return (1...count).map { i in
            WorkoutDay(id: UUID(), title: "Giorno \(i)", dayIndex: i, exercises: [
                Exercise(id: UUID(), name: "Squat", machineID: nil, muscleGroup: .legs, sets: 4, reps: "10", restSeconds: 90, recommendedLoad: "RPE 7", technicalNotes: "", order: 1)
            ])
        }
    }

    private func createRecurringAppointments(for client: Client, plan: WorkoutPlan, appointmentService: AppointmentService) async {
        let cal = Calendar.current
        let trainerID = client.trainerID
        var weekStart = cal.startOfDay(for: Date())
        for _ in 0..<durationWeeks {
            for weekday in selectedWeekdays.sorted() {
                let targetWeekday = weekday + 2
                guard let dayDate = cal.nextDate(after: weekStart, matching: DateComponents(weekday: targetWeekday % 8 == 0 ? 1 : targetWeekday), matchingPolicy: .nextTimePreservingSmallerComponents) else { continue }
                let slotTime = dayTimeSlots[weekday] ?? cal.date(bySettingHour: 10, minute: 0, second: 0, of: dayDate) ?? dayDate
                let apptStart = cal.date(bySettingHour: cal.component(.hour, from: slotTime), minute: cal.component(.minute, from: slotTime), second: 0, of: dayDate) ?? dayDate
                let apptEnd = cal.date(byAdding: .hour, value: 1, to: apptStart) ?? apptStart
                let appointment = Appointment(id: UUID(), trainerID: trainerID, clientID: client.id, date: apptStart, startTime: apptStart, endTime: apptEnd, sessionType: .workout, notes: plan.name, status: .scheduled)
                _ = await appointmentService.createAppointment(appointment)
            }
            weekStart = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        }
    }
}

struct WorkoutDayBuilderCard: View {
    @Binding var day: WorkoutDay
    let onDelete: () -> Void
    @State private var isExpanded = true

    var body: some View {
        FitCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TextField("Nome giorno", text: $day.title)
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Spacer()
                    Button { withAnimation { isExpanded.toggle() } } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold)).foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash").foregroundStyle(AppColors.dangerRed).font(.caption.weight(.bold))
                    }
                }
                if isExpanded {
                    Divider()
                    ForEach($day.exercises) { $exercise in
                        ExerciseBuilderRow(exercise: $exercise, onDelete: {
                            day.exercises.removeAll { $0.id == exercise.id }
                        }, onDuplicate: {
                            var copy = exercise
                            copy.id = UUID()
                            copy.order = (day.exercises.map(\.order).max() ?? 0) + 1
                            day.exercises.append(copy)
                        })
                    }
                    Button {
                        day.exercises.append(Exercise(id: UUID(), name: "", machineID: nil, muscleGroup: .chest, sets: 3, reps: "10", restSeconds: 60, recommendedLoad: "", technicalNotes: "", order: (day.exercises.map(\.order).max() ?? 0) + 1))
                    } label: {
                        Label("Aggiungi esercizio", systemImage: "plus")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.indigo)
                    }
                }
            }
        }
    }
}

struct ExerciseBuilderRow: View {
    @Binding var exercise: Exercise
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    @State private var isExpanded = false

    private let muscleGroups = MuscleGroup.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Nome esercizio", text: $exercise.name)
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                Button { withAnimation { isExpanded.toggle() } } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold)).foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Menu {
                    Button("Duplica", action: onDuplicate)
                    Button("Elimina", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis").foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Muscolo", selection: $exercise.muscleGroup) {
                        ForEach(muscleGroups) { g in Text(g.rawValue).tag(g) }
                    }
                    .tint(DesignSystem.Colors.indigo)
                    .font(DesignSystem.Typography.labelSM())
                    HStack(spacing: 8) {
                        exerciseField("Serie", value: $exercise.sets)
                        exerciseFieldText("Rip.", text: $exercise.reps)
                        exerciseField("Rec (s)", value: $exercise.restSeconds)
                    }
                    TextField("Note tecniche (opzionale)", text: $exercise.technicalNotes)
                        .font(DesignSystem.Typography.bodySM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        Divider()
    }

    private func exerciseField(_ label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .font(.custom("Archivo-ExtraBold", size: 15))
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(DesignSystem.Colors.bgLine.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func exerciseFieldText(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            TextField("10", text: text)
                .font(.custom("Archivo-ExtraBold", size: 15))
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(DesignSystem.Colors.bgLine.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

@MainActor
private final class TrainerCalendarService {
    static let shared = TrainerCalendarService()
    private let store = EKEventStore()
    private init() {}

    private var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func requestAccess() async -> Bool {
        if isAuthorized { return true }
        guard EKEventStore.authorizationStatus(for: .event) == .notDetermined else { return false }
        return (try? await store.requestFullAccessToEvents()) ?? false
    }

    func addAppointment(_ appointment: Appointment, clientName: String) async -> Bool {
        guard await requestAccess() else { return false }
        let event = EKEvent(eventStore: store)
        event.title = "\(appointment.sessionType.displayName) - \(clientName)"
        event.startDate = appointment.startTime
        event.endDate = appointment.endTime
        event.calendar = store.defaultCalendarForNewEvents
        if !appointment.notes.isEmpty { event.notes = appointment.notes }
        return (try? store.save(event, span: .thisEvent)) != nil
    }
}

private final class TrainerNotificationService {
    static let shared = TrainerNotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        if settings.authorizationStatus == .denied { return false }
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleWorkoutPlanExpiry(clientName: String, endDate: Date, daysBefore: Int) {
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: endDate),
              triggerDate > Date() else { return }
        let center = UNUserNotificationCenter.current()
        let safeClientName = clientName.replacingOccurrences(of: " ", with: "_")
        let id = "trainer_plan_expiry_\(safeClientName)_\(daysBefore)"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Scheda in scadenza"
        content.body = "La scheda di \(clientName) terminera tra \(daysBefore == 1 ? "1 giorno" : "\(daysBefore) giorni")."
        content.sound = .default
        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9; components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

// MARK: - T6B Create Nutrition Plan View (Wizard)

struct CreateNutritionPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    // Step 0 — client + basics
    @State private var selectedClientID: UUID
    @State private var targetWeight = 70.0
    @State private var planNotes = ""
    // Step 1 — macro + calorie
    @State private var proteins = 160
    @State private var carbs = 220
    @State private var fats = 65
    // Step 2 — meal structure
    @State private var nutritionDays: [NutritionDay] = []
    @State private var selectedDayForEdit: IdentifiableInt? = nil
    @State private var showingSavedMealPicker = false
    @State private var savedMeals: [SavedMeal] = []
    @State private var pendingDayIndex: Int = 0
    @State private var pendingMealSlot: String = ""

    let clients: [Client]
    let catalogService: CatalogService?
    let services: AppServices?
    let onCreate: (NutritionPlan) -> Void

    private let totalSteps = 3
    private let mealSlots = ["Colazione", "Spuntino mattina", "Pranzo", "Spuntino pomeridiano", "Cena", "Pre-nanna"]
    private let weekdayLabels = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
    private let mealHours = [7, 10, 13, 16, 20, 22]

    init(clients: [Client], catalogService: CatalogService? = nil, services: AppServices? = nil, onCreate: @escaping (NutritionPlan) -> Void) {
        self.clients = clients
        self.catalogService = catalogService
        self.services = services
        _selectedClientID = State(initialValue: clients.first?.id ?? UUID())
        self.onCreate = onCreate
    }

    var computedCalories: Int { proteins * 4 + carbs * 4 + fats * 9 }
    var selectedClient: Client? { clients.first(where: { $0.id == selectedClientID }) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            switch step {
                            case 0: stepZero
                            case 1: stepOne
                            case 2: stepTwo
                            default: EmptyView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.22), value: step)
                    }
                    .padding(20)
                }
                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            .sheet(isPresented: $showingSavedMealPicker) {
                SavedMealPickerSheet(meals: savedMeals) { selected in
                    importSavedMeal(selected, toDayIndex: pendingDayIndex, mealSlotName: pendingMealSlot)
                }
            }
            .sheet(item: $selectedDayForEdit) { item in
                if let idx = nutritionDays.firstIndex(where: { $0.dayIndex == item.id }) {
                    NutritionDayDetailSheet(
                        day: $nutritionDays[idx],
                        mealSlots: mealSlots,
                        mealHours: mealHours,
                        catalogService: catalogService
                    )
                }
            }
            .appScreen()
            .task {
                if let svc = services {
                    savedMeals = await svc.savedMealService.fetchSavedMeals(for: selectedClient?.trainerID ?? UUID())
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(DesignSystem.Colors.bgLine)
                Capsule()
                    .fill(DesignSystem.Colors.teal)
                    .frame(width: proxy.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: 5)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                SecondaryButton(title: "Indietro") { withAnimation { step -= 1 } }
            }
            AccentButton(title: step == totalSteps - 1 ? "Pubblica al cliente" : "Continua", color: DesignSystem.Colors.teal) {
                if step == totalSteps - 1 { createPlan() }
                else {
                    if step == 1 && nutritionDays.isEmpty { buildDefaultDays() }
                    withAnimation { step += 1 }
                }
            }
            .disabled(clients.isEmpty)
        }
        .padding(20)
    }

    // MARK: Step 0 — Cliente
    private var stepZero: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 1 · Cliente e peso")
            Text("Nuovo piano\nalimentare").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)
            FitCard {
                Picker("Cliente", selection: $selectedClientID) {
                    ForEach(clients) { c in Text(c.fullName).tag(c.id) }
                }
                .tint(DesignSystem.Colors.teal)
            }
            FitCard {
                HStack {
                    Text("Peso obiettivo").font(DesignSystem.Typography.labelMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    TextField("", value: $targetWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.custom("Archivo-ExtraBold", size: 18))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("kg").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            FitInputField(label: "Note per il cliente (opzionale)", text: $planNotes)
        }
    }

    // MARK: Step 1 — Macro + calorie calcolate + grafico torta
    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 2 · Macronutrienti")
            Text("Imposta i macro").font(.custom("Archivo-ExtraBold", size: 26)).foregroundStyle(DesignSystem.Colors.txtPrimary)

            FitCard {
                HStack {
                    FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calorie giornaliere").font(DesignSystem.Typography.labelMD()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                        Text("Calcolate automaticamente").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary.opacity(0.7)).italic()
                    }
                    Spacer()
                    Text("\(computedCalories) kcal")
                        .font(.custom("Archivo-ExtraBold", size: 22))
                        .foregroundStyle(DesignSystem.Colors.teal)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: computedCalories)
                }
            }

            HStack(spacing: 10) {
                macroField("Proteine", value: $proteins, color: DesignSystem.Colors.teal)
                macroField("Carbo", value: $carbs, color: DesignSystem.Colors.amber)
                macroField("Grassi", value: $fats, color: DesignSystem.Colors.limeDark)
            }

            FitCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Distribuzione macro").font(.custom("Archivo-ExtraBold", size: 14)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                    if #available(iOS 17, *) {
                        macroPieChart
                    } else {
                        macroBarFallback
                    }
                    HStack(spacing: 14) {
                        macroLegend("Proteine", color: DesignSystem.Colors.teal)
                        macroLegend("Carboidrati", color: DesignSystem.Colors.amber)
                        macroLegend("Grassi", color: DesignSystem.Colors.limeDark)
                    }
                }
            }
        }
    }

    @available(iOS 17, *)
    private var macroPieChart: some View {
        let total = Double(proteins * 4 + carbs * 4 + fats * 9)
        let data: [(String, Double, Color)] = [
            ("Proteine", Double(proteins * 4) / max(total, 1), DesignSystem.Colors.teal),
            ("Carboidrati", Double(carbs * 4) / max(total, 1), DesignSystem.Colors.amber),
            ("Grassi", Double(fats * 9) / max(total, 1), DesignSystem.Colors.limeDark)
        ]
        return Chart {
            ForEach(data, id: \.0) { item in
                SectorMark(angle: .value(item.0, item.1), innerRadius: .ratio(0.55), angularInset: 2)
                    .foregroundStyle(item.2)
                    .cornerRadius(4)
            }
        }
        .frame(height: 160)
        .animation(.easeInOut, value: proteins)
        .animation(.easeInOut, value: carbs)
        .animation(.easeInOut, value: fats)
    }

    private var macroBarFallback: some View {
        let total = Double(proteins * 4 + carbs * 4 + fats * 9)
        return GeometryReader { proxy in
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 6).fill(DesignSystem.Colors.teal)
                    .frame(width: proxy.size.width * CGFloat(proteins * 4) / CGFloat(max(Int(total), 1)))
                RoundedRectangle(cornerRadius: 6).fill(DesignSystem.Colors.amber)
                    .frame(width: proxy.size.width * CGFloat(carbs * 4) / CGFloat(max(Int(total), 1)))
                RoundedRectangle(cornerRadius: 6).fill(DesignSystem.Colors.limeDark)
            }
            .frame(height: 24)
        }
        .frame(height: 24)
    }

    private func macroLegend(_ label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
        }
    }

    private func macroField(_ title: String, value: Binding<Int>, color: Color) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(DesignSystem.Typography.labelSM()).foregroundStyle(color)
                TextField("", value: value, format: .number)
                    .keyboardType(.numberPad)
                    .font(.custom("Archivo-Black", size: 20))
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Text("g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
        }
    }

    // MARK: Step 2 — Struttura settimanale
    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Passo 3 · Struttura settimanale")
            Text("Organizza i pasti")
                .font(.custom("Archivo-ExtraBold", size: 26))
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
            Text("Tocca un giorno per impostare pasti e alimenti.")
                .font(DesignSystem.Typography.bodySM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)

            LazyVStack(spacing: 10) {
                ForEach(nutritionDays) { day in
                    NutritionWeekDayRow(day: day) {
                        selectedDayForEdit = IdentifiableInt(id: day.dayIndex)
                    }
                }
            }
        }
    }

    private func buildDefaultDays() {
        nutritionDays = (1...7).map { idx in
            NutritionDay(
                id: UUID(),
                dayIndex: idx,
                label: weekdayLabels[idx - 1],
                meals: mealSlots.enumerated().map { i, name in
                    Meal(id: UUID(), name: name, time: .daysFromNow(0, hour: mealHours[i]), foods: [], notes: "", dayIndex: idx)
                }
            )
        }
    }

    private func importSavedMeal(_ saved: SavedMeal, toDayIndex: Int, mealSlotName: String) {
        guard let dayIndex = nutritionDays.firstIndex(where: { $0.dayIndex == toDayIndex }) else { return }
        let food = MealFood(id: UUID(), name: saved.name, quantity: saved.description, notes: saved.notes, proteinGrams: saved.proteinGrams, carbGrams: saved.carbGrams, fatGrams: saved.fatGrams)
        if let mealIndex = nutritionDays[dayIndex].meals.firstIndex(where: { $0.name == mealSlotName }) {
            nutritionDays[dayIndex].meals[mealIndex].foods.append(food)
        } else {
            let meal = Meal(id: UUID(), name: mealSlotName, time: Date(), foods: [food], notes: "", dayIndex: toDayIndex)
            nutritionDays[dayIndex].meals.append(meal)
        }
    }

    private func createPlan() {
        guard let client = selectedClient else { return }
        let allMeals = nutritionDays.flatMap(\.meals)
        let plan = NutritionPlan(
            id: UUID(),
            trainerID: client.trainerID,
            clientID: client.id,
            dailyCalories: computedCalories,
            proteinGrams: proteins,
            carbohydrateGrams: carbs,
            fatGrams: fats,
            targetWeightKg: targetWeight,
            notes: planNotes,
            startDate: Date(),
            endDate: .daysFromNow(30),
            meals: allMeals
        )
        onCreate(plan)
        dismiss()
    }
}

// MARK: - Helpers
struct IdentifiableInt: Identifiable { var id: Int }

// MARK: - Nutrition Day model (local)
struct NutritionDay: Identifiable {
    var id: UUID
    var dayIndex: Int
    var label: String
    var meals: [Meal]

    var totalKcal: Int { meals.flatMap(\.foods).reduce(0) { $0 + Int($1.kcal) } }
    var totalProtein: Double { meals.flatMap(\.foods).reduce(0) { $0 + $1.proteinGrams } }
    var totalCarb: Double { meals.flatMap(\.foods).reduce(0) { $0 + $1.carbGrams } }
    var totalFat: Double { meals.flatMap(\.foods).reduce(0) { $0 + $1.fatGrams } }
}

struct NutritionDayCard: View {
    @Binding var day: NutritionDay
    let mealSlots: [String]
    let onAddMeal: (String) -> Void
    let onDelete: () -> Void
    @State private var isExpanded = true
    @State private var addingMealSlot: String? = nil

    var body: some View {
        FitCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TextField("Nome giorno", text: $day.label)
                        .font(.custom("Archivo-ExtraBold", size: 15))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Spacer()
                    if day.totalKcal > 0 {
                        Text("\(day.totalKcal) kcal")
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.teal)
                    }
                    Button { withAnimation { isExpanded.toggle() } } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold)).foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash").foregroundStyle(AppColors.dangerRed).font(.caption.weight(.bold))
                    }
                }

                if isExpanded {
                    Divider()
                    ForEach($day.meals) { $meal in
                        MealEntryCard(meal: $meal, onDelete: { day.meals.removeAll { $0.id == meal.id } }, onAddFromSaved: { onAddMeal(meal.name) })
                    }
                    Menu {
                        ForEach(mealSlots, id: \.self) { slot in
                            Button(slot) {
                                let newMeal = Meal(id: UUID(), name: slot, time: Date(), foods: [], notes: "", dayIndex: day.dayIndex)
                                day.meals.append(newMeal)
                            }
                        }
                    } label: {
                        Label("Aggiungi pasto", systemImage: "plus")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.teal)
                    }
                    if day.totalKcal > 0 {
                        Divider()
                        HStack(spacing: 10) {
                            macroChip("P \(Int(day.totalProtein))g", DesignSystem.Colors.teal)
                            macroChip("C \(Int(day.totalCarb))g", DesignSystem.Colors.amber)
                            macroChip("G \(Int(day.totalFat))g", DesignSystem.Colors.limeDark)
                            Spacer()
                            Text("\(day.totalKcal) kcal totali")
                                .font(DesignSystem.Typography.labelSM())
                                .foregroundStyle(DesignSystem.Colors.teal)
                        }
                    }
                }
            }
        }
    }

    private func macroChip(_ text: String, _ color: Color) -> some View {
        Text(text).font(DesignSystem.Typography.labelSM()).foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }
}

struct MealEntryCard: View {
    @Binding var meal: Meal
    let onDelete: () -> Void
    let onAddFromSaved: () -> Void
    @State private var isExpanded = false

    var mealKcal: Int { meal.foods.reduce(0) { $0 + Int($1.kcal) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.teal)
                TextField("Nome pasto", text: $meal.name)
                    .font(DesignSystem.Typography.labelMD())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                Spacer()
                if mealKcal > 0 {
                    Text("\(mealKcal) kcal")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Button { withAnimation { isExpanded.toggle() } } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold)).foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Menu {
                    Button("Aggiungi da pasti salvati", action: onAddFromSaved)
                    Button("Elimina pasto", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis").foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
            if isExpanded {
                ForEach($meal.foods) { $food in
                    MealFoodRow(food: $food, onDelete: { meal.foods.removeAll { $0.id == food.id } })
                }
                Button {
                    meal.foods.append(MealFood(id: UUID(), name: "", quantity: "", notes: "", proteinGrams: 0, carbGrams: 0, fatGrams: 0))
                } label: {
                    Label("Aggiungi alimento", systemImage: "plus")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.teal)
                }
                .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
        Divider()
    }
}

struct MealFoodRow: View {
    @Binding var food: MealFood
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Alimento", text: $food.name)
                    .font(DesignSystem.Typography.bodySM())
                    .foregroundStyle(DesignSystem.Colors.txtPrimary)
                TextField("Quantità", text: $food.quantity)
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.txtSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    miniMacro("P", $food.proteinGrams)
                    miniMacro("C", $food.carbGrams)
                    miniMacro("G", $food.fatGrams)
                }
                if food.kcal > 0 {
                    Text("\(Int(food.kcal))kcal")
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.teal)
                }
            }
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill").foregroundStyle(AppColors.dangerRed).font(.footnote)
            }
        }
        .padding(.leading, 8)
    }

    private func miniMacro(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 1) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(DesignSystem.Colors.txtSecondary)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.txtPrimary)
                .frame(width: 26)
        }
    }
}

struct SavedMealPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meals: [SavedMeal]
    let onSelect: (SavedMeal) -> Void

    var body: some View {
        NavigationStack {
            List(meals) { meal in
                Button {
                    onSelect(meal)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name).font(.custom("Archivo-ExtraBold", size: 15)).foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(meal.description).font(DesignSystem.Typography.bodySM()).foregroundStyle(DesignSystem.Colors.txtSecondary).lineLimit(1)
                        HStack(spacing: 6) {
                            Text("P \(Int(meal.proteinGrams))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.teal)
                            Text("C \(Int(meal.carbGrams))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.amber)
                            Text("G \(Int(meal.fatGrams))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.limeDark)
                            Text("· \(Int(meal.kcal)) kcal").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.txtSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Pasti salvati")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
        .appScreen()
    }
}

// MARK: - NutritionWeekDayRow

private struct NutritionWeekDayRow: View {
    let day: NutritionDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            FitCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(day.totalKcal > 0 ? DesignSystem.Colors.teal : DesignSystem.Colors.bgLine)
                        Text("\(day.dayIndex)")
                            .font(.custom("Archivo-Black", size: 14))
                            .foregroundStyle(day.totalKcal > 0 ? .white : DesignSystem.Colors.txtSecondary)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.label)
                            .font(.custom("Archivo-ExtraBold", size: 15))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(daySummary)
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    if day.totalKcal > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.teal)
                            .font(.body)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var daySummary: String {
        if day.totalKcal > 0 {
            return "\(day.meals.count) pasti · \(day.totalKcal) kcal"
        }
        return day.meals.isEmpty ? "Nessun pasto" : "\(day.meals.count) pasti · nessun alimento"
    }
}

// MARK: - NutritionDayDetailSheet

struct NutritionDayDetailSheet: View {
    @Binding var day: NutritionDay
    let mealSlots: [String]
    let mealHours: [Int]
    let catalogService: CatalogService?
    @Environment(\.dismiss) private var dismiss
    @State private var editingMealIdx: IdentifiableInt? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if day.totalKcal > 0 {
                        FitCard {
                            HStack(spacing: 14) {
                                FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(day.totalKcal) kcal totali")
                                        .font(.custom("Archivo-ExtraBold", size: 18))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    HStack(spacing: 8) {
                                        macroChip("P \(Int(day.totalProtein))g", DesignSystem.Colors.teal)
                                        macroChip("C \(Int(day.totalCarb))g", DesignSystem.Colors.amber)
                                        macroChip("G \(Int(day.totalFat))g", DesignSystem.Colors.limeDark)
                                    }
                                }
                            }
                        }
                    }

                    SectionLabel(text: "Pasti")
                    LazyVStack(spacing: 10) {
                        ForEach(day.meals.indices, id: \.self) { idx in
                            mealRow(idx: idx)
                        }
                    }

                    Menu {
                        ForEach(mealSlots, id: \.self) { slot in
                            Button(slot) {
                                let hour = mealHourFor(slot)
                                day.meals.append(Meal(id: UUID(), name: slot, time: .daysFromNow(0, hour: hour), foods: [], notes: "", dayIndex: day.dayIndex))
                            }
                        }
                    } label: {
                        Label("Aggiungi pasto", systemImage: "plus")
                            .font(DesignSystem.Typography.labelMD())
                            .foregroundStyle(DesignSystem.Colors.teal)
                    }
                    .padding(.top, 2)
                }
                .padding(20)
            }
            .navigationTitle(day.label)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.teal)
                }
            }
            .sheet(item: $editingMealIdx) { item in
                if item.id < day.meals.count {
                    MealFoodEditorSheet(meal: $day.meals[item.id], catalogService: catalogService)
                }
            }
            .appScreen()
        }
    }

    private func mealRow(idx: Int) -> some View {
        let meal = day.meals[idx]
        let mealKcal = meal.foods.reduce(0) { $0 + Int($1.kcal) }
        return Button { editingMealIdx = IdentifiableInt(id: idx) } label: {
            FitCard {
                HStack(spacing: 12) {
                    Image(systemName: mealIcon(meal.name))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.teal)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.Colors.tealBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.custom("Archivo-ExtraBold", size: 15))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(meal.foods.isEmpty
                             ? "Tocca per aggiungere alimenti"
                             : "\(meal.foods.count) alimenti · \(mealKcal) kcal")
                            .font(DesignSystem.Typography.bodySM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    if !meal.foods.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.teal)
                            .font(.body)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func macroChip(_ text: String, _ color: Color) -> some View {
        Text(text).font(DesignSystem.Typography.labelSM()).foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }

    private func mealIcon(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("colazione") { return "sunrise.fill" }
        if n.contains("spuntino") && n.contains("matt") { return "cup.and.saucer.fill" }
        if n.contains("pranzo") { return "sun.max.fill" }
        if n.contains("spuntino") { return "apple.logo" }
        if n.contains("cena") { return "moon.fill" }
        if n.contains("nanna") || n.contains("pre") { return "moon.zzz.fill" }
        return "fork.knife"
    }

    private func mealHourFor(_ name: String) -> Int {
        let n = name.lowercased()
        if n.contains("colazione") { return 7 }
        if n.contains("matt") { return 10 }
        if n.contains("pranzo") { return 13 }
        if n.contains("pomer") { return 16 }
        if n.contains("cena") { return 20 }
        if n.contains("nanna") { return 22 }
        return mealHours.first ?? 12
    }
}

// MARK: - MealFoodEditorSheet

struct MealFoodEditorSheet: View {
    @Binding var meal: Meal
    let catalogService: CatalogService?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var catalog: [FoodCatalogDTO] = []
    @State private var selectedFood: FoodCatalogDTO? = nil
    @State private var quantityGrams: Double = 100
    @State private var isLoadingCatalog = false

    private var filtered: [FoodCatalogDTO] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return Array(catalog.filter { $0.name.localizedCaseInsensitiveContains(q) }.prefix(20))
    }

    private var mealKcal: Int { meal.foods.reduce(0) { $0 + Int($1.kcal) } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarView(text: $searchText, placeholder: "Cerca alimento nel catalogo…")
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                Divider().background(DesignSystem.Colors.bgLine)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let food = selectedFood {
                            addFoodPanel(food)
                        } else if !filtered.isEmpty {
                            searchResultsSection
                        } else if isLoadingCatalog {
                            HStack { Spacer(); ProgressView(); Spacer() }.padding(.top, 30)
                        } else if meal.foods.isEmpty && searchText.isEmpty {
                            emptyPrompt
                        }

                        if !meal.foods.isEmpty {
                            SectionLabel(text: "Nel pasto")
                            LazyVStack(spacing: 8) {
                                ForEach($meal.foods) { $food in
                                    addedFoodRow($food) {
                                        meal.foods.removeAll { $0.id == food.id }
                                    }
                                }
                            }
                            mealTotalsCard
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }.foregroundStyle(DesignSystem.Colors.teal)
                }
                ToolbarItem(placement: .cancellationAction) {
                    if selectedFood != nil {
                        Button("Annulla") { selectedFood = nil; quantityGrams = 100 }
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                }
            }
            .appScreen()
            .task {
                isLoadingCatalog = true
                catalog = await catalogService?.fetchFoodCatalog() ?? []
                isLoadingCatalog = false
            }
        }
    }

    // MARK: Search results
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Risultati")
            LazyVStack(spacing: 8) {
                ForEach(filtered) { food in
                    Button {
                        selectedFood = food
                        quantityGrams = 100
                        searchText = ""
                    } label: {
                        FitCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.name)
                                        .font(.custom("Archivo-ExtraBold", size: 14))
                                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                                    Text(food.category)
                                        .font(DesignSystem.Typography.labelSM())
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let kcal = food.caloriesPer100g {
                                        Text("\(kcal) kcal")
                                            .font(DesignSystem.Typography.labelSM())
                                            .foregroundStyle(DesignSystem.Colors.teal)
                                    }
                                    Text("per 100\(food.unit)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                                }
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(DesignSystem.Colors.teal)
                                    .font(.title3)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Add food panel
    private func addFoodPanel(_ food: FoodCatalogDTO) -> some View {
        FitCard(background: DesignSystem.Colors.tealBg, border: DesignSystem.Colors.teal) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(food.name)
                            .font(.custom("Archivo-ExtraBold", size: 16))
                            .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        Text(food.category)
                            .font(DesignSystem.Typography.labelSM())
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    Spacer()
                    Button { selectedFood = nil; quantityGrams = 100 } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Text("Quantità")
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                    Spacer()
                    TextField("100", value: $quantityGrams, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.custom("Archivo-Black", size: 22))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                    Text(food.unit)
                        .font(DesignSystem.Typography.labelMD())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }

                HStack(spacing: 8) {
                    nutritionPill("\(Int(computedKcal(food))) kcal", DesignSystem.Colors.teal)
                    nutritionPill("P \(Int(computedMacro(food.proteinsPer100g)))g", DesignSystem.Colors.teal)
                    nutritionPill("C \(Int(computedMacro(food.carbsPer100g)))g", DesignSystem.Colors.amber)
                    nutritionPill("G \(Int(computedMacro(food.fatsPer100g)))g", DesignSystem.Colors.limeDark)
                }
                .animation(.easeInOut(duration: 0.18), value: quantityGrams)

                AccentButton(title: "Aggiungi al pasto", color: DesignSystem.Colors.teal) {
                    commitFood(food)
                }
            }
        }
    }

    // MARK: Added food row
    private func addedFoodRow(_ food: Binding<MealFood>, onDelete: @escaping () -> Void) -> some View {
        FitCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(food.name.wrappedValue)
                        .font(.custom("Archivo-ExtraBold", size: 14))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                    Text(food.quantity.wrappedValue)
                        .font(DesignSystem.Typography.labelSM())
                        .foregroundStyle(DesignSystem.Colors.txtSecondary)
                }
                Spacer()
                Text("\(Int(food.wrappedValue.kcal)) kcal")
                    .font(DesignSystem.Typography.labelSM())
                    .foregroundStyle(DesignSystem.Colors.teal)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").font(.footnote).foregroundStyle(AppColors.dangerRed)
                }
            }
        }
    }

    // MARK: Meal totals
    private var mealTotalsCard: some View {
        FitCard {
            HStack(spacing: 14) {
                FitIconChip(systemName: "flame.fill", color: DesignSystem.Colors.teal, background: DesignSystem.Colors.tealBg, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(mealKcal) kcal")
                        .font(.custom("Archivo-ExtraBold", size: 18))
                        .foregroundStyle(DesignSystem.Colors.txtPrimary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: mealKcal)
                    HStack(spacing: 8) {
                        Text("P \(Int(meal.foods.reduce(0) { $0 + $1.proteinGrams }))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.teal)
                        Text("C \(Int(meal.foods.reduce(0) { $0 + $1.carbGrams }))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.amber)
                        Text("G \(Int(meal.foods.reduce(0) { $0 + $1.fatGrams }))g").font(DesignSystem.Typography.labelSM()).foregroundStyle(DesignSystem.Colors.limeDark)
                    }
                }
            }
        }
    }

    // MARK: Empty state
    private var emptyPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(DesignSystem.Colors.txtSecondary.opacity(0.35))
            Text("Cerca un alimento per aggiungerlo al pasto.")
                .font(DesignSystem.Typography.bodySM())
                .foregroundStyle(DesignSystem.Colors.txtSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
    }

    // MARK: Helpers
    private func computedKcal(_ food: FoodCatalogDTO) -> Double {
        if let base = food.caloriesPer100g { return Double(base) * quantityGrams / 100 }
        return computedMacro(food.proteinsPer100g) * 4 +
               computedMacro(food.carbsPer100g) * 4 +
               computedMacro(food.fatsPer100g) * 9
    }

    private func computedMacro(_ per100g: Double?) -> Double {
        (per100g ?? 0) * quantityGrams / 100
    }

    private func nutritionPill(_ text: String, _ color: Color) -> some View {
        Text(text).font(DesignSystem.Typography.labelSM()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }

    private func commitFood(_ food: FoodCatalogDTO) {
        let protein = computedMacro(food.proteinsPer100g)
        let carbs   = computedMacro(food.carbsPer100g)
        let fats    = computedMacro(food.fatsPer100g)
        let qty = food.unit.lowercased() == "g" || food.unit.lowercased() == "ml"
            ? "\(Int(quantityGrams))\(food.unit)"
            : "\(Int(quantityGrams)) \(food.unit)"
        meal.foods.append(MealFood(id: UUID(), name: food.name, quantity: qty, notes: "", proteinGrams: protein, carbGrams: carbs, fatGrams: fats))
        selectedFood = nil
        quantityGrams = 100
    }
}
