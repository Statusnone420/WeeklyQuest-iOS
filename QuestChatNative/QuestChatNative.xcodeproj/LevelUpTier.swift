import Foundation

enum LevelUpTier {
    case normal
    case milestone
    case jackpot
    
    /// Compute the tier based on old and new level
    static func compute(oldLevel: Int, newLevel: Int) -> LevelUpTier {
        // Jackpot: every 10 levels (10, 20, 30, etc.)
        if newLevel % 10 == 0 {
            return .jackpot
        }
        
        // Milestone: every 5 levels (5, 15, 25, etc.)
        if newLevel % 5 == 0 {
            return .milestone
        }
        
        // Small chance of random jackpot (3% chance)
        if Double.random(in: 0...1) < 0.03 {
            return .jackpot
        }
        
        return .normal
    }
}

/// Data structure for pending level-up notifications
struct PendingLevelUp {
    let level: Int
    let tier: LevelUpTier
}
