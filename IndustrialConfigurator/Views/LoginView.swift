import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager

    @State private var name = ""
    @State private var email = ""
    @State private var company = ""
    @State private var showingValidationError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                        .autocapitalization(.words)
                } header: {
                    Text("Account Information")
                }

                Section {
                    Button("Continue") {
                        validateAndLogin()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)

                    Button("Continue as Guest") {
                        userManager.createGuestUser()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Information", isPresented: $showingValidationError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !company.isEmpty
    }

    private func validateAndLogin() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields"
            showingValidationError = true
            return
        }

        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            showingValidationError = true
            return
        }

        userManager.login(email: email, name: name, company: company)
        dismiss()
    }
}

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            List {
                if let user = userManager.currentUser {
                    Section {
                        ProfileInfoRow(label: "Name", value: user.name, icon: "person.fill")
                        ProfileInfoRow(label: "Email", value: user.email, icon: "envelope.fill")
                        ProfileInfoRow(label: "Company", value: user.company, icon: "building.2.fill")
                    } header: {
                        Text("Account Information")
                    }

                    Section {
                        HStack {
                            Label("Saved Configurations", systemImage: "folder.fill")
                            Spacer()
                            Text("\(user.savedConfigurations.count)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Label("Quotes", systemImage: "doc.text.fill")
                            Spacer()
                            Text("\(user.quotes.count)")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Statistics")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    userManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}
