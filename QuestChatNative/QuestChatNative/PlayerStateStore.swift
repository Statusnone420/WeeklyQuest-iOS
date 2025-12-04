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
// MARK: - XP - Level - Quest Rules
/*
Core idea:
- You are never punished. There are no debuffs and no negative XP.
- You always earn base XP for doing stuff.
- Buffs make all XP explode, so taking care of yourself feels like "cheating" the system.

Base XP:
- Every completed focus or self-care sprint grants base XP:
  baseXP = minutes * 10
  (e.g. 25 min = 250 XP, 50 min = 500 XP)

Buffs (no debuffs, ever):
- Buffs are daily status effects that only increase XP:
  • Hydrated     → water goal reached.
  • Rested       → sleep logged as OK/good/great.
  • Gut Happy    → gut logged as OK/good.
  • Ray of Sunshine → mood logged as good/great.
- Each active buff adds +20% XP to ALL XP earned for the rest of that day:
  xpMultiplier = 1.0 + 0.2 * activeBuffCount
  (0 buffs = 1.0x, 1 = 1.2x, 2 = 1.4x, 3 = 1.6x, 4 = 1.8x)
- If you are tired, dehydrated, or feel awful, you still get base XP.
  You just don't get buff multipliers. There are never XP penalties.

Health log XP + daily trifecta:
- First time per day you:
  • Hit water goal      → +250 XP and gain Hydrated buff.
  • Log decent sleep    → +250 XP and gain Rested buff.
  • Log decent gut      → +250 XP and gain Gut Happy buff.
  • Log positive mood   → gain Ray of Sunshine buff (no flat XP, just multiplier).
- If Hydrated + Rested + Gut Happy are all active in the same day:
  • One-time +500 XP "Health Trifecta" bonus for that day.

Streak XP:
- Each day you keep your streak alive (did at least one tracked action) → +100 XP.

Quests:
- Normal quest completion      → +300 XP.
- Big quest / quest chest      → +750 XP.

Level curve:
- Total XP required for level N is:
  requiredXPForLevelN = N * 1000
- Level-up occurs whenever totalXP crosses the next 1000 XP boundary.
- Level increases by 1 (capped at 100), and a "pending level up" flag can be set for UI.
*/
