import Foundation
import Combine

// MARK: - Product Database Service
class ProductDatabaseService: ObservableObject {
    static let shared = ProductDatabaseService()

    @Published private(set) var components: [Component] = []
    @Published private(set) var compatibilityRules: [CompatibilityRule] = []
    @Published private(set) var pricingRules: [PricingRule] = []
    @Published private(set) var isLoading = false

    private init() {
        loadDatabase()
    }

    // MARK: - Database Loading
    func loadDatabase() {
        isLoading = true
        defer { isLoading = false }

        // In production, this would fetch from a server or local database
        // For now, we'll use mock data
        loadMockComponents()
        loadMockCompatibilityRules()
        loadMockPricingRules()
    }

    // MARK: - Component Queries
    func getComponents(for category: ComponentCategory) -> [Component] {
        return components.filter { $0.category == category }
    }

    func getComponent(byId id: String) -> Component? {
        return components.first { $0.id == id }
    }

    func getCompatibleComponents(for sourceComponent: Component, targetCategory: ComponentCategory) -> [Component] {
        let allComponentsInCategory = getComponents(for: targetCategory)

        // Get compatibility rules for this source component
        let applicableRules = compatibilityRules.filter {
            $0.sourceComponentId == sourceComponent.id && $0.targetCategory == targetCategory
        }

        // If no rules exist, return all components in category (permissive)
        guard !applicableRules.isEmpty else {
            return allComponentsInCategory
        }

        // Filter components based on compatibility rules
        return allComponentsInCategory.filter { targetComponent in
            applicableRules.contains { rule in
                rule.isCompatible(with: targetComponent)
            }
        }
    }

    func getCompatibleComponents(for configuration: Configuration, targetCategory: ComponentCategory) -> [Component] {
        let allComponentsInCategory = getComponents(for: targetCategory)

        // Get all selected components
        let selectedComponents = Array(configuration.selectedComponents.values)

        // If no components selected yet, return all base components for base category
        guard !selectedComponents.isEmpty else {
            return targetCategory == .base ? allComponentsInCategory : []
        }

        // Collect all compatibility requirements from selected components
        var compatibleComponents = Set(allComponentsInCategory)

        for selectedComponent in selectedComponents {
            let compatibleForThis = Set(getCompatibleComponents(for: selectedComponent, targetCategory: targetCategory))
            compatibleComponents.formIntersection(compatibleForThis.isEmpty ? allComponentsInCategory : compatibleForThis)
        }

        return Array(compatibleComponents).sorted { $0.name < $1.name }
    }

    // MARK: - Pricing Rules
    func getApplicablePricingRules(for configuration: Configuration) -> [PricingRule] {
        return pricingRules.filter { rule in
            rule.condition.isMet(by: configuration)
        }
    }

