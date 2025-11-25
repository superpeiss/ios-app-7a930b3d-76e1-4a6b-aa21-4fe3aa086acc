import Foundation
import Combine

// MARK: - Configuration Manager
class ConfigurationManager: ObservableObject {
    @Published var currentConfiguration: Configuration
    @Published var savedConfigurations: [Configuration] = []

    private let databaseService = ProductDatabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.currentConfiguration = Configuration(name: "New Configuration")
        loadSavedConfigurations()
    }

    // MARK: - Configuration Management
    func createNewConfiguration() {
        currentConfiguration = Configuration(name: "New Configuration \(savedConfigurations.count + 1)")
    }

    func saveConfiguration() {
        if let index = savedConfigurations.firstIndex(where: { $0.id == currentConfiguration.id }) {
            savedConfigurations[index] = currentConfiguration
        } else {
            savedConfigurations.append(currentConfiguration)
        }
        persistConfigurations()
    }

    func loadConfiguration(_ configuration: Configuration) {
        currentConfiguration = configuration
    }

    func deleteConfiguration(_ configuration: Configuration) {
        savedConfigurations.removeAll { $0.id == configuration.id }
        persistConfigurations()
    }

    // MARK: - Component Selection
    func selectComponent(_ component: Component) {
        currentConfiguration.selectComponent(component)
        objectWillChange.send()
    }

    func removeComponent(for category: ComponentCategory) {
        currentConfiguration.removeComponent(for: category)
        objectWillChange.send()
    }

    func getCompatibleComponents(for category: ComponentCategory) -> [Component] {
        return databaseService.getCompatibleComponents(for: currentConfiguration, targetCategory: category)
    }

    func getNextCategory() -> ComponentCategory? {
        let allCategories = ComponentCategory.allCases.sorted { $0.stepOrder < $1.stepOrder }
        let selectedCategories = Set(currentConfiguration.selectedComponents.keys)

        return allCategories.first { category in
            !selectedCategories.contains(category)
        }
    }

    func isConfigurationValid() -> Bool {
        // Must have at least a base component
        guard currentConfiguration.selectedComponents[.base] != nil else {
            return false
        }

        // Validate compatibility chain
        let selectedComponents = currentConfiguration.selectedComponents.values
        for component in selectedComponents {
            for otherComponent in selectedComponents {
                if component.id != otherComponent.id {
                    let compatible = databaseService.getCompatibleComponents(
                        for: component,
                        targetCategory: otherComponent.category
                    )
                    if !compatible.isEmpty && !compatible.contains(where: { $0.id == otherComponent.id }) {
                        return false
                    }
                }
            }
        }

        return true
    }

    // MARK: - Persistence
    private func loadSavedConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: "savedConfigurations"),
              let configurations = try? JSONDecoder().decode([Configuration].self, from: data) else {
            return
        }
        savedConfigurations = configurations
    }

    private func persistConfigurations() {
        guard let data = try? JSONEncoder().encode(savedConfigurations) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "savedConfigurations")
    }
}
