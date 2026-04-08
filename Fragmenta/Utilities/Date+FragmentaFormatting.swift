import Foundation

extension Date {
    func fragmentaDayMonthYearString() -> String {
        DateFormatter.fragmentaDisplay.string(from: self)
    }

    func fragmentaRelativeDescription(referenceDate: Date = .now) -> String {
        DateFormatter.fragmentaRelative.localizedString(for: self, relativeTo: referenceDate)
    }
}

private extension DateFormatter {
    static let fragmentaDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let fragmentaRelative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
