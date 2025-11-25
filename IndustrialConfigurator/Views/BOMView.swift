import SwiftUI

struct BOMView: View {
    let configuration: Configuration
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var showingQuoteGenerated = false
    @State private var generatedQuote: Quote?
    @State private var notes: String = ""

    private let bomService = BOMService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Line Items
                    lineItemsSection

                    // Pricing Breakdown
                    pricingSection

                    // Notes
                    notesSection

                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Bill of Materials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Quote Generated", isPresented: $showingQuoteGenerated) {
                Button("View Quotes") {
                    dismiss()
                }
                Button("OK") {}
            } message: {
                Text("Your quote has been saved successfully")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(configuration.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Label("Updated", systemImage: "clock")
                Text(configuration.updatedAt, style: .date)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let user = userManager.currentUser {
                HStack {
                    Label(user.company, systemImage: "building.2")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var lineItemsSection: some View {
        let bom = bomService.generateBOM(for: configuration)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Components")
                .font(.headline)

            ForEach(bom.lineItems) { item in
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.component.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(item.component.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(bomService.formatPrice(item.totalPrice))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    if !item.component.specifications.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(item.component.specifications), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }

    private var pricingSection: some View {
        let bom = bomService.generateBOM(for: configuration)

        return VStack(spacing: 12) {
            Text("Pricing Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                // Subtotal
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                    Spacer()
                    Text(bomService.formatPrice(bom.subtotal))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Adjustments
                if !bom.adjustments.isEmpty {
                    Divider()

                    ForEach(bom.adjustments) { adjustment in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(adjustment.description)
                                    .font(.subheadline)

                                if adjustment.rule.type == .discount || adjustment.rule.type == .bundleDiscount {
                                    Text("Discount")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Surcharge")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            Spacer()

                            if adjustment.adjustment.type == .percentage {
                                Text(bomService.formatPercentage(adjustment.adjustment.value))
                                    .font(.subheadline)
                                    .foregroundColor(adjustment.adjustment.value < 0 ? .green : .orange)
                            } else {
                                Text(bomService.formatPrice(adjustment.adjustment.value))
                                    .font(.subheadline)
                                    .foregroundColor(adjustment.adjustment.value < 0 ? .green : .orange)
                            }
                        }
                    }
                }

                Divider()

                // Total
                HStack {
                    Text("Total")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text(bomService.formatPrice(bom.total))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)

            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: generateQuote) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Quote")
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: shareConfiguration) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Configuration")
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func generateQuote() {
        guard let user = userManager.currentUser else { return }

        let quote = bomService.generateQuote(
            for: configuration,
            userId: user.id,
            notes: notes.isEmpty ? nil : notes
        )

        userManager.saveQuote(quote)
        generatedQuote = quote
        showingQuoteGenerated = true
    }

    private func shareConfiguration() {
        // In production, implement share functionality
        print("Share configuration: \(configuration.name)")
    }
}
