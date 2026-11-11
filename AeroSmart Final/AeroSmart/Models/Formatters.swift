import Foundation

extension Date {
    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let shortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    private static let longDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEEE d 'de' MMMM"
        return formatter
    }()

    var hourText: String {
        Date.hourFormatter.string(from: self)
    }

    var shortDayText: String {
        Date.shortDayFormatter.string(from: self).firstCapitalized
    }

    var longDayText: String {
        Date.longDayFormatter.string(from: self).firstCapitalized
    }
}

extension String {
    var firstCapitalized: String {
        guard let first = self.first else { return self }
        return first.uppercased() + String(self.dropFirst())
    }
}

func moneyText(_ value: Double, currency: String) -> String {
    return value.formatted(.currency(code: currency))
}

func durationText(_ minutes: Int) -> String {
    return "\(minutes / 60) h \(minutes % 60) min"
}

func minutesFromISODuration(_ text: String) -> Int? {
    var days = 0
    var hours = 0
    var minutes = 0
    var number = ""
    for character in text {
        if character.isNumber {
            number.append(character)
        } else if character == "D" {
            days = Int(number) ?? 0
            number = ""
        } else if character == "H" {
            hours = Int(number) ?? 0
            number = ""
        } else if character == "M" {
            minutes = Int(number) ?? 0
            number = ""
        } else {
            number = ""
        }
    }
    let total = days * 24 * 60 + hours * 60 + minutes
    return total > 0 ? total : nil
}
