//
//  Localization.swift
//  NekoPicFixPro
//
//  Shared helpers for localized strings.
//

import Foundation

enum L10n {
    /// Returns the localized string for the specified key.
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Returns the localized and formatted string for the specified key.
    static func formatted(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