    // MARK: - Mock Data Loading
    private func loadMockComponents() {
        components = [
            // Base Components
            Component(
                id: "base-001",
                name: "Industrial Base Unit XL",
                category: .base,
                description: "Heavy-duty industrial base platform for large assemblies",
                basePrice: 1250.00,
                specifications: ["Weight Capacity": "500kg", "Dimensions": "600x600x100mm", "Material": "Aluminum"],
                compatibilityTags: ["heavy-duty", "large", "aluminum"],
                modelFileName: "base_xl"
            ),
            Component(
                id: "base-002",
                name: "Compact Base Unit",
                category: .base,
                description: "Space-saving base platform for standard assemblies",
                basePrice: 650.00,
                specifications: ["Weight Capacity": "200kg", "Dimensions": "400x400x80mm", "Material": "Steel"],
                compatibilityTags: ["standard", "compact", "steel"],
                modelFileName: "base_compact"
            ),
            Component(
                id: "base-003",
                name: "Precision Base Unit",
                category: .base,
                description: "High-precision base with micro-adjustment capabilities",
                basePrice: 1850.00,
                specifications: ["Weight Capacity": "300kg", "Dimensions": "500x500x90mm", "Material": "Cast Iron"],
                compatibilityTags: ["precision", "standard", "cast-iron"],
                modelFileName: "base_precision"
            ),

            // Mounting Systems
            Component(
                id: "mount-001",
                name: "Heavy-Duty Mounting Bracket",
                category: .mounting,
                description: "Reinforced mounting system for heavy loads",
                basePrice: 320.00,
                specifications: ["Load Rating": "500kg", "Mounting Points": "8", "Material": "Steel"],
                compatibilityTags: ["heavy-duty", "large"],
                requiredTags: ["heavy-duty"],
                modelFileName: "mount_heavy"
            ),
            Component(
                id: "mount-002",
                name: "Standard Mounting System",
                category: .mounting,
                description: "Versatile mounting system for standard applications",
                basePrice: 180.00,
                specifications: ["Load Rating": "250kg", "Mounting Points": "6", "Material": "Aluminum"],
                compatibilityTags: ["standard", "compact"],
                modelFileName: "mount_standard"
            ),
            Component(
                id: "mount-003",
                name: "Precision Micro-Adjustment Mount",
                category: .mounting,
                description: "High-precision mounting with fine adjustment screws",
                basePrice: 480.00,
                specifications: ["Load Rating": "300kg", "Mounting Points": "6", "Adjustment": "0.01mm"],
                compatibilityTags: ["precision", "standard"],
                requiredTags: ["precision"],
                modelFileName: "mount_precision"
            ),

            // Power Supplies
            Component(
                id: "power-001",
                name: "Industrial Power Supply 1000W",
                category: .power,
                description: "High-power supply for demanding applications",
                basePrice: 560.00,
                specifications: ["Power": "1000W", "Voltage": "24V DC", "Efficiency": "95%"],
                compatibilityTags: ["high-power", "heavy-duty"],
                modelFileName: "power_1000w"
            ),
            Component(
                id: "power-002",
                name: "Standard Power Supply 500W",
                category: .power,
                description: "Reliable power supply for standard configurations",
                basePrice: 280.00,
                specifications: ["Power": "500W", "Voltage": "24V DC", "Efficiency": "92%"],
                compatibilityTags: ["standard-power", "standard", "compact"],
                modelFileName: "power_500w"
            ),
            Component(
                id: "power-003",
                name: "Precision Power Supply 750W",
                category: .power,
                description: "Ultra-stable power supply with voltage regulation",
                basePrice: 640.00,
                specifications: ["Power": "750W", "Voltage": "24V DC", "Stability": "±0.1%"],
                compatibilityTags: ["regulated-power", "precision"],
                modelFileName: "power_precision"
            ),

            // Control Modules
            Component(
                id: "ctrl-001",
                name: "Advanced PLC Controller",
                category: .control,
                description: "Programmable logic controller with 32 I/O points",
                basePrice: 1420.00,
                specifications: ["I/O Points": "32", "Memory": "512KB", "Protocols": "Modbus, EtherNet/IP"],
                compatibilityTags: ["advanced-control", "heavy-duty", "precision"],
                modelFileName: "control_plc"
            ),
            Component(
                id: "ctrl-002",
                name: "Basic Control Module",
                category: .control,
                description: "Simple control module for basic operations",
                basePrice: 380.00,
                specifications: ["I/O Points": "16", "Memory": "128KB", "Protocols": "Modbus"],
                compatibilityTags: ["basic-control", "standard", "compact"],
                modelFileName: "control_basic"
            ),
            Component(
                id: "ctrl-003",
                name: "Motion Controller",
                category: .control,
                description: "Specialized controller for precision motion control",
                basePrice: 1980.00,
                specifications: ["Axes": "6", "Resolution": "0.001°", "Protocols": "EtherCAT"],
                compatibilityTags: ["motion-control", "precision"],
                requiredTags: ["precision"],
                modelFileName: "control_motion"
            ),

            // Sensors
            Component(
                id: "sensor-001",
                name: "Precision Position Sensor",
                category: .sensor,
                description: "High-accuracy position sensor with 0.001mm resolution",
                basePrice: 890.00,
                specifications: ["Resolution": "0.001mm", "Range": "500mm", "Output": "Analog 4-20mA"],
                compatibilityTags: ["precision-sensor", "precision"],
                modelFileName: "sensor_position"
            ),
            Component(
                id: "sensor-002",
                name: "Proximity Sensor Array",
                category: .sensor,
                description: "Multi-point proximity detection system",
                basePrice: 420.00,
                specifications: ["Sensors": "4", "Range": "50mm", "Output": "Digital NPN"],
                compatibilityTags: ["proximity-sensor", "standard"],
                modelFileName: "sensor_proximity"
            ),
            Component(
                id: "sensor-003",
                name: "Load Cell System",
                category: .sensor,
                description: "High-capacity load measurement system",
                basePrice: 1240.00,
                specifications: ["Capacity": "500kg", "Accuracy": "0.1%", "Output": "Analog Voltage"],
                compatibilityTags: ["load-sensor", "heavy-duty"],
                requiredTags: ["heavy-duty"],
                modelFileName: "sensor_load"
            ),

            // Actuators
            Component(
                id: "act-001",
                name: "Heavy-Duty Linear Actuator",
                category: .actuator,
                description: "High-force linear actuator for demanding applications",
                basePrice: 1650.00,
                specifications: ["Force": "10kN", "Stroke": "500mm", "Speed": "50mm/s"],
                compatibilityTags: ["linear-actuator", "heavy-duty"],
                requiredTags: ["heavy-duty"],
                modelFileName: "actuator_linear"
            ),
            Component(
                id: "act-002",
                name: "Servo Motor with Gearbox",
                category: .actuator,
                description: "Precision servo motor for controlled motion",
                basePrice: 1280.00,
                specifications: ["Torque": "20Nm", "Speed": "3000rpm", "Resolution": "0.01°"],
                compatibilityTags: ["servo-actuator", "precision"],
                modelFileName: "actuator_servo"
            ),
            Component(
                id: "act-003",
                name: "Pneumatic Cylinder",
                category: .actuator,
                description: "Fast-acting pneumatic cylinder",
                basePrice: 540.00,
                specifications: ["Bore": "63mm", "Stroke": "200mm", "Pressure": "6 bar"],
                compatibilityTags: ["pneumatic-actuator", "standard"],
                modelFileName: "actuator_pneumatic"
            ),

            // Interface Modules
            Component(
                id: "intf-001",
                name: "Industrial Ethernet Gateway",
                category: .interface,
                description: "Multi-protocol industrial Ethernet gateway",
                basePrice: 980.00,
                specifications: ["Ports": "4", "Protocols": "EtherNet/IP, Modbus TCP, PROFINET"],
                compatibilityTags: ["ethernet-interface", "advanced-control"],
                modelFileName: "interface_ethernet"
            ),
            Component(
                id: "intf-002",
                name: "Fieldbus Interface Module",
                category: .interface,
                description: "Standard fieldbus communication module",
                basePrice: 420.00,
                specifications: ["Protocol": "Modbus RTU", "Baud Rate": "115200", "Ports": "2"],
                compatibilityTags: ["fieldbus-interface", "basic-control", "standard"],
                modelFileName: "interface_fieldbus"
            ),
            Component(
                id: "intf-003",
                name: "Wireless IoT Gateway",
                category: .interface,
                description: "Cloud-connected IoT gateway with wireless connectivity",
                basePrice: 1120.00,
                specifications: ["Protocols": "MQTT, REST", "Connectivity": "WiFi, 4G LTE"],
                compatibilityTags: ["iot-interface", "precision", "standard"],
                modelFileName: "interface_iot"
            ),

            // Housing
            Component(
                id: "house-001",
                name: "Industrial Enclosure IP67",
                category: .housing,
                description: "Weatherproof industrial enclosure",
                basePrice: 780.00,
                specifications: ["Rating": "IP67", "Material": "Stainless Steel", "Size": "600x600x300mm"],
                compatibilityTags: ["sealed-housing", "heavy-duty", "large"],
                modelFileName: "housing_ip67"
            ),
            Component(
                id: "house-002",
                name: "Compact Protective Housing",
                category: .housing,
                description: "Space-efficient protective housing",
                basePrice: 380.00,
                specifications: ["Rating": "IP54", "Material": "Aluminum", "Size": "400x400x200mm"],
                compatibilityTags: ["standard-housing", "compact"],
                modelFileName: "housing_compact"
            ),
            Component(
                id: "house-003",
                name: "Precision Climate-Controlled Enclosure",
                category: .housing,
                description: "Temperature and humidity controlled enclosure",
                basePrice: 2140.00,
                specifications: ["Rating": "IP65", "Material": "Steel", "Temperature": "20±0.5°C"],
                compatibilityTags: ["climate-housing", "precision"],
                requiredTags: ["precision"],
                modelFileName: "housing_climate"
            )
        ]
    }

