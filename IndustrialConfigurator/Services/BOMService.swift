import Foundation

// MARK: - BOM and Pricing Service
class BOMService {
    static let shared = BOMService()
    private let databaseService = ProductDatabaseService.shared

    private init() {}

    // MARK: - BOM Generation
    func generateBOM(for configuration: Configuration) -> BillOfMaterials {
        // Create line items for each selected component
        let lineItems = configuration.selectedComponents.values.map { component in
            BOMLineItem(component: component, quantity: 1)
        }.sorted { $0.component.category.stepOrder < $1.component.category.stepOrder }

        // Get applicable pricing rules
        let pricingRules = databaseService.getApplicablePricingRules(for: configuration)
        let adjustments = pricingRules.map { PriceAdjustmentDetail(rule: $0) }

        return BillOfMaterials(
            configuration: configuration,
            lineItems: lineItems,
            adjustments: adjustments
        )
    }

    // MARK: - Price Calculation
    func calculateTotalPrice(for configuration: Configuration) -> Decimal {
        let bom = generateBOM(for: configuration)
        return bom.total
    }

    func calculateSubtotal(for configuration: Configuration) -> Decimal {
        return configuration.selectedComponents.values.reduce(Decimal(0)) { total, component in
            total + component.basePrice
        }
    }

    // MARK: - Quote Generation
    func generateQuote(for configuration: Configuration, userId: String, notes: String? = nil) -> Quote {
        let bom = generateBOM(for: configuration)

        // Convert BOM to QuoteBOM for encoding
        let quoteBOM = QuoteBOM(
            subtotal: bom.subtotal,
            total: bom.total,
            items: bom.lineItems.map { item in
                QuoteBOMItem(
                    id: item.id,
                    componentName: item.component.name,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    totalPrice: item.totalPrice
                )
            }
        )

        return Quote(
            configurationId: configuration.id,
            userId: userId,
            billOfMaterials: quoteBOM,
            validDays: 30,
            notes: notes
        )
    }

    // MARK: - Formatting Helpers
    func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }

    func formatPercentage(_ percentage: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: (percentage / 100) as NSDecimalNumber) ?? "0%"
    }
}
