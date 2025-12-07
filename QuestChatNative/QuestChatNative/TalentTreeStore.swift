import Foundation
import Combine

final class TalentTreeStore: ObservableObject {
    @Published private(set) var nodes: [TalentNode]
    @Published private(set) var currentRanks: [String: Int]
    @Published private(set) var totalPoints: Int
    @Published private(set) var spentPoints: Int
    @Published private(set) var currentLevel: Int  // external code can adjust this later

    init(
        nodes: [TalentNode] = TalentTreeConfig.defaultNodes,
        currentRanks: [String: Int] = [:],
        currentLevel: Int = 1
    ) {
        self.nodes = nodes
        self.currentRanks = currentRanks
        self.totalPoints = 0
        self.spentPoints = currentRanks.values.reduce(0, +)
        self.currentLevel = currentLevel
        applyLevel(currentLevel)
    }

    /// 1 talent point per level. Later we can clamp or adjust if needed.
    var pointsEarned: Int {
        totalPoints
    }

    var pointsSpent: Int {
        spentPoints
    }

    var availablePoints: Int {
        max(totalPoints - spentPoints, 0)
    }

    // Count how many talents are fully mastered (current rank >= maxRanks)
    private var masteredTalentCount: Int {
        nodes.reduce(0) { count, node in
            let current = currentRanks[node.id] ?? 0
            return current >= node.maxRanks ? count + 1 : count
        }
    }

    // Stage index based on mastered talents: every 2 mastered talents advances one stage.
    // This keeps compatibility with existing views that expect a stage index.
    var treeStageIndex: Int {
        // If there's an external array of stage images, replace 10 with its count.
        let totalStages = 10
        guard totalStages > 0 else { return 0 }
        let stageFromMastery = masteredTalentCount / 2
        return min(totalStages - 1, max(0, stageFromMastery))
    }

    // If callers use a 0–1 growth progress, keep it derived from the stage index.
    var growthProgress: Double {
        let totalStages = 10
        guard totalStages > 1 else { return 0 }
        return Double(treeStageIndex) / Double(totalStages - 1)
    }

    func rank(for node: TalentNode) -> Int {
        currentRanks[node.id] ?? 0
    }

    /// Checks tier requirement + prereqs + rank cap + available points.
    func canSpendPoint(on node: TalentNode) -> Bool {
        // No points left or already maxed
        guard availablePoints > 0 else { return false }
        let current = rank(for: node)
        guard current < node.maxRanks else { return false }

        // Tier requirement: tier 1 = 0, tier 2 = 5, tier 3 = 10, tier 4 = 15, tier 5 = 20
        let requiredPoints = max((node.tier - 1) * 5, 0)
        guard spentPoints >= requiredPoints else { return false }

        // Prerequisites must exist and be at max rank
        for prereqID in node.prerequisiteIDs {
            guard let prereqNode = nodes.first(where: { $0.id == prereqID }) else { return false }
            let prereqRank = currentRanks[prereqID] ?? 0
            guard prereqRank >= prereqNode.maxRanks else { return false }
        }

        return true
    }

    /// Attempts to spend a point into the provided node.
    func spendPoint(on node: TalentNode) {
        guard canSpendPoint(on: node) else { return }
        let current = rank(for: node)
        currentRanks[node.id] = current + 1
        recalculateSpentPoints()
    }

    func applyLevel(_ level: Int) {
        let maxPoints = nodes.reduce(0) { $0 + $1.maxRanks }
        let newTotalPoints = min(max(level, 0), maxPoints)

        currentLevel = level
        guard newTotalPoints != totalPoints else { return }

        totalPoints = newTotalPoints

        if spentPoints > totalPoints {
            currentRanks = [:]
            recalculateSpentPoints()
        }
    }

    func respecAll() {
        currentRanks = [:]
        spentPoints = 0
        saveIfNeeded()
    }

    private func recalculateSpentPoints() {
        spentPoints = currentRanks.values.reduce(0, +)
    }

    private func saveIfNeeded() {
        // Placeholder for persistence integration.
    }
}