    private func loadMockCompatibilityRules() {
        compatibilityRules = [
            // Heavy-Duty Base requires heavy-duty mounting
            CompatibilityRule(
                id: "rule-001",
                sourceComponentId: "base-001",
                targetCategory: .mounting,
                requiredTags: ["heavy-duty"],
                excludedTags: []
            ),

            // Compact Base works with standard mounting
            CompatibilityRule(
                id: "rule-002",
                sourceComponentId: "base-002",
                targetCategory: .mounting,
                requiredTags: [],
                excludedTags: ["heavy-duty"]
            ),

            // Precision Base requires precision mounting
            CompatibilityRule(
                id: "rule-003",
                sourceComponentId: "base-003",
                targetCategory: .mounting,
                requiredTags: ["precision"],
                excludedTags: []
            ),

            // Heavy-duty configurations need high-power supplies
            CompatibilityRule(
                id: "rule-004",
                sourceComponentId: "mount-001",
                targetCategory: .power,
                requiredTags: ["high-power"],
                excludedTags: []
            ),

            // Precision mounting needs regulated power
            CompatibilityRule(
                id: "rule-005",
                sourceComponentId: "mount-003",
                targetCategory: .power,
                requiredTags: ["regulated-power"],
                excludedTags: []
            ),

            // Advanced control for heavy-duty systems
            CompatibilityRule(
                id: "rule-006",
                sourceComponentId: "power-001",
                targetCategory: .control,
                requiredTags: ["advanced-control"],
                excludedTags: ["basic-control"]
            ),

            // Motion control requires precision components
            CompatibilityRule(
                id: "rule-007",
                sourceComponentId: "ctrl-003",
                targetCategory: .sensor,
                requiredTags: ["precision-sensor"],
                excludedTags: []
            ),

            // Heavy-duty actuators need heavy-duty base
            CompatibilityRule(
                id: "rule-008",
                sourceComponentId: "act-001",
                targetCategory: .sensor,
                requiredTags: ["load-sensor"],
                excludedTags: []
            )
        ]
    }

