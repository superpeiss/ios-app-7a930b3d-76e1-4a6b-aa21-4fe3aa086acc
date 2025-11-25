import XCTest
@testable import IndustrialConfigurator

final class IndustrialConfiguratorTests: XCTestCase {

    func testConfigurationCreation() {
        let configuration = Configuration(name: "Test Configuration")
        XCTAssertEqual(configuration.name, "Test Configuration")
        XCTAssertTrue(configuration.selectedComponents.isEmpty)
    }

    func testComponentSelection() {
        let configuration = Configuration(name: "Test")
        let component = Component(
            id: "test-001",
            name: "Test Component",
            category: .base,
            description: "Test",
            basePrice: 100.0
        )

        configuration.selectComponent(component)
        XCTAssertEqual(configuration.selectedComponents.count, 1)
        XCTAssertEqual(configuration.selectedComponents[.base]?.id, "test-001")
    }

    func testBOMGeneration() {
        let configuration = Configuration(name: "Test")
        let component1 = Component(
            id: "test-001",
            name: "Base",
            category: .base,
            description: "Test",
            basePrice: 100.0
        )
        let component2 = Component(
            id: "test-002",
            name: "Mount",
            category: .mounting,
            description: "Test",
            basePrice: 50.0
        )

        configuration.selectComponent(component1)
        configuration.selectComponent(component2)

        let bom = BOMService.shared.generateBOM(for: configuration)
        XCTAssertEqual(bom.lineItems.count, 2)
        XCTAssertGreaterThanOrEqual(bom.subtotal, 150.0)
    }

    func testCompatibilityRules() {
        let databaseService = ProductDatabaseService.shared
        let baseComponents = databaseService.getComponents(for: .base)
        XCTAssertFalse(baseComponents.isEmpty)
    }

    func testPricingCalculation() {
        let configuration = Configuration(name: "Test")
        let component = Component(
            id: "test-001",
            name: "Base",
            category: .base,
            description: "Test",
            basePrice: 1000.0
        )

        configuration.selectComponent(component)
        let total = BOMService.shared.calculateTotalPrice(for: configuration)
        XCTAssertGreaterThanOrEqual(total, 1000.0)
    }
}
