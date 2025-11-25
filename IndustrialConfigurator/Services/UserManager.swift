import Foundation
import Combine

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var savedQuotes: [Quote] = []

    private init() {
        loadCurrentUser()
        loadSavedQuotes()
    }

    // MARK: - User Authentication
    func login(email: String, name: String, company: String) {
        // In production, this would authenticate with a server
        let user = User(name: name, email: email, company: company)
        currentUser = user
        isLoggedIn = true
        persistCurrentUser()
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    func createGuestUser() {
        let user = User(name: "Guest User", email: "guest@example.com", company: "Guest")
        currentUser = user
        isLoggedIn = true
    }

    // MARK: - Configuration Management
    func saveConfiguration(_ configurationId: String) {
        guard var user = currentUser else { return }

        if !user.savedConfigurations.contains(configurationId) {
            user.savedConfigurations.append(configurationId)
            currentUser = user
            persistCurrentUser()
        }
    }

    func removeConfiguration(_ configurationId: String) {
        guard var user = currentUser else { return }

        user.savedConfigurations.removeAll { $0 == configurationId }
        currentUser = user
        persistCurrentUser()
    }

    // MARK: - Quote Management
    func saveQuote(_ quote: Quote) {
        guard var user = currentUser else { return }

        // Add quote to saved quotes
        if let index = savedQuotes.firstIndex(where: { $0.id == quote.id }) {
            savedQuotes[index] = quote
        } else {
            savedQuotes.append(quote)
        }

        // Add quote ID to user
        if !user.quotes.contains(quote.id) {
            user.quotes.append(quote.id)
            currentUser = user
            persistCurrentUser()
        }

        persistQuotes()
    }

    func deleteQuote(_ quote: Quote) {
        guard var user = currentUser else { return }

        savedQuotes.removeAll { $0.id == quote.id }
        user.quotes.removeAll { $0 == quote.id }
        currentUser = user

        persistCurrentUser()
        persistQuotes()
    }

    func getQuote(byId id: String) -> Quote? {
        return savedQuotes.first { $0.id == id }
    }

    func getUserQuotes() -> [Quote] {
        guard let user = currentUser else { return [] }
        return savedQuotes.filter { user.quotes.contains($0.id) }
    }

    // MARK: - Persistence
    private func loadCurrentUser() {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        currentUser = user
        isLoggedIn = true
    }

    private func persistCurrentUser() {
        guard let user = currentUser,
              let data = try? JSONEncoder().encode(user) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "currentUser")
    }

    private func loadSavedQuotes() {
        guard let data = UserDefaults.standard.data(forKey: "savedQuotes"),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data) else {
            return
        }
        savedQuotes = quotes
    }

    private func persistQuotes() {
        guard let data = try? JSONEncoder().encode(savedQuotes) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "savedQuotes")
    }
}