    private func loadMockPricingRules() {
        pricingRules = [
            // Bundle discount for complete precision system
            PricingRule(
                id: "price-001",
                name: "Precision System Bundle - 10% Discount",
                type: .bundleDiscount,
                condition: PricingCondition(
                    componentIds: [],
                    categories: [.base, .mounting, .power, .control],
                    minimumQuantity: 4,
                    requiresAll: true
                ),
                adjustment: PriceAdjustment(type: .percentage, value: -10)
            ),

            // Volume discount
            PricingRule(
                id: "price-002",
                name: "Complete System Discount - 15% Off",
                type: .volumeDiscount,
                condition: PricingCondition(
                    componentIds: [],
                    categories: Set(ComponentCategory.allCases),
                    minimumQuantity: 7,
                    requiresAll: false
                ),
                adjustment: PriceAdjustment(type: .percentage, value: -15)
            ),

            // Climate housing surcharge
            PricingRule(
                id: "price-003",
                name: "Climate Control Integration Fee",
                type: .surcharge,
                condition: PricingCondition(
                    componentIds: ["house-003"],
                    categories: [],
                    minimumQuantity: nil,
                    requiresAll: false
                ),
                adjustment: PriceAdjustment(type: .fixedAmount, value: 500)
            ),

            // IoT Gateway installation fee
            PricingRule(
                id: "price-004",
                name: "IoT Gateway Setup & Configuration",
                type: .surcharge,
                condition: PricingCondition(
                    componentIds: ["intf-003"],
                    categories: [],
                    minimumQuantity: nil,
                    requiresAll: false
                ),
                adjustment: PriceAdjustment(type: .fixedAmount, value: 350)
            )
        ]
    }
}
