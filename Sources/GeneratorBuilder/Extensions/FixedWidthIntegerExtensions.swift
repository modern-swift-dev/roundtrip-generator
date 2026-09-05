import Foundation

public extension FixedWidthInteger {

    /// Return a swift enum value declaration for any integer into
    /// a string-safe format
    var swiftEnumValueDeclaration: String {
        let frmt = NumberFormatter()
        frmt.locale = Locale(identifier: "en_US_POSIX")
        frmt.numberStyle = .spellOut
        guard let decimal = Decimal(string: String(describing: self), locale: frmt.locale) else {
            return "_\(self)"
        }
        return frmt.string(from: NSDecimalNumber(decimal: decimal))?.camelized ?? "_\(self)"

    }
}
