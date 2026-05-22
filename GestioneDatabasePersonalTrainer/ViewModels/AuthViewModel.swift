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
            session = try? await authService.restoreSession()
        }
    }

    func loginTrainer() {
        Task<Void, Never>(priority: nil) {
            isLoading = true
            defer { isLoading = false }
            do {
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
                session = .client(try await authService.registerClientWithInviteCode(code: accessCode, email: email, password: password))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loginTrainerDemo() {
        email = "demo.trainer@test.com"
        password = "DemoTrainer123!"
        loginTrainer()
    }

    func loginClientDemo() {
        email = "demo.cliente@test.com"
        password = "DemoCliente123!"
        loginClientWithEmail()
    }

    func logout() {
        Task<Void, Never>(priority: nil) {
            await authService.logout()
            session = nil
            errorMessage = nil
        }
    }
}
