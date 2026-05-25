import Foundation
import Combine

enum AuthSession {
    case trainer(Trainer)
    case client(Client)
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var session: AuthSession?
    @Published var email = "trainer@demo.it"
    @Published var password = "demo"
    @Published var accessCode = "PT-8F92KQ"
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var businessName = ""
    @Published var selectedPlanSlug = "trial_15"
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func restoreSession() {
        Task<Void, Never>(priority: nil) {
            if let restoredSession = try? await authService.restoreSession() {
                session = restoredSession
            }
        }
    }

    func loginTrainer() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
                AppConfiguration.useMockData = false
                session = .trainer(try await authService.loginTrainer(email: email, password: password))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loginClient() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
                AppConfiguration.useMockData = true
                session = .client(try await authService.loginClient(accessCode: accessCode))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loginClientWithEmail() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
                AppConfiguration.useMockData = false
                session = .client(try await authService.loginClient(email: email, password: password))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func registerTrainer() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
                AppConfiguration.useMockData = false
                session = .trainer(try await authService.registerTrainer(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    businessName: businessName,
                    selectedPlanSlug: selectedPlanSlug
                ))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func registerClientWithInviteCode() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
                AppConfiguration.useMockData = false
                session = .client(try await authService.registerClientWithInviteCode(code: accessCode, email: email, password: password))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loginTrainerDemo() {
        AppConfiguration.isDemoMode = true
        isLoading = false
        AppConfiguration.useMockData = true
        errorMessage = nil
        session = .trainer(authService.demoTrainer())
    }

    func loginClientDemo() {
        AppConfiguration.isDemoMode = true
        isLoading = false
        AppConfiguration.useMockData = true
        do {
            session = .client(try authService.demoClient())
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        AppConfiguration.isDemoMode = false
        Task<Void, Never>(priority: nil) {
            await authService.logout()
            AppConfiguration.useMockData = false
            session = nil
            errorMessage = nil
        }
    }
}
