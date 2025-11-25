import SwiftUI

struct SavedConfigurationsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var userManager: UserManager
    @State private var showingDeleteAlert = false
    @State private var configurationToDelete: Configuration?

    var body: some View {
        NavigationView {
            ZStack {
                if configurationManager.savedConfigurations.isEmpty {
                    emptyStateView
                } else {
                    configurationList
                }
            }
            .navigationTitle("Saved Configurations")
            .alert("Delete Configuration", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let config = configurationToDelete {
                        deleteConfiguration(config)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this configuration?")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Saved Configurations")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Your saved configurations will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var configurationList: some View {
        List {
            ForEach(configurationManager.savedConfigurations) { configuration in
                ConfigurationRow(configuration: configuration)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        loadConfiguration(configuration)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            configurationToDelete = configuration
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private func loadConfiguration(_ configuration: Configuration) {
        configurationManager.loadConfiguration(configuration)
    }

    private func deleteConfiguration(_ configuration: Configuration) {
        configurationManager.deleteConfiguration(configuration)
        userManager.removeConfiguration(configuration.id)
    }
}

struct ConfigurationRow: View {
    let configuration: Configuration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(configuration.name)
                    .font(.headline)

                Spacer()

                Text(configuration.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("\(configuration.selectedComponents.count) components",
                      systemImage: "cube.box")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(BOMService.shared.formatPrice(
                    BOMService.shared.calculateTotalPrice(for: configuration)
                ))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            // Component badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(configuration.selectedComponents.keys).sorted(by: { $0.stepOrder < $1.stepOrder }), id: \.self) { category in
                        Text(category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
