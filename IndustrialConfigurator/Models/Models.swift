import Foundation

// MARK: - Component Category
enum ComponentCategory: String, Codable, CaseIterable, Identifiable {
    case base = "Base Component"
    case mounting = "Mounting System"
    case power = "Power Supply"
    case control = "Control Module"
    case sensor = "Sensor"
    case actuator = "Actuator"
    case interface = "Interface Module"
    case housing = "Housing"

    var id: String { rawValue }

    var stepOrder: Int {
        switch self {
        case .base: return 0
        case .mounting: return 1
        case .power: return 2
        case .control: return 3
        case .sensor: return 4
        case .actuator: return 5
        case .interface: return 6
        case .housing: return 7
        }
    }
}

// MARK: - Component
struct Component: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: ComponentCategory
    let description: String
    let basePrice: Decimal
    let specifications: [String: String]
    let compatibilityTags: Set<String>
    let requiredTags: Set<String>
    let modelFileName: String? // 3D model file name
    let thumbnailName: String?

    init(id: String, name: String, category: ComponentCategory, description: String,
         basePrice: Decimal, specifications: [String: String] = [:],
         compatibilityTags: Set<String> = [], requiredTags: Set<String> = [],
         modelFileName: String? = nil, thumbnailName: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.basePrice = basePrice
        self.specifications = specifications
        self.compatibilityTags = compatibilityTags
        self.requiredTags = requiredTags
        self.modelFileName = modelFileName
        self.thumbnailName = thumbnailName
    }
}

// MARK: - Compatibility Rule
struct CompatibilityRule: Identifiable, Codable {
    let id: String
    let sourceComponentId: String
    let targetCategory: ComponentCategory
    let requiredTags: Set<String>
    let excludedTags: Set<String>
    let customValidation: String? // Reserved for future complex rules

    func isCompatible(with component: Component) -> Bool {
        // Component must be in the target category
        guard component.category == targetCategory else { return false }

        // Component must have all required tags
        guard requiredTags.isSubset(of: component.compatibilityTags) else { return false }

        // Component must not have any excluded tags
        guard excludedTags.isDisjoint(with: component.compatibilityTags) else { return false }

        return true
    }
}

// MARK: - Pricing Rule
struct PricingRule: Identifiable, Codable {
    let id: String
    let name: String
    let type: PricingRuleType
    let condition: PricingCondition
    let adjustment: PriceAdjustment
}

enum PricingRuleType: String, Codable {
    case discount
    case surcharge
    case bundleDiscount
    case volumeDiscount
}

struct PricingCondition: Codable {
    let componentIds: Set<String>
    let categories: Set<ComponentCategory>
    let minimumQuantity: Int?
    let requiresAll: Bool // true = all components must be present, false = any component

    func isMet(by configuration: Configuration) -> Bool {
        let selectedIds = Set(configuration.selectedComponents.keys)
        let selectedCategories = Set(configuration.selectedComponents.values.map { $0.category })

        var conditionMet = false

        if !componentIds.isEmpty {
            if requiresAll {
                conditionMet = componentIds.isSubset(of: selectedIds)
            } else {
                conditionMet = !componentIds.isDisjoint(with: selectedIds)
            }
        } else if !categories.isEmpty {
            if requiresAll {
                conditionMet = categories.isSubset(of: selectedCategories)
            } else {
                conditionMet = !categories.isDisjoint(with: selectedCategories)
            }
        } else {
            conditionMet = true
        }

        if let minQty = minimumQuantity {
            conditionMet = conditionMet && configuration.selectedComponents.count >= minQty
        }

        return conditionMet
    }
}

struct PriceAdjustment: Codable {
    let type: AdjustmentType
    let value: Decimal

    enum AdjustmentType: String, Codable {
        case percentage
        case fixedAmount
    }

    func apply(to price: Decimal) -> Decimal {
        switch type {
        case .percentage:
            return price * (1 + value / 100)
        case .fixedAmount:
            return price + value
        }
    }
}

