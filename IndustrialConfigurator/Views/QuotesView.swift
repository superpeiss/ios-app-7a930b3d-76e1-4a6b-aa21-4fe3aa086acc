import SwiftUI

struct QuotesView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedQuote: Quote?
    @State private var showingQuoteDetail = false
    @State private var showingDeleteAlert = false
    @State private var quoteToDelete: Quote?

    var body: some View {
        NavigationView {
            ZStack {
                if userManager.getUserQuotes().isEmpty {
                    emptyStateView
                } else {
                    quoteList
                }
            }
            .navigationTitle("Quotes")
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
            }
            .alert("Delete Quote", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let quote = quoteToDelete {
                        userManager.deleteQuote(quote)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this quote?")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Quotes")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Generate quotes from your configurations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var quoteList: some View {
        List {
            ForEach(userManager.getUserQuotes().sorted(by: { $0.createdAt > $1.createdAt })) { quote in
                QuoteRow(quote: quote)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedQuote = quote
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            quoteToDelete = quote
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
}

struct QuoteRow: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quote #\(quote.id.prefix(8))")
                    .font(.headline)

                Spacer()

                statusBadge
            }

            HStack {
                Label("Created", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(quote.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("Valid until", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(quote.validUntil, style: .date)
                    .font(.caption)
                    .foregroundColor(quote.validUntil < Date() ? .red : .secondary)
            }

            HStack {
                Label("\(quote.billOfMaterials.items.count) items",
                      systemImage: "list.bullet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(BOMService.shared.formatPrice(quote.billOfMaterials.total))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let (text, color) = statusInfo

        return Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private var statusInfo: (String, Color) {
        if quote.validUntil < Date() {
            return ("Expired", .red)
        }

        switch quote.status {
        case .draft:
            return ("Draft", .gray)
        case .pending:
            return ("Pending", .orange)
        case .approved:
            return ("Approved", .green)
        case .rejected:
            return ("Rejected", .red)
        case .expired:
            return ("Expired", .red)
        }
    }
}

struct QuoteDetailView: View {
    let quote: Quote
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Items
                    itemsSection

                    // Pricing
                    pricingSection

                    // Notes
                    if let notes = quote.notes {
                        notesSection(notes)
                    }
                }
                .padding()
            }
            .navigationTitle("Quote Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quote #\(quote.id.prefix(8))")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                statusBadge
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Created:")
                        .foregroundColor(.secondary)
                    Text(quote.createdAt, style: .date)
                }

                HStack {
                    Text("Valid Until:")
                        .foregroundColor(.secondary)
                    Text(quote.validUntil, style: .date)
                        .foregroundColor(quote.validUntil < Date() ? .red : .primary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var statusBadge: some View {
        let (text, color) = statusInfo

        return Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private var statusInfo: (String, Color) {
        if quote.validUntil < Date() {
            return ("Expired", .red)
        }

        switch quote.status {
        case .draft:
            return ("Draft", .gray)
        case .pending:
            return ("Pending", .orange)
        case .approved:
            return ("Approved", .green)
        case .rejected:
            return ("Rejected", .red)
        case .expired:
            return ("Expired", .red)
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)

            ForEach(quote.billOfMaterials.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.componentName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Qty: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(BOMService.shared.formatPrice(item.unitPrice))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(BOMService.shared.formatPrice(item.totalPrice))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(BOMService.shared.formatPrice(quote.billOfMaterials.subtotal))
            }
            .font(.subheadline)

            Divider()

            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(BOMService.shared.formatPrice(quote.billOfMaterials.total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}
