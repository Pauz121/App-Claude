import Foundation

@MainActor
final class MockDatabase {
    static let shared = MockDatabase()

    var trainer: Trainer
    var clients: [Client]
    var appointments: [Appointment]
    var machines: [Machine]
    var workoutPlans: [WorkoutPlan]
    var nutritionPlans: [NutritionPlan]
    var progressEntries: [ProgressEntry]
    var accessCodes: [AccessCode]
    var savedMeals: [SavedMeal]

    private init() {
        let trainerID = UUID(uuidString: "8D3E2657-0500-4D69-A37A-C3BD763C0B01")!
        let userID = UUID(uuidString: "09D4E067-C1D4-4B72-B9B6-7F48CE6B8B01")!
        let clientOneID = UUID(uuidString: "0A1B9425-8E4C-48DD-9DAD-01DA8BFB4D11")!
        let clientTwoID = UUID(uuidString: "E1D24C79-C089-4B91-A00F-1A5A74E8BD22")!
        let clientThreeID = UUID(uuidString: "7CB97F71-3B81-4B7B-A28D-37015D05F5A1")!
        let clientFourID = UUID(uuidString: "C4E09AD7-0647-4833-B2D3-3E60A7984173")!
        let clientFiveID = UUID(uuidString: "52C57134-9C56-42B4-9953-6F20795167A4")!
        let clientSixID = UUID(uuidString: "90D6AC46-A987-41B4-B280-7591D3517E4F")!
        let legPressID = UUID(uuidString: "5526C3D2-48FE-4F25-B0A4-B850E4BFF101")!
        let latMachineID = UUID(uuidString: "0990A818-F772-47D2-A082-A5119E44D201")!

        trainer = Trainer(
            id: trainerID,
            userID: userID,
            firstName: "Marco",
            lastName: "Rinaldi",
            email: "trainer@demo.it",
            studioName: "Rinaldi Performance Studio",
            subscriptionTier: .pro
        )

        clients = [
            Client(
                id: clientOneID,
                trainerID: trainerID,
                firstName: "Giulia",
                lastName: "Bianchi",
                email: "giulia.bianchi@example.com",
                phone: "+39 333 128 4501",
                birthDate: .daysFromNow(-10950),
                heightCm: 168,
                initialWeightKg: 68.4,
                currentWeightKg: 64.8,
                goal: "Ricomposizione corporea",
                accessCode: "PT-8F92KQ",
                joinedAt: .daysFromNow(-46),
                trainerNotes: "Ottima costanza. Preferisce sessioni mattutine."
            ),
            Client(
                id: clientTwoID,
                trainerID: trainerID,
                firstName: "Luca",
                lastName: "Ferrari",
                email: "luca.ferrari@example.com",
                phone: "+39 347 901 1187",
                birthDate: .daysFromNow(-12775),
                heightCm: 181,
                initialWeightKg: 82.0,
                currentWeightKg: 79.6,
                goal: "Ipertrofia e postura",
                accessCode: "PT-4N7YVB",
                joinedAt: .daysFromNow(-18),
                trainerNotes: "Attenzione alla mobilita scapolare."
            ),
            Client(
                id: clientThreeID,
                trainerID: trainerID,
                firstName: "Sofia",
                lastName: "Conti",
                email: "sofia.conti@example.com",
                phone: "+39 320 774 2219",
                birthDate: .daysFromNow(-9490),
                heightCm: 162,
                initialWeightKg: 73.5,
                currentWeightKg: 71.2,
                goal: "Dimagrimento sostenibile",
                accessCode: "PT-2M6XCP",
                isRegistered: true,
                joinedAt: .daysFromNow(-7),
                trainerNotes: "Nuova iscritta. Ha bisogno di routine semplici e obiettivi settimanali."
            ),
            Client(
                id: clientFourID,
                trainerID: trainerID,
                firstName: "Andrea",
                lastName: "Moretti",
                email: "andrea.moretti@example.com",
                phone: "+39 349 662 8104",
                birthDate: .daysFromNow(-11680),
                heightCm: 176,
                initialWeightKg: 75.0,
                currentWeightKg: 75.0,
                goal: "Forza generale",
                accessCode: "PT-9QK3HD",
                isRegistered: false,
                joinedAt: .daysFromNow(-2),
                trainerNotes: "Invito creato, deve ancora completare la registrazione cliente."
            ),
            Client(
                id: clientFiveID,
                trainerID: trainerID,
                firstName: "Martina",
                lastName: "Gallo",
                email: "martina.gallo@example.com",
                phone: "+39 338 219 0045",
                birthDate: .daysFromNow(-13870),
                heightCm: 170,
                initialWeightKg: 62.0,
                currentWeightKg: 61.4,
                goal: "Postura e mobilita",
                accessCode: "PT-6V1LZA",
                isRegistered: true,
                joinedAt: .daysFromNow(-63),
                trainerNotes: "Storico lungo. Evitare overhead press pesante per fastidio cervicale."
            ),
            Client(
                id: clientSixID,
                trainerID: trainerID,
                firstName: "Paolo",
                lastName: "Ricci",
                email: "paolo.ricci@example.com",
                phone: "+39 331 447 9820",
                birthDate: .daysFromNow(-15330),
                heightCm: 184,
                initialWeightKg: 88.5,
                currentWeightKg: 86.9,
                goal: "Preparazione mezza maratona",
                accessCode: "PT-5R8TJN",
                isRegistered: true,
                joinedAt: .daysFromNow(-29),
                trainerNotes: "Integra lavoro di forza con corsa. Monitorare recupero e polpacci."
            )
        ]

        appointments = [
            Appointment(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientOneID,
                date: .daysFromNow(0, hour: 10),
                startTime: .daysFromNow(0, hour: 10),
                endTime: .daysFromNow(0, hour: 11),
                sessionType: .workout,
                notes: "Focus tecnica su squat e spinte.",
                status: .scheduled
            ),
            Appointment(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientTwoID,
                date: .daysFromNow(1, hour: 17),
                startTime: .daysFromNow(1, hour: 17),
                endTime: .daysFromNow(1, hour: 18),
                sessionType: .checkin,
                notes: "Controllo carichi e aderenza alimentare.",
                status: .scheduled
            ),
            Appointment(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientThreeID,
                date: .daysFromNow(0, hour: 15),
                startTime: .daysFromNow(0, hour: 15),
                endTime: .daysFromNow(0, hour: 16),
                sessionType: .assessment,
                notes: "Prima valutazione: misure, anamnesi e piano iniziale.",
                status: .scheduled
            ),
            Appointment(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientFiveID,
                date: .daysFromNow(2, hour: 9),
                startTime: .daysFromNow(2, hour: 9),
                endTime: .daysFromNow(2, hour: 10),
                sessionType: .recovery,
                notes: "Mobilita toracica, anche e scarico cervicale.",
                status: .scheduled
            ),
            Appointment(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientSixID,
                date: .daysFromNow(3, hour: 18),
                startTime: .daysFromNow(3, hour: 18),
                endTime: .daysFromNow(3, hour: 19),
                sessionType: .workout,
                notes: "Forza lower body e prevenzione infortuni corsa.",
                status: .scheduled
            )
        ]

        machines = [
            Machine(id: legPressID, trainerID: trainerID, name: "Leg Press 45", muscleGroup: .legs, description: "Pressa inclinata per quadricipiti e glutei.", usageNotes: "Controllare profondita e ginocchia in linea.", imageName: nil, isAvailable: true),
            Machine(id: latMachineID, trainerID: trainerID, name: "Lat Machine", muscleGroup: .back, description: "Trazione verticale guidata.", usageNotes: "Evitare compensi lombari.", imageName: nil, isAvailable: true),
            Machine(id: UUID(), trainerID: trainerID, name: "Cavi regolabili", muscleGroup: .fullBody, description: "Stazione multifunzione per isolamento e richiamo.", usageNotes: "Verificare altezza carrucole.", imageName: nil, isAvailable: false)
        ]

        let workoutDayOne = WorkoutDay(
            id: UUID(),
            title: "Petto e Tricipiti",
            dayIndex: 1,
            exercises: [
                Exercise(id: UUID(), name: "Panca piana", machineID: nil, muscleGroup: .chest, sets: 4, reps: "8", restSeconds: 90, recommendedLoad: "RPE 8", technicalNotes: "Scapole addotte, traiettoria controllata.", order: 1),
                Exercise(id: UUID(), name: "Croci ai cavi", machineID: nil, muscleGroup: .chest, sets: 3, reps: "12", restSeconds: 60, recommendedLoad: "Moderato", technicalNotes: "Mantieni gomiti morbidi.", order: 2),
                Exercise(id: UUID(), name: "Pushdown corda", machineID: nil, muscleGroup: .triceps, sets: 3, reps: "12-15", restSeconds: 60, recommendedLoad: "Tecnico", technicalNotes: "Estensione completa senza slancio.", order: 3)
            ]
        )

        let workoutDayTwo = WorkoutDay(
            id: UUID(),
            title: "Dorso e Bicipiti",
            dayIndex: 2,
            exercises: [
                Exercise(id: UUID(), name: "Lat machine", machineID: latMachineID, muscleGroup: .back, sets: 4, reps: "10", restSeconds: 75, recommendedLoad: "Progressivo", technicalNotes: "Petto alto e gomiti verso il basso.", order: 1),
                Exercise(id: UUID(), name: "Rematore manubrio", machineID: nil, muscleGroup: .back, sets: 3, reps: "10 per lato", restSeconds: 75, recommendedLoad: "RPE 7", technicalNotes: "Non ruotare il busto.", order: 2),
                Exercise(id: UUID(), name: "Curl manubri", machineID: nil, muscleGroup: .biceps, sets: 3, reps: "12", restSeconds: 60, recommendedLoad: "Controllato", technicalNotes: "Eccentrica lenta.", order: 3)
            ]
        )

        workoutPlans = [
            WorkoutPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientOneID,
                name: "Ipertrofia 4 settimane",
                goal: "Aumento massa magra",
                createdAt: .daysFromNow(-12),
                startDate: .daysFromNow(-10),
                endDate: .daysFromNow(18),
                status: .active,
                days: [workoutDayOne, workoutDayTwo]
            ),
            WorkoutPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientTwoID,
                name: "Forza base 3 giorni",
                goal: "Progressione tecnica su multiarticolari",
                createdAt: .daysFromNow(-8),
                startDate: .daysFromNow(-6),
                endDate: .daysFromNow(22),
                status: .active,
                days: [
                    WorkoutDay(id: UUID(), title: "Lower strength", dayIndex: 1, exercises: [
                        Exercise(id: UUID(), name: "Squat goblet", machineID: nil, muscleGroup: .legs, sets: 4, reps: "8", restSeconds: 90, recommendedLoad: "RPE 7", technicalNotes: "Profondita controllata e schiena neutra.", order: 1),
                        Exercise(id: UUID(), name: "Leg press", machineID: legPressID, muscleGroup: .legs, sets: 3, reps: "10", restSeconds: 90, recommendedLoad: "Progressivo", technicalNotes: "Spingere con tutto il piede.", order: 2)
                    ]),
                    WorkoutDay(id: UUID(), title: "Upper pull", dayIndex: 2, exercises: [
                        Exercise(id: UUID(), name: "Lat machine", machineID: latMachineID, muscleGroup: .back, sets: 4, reps: "8-10", restSeconds: 75, recommendedLoad: "Tecnico", technicalNotes: "Fermare il movimento al petto alto.", order: 1),
                        Exercise(id: UUID(), name: "Face pull", machineID: nil, muscleGroup: .shoulders, sets: 3, reps: "15", restSeconds: 45, recommendedLoad: "Leggero", technicalNotes: "Gomiti alti e scapole attive.", order: 2)
                    ])
                ]
            ),
            WorkoutPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientThreeID,
                name: "Starter total body",
                goal: "Creare abitudine e aumentare dispendio",
                createdAt: .daysFromNow(-3),
                startDate: .daysFromNow(-1),
                endDate: .daysFromNow(27),
                status: .active,
                days: [
                    WorkoutDay(id: UUID(), title: "Circuito full body", dayIndex: 1, exercises: [
                        Exercise(id: UUID(), name: "Box squat", machineID: nil, muscleGroup: .legs, sets: 3, reps: "12", restSeconds: 60, recommendedLoad: "Corpo libero", technicalNotes: "Sedersi sfiorando il box, senza perdere tensione.", order: 1),
                        Exercise(id: UUID(), name: "Chest press manubri", machineID: nil, muscleGroup: .chest, sets: 3, reps: "10", restSeconds: 60, recommendedLoad: "Leggero", technicalNotes: "Movimento lento e controllato.", order: 2),
                        Exercise(id: UUID(), name: "Camminata inclinata", machineID: nil, muscleGroup: .cardio, sets: 1, reps: "15 min", restSeconds: 0, recommendedLoad: "Zona 2", technicalNotes: "Respirazione regolare.", order: 3)
                    ])
                ]
            )
        ]

        nutritionPlans = [
            NutritionPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientOneID,
                dailyCalories: 2050,
                proteinGrams: 140,
                carbohydrateGrams: 230,
                fatGrams: 58,
                targetWeightKg: 63.5,
                notes: "Bere almeno 2 litri d'acqua. Distribuire le proteine nei pasti principali.",
                startDate: .daysFromNow(-7),
                endDate: .daysFromNow(21),
                meals: [
                    Meal(id: UUID(), name: "Colazione", time: .daysFromNow(0, hour: 7, minute: 30), foods: [
                        MealFood(id: UUID(), name: "Yogurt greco", quantity: "170 g", notes: ""),
                        MealFood(id: UUID(), name: "Fiocchi d'avena", quantity: "50 g", notes: "Con frutti rossi")
                    ], notes: "Caffe senza zucchero opzionale."),
                    Meal(id: UUID(), name: "Pranzo", time: .daysFromNow(0, hour: 13), foods: [
                        MealFood(id: UUID(), name: "Riso basmati", quantity: "90 g", notes: "Peso a crudo"),
                        MealFood(id: UUID(), name: "Pollo", quantity: "160 g", notes: "Alla piastra"),
                        MealFood(id: UUID(), name: "Verdure", quantity: "libere", notes: "")
                    ], notes: "Olio EVO 10 g."),
                    Meal(id: UUID(), name: "Cena", time: .daysFromNow(0, hour: 20), foods: [
                        MealFood(id: UUID(), name: "Salmone", quantity: "150 g", notes: ""),
                        MealFood(id: UUID(), name: "Patate", quantity: "250 g", notes: ""),
                        MealFood(id: UUID(), name: "Insalata", quantity: "libera", notes: "")
                    ], notes: "")
                ]
            ),
            NutritionPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientThreeID,
                dailyCalories: 1850,
                proteinGrams: 120,
                carbohydrateGrams: 190,
                fatGrams: 55,
                targetWeightKg: 68.0,
                notes: "Deficit moderato. Inserire verdure in almeno due pasti e camminata post cena.",
                startDate: .daysFromNow(-2),
                endDate: .daysFromNow(28),
                meals: [
                    Meal(id: UUID(), name: "Colazione", time: .daysFromNow(0, hour: 8), foods: [
                        MealFood(id: UUID(), name: "Skyr", quantity: "170 g", notes: ""),
                        MealFood(id: UUID(), name: "Mela", quantity: "1", notes: "")
                    ], notes: ""),
                    Meal(id: UUID(), name: "Pranzo", time: .daysFromNow(0, hour: 13), foods: [
                        MealFood(id: UUID(), name: "Pasta integrale", quantity: "70 g", notes: "Peso a crudo"),
                        MealFood(id: UUID(), name: "Tonno naturale", quantity: "120 g", notes: "")
                    ], notes: "Aggiungere verdure a scelta."),
                    Meal(id: UUID(), name: "Cena", time: .daysFromNow(0, hour: 20), foods: [
                        MealFood(id: UUID(), name: "Tacchino", quantity: "150 g", notes: ""),
                        MealFood(id: UUID(), name: "Zucchine", quantity: "libere", notes: ""),
                        MealFood(id: UUID(), name: "Pane", quantity: "50 g", notes: "")
                    ], notes: "")
                ]
            ),
            NutritionPlan(
                id: UUID(),
                trainerID: trainerID,
                clientID: clientSixID,
                dailyCalories: 2450,
                proteinGrams: 150,
                carbohydrateGrams: 310,
                fatGrams: 70,
                targetWeightKg: 85.5,
                notes: "Carboidrati piu alti nei giorni di corsa. Curare idratazione e sali.",
                startDate: .daysFromNow(-10),
                endDate: .daysFromNow(20),
                meals: [
                    Meal(id: UUID(), name: "Pre-run", time: .daysFromNow(0, hour: 7), foods: [
                        MealFood(id: UUID(), name: "Banana", quantity: "1", notes: ""),
                        MealFood(id: UUID(), name: "Pane tostato", quantity: "60 g", notes: "Con miele")
                    ], notes: "Solo nei giorni di corsa mattutina."),
                    Meal(id: UUID(), name: "Pranzo", time: .daysFromNow(0, hour: 13), foods: [
                        MealFood(id: UUID(), name: "Riso", quantity: "110 g", notes: "Peso a crudo"),
                        MealFood(id: UUID(), name: "Manzo magro", quantity: "160 g", notes: "")
                    ], notes: ""),
                    Meal(id: UUID(), name: "Cena", time: .daysFromNow(0, hour: 20), foods: [
                        MealFood(id: UUID(), name: "Merluzzo", quantity: "180 g", notes: ""),
                        MealFood(id: UUID(), name: "Patate", quantity: "300 g", notes: "")
                    ], notes: "")
                ]
            )
        ]

        progressEntries = [
            ProgressEntry(id: UUID(), clientID: clientOneID, date: .daysFromNow(-21), weightKg: 66.7, waistCm: 75, chestCm: 91, armCm: 29, legCm: 53, frontPhotoName: "progress_front_1", sidePhotoName: "progress_side_1", backPhotoName: nil, notes: "Primo controllo positivo."),
            ProgressEntry(id: UUID(), clientID: clientOneID, date: .daysFromNow(-4), weightKg: 64.8, waistCm: 72, chestCm: 90, armCm: 29.5, legCm: 53.5, frontPhotoName: "progress_front_2", sidePhotoName: "progress_side_2", backPhotoName: "progress_back_2", notes: "Migliore definizione addominale."),
            ProgressEntry(id: UUID(), clientID: clientTwoID, date: .daysFromNow(-15), weightKg: 81.4, waistCm: 86, chestCm: 101, armCm: 35, legCm: 58, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Inizio blocco forza."),
            ProgressEntry(id: UUID(), clientID: clientTwoID, date: .daysFromNow(-3), weightKg: 79.6, waistCm: 84, chestCm: 101, armCm: 35.5, legCm: 58.5, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Carichi in crescita, postura migliorata."),
            ProgressEntry(id: UUID(), clientID: clientThreeID, date: .daysFromNow(-6), weightKg: 73.5, waistCm: 82, chestCm: 94, armCm: 31, legCm: 55, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Valutazione iniziale."),
            ProgressEntry(id: UUID(), clientID: clientThreeID, date: .daysFromNow(-1), weightKg: 71.2, waistCm: 80, chestCm: 93, armCm: 31, legCm: 54.5, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Buona risposta alla prima settimana."),
            ProgressEntry(id: UUID(), clientID: clientFiveID, date: .daysFromNow(-45), weightKg: 62.0, waistCm: 70, chestCm: 88, armCm: 28, legCm: 51, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Baseline mobilita."),
            ProgressEntry(id: UUID(), clientID: clientSixID, date: .daysFromNow(-20), weightKg: 87.8, waistCm: 89, chestCm: 104, armCm: 36, legCm: 60, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Inizio preparazione corsa."),
            ProgressEntry(id: UUID(), clientID: clientSixID, date: .daysFromNow(-5), weightKg: 86.9, waistCm: 88, chestCm: 104, armCm: 36, legCm: 60.5, frontPhotoName: nil, sidePhotoName: nil, backPhotoName: nil, notes: "Volume corsa tollerato bene.")
        ]

        accessCodes = clients.map {
            AccessCode(id: UUID(), code: $0.accessCode, trainerID: trainerID, clientID: $0.id, createdAt: $0.joinedAt, isActive: true)
        }
        savedMeals = [
            SavedMeal(id: UUID(), trainerID: trainerID, name: "Colazione proteica", description: "Yogurt greco + avena + frutti rossi", proteinGrams: 28, carbGrams: 42, fatGrams: 6, notes: "", createdAt: Date()),
            SavedMeal(id: UUID(), trainerID: trainerID, name: "Pranzo base", description: "Riso + pollo + verdure", proteinGrams: 45, carbGrams: 65, fatGrams: 10, notes: "Olio EVO 10g aggiuntivo", createdAt: Date()),
            SavedMeal(id: UUID(), trainerID: trainerID, name: "Cena leggera", description: "Salmone + patate + insalata", proteinGrams: 38, carbGrams: 38, fatGrams: 20, notes: "", createdAt: Date()),
            SavedMeal(id: UUID(), trainerID: trainerID, name: "Spuntino proteico", description: "Skyr + mandorle", proteinGrams: 18, carbGrams: 14, fatGrams: 9, notes: "", createdAt: Date())
        ]
    }
}
