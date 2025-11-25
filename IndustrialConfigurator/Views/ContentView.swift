import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var configurationManager: ConfigurationManager
    @State private var showingLoginSheet = false

    var body: some View {
        NavigationView {
            if userManager.isLoggedIn {
                mainContent
            } else {
                loginPromptView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingLoginSheet) {
            LoginView()
        }
        .onAppear {
            if !userManager.isLoggedIn {
                userManager.createGuestUser()
            }
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Industrial Configurator")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configure industrial components with precision")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                showingLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var mainContent: some View {
        TabView {
            ConfiguratorView()
                .tabItem {
                    Label("Configure", systemImage: "slider.horizontal.3")
                }

            SavedConfigurationsView()
                .tabItem {
                    Label("Saved", systemImage: "folder.fill")
                }

            QuotesView()
                .tabItem {
                    Label("Quotes", systemImage: "doc.text.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserManager.shared)
            .environmentObject(ConfigurationManager())
    }
}
