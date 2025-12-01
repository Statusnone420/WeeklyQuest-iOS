import Foundation

struct HealthBarCalculator {
    static func hp(for inputs: DailyHealthInputs) -> Int {
        let baseHP = 40

        let hydrationHP = min(inputs.hydrationCount * 4, 20)
        let selfCareHP = min(inputs.selfCareSessions * 6, 18)
        let focusHP = min(inputs.focusSprints * 3, 6)

        let gutHP: Int = {
            switch inputs.gutStatus {
            case .none:   return 0
            case .great:  return 15
            case .meh:    return 8
            case .rough:  return 2
            }
        }()

        let moodModifier: Int = {
            switch inputs.moodStatus {
            case .none:    return 0
            case .good:    return 5
            case .neutral: return 0
            case .bad:     return -5
            }
        }()

        let total = baseHP + hydrationHP + selfCareHP + focusHP + gutHP + moodModifier
        return max(0, min(total, 100))
    }
}
