import SwiftUI

struct ConfiguratorView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var userManager: UserManager
    @State private var selectedCategory: ComponentCategory = .base
    @State private var showingBOMSheet = false
    @State private var showingSaveAlert = false
    @State private var configurationName = ""
    @State private var showingSuccessAlert = false

    private let databaseService = ProductDatabaseService.shared

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if geometry.size.width > 768 {
                    // iPad landscape layout
                    HStack(spacing: 0) {
                        componentSelectionPanel
                            .frame(width: geometry.size.width * 0.4)

                        Divider()

                        ThreeDPreviewView(configuration: configurationManager.currentConfiguration)
                            .frame(width: geometry.size.width * 0.6)
                    }
                } else {
                    // iPhone or iPad portrait layout
                    VStack(spacing: 0) {
                        ThreeDPreviewView(configuration: configurationManager.currentConfiguration)
                            .frame(height: geometry.size.height * 0.4)

                        Divider()

                        componentSelectionPanel
                            .frame(height: geometry.size.height * 0.6)
                    }
                }
            }
            .navigationTitle("Configurator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New") {
                        configurationManager.createNewConfiguration()
                        selectedCategory = .base
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSaveAlert = true }) {
                            Label("Save Configuration", systemImage: "square.and.arrow.down")
                        }

                        Button(action: { showingBOMSheet = true }) {
                            Label("View BOM & Quote", systemImage: "doc.text")
                        }
                        .disabled(configurationManager.currentConfiguration.selectedComponents.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Save Configuration", isPresented: $showingSaveAlert) {
                TextField("Configuration Name", text: $configurationName)
                Button("Cancel", role: .cancel) {
                    configurationName = ""
                }
                Button("Save") {
                    saveConfiguration()
                }
            } message: {
                Text("Enter a name for this configuration")
            }
            .alert("Saved", isPresented: $showingSuccessAlert) {
                Button("OK") {}
            } message: {
                Text("Configuration saved successfully")
            }
            .sheet(isPresented: $showingBOMSheet) {
                BOMView(configuration: configurationManager.currentConfiguration)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var componentSelectionPanel: some View {
        VStack(spacing: 0) {
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComponentCategory.allCases) { category in
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category,
                            hasSelection: configurationManager.currentConfiguration.selectedComponents[category] != nil
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))

            Divider()

            // Component List
            componentList
        }
    }

    private var componentList: some View {
        let compatibleComponents = configurationManager.getCompatibleComponents(for: selectedCategory)
        let selectedComponent = configurationManager.currentConfiguration.selectedComponents[selectedCategory]

        return ScrollView {
            LazyVStack(spacing: 12) {
                if compatibleComponents.isEmpty {
                    emptyStateView
                } else {
                    ForEach(compatibleComponents) { component in
                        ComponentCard(
                            component: component,
                            isSelected: selectedComponent?.id == component.id
                        ) {
                            configurationManager.selectComponent(component)
                        } onDeselect: {
                            configurationManager.removeComponent(for: selectedCategory)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("No Compatible Components")
                .font(.headline)

            Text("Please select a \(requiredCategoryName) first")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var requiredCategoryName: String {
        // Find the first missing required category
        if configurationManager.currentConfiguration.selectedComponents[.base] == nil {
            return ComponentCategory.base.rawValue
        }
        return "previous component"
    }

    private func saveConfiguration() {
        if !configurationName.isEmpty {
            configurationManager.currentConfiguration.name = configurationName
        }
        configurationManager.saveConfiguration()
        userManager.saveConfiguration(configurationManager.currentConfiguration.id)
        configurationName = ""
        showingSuccessAlert = true
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: ComponentCategory
    let isSelected: Bool
    let hasSelection: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    if hasSelection {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if isSelected {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .primary : .secondary)
    }
}

// MARK: - Component Card
struct ComponentCard: View {
    let component: Component
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.name)
                        .font(.headline)

                    Text(component.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(BOMService.shared.formatPrice(component.basePrice))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            // Specifications
            if !component.specifications.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(component.specifications.prefix(3)), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(value)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Action Button
            if isSelected {
                Button(action: onDeselect) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Selected")
                        Spacer()
                        Text("Remove")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            } else {
                Button(action: onSelect) {
                    HStack {
                        Spacer()
                        Text("Select Component")
                        Spacer()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
