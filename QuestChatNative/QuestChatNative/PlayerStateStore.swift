import Foundation
import Combine

/// Observable object representing the player's current state within QuestChat.
final class PlayerStateStore: ObservableObject {
    @Published var currentHP: Int
    @Published var maxHP: Int
    @Published var xp: Int
    @Published var level: Int
    @Published var hydration: Int
    @Published var mood: Int
    @Published var gutStatus: Int
    @Published var sleepQuality: Int
    @Published var activeDebuffs: [String]
    @Published var activeBuffs: [String]

    init(
        currentHP: Int = 100,
        maxHP: Int = 100,
        xp: Int = 0,
        level: Int = 1,
        hydration: Int = 100,
        mood: Int = 0,
        gutStatus: Int = 0,
        sleepQuality: Int = 3,
        activeDebuffs: [String] = [],
        activeBuffs: [String] = []
    ) {
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.xp = xp
        self.level = level
        self.hydration = hydration
        self.mood = mood
        self.gutStatus = gutStatus
        self.sleepQuality = sleepQuality
        self.activeDebuffs = activeDebuffs
        self.activeBuffs = activeBuffs
    }

    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        let percentage = Double(currentHP) / Double(maxHP)
        return min(max(percentage, 0), 1)
    }
}