// MARK: - Configuration
class Configuration: ObservableObject, Identifiable, Codable {
    let id: String
    @Published var name: String
    @Published var selectedComponents: [ComponentCategory: Component]
    @Published var createdAt: Date
    @Published var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, selectedComponents, createdAt, updatedAt
    }

    init(id: String = UUID().uuidString, name: String = "New Configuration") {
        self.id = id
        self.name = name
        self.selectedComponents = [:]
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        selectedComponents = try container.decode([ComponentCategory: Component].self, forKey: .selectedComponents)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(selectedComponents, forKey: .selectedComponents)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    func selectComponent(_ component: Component) {
        selectedComponents[component.category] = component
        updatedAt = Date()
    }

    func removeComponent(for category: ComponentCategory) {
        selectedComponents.removeValue(forKey: category)
        updatedAt = Date()
    }

    func isComplete() -> Bool {
        // At minimum, must have a base component
        return selectedComponents[.base] != nil
    }
}

// MARK: - Bill of Materials
struct BillOfMaterials: Identifiable {
    let id: String
    let configuration: Configuration
    let lineItems: [BOMLineItem]
    let subtotal: Decimal
    let adjustments: [PriceAdjustmentDetail]
    let total: Decimal
    let generatedAt: Date

    init(configuration: Configuration, lineItems: [BOMLineItem], adjustments: [PriceAdjustmentDetail]) {
        self.id = UUID().uuidString
        self.configuration = configuration
        self.lineItems = lineItems
        self.subtotal = lineItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
        self.adjustments = adjustments
        self.total = adjustments.reduce(subtotal) { total, adjustment in
            adjustment.adjustment.apply(to: total)
        }
        self.generatedAt = Date()
    }
}

struct BOMLineItem: Identifiable {
    let id: String
    let component: Component
    let quantity: Int
    let unitPrice: Decimal
    let totalPrice: Decimal

    init(component: Component, quantity: Int = 1) {
        self.id = UUID().uuidString
        self.component = component
        self.quantity = quantity
        self.unitPrice = component.basePrice
        self.totalPrice = component.basePrice * Decimal(quantity)
    }
}

struct PriceAdjustmentDetail: Identifiable {
    let id: String
    let rule: PricingRule
    let adjustment: PriceAdjustment
    let description: String

    init(rule: PricingRule) {
        self.id = UUID().uuidString
        self.rule = rule
        self.adjustment = rule.adjustment
        self.description = rule.name
    }
}

// MARK: - Quote
struct Quote: Identifiable, Codable {
    let id: String
    let configurationId: String
    let userId: String
    let billOfMaterials: QuoteBOM
    let validUntil: Date
    let status: QuoteStatus
    let createdAt: Date
    let notes: String?

    enum QuoteStatus: String, Codable {
        case draft
        case pending
        case approved
        case rejected
        case expired
    }

    init(configurationId: String, userId: String, billOfMaterials: QuoteBOM,
         validDays: Int = 30, notes: String? = nil) {
        self.id = UUID().uuidString
        self.configurationId = configurationId
        self.userId = userId
        self.billOfMaterials = billOfMaterials
        self.validUntil = Calendar.current.date(byAdding: .day, value: validDays, to: Date()) ?? Date()
        self.status = .draft
        self.createdAt = Date()
        self.notes = notes
    }
}

// Simplified BOM for encoding
struct QuoteBOM: Codable {
    let subtotal: Decimal
    let total: Decimal
    let items: [QuoteBOMItem]
}

struct QuoteBOMItem: Codable, Identifiable {
    let id: String
    let componentName: String
    let quantity: Int
    let unitPrice: Decimal
    let totalPrice: Decimal
}

// MARK: - User
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var company: String
    var savedConfigurations: [String] // Configuration IDs
    var quotes: [String] // Quote IDs

    init(id: String = UUID().uuidString, name: String, email: String, company: String) {
        self.id = id
        self.name = name
        self.email = email
        self.company = company
        self.savedConfigurations = []
        self.quotes = []
    }
}
