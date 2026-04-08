import SwiftUI

enum FragmentaTypography {
    static let display = Font.system(size: 40, weight: .bold, design: .rounded)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let heroDate = Font.system(size: 28, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let cardTitle = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .default)
    static let subheadline = Font.system(size: 15, weight: .medium, design: .rounded)
    static let narrative = Font.system(size: 18, weight: .regular, design: .serif)
    static let eyebrow = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let metadata = Font.system(size: 13, weight: .medium, design: .rounded)
    static let monospacedMetadata = Font.system(size: 12, weight: .medium, design: .rounded).monospaced()
    static let chip = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
}
